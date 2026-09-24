import 'dart:async';

/// Categories of camera/ML failures handled by the pipeline.
enum CameraErrorType {
  /// Camera permission was denied by the user.
  permissionDenied,

  /// No usable camera is present on the device.
  cameraUnavailable,

  /// The pose detector timed out or failed.
  detectorFailure,

  /// Battery is below the critical threshold.
  lowBattery,

  /// Any other unexpected error.
  unknown;

  /// Human-readable message for the user.
  String get userMessage {
    switch (this) {
      case CameraErrorType.permissionDenied:
        return 'Camera access was denied. Enable it in settings or switch to manual mode.';
      case CameraErrorType.cameraUnavailable:
        return 'No camera available on this device. Switch to manual mode?';
      case CameraErrorType.detectorFailure:
        return 'Pose detection stopped responding. Retrying...';
      case CameraErrorType.lowBattery:
        return 'Battery below 15%. Consider switching to manual mode.';
      case CameraErrorType.unknown:
        return 'Something went wrong. Please retry.';
    }
  }
}

/// Result of an error-handling decision.
class CameraErrorDecision {
  /// The classified error type.
  final CameraErrorType type;

  /// Whether the pipeline should fall back to manual counting mode.
  final bool fallbackToManual;

  /// Whether the failing operation should be retried automatically.
  final bool retry;

  /// Creates a decision.
  const CameraErrorDecision({
    required this.type,
    required this.fallbackToManual,
    required this.retry,
  });
}

/// Classifies camera/ML errors and decides on the recovery strategy:
/// retry, fall back to manual mode, or simply inform the user.
class CameraErrorHandler {
  /// Battery level below which the manual fallback is recommended.
  static const double criticalBatteryLevel = 15;

  /// Maximum time without a detection result before declaring failure.
  final Duration detectorTimeout;

  /// Battery level provider (0-100), injectable for testing.
  final Future<double?> Function() batteryLevelProvider;

  /// Whether the camera permission was granted.
  final bool Function() hasCameraPermission;

  Timer? _timeoutTimer;

  CameraErrorHandler({
    this.detectorTimeout = const Duration(seconds: 5),
    required this.batteryLevelProvider,
    required this.hasCameraPermission,
  });

  /// Classifies a thrown [error] into a decision.
  CameraErrorDecision handleError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('permission') || message.contains('denied') ||
        !hasCameraPermission()) {
      return const CameraErrorDecision(
        type: CameraErrorType.permissionDenied,
        fallbackToManual: true,
        retry: false,
      );
    }
    if (message.contains('camera') && message.contains('unavailable') ||
        message.contains('no camera')) {
      return const CameraErrorDecision(
        type: CameraErrorType.cameraUnavailable,
        fallbackToManual: true,
        retry: false,
      );
    }
    if (message.contains('timeout')) {
      return const CameraErrorDecision(
        type: CameraErrorType.detectorFailure,
        fallbackToManual: false,
        retry: true,
      );
    }
    return const CameraErrorDecision(
      type: CameraErrorType.unknown,
      fallbackToManual: false,
      retry: true,
    );
  }

  /// Checks the battery level and recommends manual mode when critical.
  Future<CameraErrorDecision> checkBattery() async {
    final level = await batteryLevelProvider();
    if (level != null && level < criticalBatteryLevel) {
      return const CameraErrorDecision(
        type: CameraErrorType.lowBattery,
        fallbackToManual: true,
        retry: false,
      );
    }
    return const CameraErrorDecision(
      type: CameraErrorType.unknown,
      fallbackToManual: false,
      retry: false,
    );
  }

  /// Starts a detector watchdog; calls [onTimeout] if no result arrives
  /// within [detectorTimeout].
  void startDetectorWatchdog(void Function() onTimeout) {
    cancelDetectorWatchdog();
    _timeoutTimer = Timer(detectorTimeout, onTimeout);
  }

  /// Cancels the watchdog, e.g. when a detection result arrives.
  void cancelDetectorWatchdog() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  /// Releases timers. Call when the handler is no longer needed.
  void dispose() => cancelDetectorWatchdog();
}