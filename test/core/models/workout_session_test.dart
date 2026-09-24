import 'package:flutter_test/flutter_test.dart';
import 'package:fitpact/core/models/workout_session.dart';
import 'package:fitpact/core/enums/exercise_enums.dart';

void main() {
  final session = WorkoutSession(
    id: 's1',
    userId: 'u1',
    exerciseType: ExerciseType.pushUp,
    startTime: DateTime(2026, 1, 1, 10),
    endTime: DateTime(2026, 1, 1, 10, 5),
    repCount: 12,
    formAverage: 0.85,
    status: SyncStatus.pending,
  );

  test('toJson/fromJson round trip', () {
    final restored = WorkoutSession.fromJson(session.toJson());
    expect(restored.id, 's1');
    expect(restored.exerciseType, ExerciseType.pushUp);
    expect(restored.startTime, session.startTime);
    expect(restored.endTime, session.endTime);
    expect(restored.repCount, 12);
    expect(restored.formAverage, 0.85);
    expect(restored.status, SyncStatus.pending);
  });

  test('fromJson defaults optional fields', () {
    final restored = WorkoutSession.fromJson({
      'id': 's2',
      'userId': 'u1',
      'exerciseType': 'squat',
      'startTime': DateTime(2026, 1, 2).toIso8601String(),
    });
    expect(restored.endTime, isNull);
    expect(restored.repCount, 0);
    expect(restored.formAverage, 0);
    expect(restored.status, SyncStatus.pending);
  });

  test('copyWith changes only given fields', () {
    final updated = session.copyWith(
      repCount: 20,
      status: SyncStatus.synced,
    );
    expect(updated.repCount, 20);
    expect(updated.status, SyncStatus.synced);
    expect(updated.id, 's1');
    expect(updated.exerciseType, ExerciseType.pushUp);
  });
}