import 'package:go_router/go_router.dart';

/// Central deep-link routing: maps notification types and external
/// links to app screens, with a fallback to home.
class DeepLinkHandler {
 static const String homeRoute = '/';
 static const String streakRoute = '/streak';
 static const String challengeRoutePrefix = '/challenge';
 static const String disputeRoutePrefix = '/dispute';
 static const String leaderboardRoute = '/leaderboard';

 final GoRouter router;

 DeepLinkHandler(this.router);

 /// Navigates to [path], falling back to home for unknown routes.
 void navigate(String path) {
 if (routeExists(path)) {
 router.go(path);
 } else {
 router.go(homeRoute);
 }
 }

 /// Handles an external deep link URI (e.g. `fitpact://challenge/<id>`).
 void handleExternalUri(Uri uri) {
  final raw = uri.host.isEmpty ? uri.path : '${uri.host}${uri.path}';
  final path = raw.startsWith('/') ? raw : '/$raw';
  navigate(path);
 }

 /// Whether [path] matches a configured route (exact match on the
  /// path's first segment against the known routes).
  bool routeExists(String path) {
  final segments =
  Uri.parse(path).pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return true; // home
  final known = {
  'streak',
  'challenge',
  'dispute',
  'leaderboard',
  };
  return known.contains(segments.first);
  }
}