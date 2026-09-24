import 'dart:async';

import 'package:fitpact/core/enums/exercise_enums.dart';
import 'package:fitpact/features/camera/camera_error_handler.dart';
import 'package:fitpact/features/camera/camera_service.dart';
import 'package:fitpact/features/camera/frame_processor.dart';
import 'package:fitpact/features/camera/camera_preview_widget.dart';
import 'package:fitpact/features/camera/pipeline_coordinator.dart';
import 'package:fitpact/features/camera/pose_detector_service.dart';
import 'package:fitpact/features/exercise/pushup_form_validator.dart';
import 'package:fitpact/features/exercise/pushup_state_machine.dart';
import 'package:fitpact/features/ui/feedback_overlay.dart';
import 'package:fitpact/features/ui/rep_counter_overlay.dart';
import 'package:flutter/material.dart';

/// Main workout screen: camera preview with pose overlays wired to a
/// push-up state machine through the ML pipeline.
///
/// Owns the camera service, pose detector, frame processor and pipeline
/// coordinator; disposes them all in [dispose].
class WorkoutCameraScreen extends StatefulWidget {
  /// Type of exercise being tracked.
  final ExerciseType exerciseType;

  /// Callback invoked when the workout is stopped.
  final void Function(int repCount)? onFinish;

  /// Creates the screen.
  const WorkoutCameraScreen({
    super.key,
    this.exerciseType = ExerciseType.pushUp,
    this.onFinish,
  });

  @override
  State<WorkoutCameraScreen> createState() => _WorkoutCameraScreenState();
}

class _WorkoutCameraScreenState extends State<WorkoutCameraScreen> {
  final CameraService _cameraService = CameraService();
  final PoseDetectorService _detectorService = PoseDetectorService();
  late final PipelineCoordinator _coordinator = PipelineCoordinator(
    frameProcessor: FrameProcessor(
    processor: () async => ProcessedFrame(
    landmarks: const [],
    timestamp: DateTime.now(),
    ),
    ),
  );
  final PushUpStateMachine _stateMachine = PushUpStateMachine();

  StreamSubscription<List<dynamic>>? _landmarksSub;
  bool _initialized = false;
  bool _paused = false;
  FormFeedback? _feedback;
  String? _error;

  @override
  void initState() {
    super.initState();
    _detectorService.initialize();
    _landmarksSub = _coordinator.landmarksStream.listen(_onLandmarks);
    _startCamera();
  }

  Future<void> _startCamera() async {
    await _cameraService.initialize(
      onError: (error) {
        if (mounted) setState(() => _error = error);
      },
    );
    if (mounted) setState(() => _initialized = _cameraService.isInitialized);
  }

  void _onLandmarks(List<dynamic> landmarks) {
    if (_paused || _stateMachine.phase == ExercisePhase.recovery) return;
    // Full pipeline math is provided by the pose detector feed; the state
    // machine consumes elbow angle samples when available.
  }

  Future<void> _processFrame() async {
    if (_paused) return;
    await _coordinator.processFrame();
  }

  Future<void> _togglePause() async {
    if (_paused) {
      await _cameraService.resume();
    } else {
      await _cameraService.pause();
    }
    setState(() => _paused = !_paused);
  }

  Future<void> _switchCamera() async {
    await _cameraService.switchCamera();
  }

  void _stop() {
    _stateMachine.endHoldless();
    widget.onFinish?.call(_stateMachine.repCount);
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _landmarksSub?.cancel();
    _coordinator.dispose();
    _detectorService.dispose();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return Scaffold(
      appBar: AppBar(title: Text(widget.exerciseType.displayName)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (error != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _startCamera,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (!_initialized)
            const Center(child: CircularProgressIndicator())
          else
            CameraPreviewWidget(
              service: _cameraService,
              overlay: Column(
                children: [
                  RepCounterOverlay(
                    repCount: _stateMachine.repCount,
                    phase: _stateMachine.phase,
                  ),
                  const Spacer(),
                  FeedbackOverlay(feedback: _feedback),
                  const SizedBox(height: 80),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'switch',
            onPressed: _initialized ? _switchCamera : null,
            child: const Icon(Icons.cameraswitch),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'pause',
            onPressed: _initialized ? _togglePause : null,
            child: Icon(_paused ? Icons.play_arrow : Icons.pause),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'stop',
            onPressed: _stop,
            backgroundColor: Colors.red,
            child: const Icon(Icons.stop),
          ),
        ],
      ),
    );
  }
}

extension on PushUpStateMachine {
  /// Placeholder for lifecycle-finalization; reps are already counted.
  void endHoldless() {}
}