import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../data/sample_data.dart';
import '../data/venue_zones.dart';
import '../widgets/app_header.dart';
import '../widgets/track_tag.dart';

class MapScreen extends StatefulWidget {
  final int nowMin;
  final void Function(SessionData session) onOpenSession;
  final String? highlight;
  final VoidCallback? onThemeToggle;

  const MapScreen({super.key, required this.nowMin, required this.onOpenSession, this.highlight, this.onThemeToggle});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String? _selectedRoom;

  // "You are here" detection
  String? _youAreHere; // zone id of detected location
  String? _youAreHereLabel;
  bool _locating = false;
  String? _locError; // non-null when GPS failed → show manual fallback

  @override
  void initState() {
    super.initState();
    _selectedRoom = widget.highlight;
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlight != oldWidget.highlight && widget.highlight != null) {
      _selectedRoom = widget.highlight;
    }
  }

  /// Use GPS to detect which venue zone the attendee is standing inside.
  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _locError = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _failLocate('Location services are off. Turn them on, or pick your spot.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _failLocate('Location permission denied. Pick your spot instead.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      // Are we standing inside any zone's footprint?
      VenueZone? inZone;
      for (final z in venueZones) {
        if (z.hasPolygon &&
            _pointInPolygon(pos.latitude, pos.longitude, z.polygon)) {
          inZone = z;
          break;
        }
      }
      if (inZone != null) {
        setState(() {
          _locating = false;
          _setHere(inZone!.id, inZone.label);
        });
        return;
      }
      // Not inside any zone — are we at least within the venue grounds?
      if (_pointInPolygon(pos.latitude, pos.longitude, venueBoundary)) {
        _failLocate("You're at the venue but not inside a mapped area "
            "(maybe between buildings). Pick your spot.");
      } else {
        _failLocate("You don't seem to be at the venue yet. "
            "Pick your spot if you're already inside.");
      }
    } catch (_) {
      _failLocate('Could not read your location. Pick your spot instead.');
    }
  }

  /// Ray-casting point-in-polygon. Corners are first ordered around the centroid
  /// so the input corner order doesn't matter for these convex rectangles.
  bool _pointInPolygon(double lat, double lng, List<LatLng> poly) {
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

  void _failLocate(String msg) {
    if (!mounted) return;
    setState(() {
      _locating = false;
      _locError = msg;
    });
  }

  void _setHere(String id, String label) {
    _youAreHere = id;
    _youAreHereLabel = label;
    _locError = null;
    // Highlight the matching box, if this zone is a room (not the Food POI).
    if (id != 'Food') _selectedRoom = id;
  }

  /// Dev helper: read the current GPS coordinate so it can be pasted into
  /// venue_zones.dart (e.g. to add the Workshop). Long-press the Locate button.
  Future<void> _captureHere() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _failLocate('Location permission denied.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final coord = '${pos.latitude}, ${pos.longitude}';
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Captured location'),
          content: SelectableText(
            '$coord\n\n±${pos.accuracy.round()}m accuracy\n\nPaste this into venue_zones.dart.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: coord));
                Navigator.of(ctx).pop();
              },
              child: const Text('Copy'),
            ),
          ],
        ),
      );
    } catch (_) {
      _failLocate('Could not read your location.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    // Layout mirrors the physical venue: Hall A sits just above Companies
    // top-left, with Registration marked below them. Chill lounge mid-left,
    // Hall B lower-left, Food mid-right and Workshop on the far-right edge.
    final rooms = [
      _MapRoom(id: 'Hall A', trackId: 'a', x: 0.05, y: 0.04, w: 0.62, h: 0.15),
      _MapRoom(id: 'Companies', trackId: null, x: 0.06, y: 0.2, w: 0.60, h: 0.085),
      // _MapRoom(id: 'Chill', trackId: null, x: 0.10, y: 0.52, w: 0.34, h: 0.13),
      _MapRoom(id: 'Hall B', trackId: 'b', x: 0.13, y: 0.65, w: 0.44, h: 0.16),
      _MapRoom(id: 'Workshop', trackId: 'workshop', x: 0.74, y: 0.49, w: 0.20, h: 0.32),
    ];
    final pois = [
      _POI(icon: PhosphorIconsRegular.info, label: 'Registration', x: 0.3, y: 0.32),
      _POI(icon: PhosphorIconsRegular.forkKnife, label: 'Food', x: 0.73, y: 0.38),
    ];

    return Stack(
      children: [
        Column(
          children: [
            AppHeader(
              title: 'Map',
              subtitle: 'Sofia Tech Park',
              trailing: _ThemeButton(onTap: widget.onThemeToggle),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: _LocateBar(
                here: _youAreHere,
                hereLabel: _youAreHereLabel,
                locating: _locating,
                error: _locError,
                onLocate: _locate,
                onCapture: _captureHere,
                onClear: () => setState(() {
                  _youAreHere = null;
                  _youAreHereLabel = null;
                  _locError = null;
                }),
                onPickManual: (z) => setState(() => _setHere(z.id, z.label)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: AspectRatio(
                  aspectRatio: 1 / 1.05,
                  child: Container(
                    decoration: BoxDecoration(
                      color: jp.surfaceSunken,
                      border: Border.all(color: jp.border),
                      borderRadius: BorderRadius.circular(JPSpacing.rMd),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;
                        return Stack(
                          children: [
                            // Rooms
                            ...rooms.map((r) {
                              final tColor = r.trackId != null ? trackColor(context, r.trackId!) : null;
                              final tSoft = r.trackId != null ? trackSoftColor(context, r.trackId!) : null;
                              final sel = _selectedRoom == r.id;
                              return Positioned(
                                left: r.x * w,
                                top: r.y * h,
                                width: r.w * w,
                                height: r.h * h,
                                child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    decoration: BoxDecoration(
                                      color: tSoft ?? jp.surface2,
                                      border: Border.all(
                                        color: sel ? jp.accent : (tColor ?? jp.borderStrong),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: sel
                                          ? [BoxShadow(color: jp.accentSoft, blurRadius: 0, spreadRadius: 4)]
                                          : null,
                                    ),
                                    alignment: Alignment.bottomLeft,
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      r.id,
                                      softWrap: false,
                                      overflow: TextOverflow.visible,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: tColor ?? jp.fgSecondary,
                                      ),
                                    ),
                                  ),
                              );
                            }),
                            // POIs
                            ...pois.map(
                              (p) => Positioned(
                                left: p.x * w - 15,
                                top: p.y * h - 20,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: jp.surface,
                                        border: Border.all(color: jp.border),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.06),
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: PhosphorIcon(p.icon, size: 16, color: jp.fgSecondary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      p.label,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: jp.fgMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MapRoom {
  final String id;
  final String? trackId;
  final double x, y, w, h;

  const _MapRoom({required this.id, this.trackId, required this.x, required this.y, required this.w, required this.h});
}

class _POI {
  final PhosphorIconData icon;
  final String label;
  final double x, y;

  const _POI({required this.icon, required this.label, required this.x, required this.y});
}

/// "You are here" control: a Locate button that snaps to the nearest GPS zone,
/// a result banner once located, and a manual zone picker when GPS is weak.
class _LocateBar extends StatelessWidget {
  final String? here;
  final String? hereLabel;
  final bool locating;
  final String? error;
  final VoidCallback onLocate;
  final VoidCallback onCapture;
  final VoidCallback onClear;
  final void Function(VenueZone) onPickManual;

  const _LocateBar({
    required this.here,
    required this.hereLabel,
    required this.locating,
    required this.error,
    required this.onLocate,
    required this.onCapture,
    required this.onClear,
    required this.onPickManual,
  });

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (here != null)
          // Result banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: jp.accentSoft,
              border: Border.all(color: jp.accent),
              borderRadius: BorderRadius.circular(JPSpacing.rMd),
            ),
            child: Row(
              children: [
                PhosphorIcon(PhosphorIconsFill.mapPin, size: 18, color: jp.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You are here',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: jp.accent,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$hereLabel',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: jp.fg,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onClear,
                  child: PhosphorIcon(PhosphorIconsRegular.x, size: 16, color: jp.fgMuted),
                ),
              ],
            ),
          )
        else
          // Locate button (long-press to capture a coordinate)
          GestureDetector(
            onTap: locating ? null : onLocate,
            onLongPress: locating ? null : onCapture,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: jp.accent,
                borderRadius: BorderRadius.circular(JPSpacing.rMd),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (locating)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: jp.onAccent),
                    )
                  else
                    PhosphorIcon(PhosphorIconsFill.navigationArrow, size: 17, color: jp.onAccent),
                  const SizedBox(width: 9),
                  Text(
                    locating ? 'Locating…' : 'Locate me on the map',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: jp.onAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: GoogleFonts.hankenGrotesk(fontSize: 12, color: jp.fgSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: venueZones
                .map((z) => GestureDetector(
                      onTap: () => onPickManual(z),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: jp.surface2,
                          border: Border.all(color: jp.border),
                          borderRadius: BorderRadius.circular(JPSpacing.rPill),
                        ),
                        child: Text(
                          z.label,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: jp.fg,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _ThemeButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _ThemeButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: jp.surface2,
          border: Border.all(color: jp.border),
          borderRadius: BorderRadius.circular(JPSpacing.rPill),
        ),
        alignment: Alignment.center,
        child: PhosphorIcon(isDark ? PhosphorIconsFill.sun : PhosphorIconsFill.moonStars, size: 19, color: jp.fg),
      ),
    );
  }
}
