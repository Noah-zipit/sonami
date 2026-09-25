import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonami/main.dart';

void main() {
  testWidgets('Sonami boots with bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const SonamiApp());
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
