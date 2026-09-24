import 'dart:math';

/// Generates unique 6-char alphanumeric invite codes and enforces
/// join-by-code rate limiting (max 5 attempts per minute).
class InviteCodeRepository {
 final dynamic _client;

 static const int maxAttemptsPerMinute = 5;
 static const String _alphabet =
 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no ambiguous chars

 final Random _random;
 final Map<String, List<DateTime>> _attempts = {};

 InviteCodeRepository({dynamic client, Random? random})
 : _client = client,
  _random = random ?? Random.secure();

 /// Generates a random 6-character alphanumeric code, checking
 /// uniqueness against the challenges table.
 Future<String> generateInviteCode() async {
 for (var attempt = 0; attempt < 10; attempt++) {
 final code = _randomCode();
 final existing = await _client
 .from('challenges')
 .select('id')
 .eq('invite_code', code);
 if (existing.isEmpty) return code;
 }
 throw StateError('Could not generate a unique invite code');
 }

 /// Joins [profileId] to the challenge identified by [code].
 /// Throws StateError when rate limited or the code is invalid.
 Future<String> joinByInviteCode({
 required String code,
 required String profileId,
 }) async {
 _pruneAttempts(profileId, DateTime.now());
 final attempts = _attempts.putIfAbsent(profileId, () => []);
 if (attempts.length >= maxAttemptsPerMinute) {
 throw StateError(
 'Too many attempts. Please wait before trying again.');
 }
 attempts.add(DateTime.now());

 final rows = await _client
 .from('challenges')
 .select('id, status')
 .eq('invite_code', code.toUpperCase());
 if (rows.isEmpty) {
 throw StateError('Invalid invite code');
 }
 final row = rows.first as Map<String, dynamic>;
 if (row['status'] != 'active') {
 throw StateError('This challenge is no longer active');
 }
 final challengeId = row['id'] as String;
 final existing = await _client
 .from('challenge_members')
 .select('id')
 .eq('challenge_id', challengeId)
 .eq('profile_id', profileId);
 if (existing.isNotEmpty) {
 throw StateError('Already a member of this challenge');
 }
 await _client.from('challenge_members').insert({
 'challenge_id': challengeId,
 'profile_id': profileId,
 });
 return challengeId;
 }

 /// Removes attempts older than one minute for [profileId].
 void _pruneAttempts(String profileId, DateTime now) {
 final attempts = _attempts[profileId];
 if (attempts == null) return;
 attempts.removeWhere((t) =>
 now.difference(t) > const Duration(minutes: 1));
 if (attempts.isEmpty) _attempts.remove(profileId);
 }

 String _randomCode() => String.fromCharCodes(Iterable.generate(
 6, (_) => _alphabet.codeUnitAt(
 _random.nextInt(_alphabet.length))));
}