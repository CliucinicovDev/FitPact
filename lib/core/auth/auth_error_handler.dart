import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// User-facing classification of network and auth failures, with a
/// retry recommendation and a human-readable message.
class AuthErrorResult {
  final String message;
  final bool retryable;

  const AuthErrorResult(this.message, {required this.retryable});
}

AuthErrorResult handleAuthError(Object error) {
  if (error is AuthApiException) {
    final message = error.message.toLowerCase();
    if (error.statusCode == '429') {
      return const AuthErrorResult(
        'Too many attempts. Please wait a moment and try again.',
        retryable: true,
      );
    }
    if (message.contains('invalid login credentials')) {
      return const AuthErrorResult(
        'Invalid email or password.',
        retryable: false,
      );
    }
    if (message.contains('expired') || message.contains('jwt')) {
      return const AuthErrorResult(
        'Your session expired. Please sign in again.',
        retryable: false,
      );
    }
    if (message.contains('email not confirmed')) {
      return const AuthErrorResult(
        'Please confirm your email first (check your inbox).',
        retryable: false,
      );
    }
    return AuthErrorResult(error.message, retryable: false);
  }
  if (error is AuthRetryableFetchException) {
    return const AuthErrorResult(
      'Network problem or timeout. Check your connection and retry.',
      retryable: true,
    );
  }
  if (error is TimeoutException) {
    return const AuthErrorResult(
      'Network timeout. Check your connection and retry.',
      retryable: true,
    );
  }
  return AuthErrorResult('Unexpected error: $error', retryable: false);
}