import 'package:flutter/material.dart';

import 'package:fitpact/ui/theme/app_colors.dart';

/// Animated splash: pulsing logo that scales and fades into the app.
class SplashScreen extends StatefulWidget {
 final VoidCallback onFinished;
 final Duration duration;

 const SplashScreen({
 super.key,
 required this.onFinished,
 this.duration = const Duration(milliseconds: 2200),
 });

 @override
 State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
 with SingleTickerProviderStateMixin {
 late final AnimationController _controller =
 AnimationController(vsync: this, duration: widget.duration)
 ..addListener(() {
 if (_controller.isCompleted) widget.onFinished();
 });

 @override
 void initState() {
 super.initState();
 _controller.forward();
 }

 @override
 void dispose() {
 _controller.dispose();
 super.dispose();
 }

 @override
 Widget build(BuildContext context) {
 final curved = CurvedAnimation(
 parent: _controller, curve: Curves.easeOutCubic);

 return Scaffold(
 backgroundColor: AppColors.trustNavy,
 body: Center(
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 FadeTransition(
 opacity: curved,
 child: ScaleTransition(
 scale: Tween<double>(begin: 0.6, end: 1)
 .animate(curved),
 child: Container(
 width: 120,
 height: 120,
 decoration: BoxDecoration(
 gradient: const LinearGradient(
 colors: [
 AppColors.actionCyan,
 AppColors.winnerMagenta,
 ],
 begin: Alignment.topLeft,
 end: Alignment.bottomRight,
 ),
 borderRadius: BorderRadius.circular(28),
 boxShadow: [
 BoxShadow(
 color: AppColors.actionCyan
 .withOpacity(0.4),
 blurRadius: 40 * curved.value,
 spreadRadius: 2,
 ),
 ],
 ),
 child: const Icon(Icons.fitness_center,
 size: 56, color: AppColors.trustNavy),
 ),
 ),
 ),
 const SizedBox(height: 24),
 FadeTransition(
 opacity: curved,
 child: SlideTransition(
 position: Tween<Offset>(
 begin: const Offset(0, 0.3),
 end: Offset.zero,
 ).animate(curved),
 child: Text(
 'FitPact',
 style: Theme.of(context)
 .textTheme
 .headlineMedium
 ?.copyWith(color: AppColors.textLight),
 ),
 ),
 ),
 const SizedBox(height: 8),
 FadeTransition(
 opacity: curved,
 child: Text(
 'Train together. Prove every rep.',
 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
 color: AppColors.textMuted,
 ),
 ),
 ),
 ],
 ),
 ),
 );
 }
}