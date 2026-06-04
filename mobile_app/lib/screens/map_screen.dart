import 'dart:async';
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

  const MapScreen({
    super.key,
    required this.nowMin,
    required this.onOpenSession,
    this.highlight,
    this.onThemeToggle,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String? _selectedRoom;

  // "You are here" detection
  String? _youAreHereLabel; // name of the zone you're currently in
  bool _locating = false;
  String? _locError; // non-null when GPS failed → show manual fallback

  // Live GPS tracking: the dot follows you in real time.
  StreamSubscription<Position>? _posSub;
  bool _liveOn = false;
  String? _liveStatus; // banner subtitle when you're not in a named zone

  // Live position, projected into the schematic's 0..1 coordinate space.
  Offset? _meDot;
  double? _meAccM; // GPS accuracy in metres, for context
  bool _meApprox = false; // true when between buildings (rough placement)

  /// Maps real lat/lng onto the stylized map, fitted from known zone anchors.
  late final _VenueProjector _projector = _buildProjector();

  /// Per-room transforms, fitted lazily from each room's real corner geometry
  /// to its schematic box (handles the room's own rotation/mirroring).
  final Map<String, _Affine?> _zoneAffines = {};

  _VenueProjector _buildProjector() {
    VenueZone z(String id) => venueZones.firstWhere((e) => e.id == id);
    // Pair each anchor's real centroid with its center in the schematic
    // (see room/POI x/y/w/h in build()).
    return _VenueProjector.fit([
      (
        lng: z('Hall A').centroidLng,
        lat: z('Hall A').centroidLat,
        x: 0.36,
        y: 0.115,
      ),
      (
        lng: z('Hall B').centroidLng,
        lat: z('Hall B').centroidLat,
        x: 0.35,
        y: 0.73,
      ),
      (
        lng: z('Workshop').centroidLng,
        lat: z('Workshop').centroidLat,
        x: 0.84,
        y: 0.65,
      ),
      (
        lng: z('Food').centroidLng,
        lat: z('Food').centroidLat,
        x: 0.73,
        y: 0.38,
      ),
    ]);
  }

  @override
  void initState() {
    super.initState();
    _selectedRoom = widget.highlight;
    _startLive(); // begin real-time tracking as soon as the map opens
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlight != oldWidget.highlight && widget.highlight != null) {
      _selectedRoom = widget.highlight;
    }
  }

  /// Start streaming GPS so the dot tracks the attendee in real time.
  Future<void> _startLive() async {
    setState(() {
      _locating = true;
      _locError = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _failLocate(
          'Location services are off. Turn them on, or pick your spot.',
        );
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
      await _posSub?.cancel();
      _posSub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 1, // emit after ~1m of movement
            ),
          ).listen(
            _applyPosition,
            onError: (_) {
              if (!mounted) return;
              setState(() => _liveStatus = 'Signal lost — reconnecting…');
            },
          );
      if (mounted) setState(() => _liveOn = true);
    } catch (_) {
      _failLocate('Could not read your location. Pick your spot instead.');
    }
  }

  /// Apply one live GPS fix: move the dot and update the status banner.
  void _applyPosition(Position pos) {
    if (!mounted) return;
    VenueZone? inZone;
    for (final z in venueZones) {
      if (z.hasPolygon &&
          _pointInPolygon(pos.latitude, pos.longitude, z.polygon)) {
        inZone = z;
        break;
      }
    }
    final atVenue =
        inZone != null ||
        _pointInPolygon(pos.latitude, pos.longitude, venueBoundary);
    setState(() {
      _locating = false;
      _locError = null;
      if (atVenue) {
        _meDot = _projectMe(inZone, pos.latitude, pos.longitude);
        _meAccM = pos.accuracy;
        _meApprox = inZone == null; // between buildings → rough placement
        if (inZone != null) {
          _setHere(inZone.id, inZone.label);
          _liveStatus = null;
        } else {
          _youAreHereLabel = null;
          _liveStatus = 'On the venue grounds';
        }
      } else {
        _meDot = null;
        _meAccM = null;
        _meApprox = false;
        _youAreHereLabel = null;
        _liveStatus = "You're not at the venue yet";
      }
    });
  }

  /// Stop live tracking and clear the dot.
  void _stopLive() {
    _posSub?.cancel();
    _posSub = null;
    setState(() {
      _liveOn = false;
      _liveStatus = null;
      _meDot = null;
      _meAccM = null;
      _meApprox = false;
      _youAreHereLabel = null;
    });
  }

  /// Ray-casting point-in-polygon. Corners are first ordered around the centroid
  /// so the input corner order doesn't matter for these convex rectangles.
  bool _pointInPolygon(double lat, double lng, List<LatLng> poly) {
    if (poly.length < 3) return false;
    final pts = [...poly];
    final cLat = pts.map((p) => p.lat).reduce((a, b) => a + b) / pts.length;
    final cLng = pts.map((p) => p.lng).reduce((a, b) => a + b) / pts.length;
    pts.sort(
      (a, b) => math
          .atan2(a.lat - cLat, a.lng - cLng)
          .compareTo(math.atan2(b.lat - cLat, b.lng - cLng)),
    );
    bool inside = false;
    for (int i = 0, j = pts.length - 1; i < pts.length; j = i++) {
      final xi = pts[i].lng, yi = pts[i].lat;
      final xj = pts[j].lng, yj = pts[j].lat;
      final intersects =
          ((yi > lat) != (yj > lat)) &&
          (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi);
      if (intersects) inside = !inside;
    }
    return inside;
  }

  /// Place the live dot. Inside a known room, map your real position through
  /// that room's fitted transform — accurate, and always in the right room.
  /// Between buildings, blend nearby anchors for a rough spot.
  Offset _projectMe(VenueZone? inZone, double lat, double lng) {
    if (inZone != null) {
      final box = _zoneRects[inZone.id];
      if (box != null) {
        final aff = _zoneAffines.putIfAbsent(
          inZone.id,
          () => _fitZoneAffine(inZone, box),
        );
        if (aff != null) {
          final p = aff.apply(lat, lng);
          return Offset(
            p.dx.clamp(box.x, box.x + box.w),
            p.dy.clamp(box.y, box.y + box.h),
          );
        }
      }
      final pt = _zonePoints[inZone.id];
      if (pt != null) return pt; // POI-only zone (e.g. Food)
    }
    // Between buildings: a rough spot, blended from nearby anchors.
    return _idw(lat, lng);
  }

  /// Inverse-distance-weighted blend of the known anchors (rooms + Food). Pulls
  /// the dot toward whichever anchors you're closest to, always stays on the
  /// map, and never extrapolates to a wrong spot — good for "roughly here".
  Offset _idw(double lat, double lng) {
    final anchors = <({Offset s, double lat, double lng})>[];
    for (final e in _zoneRects.entries) {
      final z = venueZones.firstWhere((v) => v.id == e.key);
      anchors.add((
        s: Offset(e.value.x + e.value.w / 2, e.value.y + e.value.h / 2),
        lat: z.centroidLat,
        lng: z.centroidLng,
      ));
    }
    for (final e in _zonePoints.entries) {
      final z = venueZones.firstWhere((v) => v.id == e.key);
      anchors.add((s: e.value, lat: z.centroidLat, lng: z.centroidLng));
    }
    final mPerLng = 111320.0 * math.cos(lat * math.pi / 180.0);
    double sumW = 0, sx = 0, sy = 0;
    for (final a in anchors) {
      final dx = (a.lng - lng) * mPerLng, dy = (a.lat - lat) * 111320.0;
      final d2 = dx * dx + dy * dy;
      if (d2 < 1) return a.s; // essentially on the anchor
      final w = 1.0 / (d2 * d2); // 1/d^4 → favours the nearest anchor
      sumW += w;
      sx += w * a.s.dx;
      sy += w * a.s.dy;
    }
    return Offset(sx / sumW, sy / sumW);
  }

  /// Fit an affine mapping a room's real footprint (meters) onto its schematic
  /// box. A room is a rotated rectangle drawn axis-aligned, so we try all corner
  /// correspondences (4 rotations × 2 mirrorings) and keep the one that (a) is
  /// closest to a true similarity — least shear/anisotropy — and (b) points the
  /// same way as the overall map (global east/north directions).
  _Affine? _fitZoneAffine(VenueZone z, _Box box) {
    if (z.polygon.length != 4) return null;
    final refLat = z.centroidLat, refLng = z.centroidLng;
    final mPerLng = 111320.0 * math.cos(refLat * math.pi / 180.0);
    Offset toM(double la, double ln) =>
        Offset((ln - refLng) * mPerLng, (la - refLat) * 111320.0);

    // Real corners in meters, sorted CCW so correspondences are cyclic.
    final src = z.polygon.map((p) => toM(p.lat, p.lng)).toList();
    final scx = src.map((p) => p.dx).reduce((a, b) => a + b) / 4;
    final scy = src.map((p) => p.dy).reduce((a, b) => a + b) / 4;
    src.sort(
      (a, b) => math
          .atan2(a.dy - scy, a.dx - scx)
          .compareTo(math.atan2(b.dy - scy, b.dx - scx)),
    );

    final dst = <Offset>[
      Offset(box.x, box.y),
      Offset(box.x + box.w, box.y),
      Offset(box.x + box.w, box.y + box.h),
      Offset(box.x, box.y + box.h),
    ];

    // How east/north read on the schematic overall, used to fix orientation.
    final o = _projector.project(refLat, refLng);
    final gEast = _projector.project(refLat, refLng + 0.0002) - o;
    final gNorth = _projector.project(refLat + 0.0002, refLng) - o;

    _Affine? best;
    var bestScore = -1e9;
    for (final dir in [1, -1]) {
      for (var rot = 0; rot < 4; rot++) {
        final sx = <double>[],
            sy = <double>[],
            dx = <double>[],
            dy = <double>[];
        for (var i = 0; i < 4; i++) {
          final j = (((dir == 1 ? i + rot : rot - i) % 4) + 4) % 4;
          sx.add(src[j].dx);
          sy.add(src[j].dy);
          dx.add(dst[i].dx);
          dy.add(dst[i].dy);
        }
        final aff = _Affine.fit(sx, sy, dx, dy, mPerLng, refLat, refLng);
        final s1 = math.sqrt(aff.ax * aff.ax + aff.ay * aff.ay);
        final s2 = math.sqrt(aff.bx * aff.bx + aff.by * aff.by);
        final shear =
            (aff.ax * aff.bx + aff.ay * aff.by).abs() / (s1 * s2 + 1e-9) +
            (s1 - s2).abs() / (s1 + s2 + 1e-9);
        final align =
            _cos(Offset(aff.ax, aff.ay), gEast) +
            _cos(Offset(aff.bx, aff.by), gNorth);
        final score = align * 2.0 - shear; // orientation first, then shape
        if (score > bestScore) {
          bestScore = score;
          best = aff;
        }
      }
    }
    return best;
  }

  void _failLocate(String msg) {
    if (!mounted) return;
    setState(() {
      _locating = false;
      _locError = msg;
    });
  }

  void _setHere(String id, String label) {
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
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

  /// Photo for each room / POI, shown when it's tapped. Hall A and Companies
  /// share one shot of the main hall.
  static const _zonePhotos = <String, String>{
    'Hall A': 'assets/venue/hall_a.jpg',
    'Companies': 'assets/venue/hall_a.jpg',
    'Hall B': 'assets/venue/hall_b.jpg',
    'Workshop': 'assets/venue/workshop.jpg',
    'Registration': 'assets/venue/registration.jpg',
    'Food': 'assets/venue/food.jpg',
  };

  /// Show a tapped zone's photo in a full-screen overlay in front of the map.
  void _showPhoto(String id, String label) {
    final asset = _zonePhotos[id];
    if (asset == null) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  child: Image.asset(asset, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    alignment: Alignment.center,
                    child: PhosphorIcon(
                      PhosphorIconsRegular.x,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    // Layout mirrors the physical venue: Hall A sits just above Companies
    // top-left, with Registration marked below them. Chill lounge mid-left,
    // Hall B lower-left, Food mid-right and Workshop on the far-right edge.
    final rooms = [
      _MapRoom(id: 'Hall A', trackId: 'a', x: 0.05, y: 0.04, w: 0.62, h: 0.15),
      _MapRoom(
        id: 'Companies',
        trackId: null,
        x: 0.06,
        y: 0.2,
        w: 0.60,
        h: 0.085,
      ),
      // _MapRoom(id: 'Chill', trackId: null, x: 0.10, y: 0.52, w: 0.34, h: 0.13),
      _MapRoom(id: 'Hall B', trackId: 'b', x: 0.13, y: 0.65, w: 0.44, h: 0.16),
      _MapRoom(
        id: 'Workshop',
        trackId: 'workshop',
        x: 0.74,
        y: 0.49,
        w: 0.20,
        h: 0.32,
      ),
    ];
    final pois = [
      _POI(
        icon: PhosphorIconsRegular.info,
        label: 'Registration',
        x: 0.3,
        y: 0.32,
      ),
      _POI(
        icon: PhosphorIconsRegular.forkKnife,
        label: 'Food',
        x: 0.73,
        y: 0.38,
      ),
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
                live: _liveOn,
                hereLabel: _youAreHereLabel,
                status: _liveStatus,
                locating: _locating,
                error: _locError,
                onEnable: _startLive,
                onStop: _stopLive,
                onCapture: _captureHere,
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
                              final tColor = r.trackId != null
                                  ? trackColor(context, r.trackId!)
                                  : null;
                              final tSoft = r.trackId != null
                                  ? trackSoftColor(context, r.trackId!)
                                  : null;
                              final sel = _selectedRoom == r.id;
                              return Positioned(
                                left: r.x * w,
                                top: r.y * h,
                                width: r.w * w,
                                height: r.h * h,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    setState(() => _selectedRoom = r.id);
                                    _showPhoto(r.id, r.id);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    decoration: BoxDecoration(
                                      color: tSoft ?? jp.surface2,
                                      border: Border.all(
                                        color: sel
                                            ? jp.accent
                                            : (tColor ?? jp.borderStrong),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: sel
                                          ? [
                                              BoxShadow(
                                                color: jp.accentSoft,
                                                blurRadius: 0,
                                                spreadRadius: 4,
                                              ),
                                            ]
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
                                ),
                              );
                            }),
                            // POIs
                            ...pois.map(
                              (p) => Positioned(
                                left: p.x * w - 15,
                                top: p.y * h - 20,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _showPhoto(p.label, p.label),
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
                                              color: Colors.black.withValues(
                                                alpha: 0.06,
                                              ),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: PhosphorIcon(
                                          p.icon,
                                          size: 16,
                                          color: jp.fgSecondary,
                                        ),
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
                            ),
                            // Live "you are here" dot from GPS.
                            if (_meDot != null)
                              Positioned(
                                left: _meDot!.dx * w - (_meApprox ? 18 : 13),
                                top: _meDot!.dy * h - (_meApprox ? 18 : 13),
                                child: _MeDot(
                                  accuracyM: _meAccM,
                                  approximate: _meApprox,
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

class _Box {
  final double x, y, w, h;
  const _Box(this.x, this.y, this.w, this.h);
}

/// Schematic boxes for detectable rooms — must mirror the room rects in build().
/// Used to drop the live dot precisely inside the room you're standing in.
const _zoneRects = <String, _Box>{
  'Hall A': _Box(0.05, 0.04, 0.62, 0.15),
  'Hall B': _Box(0.13, 0.65, 0.44, 0.16),
  'Workshop': _Box(0.74, 0.49, 0.20, 0.32),
};

/// Zones drawn as a single point marker rather than a box (e.g. Food).
const _zonePoints = <String, Offset>{'Food': Offset(0.73, 0.38)};

class _MapRoom {
  final String id;
  final String? trackId;
  final double x, y, w, h;

  const _MapRoom({
    required this.id,
    this.trackId,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });
}

class _POI {
  final PhosphorIconData icon;
  final String label;
  final double x, y;

  const _POI({
    required this.icon,
    required this.label,
    required this.x,
    required this.y,
  });
}

/// "You are here" control: a Locate button that snaps to the nearest GPS zone,
/// a result banner once located, and a manual zone picker when GPS is weak.
class _LocateBar extends StatelessWidget {
  final bool live; // real-time tracking active
  final String? hereLabel; // name of the zone you're in, if any
  final String? status; // generic status when not in a named zone
  final bool locating;
  final String? error;
  final VoidCallback onEnable;
  final VoidCallback onStop;
  final VoidCallback onCapture;
  final void Function(VenueZone) onPickManual;

  const _LocateBar({
    required this.live,
    required this.hereLabel,
    required this.status,
    required this.locating,
    required this.error,
    required this.onEnable,
    required this.onStop,
    required this.onCapture,
    required this.onPickManual,
  });

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (live || locating)
          // Live status banner — updates in real time as you move.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: jp.accentSoft,
              border: Border.all(color: jp.accent),
              borderRadius: BorderRadius.circular(JPSpacing.rMd),
            ),
            child: Row(
              children: [
                PhosphorIcon(
                  PhosphorIconsFill.navigationArrow,
                  size: 18,
                  color: jp.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF22C55E),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            hereLabel != null ? 'LIVE · YOU ARE HERE' : 'LIVE',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: jp.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hereLabel ??
                            status ??
                            (locating ? 'Finding you…' : 'Tracking…'),
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
                  onTap: onStop,
                  child: PhosphorIcon(
                    PhosphorIconsRegular.x,
                    size: 16,
                    color: jp.fgMuted,
                  ),
                ),
              ],
            ),
          )
        else
          // Enable button (long-press to capture a coordinate for dev use)
          GestureDetector(
            onTap: onEnable,
            onLongPress: onCapture,
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
                  PhosphorIcon(
                    PhosphorIconsFill.navigationArrow,
                    size: 17,
                    color: jp.onAccent,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Turn on live location',
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
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              color: jp.fgSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: venueZones
                .map(
                  (z) => GestureDetector(
                    onTap: () => onPickManual(z),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
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
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

/// Pulsing "you are here" dot. Crisp & solid when exact (inside a room);
/// softer, hollow, with a wider halo when approximate (between buildings).
class _MeDot extends StatefulWidget {
  final double? accuracyM;
  final bool approximate;
  const _MeDot({this.accuracyM, this.approximate = false});

  @override
  State<_MeDot> createState() => _MeDotState();
}

class _MeDotState extends State<_MeDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    final approx = widget.approximate;
    final haloMax = approx ? 22.0 : 14.0;
    final dot = SizedBox(
      width: approx ? 36 : 26,
      height: approx ? 36 : 26,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = _c.value; // expanding, fading halo
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 12 + haloMax * t,
                height: 12 + haloMax * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: jp.accent.withValues(
                    alpha: (approx ? 0.20 : 0.28) * (1 - t),
                  ),
                ),
              ),
              child!,
            ],
          );
        },
        child: Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: approx ? jp.accent.withValues(alpha: 0.30) : jp.accent,
            border: Border.all(
              color: approx ? jp.accent : Colors.white,
              width: 2.5,
            ),
            boxShadow: approx
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
        ),
      ),
    );
    final acc = widget.accuracyM;
    final msg = approx
        ? 'Approximate — you\'re between buildings'
        : (acc == null ? null : 'Accurate to ±${acc.round()}m');
    return msg == null ? dot : Tooltip(message: msg, child: dot);
  }
}

