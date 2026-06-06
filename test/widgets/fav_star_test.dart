import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/widgets/fav_star.dart';

import 'widget_test_helpers.dart';

void main() {
  group('FavStar', () {
    testWidgets('renders when off', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const FavStar(on: false),
      ));
      expect(find.byType(FavStar), findsOneWidget);
    });

    testWidgets('renders when on', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const FavStar(on: true),
      ));
      expect(find.byType(FavStar), findsOneWidget);
    });

    testWidgets('calls onToggle when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrapWithTheme(
        FavStar(on: false, onToggle: () => tapped = true),
      ));
      await tester.tap(find.byType(FavStar));
      expect(tapped, isTrue);
    });

    testWidgets('does not crash when onToggle is null', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const FavStar(on: false, onToggle: null),
      ));
      await tester.tap(find.byType(FavStar));
      await tester.pump();
      // Should not throw
    });
  });
}
