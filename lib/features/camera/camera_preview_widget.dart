import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'camera_service.dart';

/// Widget that renders the live camera preview from [CameraService].
///
/// Rebuilds whenever the underlying camera controller changes (e.g. after
/// initialization or a front/back switch) or its value updates.
class CameraPreviewWidget extends StatelessWidget {
  /// Provides the camera controller to render.
  final CameraService service;

  /// Optional overlay rendered on top of the preview.
  final Widget? overlay;

  /// Widget shown when the camera is unavailable or not initialized yet.
  final Widget? errorBuilder;

  const CameraPreviewWidget({
    super.key,
    required this.service,
    this.overlay,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final controller = service.controller;
        if (controller == null || !controller.value.isInitialized) {
          return errorBuilder ??
              const Center(child: CircularProgressIndicator());
        }
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(controller),
              if (overlay != null) overlay!,
            ],
          ),
        );
      },
    );
  }
}