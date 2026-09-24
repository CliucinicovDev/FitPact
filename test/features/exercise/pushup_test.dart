import 'package:flutter_test/flutter_test.dart';
import 'package:fitpact/core/enums/exercise_enums.dart';
import 'package:fitpact/core/math/point_3d.dart';
import 'package:fitpact/features/exercise/pushup_form_validator.dart';
import 'package:fitpact/features/exercise/pushup_state_machine.dart';

void main() {
  group('PushUpStateMachine', () {
    test('starts in setup phase', () {
      final sm = PushUpStateMachine();
      expect(sm.phase, ExercisePhase.setup);
      expect(sm.repCount, 0);
    });

    test('full rep: setup -> down -> up counts one rep', () {
      final sm = PushUpStateMachine();
      expect(sm.processElbowAngle(90), ExercisePhase.down);
      expect(sm.processElbowAngle(165), ExercisePhase.up);
      expect(sm.repCount, 1);
    });

    test('multiple reps accumulate', () {
      final sm = PushUpStateMachine();
      for (var i = 0; i < 3; i++) {
        sm.processElbowAngle(85);
        sm.processElbowAngle(170);
      }
      expect(sm.repCount, 3);
    });

    test('angles above down threshold do not start a rep from setup', () {
      final sm = PushUpStateMachine();
      expect(sm.processElbowAngle(140), isNull);
      expect(sm.phase, ExercisePhase.setup);
      expect(sm.repCount, 0);
    });

    test('down -> setup transition allowed (bailout)', () {
      final sm = PushUpStateMachine();
      sm.processElbowAngle(90);
      expect(sm.transition(ExercisePhase.setup), ExercisePhase.setup);
      expect(sm.repCount, 0);
    });

    test('invalid angle resets machine with warning', () {
      final sm = PushUpStateMachine();
      sm.processElbowAngle(90);
      sm.processElbowAngle(200); // invalid
      expect(sm.phase, ExercisePhase.setup);
      expect(sm.lastWarning, isNotNull);
      expect(sm.repCount, 0);
    });

    test('up -> recovery -> setup cycle resets cleanly', () {
      final sm = PushUpStateMachine();
      sm.processElbowAngle(90);
      sm.processElbowAngle(170);
      expect(sm.transition(ExercisePhase.recovery), ExercisePhase.recovery);
      expect(sm.transition(ExercisePhase.setup), ExercisePhase.setup);
      expect(sm.repCount, 1);
    });

    test('reset clears reps, phase and history', () {
      final sm = PushUpStateMachine();
      sm.processElbowAngle(90);
      sm.processElbowAngle(170);
      sm.reset();
      expect(sm.phase, ExercisePhase.setup);
      expect(sm.repCount, 0);
      expect(sm.history, isEmpty);
      expect(sm.lastWarning, isNull);
    });

    test('history records transitions', () {
      final sm = PushUpStateMachine();
      sm.processElbowAngle(90);
      sm.processElbowAngle(170);
      expect(sm.history.length, 2);
      expect(sm.history[0].to, ExercisePhase.down);
      expect(sm.history[1].to, ExercisePhase.up);
    });

    test('no memory leak: repeated usage keeps stable history length', () {
      final sm = PushUpStateMachine();
      for (var i = 0; i < 100; i++) {
        sm.processElbowAngle(88);
        sm.processElbowAngle(168);
      }
      expect(sm.repCount, 100);
      expect(sm.history.length, 200);
      sm.reset();
      expect(sm.history, isEmpty);
    });
  });

  group('PushUpFormValidator', () {
    final validator = PushUpFormValidator();

    test('missing landmarks return incomplete feedback', () {
      final fb = validator.validate(const PushUpLandmarks());
      expect(fb.incomplete, isTrue);
      expect(fb.score, 0);
    });

    test('good elbow angle scores 1.0', () {
      final lm = PushUpLandmarks(
        leftShoulder: const Point3D(0, 2, 0),
        leftElbow: const Point3D(0, 1, 0.5),
        leftWrist: const Point3D(0, 0, 0),
      );
      final fb = validator.validateElbowAngle(lm);
      expect(fb.incomplete, isFalse);
      expect(fb.score, greaterThan(0.5));
    });

    test('fully extended elbow scores low', () {
      final lm = PushUpLandmarks(
        leftShoulder: const Point3D(0, 2, 0),
        leftElbow: const Point3D(0, 1, 0),
        leftWrist: const Point3D(0, 0, 0),
      );
      final fb = validator.validateElbowAngle(lm);
      expect(fb.incomplete, isFalse);
      expect(fb.score, lessThan(0.5));
    });

    test('straight body alignment scores 1.0', () {
      final lm = PushUpLandmarks(
        leftShoulder: const Point3D(-0.2, 2, 0),
        rightShoulder: const Point3D(0.2, 2, 0),
        leftHip: const Point3D(-0.2, 0, 0),
        rightHip: const Point3D(0.2, 0, 0),
        leftKnee: const Point3D(-0.2, -1, 0),
        rightKnee: const Point3D(0.2, -1, 0),
      );
      final fb = validator.validateBodyAlignment(lm);
      expect(fb.incomplete, isFalse);
      expect(fb.score, greaterThan(0.9));
    });

    test('bent body alignment scores below 1.0', () {
      final lm = PushUpLandmarks(
        leftShoulder: const Point3D(-0.2, 2, 0),
        rightShoulder: const Point3D(0.2, 2, 0),
        leftHip: const Point3D(-0.2, 0, 0),
        rightHip: const Point3D(0.2, 0, 0),
        leftKnee: const Point3D(-0.2, -1, 1.5),
        rightKnee: const Point3D(0.2, -1, 1.5),
      );
      final fb = validator.validateBodyAlignment(lm);
      expect(fb.incomplete, isFalse);
      expect(fb.score, lessThan(1.0));
    });

    test('depth: 90 degrees or lower is full depth', () {
      expect(validator.validateDepth(90).score, 1.0);
      expect(validator.validateDepth(60).score, 1.0);
    });

    test('depth: shallow bottom scores below 1.0', () {
      final fb = validator.validateDepth(140);
      expect(fb.score, lessThan(1.0));
      expect(fb.incomplete, isFalse);
    });

    test('depth: invalid angle returns incomplete', () {
      expect(validator.validateDepth(-5).incomplete, isTrue);
      expect(validator.validateDepth(200).incomplete, isTrue);
    });

    test('aggregate validate blends sub-scores', () {
      final lm = PushUpLandmarks(
        leftShoulder: const Point3D(-0.2, 2, 0),
        rightShoulder: const Point3D(0.2, 2, 0),
        leftHip: const Point3D(-0.2, 0, 0),
        rightHip: const Point3D(0.2, 0, 0),
        leftKnee: const Point3D(-0.2, -1, 0),
        rightKnee: const Point3D(0.2, -1, 0),
      );
      final fb = validator.validate(lm, bottomElbowAngle: 90);
      expect(fb.incomplete, isFalse);
      expect(fb.score, greaterThan(0.0));
      expect(fb.score, lessThanOrEqualTo(1.0));
    });
  });
}