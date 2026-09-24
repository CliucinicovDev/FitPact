import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer loading placeholder for the workout screen.
class WorkoutLoadingState extends StatelessWidget {
 /// Creates the loading placeholder.
 const WorkoutLoadingState({super.key});

 @override
 Widget build(BuildContext context) {
 final base = Colors.grey.shade300;
 return Shimmer.fromColors(
 baseColor: base,
 highlightColor: Colors.grey.shade100,
 child: Column(
 children: [
 const SizedBox(height: 40),
 Container(
 width: 120, height: 120,
 decoration: const BoxDecoration(
 color: Colors.white, shape: BoxShape.circle),
 ),
 const SizedBox(height: 24),
 Container(width: 200, height: 24, color: Colors.white),
 const SizedBox(height: 12),
 Container(width: 160, height: 16, color: Colors.white),
 ],
 ),
 );
 }
}

/// Empty state shown when no camera is available ("no camera").
class WorkoutEmptyState extends StatelessWidget {
 /// Message displayed to the user.
 final String message;

 /// Callback for switching to manual counting mode.
 final VoidCallback? onManualMode;

 /// Creates the empty state.
 const WorkoutEmptyState({
 super.key,
 this.message = 'No camera available on this device',
 this.onManualMode,
 });

 @override
 Widget build(BuildContext context) {
 return Center(
 child: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 const Icon(Icons.videocam_off, size: 80, color: Colors.grey),
 const SizedBox(height: 16),
 Text(message,
 textAlign: TextAlign.center,
 style: Theme.of(context).textTheme.titleMedium),
 const SizedBox(height: 24),
 if (onManualMode != null)
 FilledButton.icon(
 onPressed: onManualMode,
 icon: const Icon(Icons.touch_app),
 label: const Text('Switch to manual mode'),
 ),
 ],
 ),
 );
 }
}

/// Error state with an optional retry action.
class WorkoutErrorState extends StatelessWidget {
 /// Error description for the user.
 final String message;

 /// Retry callback; hides the button when null.
 final VoidCallback? onRetry;

 /// Creates the error state.
 const WorkoutErrorState({
 super.key,
 required this.message,
 this.onRetry,
 });

 @override
 Widget build(BuildContext context) {
 return Center(
 child: Padding(
 padding: const EdgeInsets.all(24),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 const Icon(Icons.error_outline, size: 80, color: Colors.red),
 const SizedBox(height: 16),
 Text(message,
 textAlign: TextAlign.center,
 style: Theme.of(context).textTheme.titleMedium),
 if (onRetry != null) ...[
 const SizedBox(height: 24),
 FilledButton.icon(
 onPressed: onRetry,
 icon: const Icon(Icons.refresh),
 label: const Text('Retry'),
 ),
 ],
 ],
 ),
 ),
 );
 }
}

/// Offline banner pinned above the workout content.
class OfflineBanner extends StatelessWidget {
 /// Creates the offline banner.
 const OfflineBanner({super.key});

 @override
 Widget build(BuildContext context) {
 return Container(
 width: double.infinity,
 color: Colors.orange.shade700,
 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
 child: const Row(
 children: [
 Icon(Icons.wifi_off, color: Colors.white, size: 18),
 SizedBox(width: 8),
 Expanded(
 child: Text(
 'You are offline. Sessions will sync later.',
 style: TextStyle(color: Colors.white, fontSize: 14),
 ),
 ),
 ],
 ),
 );
 }
}