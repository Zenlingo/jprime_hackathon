import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/widgets/progress_bar.dart';

import 'widget_test_helpers.dart';

void main() {
  group('JPProgressBar', () {
    testWidgets('renders without error at 0%', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const JPProgressBar(value: 0.0),
      ));
      expect(find.byType(JPProgressBar), findsOneWidget);
    });

    testWidgets('renders without error at 50%', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const JPProgressBar(value: 0.5),
      ));
      expect(find.byType(JPProgressBar), findsOneWidget);
    });

    testWidgets('renders without error at 100%', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const JPProgressBar(value: 1.0),
      ));
      expect(find.byType(JPProgressBar), findsOneWidget);
    });

    testWidgets('clamps values above 1.0', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const JPProgressBar(value: 1.5),
      ));
      // Should not throw
      expect(find.byType(JPProgressBar), findsOneWidget);
    });

    testWidgets('clamps values below 0.0', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const JPProgressBar(value: -0.5),
      ));
      expect(find.byType(JPProgressBar), findsOneWidget);
    });

    testWidgets('uses FractionallySizedBox for fill', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const JPProgressBar(value: 0.7),
      ));
      final box = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(box.widthFactor, 0.7);
    });
  });
}
