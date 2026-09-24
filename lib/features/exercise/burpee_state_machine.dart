import 'package:fitpact/core/enums/exercise_enums.dart';
import 'package:fitpact/core/math/base_exercise_state_machine.dart';

/// Phase state machine for a full burpee.
///
/// The 5-phase sequence is setup -> down -> plank -> jump -> up, then
/// recovery. A rep is counted only when the complete sequence is
/// performed in order; an incomplete jump breaks the rep and resets
/// the machine with a warning.
class BurpeeStateMachine extends BaseExerciseStateMachine {
 /// Minimum vertical hip displacement (meters) for a valid jump.
 final double minJumpHeight;

 int _repCount = 0;
 double _jumpPeak = 0;
 String? _lastWarning;

 BurpeeStateMachine({this.minJumpHeight = 0.1});

 /// Number of completed burpee reps.
 int get repCount => _repCount;

 /// Peak vertical displacement observed in the current jump, in meters.
 double get jumpPeak => _jumpPeak;

 /// Warning from the last invalid reset, if any.
 String? get lastWarning => _lastWarning;

 @override
 Map<ExercisePhase, Set<ExercisePhase>> get allowedTransitions => const {
 ExercisePhase.setup: {ExercisePhase.down, ExercisePhase.recovery},
 ExercisePhase.down: {ExercisePhase.plank, ExercisePhase.setup},
 ExercisePhase.plank: {ExercisePhase.jump, ExercisePhase.setup},
 ExercisePhase.jump: {ExercisePhase.up, ExercisePhase.setup},
 ExercisePhase.up: {ExercisePhase.recovery, ExercisePhase.down},
 ExercisePhase.recovery: {ExercisePhase.setup, ExercisePhase.down},
 ExercisePhase.hold: {},
 };

 /// Advances the machine through the burpee sequence.
 ///
 /// Returns the new phase, or null if no phase change occurred.
 /// [jumpHeight] is the observed vertical hip displacement (meters) and
 /// is only consulted when leaving the jump phase.
 ExercisePhase? advance({double? jumpHeight}) {
 switch (phase) {
 case ExercisePhase.setup:
 case ExercisePhase.recovery:
 _jumpPeak = 0;
 return transition(ExercisePhase.down);
 case ExercisePhase.down:
 return transition(ExercisePhase.plank);
 case ExercisePhase.plank:
 return transition(ExercisePhase.jump);
 case ExercisePhase.jump:
 if (jumpHeight != null) _jumpPeak = jumpHeight;
 if (jumpHeight != null && jumpHeight < minJumpHeight) {
 _resetWithWarning('Incomplete jump (${jumpHeight.toStringAsFixed(2)}m)');
 return ExercisePhase.setup;
 }
 _repCount++;
 return transition(ExercisePhase.up);
 case ExercisePhase.up:
 return transition(ExercisePhase.recovery);
 default:
 return null;
 }
 }

 /// Resets the machine and clears the rep count.
 @override
 void reset() {
 super.reset();
 _repCount = 0;
 _jumpPeak = 0;
 _lastWarning = null;
 }

 void _resetWithWarning(String message) {
 reset();
 _lastWarning = message;
 }
}