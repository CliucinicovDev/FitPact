import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Loading, empty, error (with retry) and offline states for challenge
/// lists, so the UI never shows a blank screen.
class ChallengeLoadingState extends StatelessWidget {
 const ChallengeLoadingState({super.key});

 @override
 Widget build(BuildContext context) => Shimmer.fromColors(
 baseColor: Colors.grey.shade300,
 highlightColor: Colors.grey.shade100,
 child: ListView.builder(
 itemCount: 5,
 itemBuilder: (context, i) => ListTile(
 leading: const CircleAvatar(),
 title: Container(
 height: 16, color: Colors.white),
 subtitle: Container(
 height: 12, color: Colors.white),
 ),
 ),
 );
}

class ChallengeEmptyState extends StatelessWidget {
 const ChallengeEmptyState({super.key});

 @override
 Widget build(BuildContext context) => Center(
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 const Icon(Icons.emoji_events_outlined, size: 64),
 const SizedBox(height: 8),
 const Text('No challenges yet'),
 Text(
 'Create one and invite your squad!',
 style: Theme.of(context).textTheme.bodySmall,
 ),
 ],
 ),
 );
}

class ChallengeErrorState extends StatelessWidget {
 final String message;
 final VoidCallback onRetry;

 const ChallengeErrorState(
 {super.key, required this.message, required this.onRetry});

 @override
 Widget build(BuildContext context) => Center(
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 const Icon(Icons.error_outline, size: 64),
 const SizedBox(height: 8),
 Text(message),
 const SizedBox(height: 8),
 FilledButton(
 onPressed: onRetry, child: const Text('Retry')),
 ],
 ),
 );
}

class ChallengeOfflineState extends StatelessWidget {
 final VoidCallback onRetry;

 const ChallengeOfflineState({super.key, required this.onRetry});

 @override
 Widget build(BuildContext context) => Center(
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 const Icon(Icons.wifi_off, size: 64),
 const SizedBox(height: 8),
 const Text('You are offline'),
 Text(
 'Challenges will sync when you reconnect.',
 style: Theme.of(context).textTheme.bodySmall,
 ),
 const SizedBox(height: 8),
 OutlinedButton(
 onPressed: onRetry, child: const Text('Retry')),
 ],
 ),
 );
}