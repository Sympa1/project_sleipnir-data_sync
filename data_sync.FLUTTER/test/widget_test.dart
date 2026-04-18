// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:data_sync_flutter/main.dart';

void main() {
  testWidgets('App shows polished sync and settings pages', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Sync'), findsWidgets);
    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('Bereit fuer den ersten Abgleich'), findsOneWidget);

    await tester.tap(find.text('Einstellungen'));
    await tester.pumpAndSettle();

    expect(find.text('Alles Wichtige an einem Ort'), findsOneWidget);
    expect(find.text('Konfiguration'), findsOneWidget);
  });
}
