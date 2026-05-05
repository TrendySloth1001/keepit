import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

class AppTheme {
  // Glassdoor-inspired mint-green palette.
  static const primary = Color(0xFF0CAA6E);
  static const primaryDark = Color(0xFF067A4F);
  static const primarySoft = Color(0xFFE5F8EE);
  static const accent = Color(0xFF0E1E1A);

  static const onPrimary = Colors.white;
  static const surface = Colors.white;
  static const surfaceAlt = Color(0xFFF6F8F7);
  static const bg = Color(0xFFF7FBF9);
  static const fg = Color(0xFF0E1E1A);
  static const muted = Color(0xFF6B7A75);
  static const hairline = Color(0xFFE3EAE6);

  static const black = Colors.black;
  static const white = Colors.white;
  static const ink = Color(0xFF0E1E1A);

  static const error = Color(0xFFE2483A);
  static const success = Color(0xFF0CAA6E);
  static const warning = Color(0xFFE08A1A);
  static const info = Color(0xFF1E78D6);

  static ThemeData get dark => light;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      onPrimary: onPrimary,
      surface: surface,
      onSurface: fg,
      error: error,
    );

    OutlineInputBorder border([Color color = hairline, double w = 1.2]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.brLg,
          borderSide: BorderSide(color: color, width: w),
        );

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: fg,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: fg,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: hairline),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: hairline,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        side: const BorderSide(color: hairline),
        labelStyle: const TextStyle(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        labelStyle: const TextStyle(color: muted, fontWeight: FontWeight.w500),
        floatingLabelStyle:
            const TextStyle(color: primary, fontWeight: FontWeight.w600),
        helperStyle: const TextStyle(color: muted, fontSize: 12),
        hintStyle: const TextStyle(color: muted),
        prefixIconColor: muted,
        suffixIconColor: muted,
        border: border(),
        enabledBorder: border(),
        focusedBorder: border(primary, 1.6),
        errorBorder: border(error, 1.4),
        focusedErrorBorder: border(error, 1.6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(AppLayout.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: const BorderSide(color: hairline, width: 1.2),
          minimumSize: const Size.fromHeight(AppLayout.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ink,
        foregroundColor: primary,
        elevation: 2,
        highlightElevation: 4,
        shape: StadiumBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: const TextStyle(color: white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  /// A soft mint surface used for hero banners and promotional cards.
  static const heroGreen = primarySoft;
}
