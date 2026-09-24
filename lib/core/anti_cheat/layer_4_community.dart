import 'dart:math';

import 'package:fitpact/core/anti_cheat/cheat_verdict.dart';

/// Layer 4 community review: 3 randomly selected members review a
/// disputed rep; a verdict of "cheat" is reached with >= 2/3 agreement.
class Layer4Community {
 final Random _random;

 Layer4Community({Random? random}) : _random = random ?? Random();

 /// Selects [count] distinct reviewers from [memberIds], excluding the
 /// user under review.
 List<String> selectReviewers(
 List<String> memberIds, {
 String? exclude,
 int count = 3,
 }) {
 final pool = memberIds.where((id) => id != exclude).toList()..shuffle(_random);
 return pool.take(count).toList();
 }

 /// Aggregates individual reviewer votes into a final verdict.
 /// [votes] maps reviewer ids to their judgment (true = cheating).
 CommunityResult resolve(Map<String, bool> votes, {int threshold = 2}) {
 final cheats = votes.values.where((v) => v).length;
 final clean = votes.length - cheats;
 if (cheats >= threshold) {
 return CommunityResult(
 CheatVerdict.suspect, 'Community flagged cheating ($cheats/${votes.length})');
 }
 if (clean >= threshold) {
 return CommunityResult(
 CheatVerdict.clean, 'Community cleared the rep ($clean/${votes.length})');
 }
 return const CommunityResult(
 CheatVerdict.invalid, 'Inconclusive vote; re-review needed');
 }
}

/// Final outcome of a community review round.
class CommunityResult {
 final CheatVerdict verdict;
 final String reason;

 const CommunityResult(this.verdict, this.reason);
}