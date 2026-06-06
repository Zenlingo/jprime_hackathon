import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/features/map/data/venue_zones.dart';

void main() {
  group('LatLng', () {
    test('stores lat and lng', () {
      const point = LatLng(42.666, 23.375);
      expect(point.lat, 42.666);
      expect(point.lng, 23.375);
    });
  });

  group('VenueZone', () {
    test('hasPolygon is true when 3+ points', () {
      const zone = VenueZone(
        id: 'test',
        label: 'Test',
        polygon: [LatLng(0, 0), LatLng(1, 0), LatLng(0, 1)],
      );
      expect(zone.hasPolygon, isTrue);
    });

    test('hasPolygon is false when fewer than 3 points', () {
      const zone = VenueZone(
        id: 'test',
        label: 'Test',
        polygon: [LatLng(0, 0), LatLng(1, 0)],
      );
      expect(zone.hasPolygon, isFalse);
    });

    test('hasPolygon is false when empty', () {
      const zone = VenueZone(id: 'test', label: 'Test');
      expect(zone.hasPolygon, isFalse);
    });

    test('centroid is computed correctly', () {
      const zone = VenueZone(
        id: 'test',
        label: 'Test',
        polygon: [
          LatLng(0, 0),
          LatLng(2, 0),
          LatLng(2, 4),
          LatLng(0, 4),
        ],
      );
      expect(zone.centroidLat, 1.0);
      expect(zone.centroidLng, 2.0);
    });
  });

  group('venueZones constant', () {
    test('contains 4 zones', () {
      expect(venueZones.length, 4);
    });

    test('all zones have valid polygons', () {
      for (final zone in venueZones) {
        expect(zone.hasPolygon, isTrue,
            reason: '${zone.label} should have a valid polygon');
      }
    });

    test('zone ids match expected names', () {
      final ids = venueZones.map((z) => z.id).toSet();
      expect(ids, containsAll(['Hall A', 'Hall B', 'Food', 'Workshop']));
    });

    test('each zone has exactly 4 corners', () {
      for (final zone in venueZones) {
        expect(zone.polygon.length, 4,
            reason: '${zone.label} should have 4 corners');
      }
    });

    test('all coordinates are in Sofia area', () {
      for (final zone in venueZones) {
        for (final point in zone.polygon) {
          expect(point.lat, closeTo(42.666, 0.005),
              reason: '${zone.label} lat should be near Sofia');
          expect(point.lng, closeTo(23.375, 0.005),
              reason: '${zone.label} lng should be near Sofia');
        }
      }
    });
  });

  group('venueBoundary', () {
    test('has 4 points', () {
      expect(venueBoundary.length, 4);
    });

    test('all boundary points are in Sofia area', () {
      for (final point in venueBoundary) {
        expect(point.lat, closeTo(42.667, 0.003));
        expect(point.lng, closeTo(23.375, 0.004));
      }
    });
  });
}
