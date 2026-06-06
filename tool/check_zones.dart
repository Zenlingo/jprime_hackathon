// Standalone sanity-check for the venue geofencing (run: fvm dart run tool/check_zones.dart)
// ignore_for_file: avoid_print
import 'dart:math' as math;
import 'package:mobile_app/features/map/data/venue_zones.dart';

bool pointInPolygon(double lat, double lng, List<LatLng> poly) {
  if (poly.length < 3) return false;
  final pts = [...poly];
  final cLat = pts.map((p) => p.lat).reduce((a, b) => a + b) / pts.length;
  final cLng = pts.map((p) => p.lng).reduce((a, b) => a + b) / pts.length;
  pts.sort((a, b) => math
      .atan2(a.lat - cLat, a.lng - cLng)
      .compareTo(math.atan2(b.lat - cLat, b.lng - cLng)));
  bool inside = false;
  for (int i = 0, j = pts.length - 1; i < pts.length; j = i++) {
    final xi = pts[i].lng, yi = pts[i].lat;
    final xj = pts[j].lng, yj = pts[j].lat;
    final intersects = ((yi > lat) != (yj > lat)) &&
        (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi);
    if (intersects) inside = !inside;
  }
  return inside;
}

String? detect(double lat, double lng) {
  for (final z in venueZones) {
    if (z.hasPolygon && pointInPolygon(lat, lng, z.polygon)) return z.id;
  }
  return null;
}

void main() {
  var pass = true;
  void check(String label, bool ok) {
    pass = pass && ok;
    print('${label.padRight(34)} ${ok ? "OK" : "FAIL"}');
  }

  // 1) Each zone's centroid resolves to that zone, and sits inside the venue.
  for (final z in venueZones) {
    check('${z.id} centroid -> ${detect(z.centroidLat, z.centroidLng) ?? "none"}',
        detect(z.centroidLat, z.centroidLng) == z.id);
    check('${z.id} centroid inside venue boundary',
        pointInPolygon(z.centroidLat, z.centroidLng, venueBoundary));
  }
  // 2) A point 2km away: not a zone, and outside the venue boundary.
  check('far away -> not a zone', detect(42.6977, 23.3219) == null);
  check('far away -> outside venue boundary',
      !pointInPolygon(42.6977, 23.3219, venueBoundary));
  // 3) No corner of any zone leaks into another zone.
  for (final z in venueZones) {
    for (final c in z.polygon) {
      final got = detect(c.lat, c.lng);
      if (got != null && got != z.id) {
        check('CORNER LEAK ${z.id} -> $got', false);
      }
    }
  }
  print(pass ? '\nALL CHECKS PASSED' : '\nSOME CHECKS FAILED');
}
