import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Exposes the Supabase auth state as a stream and routes the user to
/// login when the session is lost. Token refresh is automatic in the SDK.
class AuthStateListener {
  final GoTrueClient _auth;
  StreamSubscription<AuthState>? _sub;

  AuthStateListener({GoTrueClient? auth})
      : _auth = auth ?? Supabase.instance.client.auth;

  /// Emits true when a session exists, false when the user must log in.
  Stream<bool> get sessionState =>
      _auth.onAuthStateChange.map((state) => state.session != null);

  /// The current authentication state.
  bool get isAuthenticated => _auth.currentSession != null;

  /// Subscribes [onUnauthenticated] and calls it whenever the session
  /// is lost, so the app can redirect to the login screen.
  void listen(void Function() onUnauthenticated) {
    _sub?.cancel();
    _sub = _auth.onAuthStateChange.listen((state) {
      if (state.session == null) {
        onUnauthenticated();
      }
    });
  }

  /// Forces a token refresh; the SDK retries automatically, this is an
  /// explicit escape hatch (e.g. after resuming from background).
  Future<void> refreshSession() async {
    final session = _auth.currentSession;
    if (session != null) {
    // Supabase SDK refreshes using the session's refresh token internally.
    await _auth.refreshSession(session.refreshToken);
    }
  }

  /// Stops listening. Call on dispose.
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}