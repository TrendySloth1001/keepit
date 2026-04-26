import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);

  static const error = Color(0xFFFF3B30);
  static const success = Color(0xFF34C759);
  static const warning = Color(0xFFFFCC00);
  static const info = Color(0xFF0A84FF);

  static ThemeData get dark {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        surface: black,
        onSurface: white,
        primary: white,
        onPrimary: black,
        secondary: white,
        onSecondary: black,
        tertiary: white,
        onTertiary: black,
        error: white,
        onError: black,
        outline: white,
        outlineVariant: white,
        shadow: black,
        scrim: black,
        inverseSurface: white,
        onInverseSurface: black,
        inversePrimary: black,
        surfaceTint: black,
      ),
    );

    final textTheme = GoogleFonts.manropeTextTheme(base.textTheme).apply(
      bodyColor: white,
      displayColor: white,
      decorationColor: white,
    );

    return base.copyWith(
      scaffoldBackgroundColor: black,
      canvasColor: black,
      dividerColor: white,
      splashColor: white.withValues(alpha: 0),
      highlightColor: white.withValues(alpha: 0),
      hoverColor: white.withValues(alpha: 0),
      focusColor: white.withValues(alpha: 0),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: const IconThemeData(color: white),
      primaryIconTheme: const IconThemeData(color: white),
      dividerTheme: const DividerThemeData(color: white, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: black,
        foregroundColor: white,
        surfaceTintColor: black,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: white),
        actionsIconTheme: const IconThemeData(color: white),
        titleTextStyle: GoogleFonts.manrope(
          color: white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: black,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: black,
        surfaceTintColor: black,
        shadowColor: black,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: white, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: black,
        surfaceTintColor: black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: white, width: 1),
        ),
        titleTextStyle: GoogleFonts.manrope(
          color: white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.manrope(color: white, fontSize: 14),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: black,
        surfaceTintColor: black,
        modalBackgroundColor: black,
        modalBarrierColor: black,
        showDragHandle: true,
        dragHandleColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: white, width: 1),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: black,
        surfaceTintColor: black,
        scrimColor: black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: white, width: 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: black,
        contentTextStyle: GoogleFonts.manrope(color: white, fontSize: 14),
        actionTextColor: white,
        closeIconColor: white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: white, width: 1),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: black,
          border: Border.all(color: white),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.manrope(color: white, fontSize: 12),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: black,
        selectedTileColor: white,
        textColor: white,
        selectedColor: black,
        iconColor: white,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: black,
        deleteIconColor: white,
        selectedColor: white,
        secondarySelectedColor: white,
        checkmarkColor: black,
        side: const BorderSide(color: white),
        labelStyle: GoogleFonts.manrope(color: white, fontSize: 12),
        secondaryLabelStyle: GoogleFonts.manrope(color: black, fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: white),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? black : white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? white : black,
        ),
        trackOutlineColor: WidgetStateProperty.all(white),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? white : black,
        ),
        checkColor: WidgetStateProperty.all(black),
        side: const BorderSide(color: white, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.all(white),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: white,
        linearTrackColor: black,
        circularTrackColor: black,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: white,
        unselectedLabelColor: white,
        indicatorColor: white,
        dividerColor: white,
        labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w400),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: black,
        selectedItemColor: white,
        unselectedItemColor: white,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: black,
        surfaceTintColor: black,
        indicatorColor: white,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? black : white,
          ),
        ),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.manrope(color: white, fontSize: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: black,
        hintStyle: GoogleFonts.manrope(color: white),
        labelStyle: GoogleFonts.manrope(color: white),
        floatingLabelStyle: GoogleFonts.manrope(color: white),
        helperStyle: GoogleFonts.manrope(color: white),
        errorStyle: GoogleFonts.manrope(color: error),
        prefixIconColor: white,
        suffixIconColor: white,
        iconColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: white, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: white, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: white, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: white, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: white, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: white, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: white,
          foregroundColor: black,
          disabledBackgroundColor: black,
          disabledForegroundColor: white,
          elevation: 0,
          shadowColor: black,
          surfaceTintColor: black,
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: white, width: 1),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: black,
          foregroundColor: white,
          disabledForegroundColor: white,
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: white, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: white,
          disabledForegroundColor: white,
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: white,
          backgroundColor: black,
          shape: const CircleBorder(side: BorderSide(color: white, width: 1)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: white,
        foregroundColor: black,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        shape: CircleBorder(side: BorderSide(color: white, width: 1)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: black,
        surfaceTintColor: black,
        textStyle: GoogleFonts.manrope(color: white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: white, width: 1),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(black),
          surfaceTintColor: WidgetStateProperty.all(black),
          side: WidgetStateProperty.all(const BorderSide(color: white)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: white,
        inactiveTrackColor: white,
        thumbColor: white,
        overlayColor: black,
        valueIndicatorColor: white,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: white,
        selectionColor: white,
        selectionHandleColor: white,
      ),
    );
  }
}
