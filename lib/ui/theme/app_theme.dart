import 'package:flutter/material.dart';

import 'package:fitpact/ui/theme/app_colors.dart';
import 'package:fitpact/ui/theme/app_typography.dart';

/// Light and dark [ThemeData] built from the FitPact design tokens.
abstract final class AppTheme {
 /// Dark theme (the default FitPact look).
 static ThemeData dark() {
 final scheme = ColorScheme.fromSeed(
 seedColor: AppColors.actionCyan,
 brightness: Brightness.dark,
 primary: AppColors.actionCyan,
 secondary: AppColors.winnerMagenta,
 surface: AppColors.surfaceDark,
 error: AppColors.error,
 );
 return _base(scheme, AppColors.trustNavy, AppColors.textLight);
 }

 /// Optional light theme.
 static ThemeData light() {
 final scheme = ColorScheme.fromSeed(
 seedColor: AppColors.actionCyan,
 brightness: Brightness.light,
 primary: AppColors.actionCyan,
 secondary: AppColors.winnerMagenta,
 surface: Colors.white,
 error: AppColors.error,
 );
 return _base(scheme, AppColors.backgroundLight, AppColors.trustNavy);
 }

 static ThemeData _base(
 ColorScheme scheme, Color scaffold, Color text) {
 final textTheme = AppTypography.light(text);
 return ThemeData(
 useMaterial3: true,
 colorScheme: scheme,
 scaffoldBackgroundColor: scaffold,
 textTheme: textTheme,
 appBarTheme: AppBarTheme(
 backgroundColor: scaffold,
 foregroundColor: text,
 elevation: 0,
 centerTitle: true,
 titleTextStyle: textTheme.titleLarge,
 ),
 cardTheme: CardTheme(
 color: scheme.surface,
 elevation: 2,
 margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(12),
 side: BorderSide(color: AppColors.border),
 ),
 ),
 filledButtonTheme: FilledButtonThemeData(
 style: FilledButton.styleFrom(
 backgroundColor: AppColors.actionCyan,
 foregroundColor: AppColors.trustNavy,
 textStyle: textTheme.labelLarge,
 padding: const EdgeInsets.symmetric(
 horizontal: 24, vertical: 14),
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(10)),
 ),
 ),
 outlinedButtonTheme: OutlinedButtonThemeData(
 style: OutlinedButton.styleFrom(
 foregroundColor: AppColors.actionCyan,
 side: const BorderSide(color: AppColors.actionCyan),
 textStyle: textTheme.labelLarge,
 ),
 ),
 textButtonTheme: TextButtonThemeData(
 style: TextButton.styleFrom(
 foregroundColor: AppColors.actionCyan,
 textStyle: textTheme.labelLarge,
 ),
 ),
 inputDecorationTheme: InputDecorationTheme(
 filled: true,
 fillColor: scheme.surface,
 border: OutlineInputBorder(
 borderRadius: BorderRadius.circular(10),
 borderSide: const BorderSide(color: AppColors.border),
 ),
 hintStyle: textTheme.bodyMedium
 ?.copyWith(color: AppColors.textMuted),
 ),
 dividerTheme: const DividerThemeData(
 color: AppColors.border, thickness: 1),
 snackBarTheme: const SnackBarThemeData(
 backgroundColor: AppColors.surfaceDark,
 contentTextStyle: TextStyle(color: AppColors.textLight),
 ),
 checkboxTheme: CheckboxThemeData(
 fillColor: WidgetStateProperty.resolveWith((states) =>
 states.contains(WidgetState.selected)
 ? AppColors.actionCyan
 : AppColors.textMuted),
 ),
 pageTransitionsTheme: const PageTransitionsTheme(
 builders: {
 TargetPlatform.android:
 CupertinoPageTransitionsBuilder(),
 TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
 },
 ),
 );
 }
}