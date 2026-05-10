import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

class AppTheme {
  // Glassdoor-inspired mint-green palette. Used as the seed when the OS
  // doesn't provide a dynamic palette (e.g. iOS, Android < 12, or when
  // dynamic_color fails to load). On Android 12+ the OS wallpaper-derived
  // ColorScheme overrides these via [light]'s `scheme` parameter.
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

  /// A soft mint surface used for hero banners and promotional cards.
  static const heroGreen = primarySoft;

  /// Builds a Material 3 Expressive-style theme. When [scheme] is non-null
  /// (the OS dynamic-color palette on Android 12+) we use it directly, which
  /// gives Material You — the app picks up the user's wallpaper. Otherwise
  /// we seed from our brand mint, harmonized for legibility.
  static ThemeData light({ColorScheme? scheme}) {
    final cs = scheme ??
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        );

    OutlineInputBorder border([Color? color, double w = 1.2]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.brLg,
          borderSide: BorderSide(color: color ?? cs.outlineVariant, width: w),
        );

    return ThemeData(
      brightness: cs.brightness,
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      canvasColor: cs.surface,
      splashFactory: InkSparkle.splashFactory,
      // M3 Expressive leans on slightly bolder weight + tighter tracking on
      // headlines. Roboto is the system default on Android — we keep it.
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: cs.surfaceTint,
        titleTextStyle: TextStyle(
          color: cs.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              cs.brightness == Brightness.light
                  ? Brightness.dark
                  : Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: cs.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: cs.onSurfaceVariant.withValues(alpha: 0.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: cs.onSurfaceVariant,
        titleTextStyle: TextStyle(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        subtitleTextStyle: TextStyle(
          color: cs.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        selectedColor: cs.secondaryContainer,
        side: BorderSide(color: cs.outlineVariant),
        labelStyle: TextStyle(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        secondaryLabelStyle: TextStyle(
          color: cs.onSecondaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor:
            WidgetStatePropertyAll(cs.surfaceContainerHigh),
        surfaceTintColor:
            const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        side: WidgetStatePropertyAll(
          BorderSide(color: cs.outlineVariant),
        ),
        textStyle: WidgetStatePropertyAll(
          TextStyle(color: cs.onSurface, fontSize: 14),
        ),
        hintStyle: WidgetStatePropertyAll(
          TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppLayout.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        labelStyle: TextStyle(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: cs.primary,
          fontWeight: FontWeight.w600,
        ),
        helperStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        hintStyle: TextStyle(color: cs.onSurfaceVariant),
        prefixIconColor: cs.onSurfaceVariant,
        suffixIconColor: cs.onSurfaceVariant,
        border: border(),
        enabledBorder: border(),
        focusedBorder: border(cs.primary, 1.6),
        errorBorder: border(cs.error, 1.4),
        focusedErrorBorder: border(cs.error, 1.6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(AppLayout.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.outlineVariant, width: 1.2),
          minimumSize: const Size.fromHeight(AppLayout.buttonHeight),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: cs.onSurface,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        elevation: 1,
        highlightElevation: 3,
        // M3 Expressive FABs use a softer rounded-square instead of full pill.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        extendedTextStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surfaceContainer,
        indicatorColor: cs.secondaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        height: 72,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: cs.surfaceContainerHigh,
          foregroundColor: cs.onSurface,
          selectedBackgroundColor: cs.secondaryContainer,
          selectedForegroundColor: cs.onSecondaryContainer,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cs.inverseSurface,
        contentTextStyle: TextStyle(color: cs.onInverseSurface),
        actionTextColor: cs.inversePrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.surfaceContainerHigh,
        circularTrackColor: cs.surfaceContainerHigh,
      ),
    );
  }

  /// Backwards-compatible accessors used across the app. These keep the
  /// brand palette as a fallback for screens that haven't migrated to
  /// ColorScheme references yet.
  static ThemeData get dark => light();
}
