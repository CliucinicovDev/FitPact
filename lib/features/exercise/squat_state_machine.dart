import 'package:fitpact/core/enums/exercise_enums.dart';
import 'package:fitpact/core/math/base_exercise_state_machine.dart';

/// Phase state machine for bodyweight squats.
///
/// Phases: setup -> down -> up -> recovery. A rep is counted on the
/// down -> up transition. Knee angle thresholds detect "down" (near 90
/// degrees) and "up" (legs extended, 170+ degrees). A partial squat
/// (not deep enough) does not count as a rep.
class SquatStateMachine extends BaseExerciseStateMachine {
 /// Knee angle (degrees) at or below which the rep is "down".
 final double downAngle;

 /// Knee angle (degrees) at or above which the position is "up".
 final double upAngle;

 int _repCount = 0;
 bool _reachedDepth = false;
 String? _lastWarning;

 SquatStateMachine({
 this.downAngle = 90,
 this.upAngle = 170,
 });

 /// Number of completed (full-depth) reps.
 int get repCount => _repCount;

 /// Whether the current descent reached the required depth.
 bool get reachedDepth => _reachedDepth;

 /// Warning from the last partial-squat rejection, if any.
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

 /// Processes a new knee angle sample and advances the machine.
 ///
 /// Returns the new phase, or `null` if no phase change occurred.
 ExercisePhase? processKneeAngle(double kneeAngle) {
 if (kneeAngle < 0 || kneeAngle > 180) {
 _resetWithWarning('Invalid knee angle: $kneeAngle');
 return null;
 }
 switch (phase) {
 case ExercisePhase.setup:
 case ExercisePhase.recovery:
 if (kneeAngle <= downAngle) {
 _reachedDepth = true;
 return transition(ExercisePhase.down);
 }
 if (kneeAngle < upAngle) {
 // Started descending from standing but not yet deep enough.
 return null;
 }
 return null;
 case ExercisePhase.down:
 if (kneeAngle >= upAngle) {
 if (_reachedDepth) {
 _repCount++;
 _reachedDepth = false;
 return transition(ExercisePhase.up);
 }
 // Partial squat: reject the rep with a warning.
 _resetWithWarning('Partial squat - not deep enough');
 return transition(ExercisePhase.setup);
 }
 return null;
 case ExercisePhase.up:
 if (kneeAngle <= downAngle) {
 _reachedDepth = true;
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
 _reachedDepth = false;
 _lastWarning = null;
 }

 void _resetWithWarning(String message) {
 _lastWarning = message;
 _repCount = 0;
 _reachedDepth = false;
 super.reset();
 }
}