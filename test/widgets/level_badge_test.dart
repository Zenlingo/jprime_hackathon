import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/features/schedule/widgets/level_badge.dart';

import 'widget_test_helpers.dart';

void main() {
  group('LevelBadge', () {
    testWidgets('renders the level text', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const LevelBadge(level: 'Beginner'),
      ));
      expect(find.text('Beginner'), findsOneWidget);
    });

    testWidgets('renders Intermediate', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const LevelBadge(level: 'Intermediate'),
      ));
      expect(find.text('Intermediate'), findsOneWidget);
    });

    testWidgets('renders Advanced', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const LevelBadge(level: 'Advanced'),
      ));
      expect(find.text('Advanced'), findsOneWidget);
    });

    testWidgets('renders nothing when level is empty', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const LevelBadge(level: ''),
      ));
      // SizedBox.shrink renders no text
      expect(find.text(''), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('renders in small mode', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const LevelBadge(level: 'All', small: true),
      ));
      expect(find.text('All'), findsOneWidget);
    });
  });
}
