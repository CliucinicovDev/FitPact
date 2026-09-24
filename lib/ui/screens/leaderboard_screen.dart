import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitpact/core/models/challenge_member.dart';
import 'package:fitpact/ui/widgets/challenge_error_states.dart';

/// Leaderboard for a challenge: members sorted by totalReps, showing
/// remaining lives (3 max), refreshing at local midnight.
class LeaderboardScreen extends StatefulWidget {
 final String challengeId;
 final Future<List<ChallengeMember>> Function(String challengeId) loadMembers;
 final Timer Function(void Function()) scheduleMidnightRefresh;

 const LeaderboardScreen({
 super.key,
 required this.challengeId,
 required this.loadMembers,
 required this.scheduleMidnightRefresh,
 });

 @override
 State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
 List<ChallengeMember>? _members;
 String? _error;
 Timer? _refreshTimer;

 @override
 void initState() {
 super.initState();
 _load();
  _refreshTimer = widget.scheduleMidnightRefresh(_refreshAtMidnight);
 }

  void _refreshAtMidnight() {
  _load();
  _refreshTimer = widget.scheduleMidnightRefresh(_refreshAtMidnight);
  }

 Future<void> _load() async {
 try {
 final members = await widget.loadMembers(widget.challengeId);
 final sorted = [...members]
 ..sort((a, b) => b.totalReps.compareTo(a.totalReps));
  if (!mounted) return;
  setState(() {
  _members = sorted;
  _error = null;
  });
  } catch (e) {
  if (!mounted) return;
  setState(() => _error = 'Could not load leaderboard: $e');
  }
  }

 @override
 void dispose() {
 _refreshTimer?.cancel();
 super.dispose();
 }

 @override
 Widget build(BuildContext context) {
 if (_error != null) {
 return Scaffold(
 appBar: AppBar(title: const Text('Leaderboard')),
 body: ChallengeErrorState(message: _error!, onRetry: _load),
 );
 }
 if (_members == null) {
 return Scaffold(
 appBar: AppBar(title: const Text('Leaderboard')),
 body: const ChallengeLoadingState(),
 );
 }
 final members = _members!;
 return Scaffold(
 appBar: AppBar(title: const Text('Leaderboard')),
  floatingActionButton: FloatingActionButton.extended(
  onPressed: () => context.push('/workout'),
  icon: const Icon(Icons.fitness_center),
  label: const Text('Start workout'),
  ),
  body: members.isEmpty
 ? const ChallengeEmptyState()
 : ListView.builder(
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
 ),
 );
 }
}

/// Schedules [onRefresh] to run once at the next local midnight.
/// Re-scheduling is the caller's responsibility (the screen re-arms the
/// timer after each refresh so it can be cancelled on dispose).
Timer scheduleMidnight(void Function() onRefresh) {
 final now = DateTime.now();
 final next = DateTime(now.year, now.month, now.day + 1);
 return Timer(next.difference(now), onRefresh);
}