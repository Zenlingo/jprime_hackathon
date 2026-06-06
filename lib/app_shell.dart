import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'models/sample_data.dart';
import 'core/services/api_service.dart';
import 'features/now_next/now_next_screen.dart';
import 'features/schedule/schedule_screen.dart';
import 'features/agenda/my_agenda_screen.dart';
import 'features/map/map_screen.dart';
import 'features/connect/connect_screen.dart';
import 'features/session/session_detail_screen.dart';
import 'features/speaker/speaker_detail_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'core/services/notification_service.dart';

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
  Set<String> _favs = {};
  Set<String> _reminders = {};
  bool _showOnboarding = false;
  bool _prefsLoaded = false;
  // ignore: prefer_final_fields
  bool _offline = false;
  String? _linkedInUrl;
  String? _displayName;

  Timer? _clockTimer;

  // DEBUG: set to e.g. 10*60+30 to simulate 10:30, or null for real time
  static const int? _debugNowMin = null;
  // DEBUG: set to e.g. 1 or 2 to simulate a conference day, or null for real date
  static const int? _debugDay = null;

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
      setState(() {});
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
    final savedFavs = prefs.getStringList('favs');
    final savedReminders = prefs.getStringList('reminders');
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    if (mounted) {
      setState(() {
        _linkedInUrl = url;
        _displayName = name;
        if (savedFavs != null) _favs = savedFavs.toSet();
        if (savedReminders != null) _reminders = savedReminders.toSet();
        _showOnboarding = !onboardingDone;
        _prefsLoaded = true;
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
    _saveFavs();
  }

  Future<void> _saveFavs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favs', _favs.toList());
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('reminders', _reminders.toList());
  }

  bool _reminderBusy = false;

  void _toggleReminder(SessionData s) {
    if (_reminderBusy) return;
    _reminderBusy = true;
    Future.microtask(() => _reminderBusy = false);

    final isOn = _reminders.contains(s.id);
    if (isOn) {
      NotificationService.cancelReminder(s.id);
      setState(() => _reminders = {..._reminders}..remove(s.id));
    } else {
      // Compute session start DateTime
      if (s.day >= 1 && s.day <= JPData.conferenceDates.length) {
        final date = JPData.conferenceDates[s.day - 1];
        final startTime = date.add(Duration(minutes: s.startMin));
        NotificationService.scheduleReminder(
          sessionId: s.id,
          title: s.title,
          room: s.room,
          scheduledTime: startTime,
        );
      }
      setState(() => _reminders = {..._reminders, s.id});
    }
    _saveReminders();
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
                        Icon(Icons.cloud_off, size: 16, color: jp.warning),
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
                      currentDay: _currentDay > 0 ? _currentDay : 1,
                      favs: _favs,
                      isActive: _tabIndex == 1,
                      onToggleFav: (id) => _toggleFav(id),
                      onOpenSession: _openSession,
                    ),
                    MyAgendaScreen(
                      nowMin: _nowMin,
                      currentDay: _currentDay > 0 ? _currentDay : 1,
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
              displayName: _displayName,
              remind: _reminders.contains(_detailSession!.id),
              onRemind: () => _toggleReminder(_detailSession!),
            ),

          // Speaker detail overlay
          if (_detailSpeaker != null)
            SpeakerDetailScreen(
              speaker: _detailSpeaker!,
              onClose: () => setState(() => _detailSpeaker = null),
            ),

          // Onboarding overlay
          if (_prefsLoaded && _showOnboarding)
            OnboardingScreen(
              onDone: (linkedInUrl) async {
                setState(() => _showOnboarding = false);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('onboarding_done', true);
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
    _TabDef(Icons.podcasts_outlined, Icons.podcasts, 'Now & Next'),
    _TabDef(Icons.calendar_today_outlined, Icons.calendar_month, 'Schedule'),
    _TabDef(Icons.auto_awesome_outlined, Icons.auto_awesome, 'My Agenda', badge: true),
    _TabDef(Icons.map_outlined, Icons.map, 'Map'),
    _TabDef(Icons.group_outlined, Icons.group, 'Connect'),
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
                          Icon(
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
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool badge;

  const _TabDef(this.icon, this.activeIcon, this.label, {this.badge = false});
}
