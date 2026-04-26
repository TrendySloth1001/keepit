import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:keepit/app/keepit_app.dart';

void main() {
  testWidgets('renders KeepIt app shell', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: KeepItApp()));

    await tester.pumpAndSettle();

    expect(find.text('KeepIt'), findsWidgets);
  });
}
