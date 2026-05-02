import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'sketch.dart';

/// New light palette inspired by the "Sweet Heart / Dr. White" mood board.
/// We keep the legacy [black] and [white] aliases so existing widgets render
/// in the new theme without sweeping renames — both still describe the
/// "darkest" and "lightest" surface tokens, just with softer, friendlier
/// off-black / off-white values.
class AppTheme {
  // Palette — matches the mood board.
  static const drWhite = Color(0xFFFAFAFA); // background
  static const plaster = Color(0xFFEAEAEA); // muted surface
  static const porpoise = Color(0xFFDBDADA); // separator-ish
  static const dreamscape = Color(0xFFC7C5C5); // border
  static const sweetHeart = Color(0xFFEAAAB2); // primary accent
  static const sweetHeartDark = Color(0xFFD78E97); // pressed/hover
  static const beijingMoon = Color(0xFFA8A3A3); // secondary text
  static const ink = Color(0xFF1B1B1B); // primary text/foreground

  // Semantic aliases.
  static const bg = drWhite;
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = plaster;
  static const border = dreamscape;
  static const muted = beijingMoon;
  static const fg = ink;
  static const primary = sweetHeart;
  static const primaryDark = sweetHeartDark;
  static const onPrimary = Color(0xFF3A1F25); // deep wine for AA contrast on pink

  // Legacy names — kept so existing widgets compile and look right under the
  // new light theme. [black] is now the foreground/ink colour (the darkest
  // semantic colour); [white] is the surface/background colour.
  static const black = bg;
  static const white = fg;

  // Status colours.
  static const error = Color(0xFFD64545);
  static const success = Color(0xFF3DA46A);
  static const warning = Color(0xFFD9A441);
  static const info = Color(0xFF5B8DEF);

  static ThemeData get dark => light;

