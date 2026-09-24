import 'dart:async';

import 'package:fitpact/core/math/point_3d.dart';
import 'package:flutter/foundation.dart';

import 'frame_processor.dart';

/// Coordinates the flow camera -> pose detector -> state machine -> UI.
///
/// Frames offered by the camera are throttled by a [FrameProcessor], the
/// resulting landmark lists are kept in a small rolling buffer (3 frames)
/// and forwarded to listeners (e.g. state machines or UI).
class PipelineCoordinator {
 /// Maximum number of recent results kept in the buffer.
 static const int bufferSize = 3;

 final FrameProcessor _frameProcessor;
 final List<List<Point3D>> _buffer = [];
 final StreamController<List<Point3D>> _landmarksController =
 StreamController<List<Point3D>>.broadcast();

 PipelineCoordinator({required FrameProcessor frameProcessor})
 : _frameProcessor = frameProcessor;

 /// Live stream of landmark lists, one event per processed frame.
 Stream<List<Point3D>> get landmarksStream => _landmarksController.stream;

 /// The rolling buffer of the most recent [bufferSize] landmark lists.
 List<List<Point3D>> get buffer => List.unmodifiable(_buffer);

 /// The last processed landmark list, if any.
 List<Point3D>? get lastLandmarks =>
 _buffer.isEmpty ? null : _buffer.last;

 /// Offers one camera frame for processing, forwarding results to
 /// [landmarksStream] and maintaining the rolling buffer.
 Future<void> processFrame() async {
 final result = await _frameProcessor.offerFrame();
 if (result == null) return;
 _buffer.add(result.landmarks);
 while (_buffer.length > bufferSize) {
 _buffer.removeAt(0);
 }
 _landmarksController.add(result.landmarks);
 }

 /// Clears the buffer and resets the underlying frame processor.
 void reset() {
 _buffer.clear();
 _frameProcessor.reset();
 }

 /// Releases stream resources.
 void dispose() {
 _landmarksController.close();
 }
}