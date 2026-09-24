import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Manages camera lifecycle: initialization, front/back switching,
/// zoom and flash control. Notifies listeners when the controller changes.
class CameraService extends ChangeNotifier {
  CameraController? _controller;
  double _maxZoomLevel = 1.0;

  /// The active camera controller, if initialized.
  CameraController? get controller => _controller;

  /// Whether the camera has been initialized and started.
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  /// Whether the active camera faces the user.
  bool get isFrontCamera =>
      _controller?.description.lensDirection == CameraLensDirection.front;

  /// The maximum zoom level supported by the active camera.
  double get maxZoomLevel => _maxZoomLevel;

  /// Discovers and initializes the default (back) camera.
  ///
  /// [onError] is invoked when no camera is available or startup fails.
  Future<void> initialize({void Function(String error)? onError}) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        onError?.call('No camera available');
        return;
      }
      await _start(cameras.first);
    } on CameraException catch (e) {
      onError?.call(e.description ?? 'Camera error');
    }
  }

  Future<void> _start(CameraDescription camera) async {
    final old = _controller;
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );
    await controller.initialize();
    _maxZoomLevel = await controller.getMaxZoomLevel();
    _controller = controller;
    notifyListeners();
    await old?.dispose();
  }

  /// Switches between the front and back cameras.
  Future<void> switchCamera() async {
    final cameras = await availableCameras();
    if (cameras.length < 2) return;
    final current = _controller?.description;
    final next = cameras.firstWhere((c) => c.name != current?.name,
        orElse: () => cameras.first);
    await _start(next);
  }

  /// Sets the flash mode. Returns false when not ready.
  Future<bool> setFlashMode(FlashMode mode) async {
    final controller = _controller;
    if (controller == null) return false;
    try {
      await controller.setFlashMode(mode);
      return true;
    } on CameraException {
      return false;
    }
  }

  /// Sets the zoom factor. Returns false when not ready.
  Future<bool> setZoom(double zoom) async {
    final controller = _controller;
    if (controller == null) return false;
    try {
      await controller.setZoomLevel(zoom.clamp(1.0, _maxZoomLevel));
      return true;
    } on CameraException {
      return false;
    }
  }

  /// Pauses the active preview.
  Future<void> pause() async => await _controller?.pausePreview();

  /// Resumes the active preview.
  Future<void> resume() async => await _controller?.resumePreview();

  /// Releases the camera. Call when the service is no longer needed.
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}