  static ThemeData get light {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        surface: bg,
        onSurface: fg,
        primary: primary,
        onPrimary: onPrimary,
        secondary: ink,
        onSecondary: bg,
        tertiary: sweetHeartDark,
        onTertiary: bg,
        error: error,
        onError: bg,
        outline: border,
        outlineVariant: porpoise,
        shadow: Color(0x14000000),
        scrim: Color(0x66000000),
        inverseSurface: ink,
        onInverseSurface: bg,
        inversePrimary: sweetHeartDark,
        surfaceTint: bg,
      ),
    );

    // Body uses Patrick Hand (very legible printed handwriting). Headlines
    // use Caveat (looser script) so titles look hand-scribbled while
    // paragraphs stay readable.
    final body = GoogleFonts.patrickHandTextTheme(base.textTheme);
    final textTheme = body
        .copyWith(
          displayLarge: GoogleFonts.caveat(textStyle: body.displayLarge, fontWeight: FontWeight.w700),
          displayMedium: GoogleFonts.caveat(textStyle: body.displayMedium, fontWeight: FontWeight.w700),
          displaySmall: GoogleFonts.caveat(textStyle: body.displaySmall, fontWeight: FontWeight.w700),
          headlineLarge: GoogleFonts.caveat(textStyle: body.headlineLarge, fontWeight: FontWeight.w700),
          headlineMedium: GoogleFonts.caveat(textStyle: body.headlineMedium, fontWeight: FontWeight.w700),
          headlineSmall: GoogleFonts.caveat(textStyle: body.headlineSmall, fontWeight: FontWeight.w700),
          titleLarge: GoogleFonts.caveat(textStyle: body.titleLarge, fontWeight: FontWeight.w700),
        )
        .apply(
          bodyColor: fg,
          displayColor: fg,
          decorationColor: fg,
        );

    return base.copyWith(
      // The root [SketchPaper] paints the bg + notebook ruling. We make the
      // scaffold transparent so those lines bleed through every screen.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: bg,
      dividerColor: border,
      splashColor: primary.withValues(alpha: 0.10),
      highlightColor: primary.withValues(alpha: 0.06),
      hoverColor: primary.withValues(alpha: 0.06),
      focusColor: primary.withValues(alpha: 0.12),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: const IconThemeData(color: fg),
      primaryIconTheme: const IconThemeData(color: fg),
      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: fg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: fg),
        actionsIconTheme: const IconThemeData(color: fg),
        titleTextStyle: GoogleFonts.caveat(
          color: fg,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: bg,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: bg,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: const CardThemeData(
        color: surface,
        surfaceTintColor: surface,
        shadowColor: Color(0x14000000),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoughRectBorder(radius: 16, color: fg),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: surface,
        shape: const RoughRectBorder(radius: 18, color: fg),
        titleTextStyle: GoogleFonts.patrickHand(
          color: fg,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.patrickHand(color: fg, fontSize: 14),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: surface,
        modalBackgroundColor: surface,
        modalBarrierColor: Color(0x66000000),
        showDragHandle: true,
        dragHandleColor: fg,
        shape: RoughRectBorder(radius: 22, color: fg),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: bg,
        surfaceTintColor: bg,
        scrimColor: Color(0x66000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: border, width: 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: GoogleFonts.patrickHand(color: bg, fontSize: 14),
        actionTextColor: primary,
        closeIconColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.patrickHand(color: bg, fontSize: 12),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: surface,
        selectedTileColor: primary,
        textColor: fg,
        selectedColor: onPrimary,
        iconColor: fg,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        deleteIconColor: fg,
        selectedColor: primary,
        secondarySelectedColor: primary,
        checkmarkColor: onPrimary,
        side: const BorderSide(color: border),
        labelStyle: GoogleFonts.patrickHand(color: fg, fontSize: 12),
        secondaryLabelStyle: GoogleFonts.patrickHand(color: onPrimary, fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: border),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? onPrimary : surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : surfaceMuted,
        ),
        trackOutlineColor: WidgetStateProperty.all(border),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : surface,
        ),
        checkColor: WidgetStateProperty.all(onPrimary),
        side: const BorderSide(color: border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.all(primary),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: surfaceMuted,
        circularTrackColor: surfaceMuted,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: fg,
        unselectedLabelColor: muted,
        indicatorColor: primary,
        dividerColor: border,
        labelStyle: GoogleFonts.patrickHand(fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.patrickHand(fontWeight: FontWeight.w400),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: surface,
        indicatorColor: primary,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? onPrimary : fg,
          ),
        ),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.patrickHand(color: fg, fontSize: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: GoogleFonts.patrickHand(color: muted),
        labelStyle: GoogleFonts.patrickHand(color: muted),
        floatingLabelStyle: GoogleFonts.caveat(color: fg, fontWeight: FontWeight.w700, fontSize: 18),
        helperStyle: GoogleFonts.patrickHand(color: muted),
        errorStyle: GoogleFonts.patrickHand(color: error),
        prefixIconColor: muted,
        suffixIconColor: muted,
        iconColor: muted,
        border: const SketchInputBorder(),
        enabledBorder: const SketchInputBorder(),
        focusedBorder: const SketchInputBorder(color: primary, strokeWidth: 1.6),
        disabledBorder: const SketchInputBorder(color: porpoise),
        errorBorder: const SketchInputBorder(color: error),
        focusedErrorBorder: const SketchInputBorder(color: error, strokeWidth: 1.6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: surfaceMuted,
          disabledForegroundColor: muted,
          elevation: 0,
          shadowColor: const Color(0x14000000),
          surfaceTintColor: primary,
          textStyle: GoogleFonts.patrickHand(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: const RoughRectBorder(radius: 14, color: fg, strokeWidth: 1.6),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: surface,
          foregroundColor: fg,
          disabledForegroundColor: muted,
          textStyle: GoogleFonts.patrickHand(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          side: BorderSide.none,
          shape: const RoughRectBorder(radius: 14, color: fg, strokeWidth: 1.4),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryDark,
          disabledForegroundColor: muted,
          textStyle: GoogleFonts.patrickHand(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: fg,
          backgroundColor: surface,
          shape: const RoughCircleBorder(color: fg),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        shape: RoughCircleBorder(color: fg, strokeWidth: 1.8),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: surface,
        textStyle: GoogleFonts.patrickHand(color: fg),
        shape: const RoughRectBorder(radius: 12, color: fg),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(surface),
          surfaceTintColor: WidgetStateProperty.all(surface),
          shape: WidgetStateProperty.all(
            const RoughRectBorder(radius: 12, color: fg),
          ),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: surfaceMuted,
        thumbColor: primary,
        overlayColor: Color(0x33EAAAB2),
        valueIndicatorColor: ink,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: Color(0x55EAAAB2),
        selectionHandleColor: primary,
      ),
    );
  }
}
