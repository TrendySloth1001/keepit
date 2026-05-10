import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root app widget. Wraps in [DynamicColorBuilder] so on Android 12+ we get
/// Material You — the user's wallpaper-derived ColorScheme. On older OSes,
/// iOS, web, and desktop, [light]/[dark] arrive null and we fall back to
/// the brand palette seeded inside [AppTheme.light].
class KeepItApp extends ConsumerWidget {
  const KeepItApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DynamicColorBuilder(
      builder: (light, dark) {
        // Harmonize the OS-derived palette with our brand seed so accent
        // colors (success/info chips) blend rather than clash.
        final lightScheme = light?.harmonized();
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'KeepIt',
          theme: AppTheme.light(scheme: lightScheme),
          darkTheme: AppTheme.light(scheme: lightScheme),
          themeMode: ThemeMode.light,
          routerConfig: ref.watch(appRouterProvider),
        );
      },
    );
  }
}
