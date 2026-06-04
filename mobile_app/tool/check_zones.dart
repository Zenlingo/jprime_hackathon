// Standalone sanity-check for the venue geofencing (run: fvm dart run tool/check_zones.dart)
import 'dart:math' as math;
import 'package:mobile_app/data/venue_zones.dart';

bool pointInZone(double lat, double lng, VenueZone z) {
  final pts = [...z.polygon];
  final cLat = z.centroidLat, cLng = z.centroidLng;
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
    if (z.hasPolygon && pointInZone(lat, lng, z)) return z.id;
  }
  return null;
}

void main() {
  var pass = true;
  // 1) Each zone's centroid must be detected as that zone (and only that zone).
  for (final z in venueZones) {
    final got = detect(z.centroidLat, z.centroidLng);
    final ok = got == z.id;
    pass = pass && ok;
    print('${z.id.padRight(10)} centroid -> ${got ?? "none"}   ${ok ? "OK" : "FAIL"}');
  }
  // 2) A point far away must match nothing.
  final far = detect(42.6977, 23.3219);
  pass = pass && far == null;
  print('far away    -> ${far ?? "none"}   ${far == null ? "OK" : "FAIL"}');
  // 3) Each corner of each zone should resolve to that zone (or none at the very edge).
  for (final z in venueZones) {
    for (final c in z.polygon) {
      final got = detect(c.lat, c.lng);
      if (got != null && got != z.id) {
        pass = false;
        print('CORNER LEAK: ${z.id} corner detected as $got');
      }
    }
  }
  print(pass ? '\nALL CHECKS PASSED' : '\nSOME CHECKS FAILED');
}
