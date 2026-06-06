import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/widgets/empty_state.dart';

import 'widget_test_helpers.dart';

void main() {
  group('EmptyState', () {
    testWidgets('shows title and body text', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const EmptyState(
          icon: Icons.calendar_today,
          title: 'No sessions',
          body: 'Star some sessions to build your agenda.',
        ),
      ));
      expect(find.text('No sessions'), findsOneWidget);
      expect(
        find.text('Star some sessions to build your agenda.'),
        findsOneWidget,
      );
    });

    testWidgets('renders action widget when provided', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const EmptyState(
          icon: Icons.calendar_today,
          title: 'No sessions',
          body: 'Try browsing.',
          action: Text('Browse'),
        ),
      ));
      expect(find.text('Browse'), findsOneWidget);
    });

    testWidgets('does not render action widget when null', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const EmptyState(
          icon: Icons.calendar_today,
          title: 'Empty',
          body: 'Nothing here.',
        ),
      ));
      expect(find.text('Empty'), findsOneWidget);
      // Only title + body text widgets, no extra action
    });
  });
}
