import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_theme.dart';
import '../data/sample_data.dart';
import '../widgets/app_header.dart';
import '../widgets/session_card.dart';
import '../widgets/segmented_control.dart';
import '../widgets/jp_chip.dart';
import '../widgets/jp_button.dart';
import '../widgets/empty_state.dart';

class ScheduleScreen extends StatefulWidget {
  final int nowMin;
  final int currentDay;
  final Set<String> favs;
  final bool isActive;
  final void Function(String id) onToggleFav;
  final void Function(SessionData session) onOpenSession;

  const ScheduleScreen({
    super.key,
    required this.nowMin,
    this.currentDay = 1,
    required this.favs,
    this.isActive = false,
    required this.onToggleFav,
    required this.onOpenSession,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late int _day = widget.currentDay.clamp(1, JPData.totalDays.clamp(1, 99));

  /// Effective nowMin accounting for day: future day → all upcoming, past day → all finished.
  int get _effectiveNowMin {
    if (_day < widget.currentDay) return 9999; // past day — all finished
    if (_day > widget.currentDay) return 0;    // future day — all upcoming
    return widget.nowMin;                       // current day — real time
  }

  String _query = '';
  String _filter = 'all';
  bool _showFilterSheet = false;
  final _searchController = TextEditingController();
  final _scrollKey = GlobalKey();
  bool _hasScrolled = false;
  int _lastSessionCount = 0;

  @override
  void didUpdateWidget(covariant ScheduleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sessionCount = _filteredSessions.length;
    // Scroll when tab becomes active, or when data first loads while active
    final justActivated = widget.isActive && !oldWidget.isActive;
    final dataJustLoaded =
        widget.isActive && sessionCount > 0 && _lastSessionCount == 0;
    _lastSessionCount = sessionCount;
    if (justActivated || (dataJustLoaded && !_hasScrolled)) {
      _hasScrolled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentSlot();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SessionData> get _filteredSessions {
    var list = JPData.sessions.where((s) => s.day == _day).toList();
    if (_filter == 'favs') {
      list = list
          .where((s) => s.isBreak || widget.favs.contains(s.id))
          .toList();
    } else if (_filter != 'all') {
      list = list
          .where((s) => s.isBreak || s.trackId == _filter)
          .toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((s) {
        if (s.isBreak) return s.title.toLowerCase().contains(q);
        final name = s.speakerName?.toLowerCase() ??
            JPData.speakers[s.speakerId]?.name.toLowerCase() ??
            '';
        return s.title.toLowerCase().contains(q) || name.contains(q);
      }).toList();
    }
    return list;
  }

  void _scrollToCurrentSlot() {
    if (_scrollKey.currentContext != null) {
      Scrollable.ensureVisible(
        _scrollKey.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        alignment: 0.0,
      );
    }
  }

  /// Find the time key of the first slot that is live or upcoming.
  String? get _targetSlotKey {
    final grouped = _groupedBySlot;
    // First: a live talk (not a break)
    for (final entry in grouped.entries) {
      if (entry.value.any((s) => !s.isBreak && s.statusAt(_effectiveNowMin) == 'live')) {
        return entry.key;
      }
    }
    // Then the first upcoming slot (talks or breaks)
    for (final entry in grouped.entries) {
      if (entry.value.any((s) => s.statusAt(_effectiveNowMin) == 'upcoming')) {
        return entry.key;
      }
    }
    // All finished — stay at top
    return null;
  }

  List<Widget> _buildSlotGroups(
      Map<String, List<SessionData>> grouped, JPThemeColors jp) {
    final targetKey = _targetSlotKey;
    final widgets = <Widget>[];

    for (final entry in grouped.entries) {
      final time = entry.key;
      final sessions = entry.value;
      final isTarget = time == targetKey;

      widgets.add(
        Padding(
          key: isTarget ? _scrollKey : null,
          padding: const EdgeInsets.only(bottom: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    time,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: jp.fg,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${sessions.first.end} end',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: jp.fgMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...sessions.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: s.isBreak
                        ? _BreakRow(session: s, nowMin: _effectiveNowMin)
                        : SessionCard(
                            session: s,
                            nowMin: _effectiveNowMin,
                            fav: widget.favs.contains(s.id),
                            onFav: () => widget.onToggleFav(s.id),
                            onTap: () => widget.onOpenSession(s),
                          ),
                  )),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  Map<String, List<SessionData>> get _groupedBySlot {
    final map = <String, List<SessionData>>{};
    for (final s in _filteredSessions) {
      (map[s.start] ??= []).add(s);
    }
    return Map.fromEntries(
      map.entries.toList()
        ..sort((a, b) => SessionData.toMin(a.key).compareTo(SessionData.toMin(b.key))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    final grouped = _groupedBySlot;

    return Stack(
      children: [
        Column(
          children: [
            AppHeader(
              title: 'Schedule',
              trailing: JPData.totalDays > 1
                  ? SegmentedControl<int>(
                      value: _day,
                      onChanged: (v) => setState(() => _day = v),
                      options: [
                        for (var d = 1; d <= JPData.totalDays; d++)
                          (value: d, label: 'Day $d'),
                      ],
                    )
                  : null,
            ),

            // Search + filter chips
            Container(
          color: jp.bg,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
          child: Column(
            children: [
              // Search bar
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: jp.surfaceSunken,
                  border: Border.all(color: jp.border),
                  borderRadius: BorderRadius.circular(JPSpacing.rSm),
                ),
                child: Row(
                  children: [
                    PhosphorIcon(PhosphorIconsRegular.magnifyingGlass,
                        size: 19, color: jp.fgMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v),
                        style: GoogleFonts.hankenGrotesk(
                            fontSize: 15, color: jp.fg),
                        decoration: InputDecoration(
                          hintText: 'Search talks, speakers, rooms',
                          hintStyle: GoogleFonts.hankenGrotesk(
                              fontSize: 15, color: jp.fgMuted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        child: PhosphorIcon(PhosphorIconsFill.xCircle,
                            size: 18, color: jp.fgMuted),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    JPChip(
                      label: 'Filters',
                      leading: PhosphorIcon(PhosphorIconsRegular.funnel,
                          size: 15, color: jp.fg),
                      onTap: () => setState(() => _showFilterSheet = true),
                    ),
                    const SizedBox(width: 8),
                    ...[
                      ('all', 'All'),
                      ('favs', 'Favorites'),
                      ('a', 'Hall A'),
                      ('b', 'Hall B'),
                      ('workshop', 'Workshops'),
                    ].map((e) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: JPChip(
                            label: e.$2,
                            selected: _filter == e.$1,
                            leading: e.$1 == 'favs'
                                ? PhosphorIcon(
                                    _filter == 'favs'
                                        ? PhosphorIconsFill.star
                                        : PhosphorIconsRegular.star,
                                    size: 14,
                                    color: _filter == 'favs'
                                        ? jp.onAccent
                                        : jp.fg,
                                  )
                                : null,
                            onTap: () =>
                                setState(() => _filter = e.$1),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Session list
        Expanded(
          child: grouped.isEmpty
              ? EmptyState(
                  icon: PhosphorIconsRegular.magnifyingGlass,
                  title: 'No talks match',
                  body: 'Try clearing the filter or search.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 90),
                  children: _buildSlotGroups(grouped, jp),
                ),
        ),
          ],
        ),

        // Filter bottom sheet
        if (_showFilterSheet)
          _FilterSheet(
            filter: _filter,
            onFilter: (f) => setState(() => _filter = f),
            onClose: () => setState(() => _showFilterSheet = false),
          ),
      ],
    );
  }
}

class _BreakRow extends StatelessWidget {
  final SessionData session;
  final int nowMin;

  const _BreakRow({required this.session, required this.nowMin});

  IconData get _icon {
    final t = session.title.toLowerCase();
    if (t.contains('lunch')) return PhosphorIconsRegular.forkKnife;
    if (t.contains('coffee')) return PhosphorIconsRegular.coffee;
    if (t.contains('registration')) return PhosphorIconsRegular.clipboardText;
    if (t.contains('raffle')) return PhosphorIconsRegular.gift;
    if (t.contains('opening')) return PhosphorIconsRegular.megaphone;
    return PhosphorIconsRegular.coffee;
  }

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    final isFinished = session.statusAt(nowMin) == 'finished';

    return AnimatedOpacity(
      opacity: isFinished ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 220),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: jp.surface,
          border: Border.all(color: jp.border),
          borderRadius: BorderRadius.circular(JPSpacing.rSm),
        ),
        child: Row(
          children: [
            PhosphorIcon(_icon, size: 18, color: jp.fgMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                session.title,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: jp.fgSecondary,
                ),
              ),
            ),
            Text(
              '${session.start}\u2013${session.end}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: jp.fgMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  final String filter;
  final void Function(String) onFilter;
  final VoidCallback onClose;

  const _FilterSheet({
    required this.filter,
    required this.onFilter,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    final opts = [
      ('all', 'All halls'),
      ('a', 'Hall A'),
      ('b', 'Hall B'),
      ('workshop', 'Workshops'),
      ('favs', 'Favorites only'),
    ];

    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: Material(
          color: jp.scrim,
          child: Align(
            alignment: Alignment.bottomCenter,
          child: Container(
            decoration: BoxDecoration(
              color: jp.surface,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(JPSpacing.rLg)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 32,
                  offset: const Offset(0, -12),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: jp.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Filter',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: jp.fg,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: jp.surface2,
                          border: Border.all(color: jp.border),
                        ),
                        alignment: Alignment.center,
                        child: PhosphorIcon(PhosphorIconsRegular.x,
                            size: 16, color: jp.fg),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...opts.map((o) => GestureDetector(
                      onTap: () => onFilter(o.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: jp.border)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                o.$2,
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: jp.fg,
                                ),
                              ),
                            ),
                            if (filter == o.$1)
                              PhosphorIcon(PhosphorIconsRegular.check,
                                  size: 20, color: jp.accent),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: JPButton(label: 'Show results', onTap: onClose),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
