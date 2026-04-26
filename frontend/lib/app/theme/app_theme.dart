import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _ink = Color(0xFF14213D);
  static const _paper = Color(0xFFF7F5F0);
  static const _sand = Color(0xFFE9D8A6);
  static const _accent = Color(0xFFFCA311);
  static const _muted = Color(0xFF6C757D);

  static ThemeData get light {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _accent,
        brightness: Brightness.light,
        surface: _paper,
        primary: _ink,
        secondary: _accent,
      ),
      useMaterial3: true,
    );

    return base.copyWith(
      scaffoldBackgroundColor: _paper,
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
        bodyLarge: GoogleFonts.manrope(color: _ink),
        bodyMedium: GoogleFonts.manrope(color: _ink),
        headlineSmall: GoogleFonts.manrope(
          color: _ink,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: GoogleFonts.manrope(
          color: _ink,
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _ink,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: _muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: _sand.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _accent, width: 1.4),
        ),
      ),
    );
  }
}
