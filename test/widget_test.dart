import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/theme/app_theme.dart';

void main() {
  testWidgets('App theme builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const Scaffold(body: Text('jPrime')),
      ),
    );
    expect(find.text('jPrime'), findsOneWidget);
  });
}
