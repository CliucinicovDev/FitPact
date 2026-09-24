import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fitpact/core/models/challenge_member.dart';
import 'package:fitpact/ui/screens/gdpr_consent_screen.dart';
import 'package:fitpact/ui/screens/leaderboard_screen.dart';
import 'package:fitpact/ui/screens/onboarding_screen.dart';
import 'package:fitpact/ui/screens/splash_screen.dart';
import 'package:fitpact/features/ui/workout_camera_screen.dart';
import 'package:fitpact/ui/screens/challenges_screen.dart';
import 'package:fitpact/ui/theme/app_theme.dart';

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(
        onFinished: _splashDone,
      ),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => OnboardingScreen(
            onFinish: () => _router.go('/challenges'),
      ),
    ),
    GoRoute(
          path: '/challenges',
          builder: (context, state) => const ChallengesScreen(),
        ),
        GoRoute(
          path: '/leaderboard',
          builder: (context, state) => LeaderboardScreen(
            challengeId:
                state.uri.queryParameters['challengeId'] ?? 'default',
            loadMembers: _loadMembers,
            scheduleMidnightRefresh: _scheduleMidnightRefresh,
          ),
        ),
    GoRoute(
    path: '/gdpr',
    builder: (context, state) => GdprConsentScreen(
    onDone: _gdprDone,
    ),
    ),
    GoRoute(
    path: '/workout',
    builder: (context, state) => const WorkoutCameraScreen(),
    ),
  ],
);

void _splashDone() => _router.go('/onboarding');
void _gdprDone() => _router.go('/leaderboard');

Future<List<ChallengeMember>> _loadMembers(String challengeId) async => [];

Timer _scheduleMidnightRefresh(void Function() onRefresh) =>
    Timer(const Duration(seconds: 1), onRefresh);

void main() {
  runApp(const FitPactApp());
}

class FitPactApp extends StatelessWidget {
  const FitPactApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FitPact',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: _router,
    );
  }
}