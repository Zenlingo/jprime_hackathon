import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'data/sample_data.dart';
import 'screens/now_next_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/my_agenda_screen.dart';
import 'screens/map_screen.dart';
import 'screens/connect_screen.dart';
import 'screens/session_detail_screen.dart';
import 'screens/onboarding_screen.dart';

class AppShell extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const AppShell({super.key, required this.onThemeToggle});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tabIndex = 3; // TEMP preview: open on Map
  SessionData? _detailSession;
  String? _mapHighlight;
  Set<String> _favs = {'s2', 's5'};
  bool _showOnboarding = false; // TEMP preview: skip onboarding
  // ignore: prefer_final_fields
  bool _offline = false;
  String? _linkedInUrl;

  // Simulated time: 10:30 → s2/s3 are live, s1 finished
  static const _nowMin = 630;

  @override
  void initState() {
    super.initState();
    _loadLinkedInUrl();
  }

  Future<void> _loadLinkedInUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('linkedin_url');
    if (url != null && mounted) {
      setState(() => _linkedInUrl = url);
    }
  }

  Future<void> _saveLinkedInUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url != null && url.isNotEmpty) {
      await prefs.setString('linkedin_url', url);
    } else {
      await prefs.remove('linkedin_url');
    }
    if (mounted) {
      setState(() => _linkedInUrl = url?.isNotEmpty == true ? url : null);
    }
  }

  void _toggleFav(String id, {bool forceOn = false}) {
    setState(() {
      if (forceOn) {
        _favs = {..._favs, id};
      } else if (_favs.contains(id)) {
        _favs = {..._favs}..remove(id);
      } else {
        _favs = {..._favs, id};
      }
    });
  }

  void _openSession(SessionData s) => setState(() => _detailSession = s);

  void _findRoom(SessionData s) {
    setState(() {
      _detailSession = null;
      _mapHighlight = s.room;
      _tabIndex = 3; // Map tab
    });
  }

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;

    return Scaffold(
      backgroundColor: jp.bg,
      body: Stack(
        children: [
          Column(
            children: [
              // Offline banner
              if (_offline)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 8),
                  color: jp.warningSoft,
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        PhosphorIcon(PhosphorIconsFill.cloudSlash,
                            size: 16, color: jp.warning),
                        const SizedBox(width: 8),
                        Text(
                          'You\'re offline. Showing your saved schedule.',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: jp.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Main content
              Expanded(
                child: IndexedStack(
                  index: _tabIndex,
                  children: [
                    NowNextScreen(
                      nowMin: _nowMin,
                      onThemeToggle: widget.onThemeToggle,
                      onOpenSession: _openSession,
                    ),
                    ScheduleScreen(
                      nowMin: _nowMin,
                      favs: _favs,
                      onToggleFav: (id) => _toggleFav(id),
                      onOpenSession: _openSession,
                    ),
                    MyAgendaScreen(
                      nowMin: _nowMin,
                      favs: _favs,
                      onToggleFav: (id, {forceOn = false}) =>
                          _toggleFav(id, forceOn: forceOn),
                      onOpenSession: _openSession,
                      onThemeToggle: widget.onThemeToggle,
                    ),
                    MapScreen(
                      nowMin: _nowMin,
                      onOpenSession: _openSession,
                      highlight: _mapHighlight,
                      onThemeToggle: widget.onThemeToggle,
                    ),
                    ConnectScreen(
                      onThemeToggle: widget.onThemeToggle,
                      linkedInUrl: _linkedInUrl,
                      onLinkedInChanged: _saveLinkedInUrl,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Bottom tab bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _TabBar(
              activeIndex: _tabIndex,
              onTap: (i) => setState(() {
                _mapHighlight = null;
                _tabIndex = i;
              }),
            ),
          ),

          // Session detail overlay
          if (_detailSession != null)
            SessionDetailScreen(
              session: _detailSession!,
              nowMin: _nowMin,
              fav: _favs.contains(_detailSession!.id),
              onFav: () => _toggleFav(_detailSession!.id),
              onClose: () => setState(() => _detailSession = null),
              onFindRoom: _findRoom,
            ),

          // Onboarding overlay
          if (_showOnboarding)
            OnboardingScreen(
              onDone: (linkedInUrl) {
                setState(() => _showOnboarding = false);
                if (linkedInUrl != null) {
                  _saveLinkedInUrl(linkedInUrl);
                }
              },
            ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final int activeIndex;
  final void Function(int) onTap;

  const _TabBar({required this.activeIndex, required this.onTap});

  static final _tabs = [
    _TabDef(PhosphorIconsRegular.broadcast, PhosphorIconsFill.broadcast, 'Now & Next'),
    _TabDef(PhosphorIconsRegular.calendarBlank, PhosphorIconsFill.calendarBlank, 'Schedule'),
    _TabDef(PhosphorIconsRegular.sparkle, PhosphorIconsFill.sparkle, 'My Agenda', badge: true),
    _TabDef(PhosphorIconsRegular.mapTrifold, PhosphorIconsFill.mapTrifold, 'Map'),
    _TabDef(PhosphorIconsRegular.usersThree, PhosphorIconsFill.usersThree, 'Connect'),
  ];

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: jp.surface.withValues(alpha: 0.86),
            border: Border(top: BorderSide(color: jp.border)),
          ),
          padding: EdgeInsets.only(
            left: 4,
            right: 4,
            top: 7,
            bottom: 7 + MediaQuery.of(context).padding.bottom,
          ),
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final active = i == activeIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          PhosphorIcon(
                            active ? tab.activeIcon : tab.icon,
                            size: 24,
                            color: active ? jp.accent : jp.fgMuted,
                          ),
                          if (tab.badge)
                            Positioned(
                              right: -6,
                              top: -2,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: jp.accent,
                                  border: Border.all(
                                      color: jp.surface, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tab.label,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: active ? jp.accent : jp.fgMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TabDef {
  final PhosphorIconData icon;
  final PhosphorIconData activeIcon;
  final String label;
  final bool badge;

  const _TabDef(this.icon, this.activeIcon, this.label, {this.badge = false});
}