/// Cosine of the angle between two schematic vectors (1 = same direction).
double _cos(Offset a, Offset b) {
  final na = a.distance, nb = b.distance;
  if (na < 1e-9 || nb < 1e-9) return 0;
  return (a.dx * b.dx + a.dy * b.dy) / (na * nb);
}

/// Least-squares affine fit from venue lat/lng to the schematic's 0..1 space,
/// derived from known zone anchors. Lets a live GPS fix be drawn as a dot.
class _VenueProjector {
  final double _mLng, _mLat; // anchor means, subtracted for numerical stability
  final List<double> _cx, _cy; // [a, b, c] coefficients for x and y
  _VenueProjector._(this._mLng, this._mLat, this._cx, this._cy);

  factory _VenueProjector.fit(
    List<({double lng, double lat, double x, double y})> pts,
  ) {
    final n = pts.length;
    final mLng = pts.map((p) => p.lng).reduce((a, b) => a + b) / n;
    final mLat = pts.map((p) => p.lat).reduce((a, b) => a + b) / n;
    final m = List.generate(3, (_) => List.filled(3, 0.0));
    final bx = List.filled(3, 0.0), by = List.filled(3, 0.0);
    for (final p in pts) {
      final v = [p.lng - mLng, p.lat - mLat, 1.0];
      for (var i = 0; i < 3; i++) {
        for (var j = 0; j < 3; j++) {
          m[i][j] += v[i] * v[j];
        }
        bx[i] += v[i] * p.x;
        by[i] += v[i] * p.y;
      }
    }
    final cx = _solve3(
      [
        for (final r in m) [...r],
      ],
      [...bx],
    );
    final cy = _solve3(
      [
        for (final r in m) [...r],
      ],
      [...by],
    );
    return _VenueProjector._(mLng, mLat, cx, cy);
  }

