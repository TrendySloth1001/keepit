import 'package:flutter/material.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

class KeepItApp extends StatelessWidget {
  const KeepItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'KeepIt',
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
