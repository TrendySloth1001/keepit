import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keepit/features/auth/presentation/pages/login_page.dart';
import 'package:keepit/shared/widgets/keepit_logo.dart';

void main() {
  testWidgets('renders KeepIt logo on login page', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );

    await tester.pump();

    expect(find.byType(KeepItLogo), findsWidgets);
  });
}
