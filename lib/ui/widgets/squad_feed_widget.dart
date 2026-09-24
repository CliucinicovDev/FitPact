import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fitpact/core/models/challenge_member.dart';
import 'package:fitpact/ui/widgets/challenge_error_states.dart';

/// Live squad feed: subscribes to Supabase Realtime changes on
/// challenge_members and updates the leaderboard as reps come in.
class SquadFeedWidget extends StatefulWidget {
 final String challengeId;
 final dynamic client;
 final Future<List<ChallengeMember>> Function(String challengeId) loadMembers;
 final Stream<void> Function(String challengeId) subscribeChanges;

 const SquadFeedWidget({
 super.key,
 required this.challengeId,
 required this.client,
 required this.loadMembers,
 required this.subscribeChanges,
 });

 @override
 State<SquadFeedWidget> createState() => _SquadFeedWidgetState();
}

class _SquadFeedWidgetState extends State<SquadFeedWidget> {
 List<ChallengeMember>? _members;
 String? _error;
 bool _offline = false;
 StreamSubscription<void>? _sub;

 @override
 void initState() {
 super.initState();
 _load();
 _sub = widget.subscribeChanges(widget.challengeId).listen(
 (_) => _load(),
 onError: (_) => setState(() => _offline = true),
 );
 }

 Future<void> _load() async {
 try {
 final members = await widget.loadMembers(widget.challengeId);
  if (!mounted) return;
  setState(() {
  _members = members;
  _error = null;
  _offline = false;
  });
  } catch (e) {
  if (!mounted) return;
  setState(() => _error = 'Could not load squad: $e');
  }
  }

 @override
 void dispose() {
 _sub?.cancel();
 super.dispose();
 }

 @override
 Widget build(BuildContext context) {
 if (_offline) {
 return ChallengeOfflineState(onRetry: _load);
 }
 if (_error != null) {
 return ChallengeErrorState(message: _error!, onRetry: _load);
 }
 if (_members == null) {
 return const ChallengeLoadingState();
 }
 final members = _members!;
 if (members.isEmpty) {
 return const ChallengeEmptyState();
 }
 return ListView.builder(
 itemCount: members.length,
 itemBuilder: (context, i) {
 final m = members[i];
 return ListTile(
 leading: CircleAvatar(child: Text('${i + 1}')),
 title: Text(m.profileId.substring(0, 8)),
 trailing: Text('${m.totalReps} reps'),
 subtitle: Row(
 children: [
 for (var life = 0; life < 3; life++)
 Icon(
 life < m.livesRemaining
 ? Icons.favorite
 : Icons.favorite_border,
 size: 16,
 color: life < m.livesRemaining
 ? Colors.red
 : Colors.grey,
 ),
 ],
 ),
 );
 },
 );
 }
}