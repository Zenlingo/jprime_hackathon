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
  final Set<String> favs;
  final void Function(String id) onToggleFav;
  final void Function(SessionData session) onOpenSession;

  const ScheduleScreen({
    super.key,
    required this.nowMin,
    required this.favs,
    required this.onToggleFav,
    required this.onOpenSession,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _day = 1;
  String _query = '';
  String _filter = 'all';
  bool _showFilterSheet = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SessionData> get _filteredSessions {
    var list =
        JPData.sessions.where((s) => !s.isBreak).toList();
    if (_filter == 'favs') {
      list = list.where((s) => widget.favs.contains(s.id)).toList();
    } else if (_filter != 'all') {
      list = list.where((s) => s.trackId == _filter).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((s) {
        final speakerName =
            JPData.speakers[s.speakerId]?.name.toLowerCase() ?? '';
        return s.title.toLowerCase().contains(q) || speakerName.contains(q);
      }).toList();
    }
    return list;
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
              trailing: SegmentedControl<int>(
                value: _day,
                onChanged: (v) => setState(() => _day = v),
                options: [(value: 1, label: 'Day 1'), (value: 2, label: 'Day 2')],
              ),
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
                      ('a', 'Track A'),
                      ('b', 'Track B'),
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
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 90),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final entry = grouped.entries.elementAt(index);
                    final time = entry.key;
                    final sessions = entry.value;
                    return Padding(
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
                                child: SessionCard(
                                  session: s,
                                  nowMin: widget.nowMin,
                                  fav: widget.favs.contains(s.id),
                                  onFav: () => widget.onToggleFav(s.id),
                                  onTap: () => widget.onOpenSession(s),
                                ),
                              )),
                        ],
                      ),
                    );
                  },
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
      ('all', 'All tracks'),
      ('a', 'Track A'),
      ('b', 'Track B'),
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
