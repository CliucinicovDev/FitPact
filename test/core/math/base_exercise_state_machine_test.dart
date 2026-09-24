import 'package:flutter_test/flutter_test.dart';
import 'package:fitpact/core/enums/exercise_enums.dart';
import 'package:fitpact/core/math/base_exercise_state_machine.dart';

/// Simple concrete machine for testing the base contract.
class _TestMachine extends BaseExerciseStateMachine {
  @override
  Map<ExercisePhase, Set<ExercisePhase>> get allowedTransitions => const {
        ExercisePhase.setup: {ExercisePhase.down},
        ExercisePhase.down: {ExercisePhase.hold, ExercisePhase.up},
        ExercisePhase.hold: {ExercisePhase.up},
        ExercisePhase.up: {ExercisePhase.recovery, ExercisePhase.setup},
        ExercisePhase.recovery: {ExercisePhase.down},
      };
}

void main() {
  late _TestMachine machine;

  setUp(() {
    machine = _TestMachine();
  });

  test('initial phase is setup', () {
    expect(machine.phase, ExercisePhase.setup);
  });

  test('every allowed combo transitions correctly', () {
    expect(machine.transition(ExercisePhase.down), ExercisePhase.down);
    expect(machine.transition(ExercisePhase.hold), ExercisePhase.hold);
    expect(machine.transition(ExercisePhase.up), ExercisePhase.up);
    expect(machine.transition(ExercisePhase.setup), ExercisePhase.setup);

    machine.transition(ExercisePhase.down);
    expect(machine.transition(ExercisePhase.up), ExercisePhase.up);
    expect(machine.transition(ExercisePhase.recovery), ExercisePhase.recovery);
    expect(machine.transition(ExercisePhase.down), ExercisePhase.down);
  });

  test('invalid transitions are rejected and phase unchanged', () {
    expect(machine.transition(ExercisePhase.up), isNull);
    expect(machine.phase, ExercisePhase.setup);
    expect(machine.history, isEmpty);

    machine.transition(ExercisePhase.down);
    expect(machine.transition(ExercisePhase.recovery), isNull);
    expect(machine.phase, ExercisePhase.down);
    expect(machine.history.length, 1);

    expect(machine.canTransitionTo(ExercisePhase.jump), isFalse);
  });

  test('canTransitionTo reports allowed moves', () {
    expect(machine.canTransitionTo(ExercisePhase.down), isTrue);
    expect(machine.canTransitionTo(ExercisePhase.up), isFalse);
  });

  test('history is preserved and reset clears it', () {
    machine.transition(ExercisePhase.down);
    machine.transition(ExercisePhase.up);

    expect(machine.history.length, 2);
    expect(machine.history[0].from, ExercisePhase.setup);
    expect(machine.history[0].to, ExercisePhase.down);
    expect(machine.history[0].timestamp, isNotNull);
    expect(machine.history[1].from, ExercisePhase.down);
    expect(machine.history[1].to, ExercisePhase.up);

    machine.reset();
    expect(machine.phase, ExercisePhase.setup);
    expect(machine.history, isEmpty);
  });
}