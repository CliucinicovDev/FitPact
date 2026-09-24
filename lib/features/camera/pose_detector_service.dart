import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:fitpact/core/math/point_3d.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Wraps the ML Kit pose detector with lifecycle management and maps
/// ML Kit landmarks to [Point3D] with confidence filtering.
class PoseDetectorService {
  PoseDetector? _detector;
  bool _isBusy = false;
  final double minConfidence;

  PoseDetectorService({this.minConfidence = 0.5});

  /// Whether the detector has been initialized.
  bool get isInitialized => _detector != null;

  /// Whether a frame is currently being processed.
  bool get isBusy => _isBusy;

  /// Initializes the ML Kit pose detector in stream mode with the
  /// base model.
  void initialize() {
    _detector?.close();
    _detector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.base,
      ),
    );
  }

  /// Processes a camera image and returns filtered 3D landmarks.
  ///
  /// [sensorOrientation] describes the rotation of the camera sensor;
  /// pass `cameraDescription.sensorOrientation` from the active camera.
  ///
  /// Returns an empty list when the detector is not initialized, the
  /// service is busy, the image cannot be decoded, or no pose is found.
  Future<List<Point3D>> processImage(
    CameraImage image, {
    int sensorOrientation = 0,
  }) async {
    final detector = _detector;
    if (detector == null || _isBusy) return const [];
    final inputImage = _toInputImage(image, sensorOrientation);
    if (inputImage == null) return const [];
    _isBusy = true;
    try {
      final poses = await detector.processImage(inputImage);
      if (poses.isEmpty) return const [];
      return _mapLandmarks(poses.first);
    } catch (_) {
      return const [];
    } finally {
      _isBusy = false;
    }
  }

  /// Converts a [CameraImage] into an ML Kit [InputImage], or null when
  /// the image cannot be decoded (unknown format, no planes).
  InputImage? _toInputImage(CameraImage image, int sensorOrientation) {
    final rotation =
        InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null || image.planes.isEmpty) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

    final builder = BytesBuilder(copy: false);
    for (final plane in image.planes) {
      builder.add(plane.bytes);
    }

    return InputImage.fromBytes(
      bytes: builder.takeBytes(),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  /// Maps ML Kit pose landmarks to [Point3D], dropping low-confidence ones.
  List<Point3D> _mapLandmarks(Pose pose) {
    final landmarks = <Point3D>[];
    for (final type in PoseLandmarkType.values) {
      final lm = pose.landmarks[type];
      if (lm == null) continue;
      if ((lm.likelihood ?? 1.0) < minConfidence) continue;
      landmarks.add(Point3D(lm.x, lm.y, lm.z));
    }
    return landmarks;
  }

  /// Releases the detector. Call when the service is no longer needed.
  void dispose() {
    _detector?.close();
    _detector = null;
    _isBusy = false;
  }
}