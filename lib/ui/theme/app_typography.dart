import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App typography: Montserrat Bold for headings, Work Sans for body.
abstract final class AppTypography {
  static TextTheme light(Color textColor) => TextTheme(
        displayLarge: _heading(textColor, 57, FontWeight.w700),
        displayMedium: _heading(textColor, 45, FontWeight.w700),
        displaySmall: _heading(textColor, 36, FontWeight.w700),
        headlineLarge: _heading(textColor, 32, FontWeight.w700),
        headlineMedium: _heading(textColor, 28, FontWeight.w700),
        headlineSmall: _heading(textColor, 24, FontWeight.w700),
        titleLarge: _heading(textColor, 22, FontWeight.w600),
        titleMedium: _heading(textColor, 16, FontWeight.w600),
        titleSmall: _heading(textColor, 14, FontWeight.w600),
        bodyLarge: _body(textColor, 16),
        bodyMedium: _body(textColor, 14),
        bodySmall: _body(textColor, 12),
        labelLarge: _body(textColor, 14).copyWith(fontWeight: FontWeight.w500),
        labelMedium: _body(textColor, 12).copyWith(fontWeight: FontWeight.w500),
        labelSmall: _body(textColor, 11).copyWith(fontWeight: FontWeight.w500),
      );

  static TextStyle _heading(Color color, double size, FontWeight weight) =>
      GoogleFonts.montserrat(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );

  static TextStyle _body(Color color, double size) => GoogleFonts.workSans(
        fontSize: size,
        color: color,
      );
}