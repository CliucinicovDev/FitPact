import 'package:supabase_flutter/supabase_flutter.dart';

/// Google Sign-In (OAuth), magic link, anonymous sign-in and account
/// upgrade, session persistence (handled by the SDK) and logout.
class SupabaseAuthService {
 final SupabaseClient _client;

 SupabaseAuthService({SupabaseClient? client})
 : _client = client ?? Supabase.instance.client;

 GoTrueClient get _auth => _client.auth;

 /// Current user id, or null when signed out.
 String? get userId => _auth.currentUser?.id;

 /// Whether a user is currently signed in.
 bool get isSignedIn => _auth.currentSession != null;

 /// Signs in with the Google OAuth provider.
 /// The SDK persists the session for subsequent launches.
 Future<void> signInWithGoogle() async {
 await _auth.signInWithOAuth(
 OAuthProvider.google,
 redirectTo: 'io.fitpact.app://login-callback',
 );
 }

 /// Sends a magic link to [email]. The user signs in by opening it.
 Future<void> sendMagicLink(String email) async {
 await _auth.signInWithOtp(
 email: email,
 emailRedirectTo: 'io.fitpact.app://login-callback',
 );
 }

 /// Signs in anonymously (guest mode).
 Future<void> signInAnonymously() async {
 await _auth.signInAnonymously();
 }

 /// Upgrades the current anonymous account to a permanent one by
 /// linking [email] (magic-link based). Throws if not anonymous.
 Future<void> upgradeAnonymousAccount(String email) async {
 final user = _auth.currentUser;
 if (user == null) {
 throw StateError('No user signed in');
 }
 if (!user.isAnonymous) {
 throw StateError('Current account is not anonymous');
 }
 await _auth.updateUser(UserAttributes(email: email));
 }

 /// Signs out and removes the persisted session.
 Future<void> signOut() async {
 await _auth.signOut();
 }
}