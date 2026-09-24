import 'package:flutter/material.dart';

/// FitPact design tokens.
///
/// Palette: Action Cyan drives primary actions, Trust Navy is the dark
/// surface, Winner Magenta highlights victories and streaks.
abstract final class AppColors {
  /// Primary action color (buttons, active states).
  static const Color actionCyan = Color(0xFF00D2FF);

  /// Dark background / surface color.
  static const Color trustNavy = Color(0xFF112233);

  /// Accent for wins, streaks and celebrations.
  static const Color winnerMagenta = Color(0xFFF0148C);

  // Neutrals
  /// Near-white text on dark surfaces.
  static const Color textLight = Color(0xFFF5F7FA);

  /// Muted secondary text.
  static const Color textMuted = Color(0xFF9AA7B4);

  /// Standard scaffold background in light mode.
  static const Color backgroundLight = Color(0xFFF7F9FB);

  /// Card / surface background in dark mode.
  static const Color surfaceDark = Color(0xFF182A3E);

  /// Divider and border color.
  static const Color border = Color(0xFF24384D);

  /// Success green (rep counted, goal reached).
  static const Color success = Color(0xFF2ECC71);

  /// Warning orange (last life, degraded form).
  static const Color warning = Color(0xFFF39C12);

  /// Error red (failed sync, invalid rep).
  static const Color error = Color(0xFFE74C3C);
}