import 'package:fitpact/core/enums/exercise_enums.dart';
import 'package:fitpact/core/math/angle_calculator.dart';
import 'package:fitpact/core/math/base_exercise_state_machine.dart';

/// Phase state machine for push-ups.
///
/// Phases: setup -> down -> up -> recovery. A rep is counted on the
/// down -> up transition. Elbow angle thresholds detect "down" (near 90
/// degrees) and "up" (arms extended, 160+ degrees).
class PushUpStateMachine extends BaseExerciseStateMachine {
  /// Elbow angle (degrees) at or below which the rep is "down".
  final double downAngle;

  /// Elbow angle (degrees) at or above which the rep is "up".
  final double upAngle;

  int _repCount = 0;
  String? _lastWarning;

  PushUpStateMachine({
    this.downAngle = 90,
    this.upAngle = 160,
  });

  /// Number of completed reps.
  int get repCount => _repCount;

  /// Warning from the last invalid reset, if any.
  String? get lastWarning => _lastWarning;

  @override
  Map<ExercisePhase, Set<ExercisePhase>> get allowedTransitions => const {
        ExercisePhase.setup: {ExercisePhase.down, ExercisePhase.recovery},
        ExercisePhase.down: {ExercisePhase.up, ExercisePhase.setup},
        ExercisePhase.up: {ExercisePhase.recovery, ExercisePhase.down},
        ExercisePhase.recovery: {ExercisePhase.setup, ExercisePhase.down},
        ExercisePhase.plank: {},
        ExercisePhase.hold: {},
        ExercisePhase.jump: {},
      };

  /// Processes a new elbow angle sample and advances the machine.
  ///
  /// Returns the new phase, or `null` if no phase change occurred.
  ExercisePhase? processElbowAngle(double elbowAngle) {
    if (elbowAngle < 0 || elbowAngle > 180) {
      _resetWithWarning('Invalid elbow angle: $elbowAngle');
      return null;
    }
    switch (phase) {
      case ExercisePhase.setup:
      case ExercisePhase.recovery:
        if (elbowAngle <= downAngle) {
          return transition(ExercisePhase.down);
        }
        return null;
      case ExercisePhase.down:
        if (elbowAngle >= upAngle) {
          _repCount++;
          return transition(ExercisePhase.up);
        }
        return null;
      case ExercisePhase.up:
        if (elbowAngle <= downAngle) {
          return transition(ExercisePhase.down);
        }
        return null;
      default:
        return null;
    }
  }

  /// Resets the machine and clears the rep count.
  @override
  void reset() {
    super.reset();
    _repCount = 0;
    _lastWarning = null;
  }

  void _resetWithWarning(String message) {
      reset();
      _lastWarning = message;
  }
}