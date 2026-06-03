import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'data/sample_data.dart';
import 'data/api_service.dart';
import 'screens/now_next_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/my_agenda_screen.dart';
import 'screens/map_screen.dart';
import 'screens/connect_screen.dart';
import 'screens/session_detail_screen.dart';
import 'screens/speaker_detail_screen.dart';
import 'screens/onboarding_screen.dart';

class AppShell extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const AppShell({super.key, required this.onThemeToggle});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tabIndex = 0;
  SessionData? _detailSession;
  SpeakerData? _detailSpeaker;
  String? _mapHighlight;
  Set<String> _favs = {'s2', 's5'};
  bool _showOnboarding = true;
  // ignore: prefer_final_fields
  bool _offline = false;
  String? _linkedInUrl;
  String? _displayName;

  Timer? _clockTimer;

  // DEBUG: set to e.g. 10*60+30 to simulate 10:30, or null for real time
  static const int? _debugNowMin = 900; // 15:00
  // DEBUG: set to e.g. 1 or 2 to simulate a conference day, or null for real date
  static const int? _debugDay = 1;

  int get _nowMin => _debugNowMin ?? (DateTime.now().hour * 60 + DateTime.now().minute);

  int get _currentDay => _debugDay ?? JPData.dayForDate(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadSchedule();
    // Refresh every 30s to keep live session status current
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    // Load speakers directory first so session loading can use it
    await JPrimeApi.loadSpeakers();
    final ok = await JPrimeApi.loadSchedule();
    if (mounted && ok) {
      setState(() {
        _favs = {};
      });
      // Load levels in background, refresh UI when done
      JPrimeApi.loadLevels().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('linkedin_url');
    final name = prefs.getString('display_name');
    if (mounted) {
      setState(() {
        _linkedInUrl = url;
        _displayName = name;
      });
    }
  }

  Future<void> _saveLinkedInUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url != null && url.isNotEmpty) {
      await prefs.setString('linkedin_url', url);
      // Auto-extract name from URL if no name is set yet
      if (_displayName == null || _displayName!.isEmpty) {
        final extracted = _nameFromLinkedInUrl(url);
        if (extracted != null) {
          await prefs.setString('display_name', extracted);
          if (mounted) setState(() => _displayName = extracted);
        }
      }
    } else {
      await prefs.remove('linkedin_url');
    }
    if (mounted) {
      setState(() => _linkedInUrl = url?.isNotEmpty == true ? url : null);
    }
  }

  Future<void> _saveDisplayName(String? name) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null && name.isNotEmpty) {
      await prefs.setString('display_name', name);
    } else {
      await prefs.remove('display_name');
    }
    if (mounted) {
      setState(() => _displayName = name?.isNotEmpty == true ? name : null);
    }
  }

  static String? _nameFromLinkedInUrl(String url) {
    final match = RegExp(r'linkedin\.com/in/([a-zA-Z0-9\-_%]+)').firstMatch(url);
    if (match == null) return null;
    final slug = match.group(1)!.replaceAll(RegExp(r'/$'), '');
    // Skip slugs that are just IDs or numbers
    if (RegExp(r'^\d+$').hasMatch(slug)) return null;
    // Remove trailing numbers (e.g. "john-doe-123ab")
    final cleaned = slug.replaceAll(RegExp(r'[\-_]\w{0,8}\d+$'), '');
    final parts = cleaned.split(RegExp(r'[\-_]+'));
    if (parts.isEmpty || (parts.length == 1 && parts[0].length < 2)) return null;
    return parts
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
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
  void _openSpeaker(SpeakerData s) => setState(() => _detailSpeaker = s);

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
                      currentDay: _currentDay,
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
                      displayName: _displayName,
                      onDisplayNameChanged: _saveDisplayName,
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
              onOpenSpeaker: _openSpeaker,
            ),

          // Speaker detail overlay
          if (_detailSpeaker != null)
            SpeakerDetailScreen(
              speaker: _detailSpeaker!,
              onClose: () => setState(() => _detailSpeaker = null),
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
