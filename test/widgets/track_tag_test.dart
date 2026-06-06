import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/features/schedule/widgets/track_tag.dart';

import 'widget_test_helpers.dart';

void main() {
  group('TrackTag', () {
    testWidgets('shows "Hall A" for track id "a"', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const TrackTag(trackId: 'a'),
      ));
      expect(find.text('Hall A'), findsOneWidget);
    });

    testWidgets('shows "Hall B" for track id "b"', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const TrackTag(trackId: 'b'),
      ));
      expect(find.text('Hall B'), findsOneWidget);
    });

    testWidgets('shows "Workshop" for track id "workshop"', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const TrackTag(trackId: 'workshop'),
      ));
      expect(find.text('Workshop'), findsOneWidget);
    });

    testWidgets('shows raw trackId for unknown id', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const TrackTag(trackId: 'unknown'),
      ));
      expect(find.text('unknown'), findsOneWidget);
    });

    testWidgets('renders in small mode', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const TrackTag(trackId: 'a', small: true),
      ));
      expect(find.text('Hall A'), findsOneWidget);
    });
  });
}
