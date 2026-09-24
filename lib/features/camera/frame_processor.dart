import 'dart:async';

import 'package:fitpact/core/math/point_3d.dart';

/// Result of one processed frame.
class ProcessedFrame {
  /// 3D pose landmarks extracted from the frame.
  final List<Point3D> landmarks;

  /// Wall-clock time (from the processor's clock) of the processing result.
  final DateTime timestamp;

  /// Creates a frame result.
  const ProcessedFrame({required this.landmarks, required this.timestamp});
}

/// Throttles frame processing to a maximum rate and skips work while busy,
/// while always keeping the most recent result available.
///
/// The processing function is supplied by the caller; the processor only
/// decides *when* it runs.
class FrameProcessor {
  /// Minimum interval between two processed frames.
  final Duration minInterval;

  final Future<ProcessedFrame?> Function() _processor;
  final DateTime Function() _now;

  bool _busy = false;
  DateTime _lastProcessedAt = DateTime.fromMillisecondsSinceEpoch(0);
  int _processedCount = 0;
  int _skippedCount = 0;
  ProcessedFrame? _lastResult;

  FrameProcessor({
    this.minInterval = const Duration(milliseconds: 66), // ~15 fps
    required Future<ProcessedFrame?> Function() processor,
    DateTime Function()? clock,
  })  : _processor = processor,
        _now = clock ?? DateTime.now;

  /// The most recent successfully processed frame, if any.
  ProcessedFrame? get lastResult => _lastResult;

  /// Number of frames processed so far.
  int get processedCount => _processedCount;

  /// Number of frames skipped due to rate limiting or busy state.
  int get skippedCount => _skippedCount;

  /// Whether a frame is currently being processed.
  bool get isBusy => _busy;

  /// Offers a frame for processing.
  ///
  /// The frame is skipped (returning null) when the processor is busy or
  /// the last processed frame is more recent than [minInterval].
  Future<ProcessedFrame?> offerFrame() async {
    if (_busy) {
      _skippedCount++;
      return null;
    }
    final now = _now();
    if (now.difference(_lastProcessedAt) < minInterval) {
      _skippedCount++;
      return null;
    }
    _busy = true;
    try {
      final result = await _processor();
      _lastProcessedAt = _now();
      if (result != null) {
        _lastResult = result;
        _processedCount++;
      }
      return result;
    } finally {
      _busy = false;
    }
  }

  /// Resets counters and the cached last result.
  void reset() {
    _busy = false;
    _lastProcessedAt = DateTime.fromMillisecondsSinceEpoch(0);
    _processedCount = 0;
    _skippedCount = 0;
    _lastResult = null;
  }
}