import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/widgets/live_dot.dart';

import 'widget_test_helpers.dart';

void main() {
  group('LiveDot', () {
    testWidgets('renders with default size', (tester) async {
      await tester.pumpWidget(wrapWithTheme(const LiveDot()));
      expect(find.byType(LiveDot), findsOneWidget);
    });

    testWidgets('renders with custom size', (tester) async {
      await tester.pumpWidget(wrapWithTheme(const LiveDot(size: 12)));
      expect(find.byType(LiveDot), findsOneWidget);
    });

    testWidgets('animates without error', (tester) async {
      await tester.pumpWidget(wrapWithTheme(const LiveDot()));
      // Advance animation a bit
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LiveDot), findsOneWidget);
    });
  });
}
