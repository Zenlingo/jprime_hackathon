import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_theme.dart';
import '../data/sample_data.dart';
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