  /// Schematic 0..1 coordinate for a real point, clamped to stay on the map.
  Offset project(double lat, double lng) {
    final dl = lng - _mLng, da = lat - _mLat;
    final x = _cx[0] * dl + _cx[1] * da + _cx[2];
    final y = _cy[0] * dl + _cy[1] * da + _cy[2];
    return Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
  }
}

/// Affine map from real coordinates (via local meters) to schematic 0..1 space:
///   x = ax·mx + bx·my + cx,  y = ay·mx + by·my + cy
/// where (mx, my) are east/north metres relative to the reference point.
class _Affine {
  final double ax, bx, cx, ay, by, cy;
  final double refLat, refLng, mPerLng;
  const _Affine(
    this.ax,
    this.bx,
    this.cx,
    this.ay,
    this.by,
    this.cy,
    this.refLat,
    this.refLng,
    this.mPerLng,
  );

  factory _Affine.fit(
    List<double> sx,
    List<double> sy,
    List<double> dx,
    List<double> dy,
    double mPerLng,
    double refLat,
    double refLng,
  ) {
    final m = List.generate(3, (_) => List.filled(3, 0.0));
    final bX = List.filled(3, 0.0), bY = List.filled(3, 0.0);
    for (var i = 0; i < sx.length; i++) {
      final v = [sx[i], sy[i], 1.0];
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          m[r][c] += v[r] * v[c];
        }
        bX[r] += v[r] * dx[i];
        bY[r] += v[r] * dy[i];
      }
    }
    final cX = _solve3(
      [
        for (final r in m) [...r],
      ],
      [...bX],
    );
    final cY = _solve3(
      [
        for (final r in m) [...r],
      ],
      [...bY],
    );
    return _Affine(
      cX[0],
      cX[1],
      cX[2],
      cY[0],
      cY[1],
      cY[2],
      refLat,
      refLng,
      mPerLng,
    );
  }

  Offset apply(double lat, double lng) {
    final mx = (lng - refLng) * mPerLng;
    final my = (lat - refLat) * 111320.0;
    return Offset(ax * mx + bx * my + cx, ay * mx + by * my + cy);
  }
}

/// Solves a 3x3 linear system via Gauss-Jordan elimination with partial pivoting.
List<double> _solve3(List<List<double>> a, List<double> b) {
  for (var col = 0; col < 3; col++) {
    var piv = col;
    for (var r = col + 1; r < 3; r++) {
      if (a[r][col].abs() > a[piv][col].abs()) piv = r;
    }
    final tr = a[col];
    a[col] = a[piv];
    a[piv] = tr;
    final tb = b[col];
    b[col] = b[piv];
    b[piv] = tb;
    final d = a[col][col];
    if (d.abs() < 1e-12) continue; // degenerate; leave as-is
    for (var r = 0; r < 3; r++) {
      if (r == col) continue;
      final f = a[r][col] / d;
      for (var c = 0; c < 3; c++) {
        a[r][c] -= f * a[col][c];
      }
      b[r] -= f * b[col];
    }
  }
  return [b[0] / a[0][0], b[1] / a[1][1], b[2] / a[2][2]];
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
        child: PhosphorIcon(
          isDark ? PhosphorIconsFill.sun : PhosphorIconsFill.moonStars,
          size: 19,
          color: jp.fg,
        ),
      ),
    );
  }
}
