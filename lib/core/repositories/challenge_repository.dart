import 'package:fitpact/core/models/challenge.dart';
import 'package:fitpact/core/models/challenge_member.dart';

/// Maximum members per challenge.
const int _maxMembers = 10;

/// Data access for challenges and memberships, backed by Supabase.
class ChallengeRepository {
 final dynamic _client;

 ChallengeRepository({dynamic client}) : _client = client;

 /// Creates a challenge and joins the creator as first member.
 Future<Challenge> createChallenge({
 required String title,
 required String exerciseType,
 required int goalReps,
 required int durationDays,
 required String createdBy,
 String? inviteCode,
 dynamic client,
 }) async {
 if (title.isEmpty || title.length > 80) {
 throw ArgumentError('Title must be 1-80 characters');
 }
 if (goalReps <= 0) throw ArgumentError('goalReps must be positive');
 if (durationDays < 1 || durationDays > 90) {
 throw ArgumentError('durationDays must be 1-90');
 }
 final db = client ?? _client;
 final row = await db.from('challenges').insert({
 'title': title,
 'exercise_type': exerciseType,
 'goal_reps': goalReps,
 'duration_days': durationDays,
 'invite_code': inviteCode,
 'created_by': createdBy,
 }).select().single();
 final challenge = Challenge.fromMap(row);
 await db.from('challenge_members').insert({
 'challenge_id': challenge.id,
 'profile_id': createdBy,
 });
 return challenge;
 }

 /// Joins the current user (profileId) to a challenge.
 Future<void> joinChallenge({
 required String challengeId,
 required String profileId,
 dynamic client,
 }) async {
 final db = client ?? _client;
 final existing = await db
 .from('challenge_members')
 .select('id')
 .eq('challenge_id', challengeId)
 .eq('profile_id', profileId);
 if (existing.isNotEmpty) {
 throw StateError('Already a member of this challenge');
 }
 await db.from('challenge_members').insert({
 'challenge_id': challengeId,
 'profile_id': profileId,
 });
 }

 /// Leaves a challenge by removing the membership row.
 Future<void> leaveChallenge({
 required String challengeId,
 required String profileId,
 dynamic client,
 }) async {
 final db = client ?? _client;
 await db
 .from('challenge_members')
 .delete()
 .eq('challenge_id', challengeId)
 .eq('profile_id', profileId);
 }

 /// Lists members of a challenge ordered by total reps (leaderboard).
 Future<List<ChallengeMember>> getMembers(String challengeId) async {
 final rows = await _client
 .from('challenge_members')
 .select()
 .eq('challenge_id', challengeId)
 .order('total_reps', ascending: false);
 return [for (final r in rows) ChallengeMember.fromMap(r)];
 }
}