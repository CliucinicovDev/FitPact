import 'package:flutter_test/flutter_test.dart';
import 'package:fitpact/core/enums/exercise_enums.dart';
import 'package:fitpact/features/exercise/burpee_state_machine.dart';

void main() {
  group('BurpeeStateMachine', () {
    test('starts in setup phase', () {
      final sm = BurpeeStateMachine();
      expect(sm.phase, ExercisePhase.setup);
      expect(sm.repCount, 0);
    });

    test('full sequence counts one rep', () {
      final sm = BurpeeStateMachine();
      expect(sm.advance(), ExercisePhase.down);
      expect(sm.advance(), ExercisePhase.plank);
      expect(sm.advance(), ExercisePhase.jump);
      expect(sm.advance(jumpHeight: 0.3), ExercisePhase.up);
      expect(sm.repCount, 1);
    });

    test('sequence ends in recovery then restarts', () {
      final sm = BurpeeStateMachine();
      sm.advance(); // down
      sm.advance(); // plank
      sm.advance(); // jump
      sm.advance(jumpHeight: 0.2); // up
      expect(sm.advance(), ExercisePhase.recovery);
      expect(sm.advance(), ExercisePhase.down); // new rep begins
      expect(sm.repCount, 1);
    });

    test('multiple reps accumulate', () {
      final sm = BurpeeStateMachine();
      for (var i = 0; i < 4; i++) {
        sm.advance();
        sm.advance();
        sm.advance();
        sm.advance(jumpHeight: 0.15);
        sm.advance(); // recovery
      }
      expect(sm.repCount, 4);
    });

    test('incomplete jump does not count and resets with warning', () {
      final sm = BurpeeStateMachine();
      sm.advance(); // down
      sm.advance(); // plank
      sm.advance(); // jump
      expect(sm.advance(jumpHeight: 0.05), ExercisePhase.setup);
      expect(sm.repCount, 0);
      expect(sm.lastWarning, isNotNull);
      expect(sm.history, isEmpty);
    });

    test('jumpPeak records the observed displacement', () {
      final sm = BurpeeStateMachine();
      sm.advance();
      sm.advance();
      sm.advance();
      expect(sm.advance(jumpHeight: 0.4), ExercisePhase.up);
      expect(sm.jumpPeak, 0.4);
    });

    test('invalid transitions rejected outside advance', () {
      final sm = BurpeeStateMachine();
      expect(sm.transition(ExercisePhase.jump), isNull);
      expect(sm.transition(ExercisePhase.plank), isNull);
      expect(sm.phase, ExercisePhase.setup);
    });

    test('history records the 5-phase sequence in order', () {
      final sm = BurpeeStateMachine();
      sm.advance();
      sm.advance();
      sm.advance();
      sm.advance(jumpHeight: 0.2);
      expect(sm.history.map((t) => t.to).toList(), [
        ExercisePhase.down,
        ExercisePhase.plank,
        ExercisePhase.jump,
        ExercisePhase.up,
      ]);
    });

    test('reset clears reps and state', () {
      final sm = BurpeeStateMachine();
      sm.advance();
      sm.advance();
      sm.advance();
      sm.advance(jumpHeight: 0.2);
      sm.reset();
      expect(sm.phase, ExercisePhase.setup);
      expect(sm.repCount, 0);
      expect(sm.jumpPeak, 0);
      expect(sm.lastWarning, isNull);
      expect(sm.history, isEmpty);
    });

    test('custom minJumpHeight threshold respected', () {
      final sm = BurpeeStateMachine(minJumpHeight: 0.5);
      sm.advance();
      sm.advance();
      sm.advance();
      expect(sm.advance(jumpHeight: 0.4), ExercisePhase.setup);
      expect(sm.repCount, 0);
    });

    test('long usage keeps bounded history per reset', () {
      final sm = BurpeeStateMachine();
      for (var i = 0; i < 50; i++) {
        sm.advance();
        sm.advance();
        sm.advance();
        sm.advance(jumpHeight: 0.12);
        sm.advance();
      }
      expect(sm.repCount, 50);
      sm.reset();
      expect(sm.history, isEmpty);
    });
  });
}