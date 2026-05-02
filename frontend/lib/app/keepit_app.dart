import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/sketch.dart';

class KeepItApp extends ConsumerWidget {
  const KeepItApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'KeepIt',
      theme: AppTheme.light,
      darkTheme: AppTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) => SketchPaper(child: child ?? const SizedBox()),
    );
  }
}
