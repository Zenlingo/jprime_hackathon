/// Real-world footprints for venue zones, used to detect which part of the
/// venue the attendee is in ("you are here"). Each zone is a polygon (the 4
/// corners of its rough rectangle); if the attendee's GPS point falls *inside*
/// that polygon, they're in that zone. `id` matches a map room id / POI label
/// in map_screen.dart so the matching box can be highlighted.
///
/// To adjust a zone: walk its corners and use the in-app capture tool
/// (long-press Locate), or right-click each corner in Google Maps. Corner order
/// doesn't matter — the detector sorts them around the centroid.
class LatLng {
  final double lat;
  final double lng;
  const LatLng(this.lat, this.lng);
}

class VenueZone {
  final String id;
  final String label;
  final List<LatLng> polygon;

  const VenueZone({
    required this.id,
    required this.label,
    this.polygon = const [],
  });

  bool get hasPolygon => polygon.length >= 3;

  double get centroidLat =>
      polygon.map((p) => p.lat).reduce((a, b) => a + b) / polygon.length;
  double get centroidLng =>
      polygon.map((p) => p.lng).reduce((a, b) => a + b) / polygon.length;
}

const venueZones = <VenueZone>[
  // Hall A's building also covers Companies + Registration.
  VenueZone(id: 'Hall A', label: 'Hall A', polygon: [
    LatLng(42.666080, 23.375087),
    LatLng(42.666490, 23.375696),
    LatLng(42.666301, 23.375966),
    LatLng(42.665848, 23.375404),
  ]),
  VenueZone(id: 'Hall B', label: 'Hall B (tent)', polygon: [
    LatLng(42.666465, 23.374822),
    LatLng(42.666582, 23.375035),
    LatLng(42.666701, 23.374897),
    LatLng(42.666608, 23.374656),
  ]),
  VenueZone(id: 'Food', label: 'Food', polygon: [
    LatLng(42.666284, 23.375129),
    LatLng(42.666215, 23.375009),
    LatLng(42.666367, 23.374854),
    LatLng(42.666419, 23.374989),
  ]),
  VenueZone(id: 'Workshop', label: 'Workshop', polygon: [
    LatLng(42.666876, 23.373688),
    LatLng(42.666765, 23.373537),
    LatLng(42.666606, 23.373735),
    LatLng(42.666731, 23.373897),
  ]),
];

/// Outer footprint of the whole venue. Inside this but not in any zone means
/// "at the venue, between buildings"; outside means "not at the venue".
const venueBoundary = <LatLng>[
  LatLng(42.666509, 23.377449),
  LatLng(42.664688, 23.375167),
  LatLng(42.667074, 23.371600),
  LatLng(42.668820, 23.374198),
];
