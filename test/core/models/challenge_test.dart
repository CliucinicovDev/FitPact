import 'package:flutter_test/flutter_test.dart';
import 'package:fitpact/core/models/challenge.dart';
import 'package:fitpact/core/models/challenge_member.dart';
import 'package:fitpact/core/enums/exercise_enums.dart';

void main() {
 test('Challenge fromMap/toMap round trip', () {
 final map = {
 'id': 'c1',
 'title': 'Push-up war',
 'exercise_type': 'pushUp',
 'goal_reps': 1000,
 'duration_days': 30,
 'status': 'active',
 'invite_code': 'ABC123',
 'created_by': 'u1',
 'created_at': '2026-09-01T10:00:00Z',
 };
 final c = Challenge.fromMap(map);
 expect(c.id, 'c1');
 expect(c.exerciseType, ExerciseType.pushUp);
 expect(c.status, ChallengeStatus.active);
 final out = c.toMap();
 expect(out['exercise_type'], 'pushUp');
 expect(out['goal_reps'], 1000);
 });

 test('Challenge copyWith changes only given fields', () {
 final c = Challenge(
 id: 'c1',
 title: 'Squats',
 exerciseType: ExerciseType.squat,
 goalReps: 500,
 durationDays: 14,
 );
 final updated = c.copyWith(status: ChallengeStatus.completed);
 expect(updated.status, ChallengeStatus.completed);
 expect(updated.title, 'Squats');
 });

 test('ChallengeMember fromMap defaults and copyWith', () {
 final m = ChallengeMember.fromMap({
 'id': 'm1',
 'challenge_id': 'c1',
 'profile_id': 'u1',
 });
 expect(m.totalReps, 0);
 expect(m.livesRemaining, 3);
 final updated = m.copyWith(totalReps: 42, livesRemaining: 1);
 expect(updated.totalReps, 42);
 expect(updated.livesRemaining, 1);
 expect(updated.id, 'm1');
 });
}