import 'package:flutter_test/flutter_test.dart';
import 'package:fitpact/core/enums/exercise_enums.dart';

void main() {
  group('ExerciseType', () {
    test('values contains all expected entries', () {
      expect(ExerciseType.values, [
        ExerciseType.pushUp,
        ExerciseType.squat,
        ExerciseType.plank,
        ExerciseType.burpee,
      ]);
    });

    test('displayName is not empty for every value', () {
      for (final v in ExerciseType.values) {
        expect(v.displayName, isNotEmpty);
      }
    });

    test('displayName returns expected labels', () {
      expect(ExerciseType.pushUp.displayName, 'Push-Up');
      expect(ExerciseType.squat.displayName, 'Squat');
      expect(ExerciseType.plank.displayName, 'Plank');
      expect(ExerciseType.burpee.displayName, 'Burpee');
    });
  });

  group('ExercisePhase', () {
    test('values contains all expected entries', () {
      expect(ExercisePhase.values, [
        ExercisePhase.setup,
        ExercisePhase.down,
        ExercisePhase.hold,
        ExercisePhase.plank,
        ExercisePhase.jump,
        ExercisePhase.up,
        ExercisePhase.recovery,
      ]);
    });

    test('displayName is not empty for every value', () {
      for (final v in ExercisePhase.values) {
        expect(v.displayName, isNotEmpty);
      }
    });
  });

  group('RepQuality', () {
    test('values contains all expected entries', () {
      expect(RepQuality.values, [
        RepQuality.perfect,
        RepQuality.good,
        RepQuality.poor,
        RepQuality.invalid,
      ]);
    });

    test('displayName is not empty for every value', () {
      for (final v in RepQuality.values) {
        expect(v.displayName, isNotEmpty);
      }
    });

    test('score values are correct', () {
      expect(RepQuality.perfect.score, 1.0);
      expect(RepQuality.good.score, 0.8);
      expect(RepQuality.poor.score, 0.5);
      expect(RepQuality.invalid.score, 0.0);
    });
  });

  group('SyncStatus', () {
    test('values contains all expected entries', () {
      expect(SyncStatus.values, [
        SyncStatus.pending,
        SyncStatus.syncing,
        SyncStatus.synced,
        SyncStatus.failed,
        SyncStatus.conflict,
      ]);
    });

    test('displayName is not empty for every value', () {
      for (final v in SyncStatus.values) {
        expect(v.displayName, isNotEmpty);
      }
    });
  });

  group('DeviceOrientation', () {
    test('values contains all expected entries', () {
      expect(DeviceOrientation.values, [
        DeviceOrientation.portrait,
        DeviceOrientation.portraitUpsideDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });

    test('displayName is not empty for every value', () {
      for (final v in DeviceOrientation.values) {
        expect(v.displayName, isNotEmpty);
      }
    });
  });
}