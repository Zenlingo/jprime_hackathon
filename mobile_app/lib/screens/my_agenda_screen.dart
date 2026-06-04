import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_theme.dart';
import '../data/sample_data.dart';
import '../widgets/app_header.dart';
import '../widgets/section_label.dart';
import '../widgets/session_card.dart';
import '../widgets/empty_state.dart';

class MyAgendaScreen extends StatefulWidget {
  final int nowMin;
  final int currentDay;
  final Set<String> favs;
  final void Function(String id, {bool forceOn}) onToggleFav;
  final void Function(SessionData session) onOpenSession;
  final VoidCallback? onThemeToggle;

  const MyAgendaScreen({
    super.key,
    required this.nowMin,
    this.currentDay = 1,
    required this.favs,
    required this.onToggleFav,
    required this.onOpenSession,
    this.onThemeToggle,
  });

  @override
  State<MyAgendaScreen> createState() => _MyAgendaScreenState();
}

class _MyAgendaScreenState extends State<MyAgendaScreen> {
  List<Widget> _buildTimeline(
      Map<int, List<SessionData>> byDay, List<SessionData> all, JPThemeColors jp) {
    final days = byDay.keys.toList()..sort();
    final showDayHeaders = days.length > 1;
    final widgets = <Widget>[];

    for (final day in days) {
      if (showDayHeaders) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 10),
            child: Row(
              children: [
                PhosphorIcon(PhosphorIconsRegular.calendar,
                    size: 16, color: jp.fgMuted),
                const SizedBox(width: 8),
                Text(
                  'Day $day',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: jp.fgSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      for (final s in byDay[day]!) {
        final hasConflict = all
            .where((o) => o.id != s.id && o.day == s.day && o.start == s.start)
            .isNotEmpty;
        if (hasConflict) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  PhosphorIcon(PhosphorIconsFill.warning,
                      size: 15, color: jp.warning),
                  const SizedBox(width: 7),
                  Text(
                    'Overlaps another talk at ${s.start}',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: jp.warning,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SessionCard(
              session: s,
              nowMin: _effectiveNowMin(s),
              fav: true,
              onFav: () => widget.onToggleFav(s.id),
              onTap: () => widget.onOpenSession(s),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  int _effectiveNowMin(SessionData s) {
    if (s.day < widget.currentDay) return 9999;
    if (s.day > widget.currentDay) return 0;
    return widget.nowMin;
  }

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;

    final mine = JPData.sessions
        .where((s) => widget.favs.contains(s.id) && !s.isBreak)
        .toList()
      ..sort((a, b) {
        final dc = a.day.compareTo(b.day);
        if (dc != 0) return dc;
        return a.startMin.compareTo(b.startMin);
      });

    // Group by day
    final mineByDay = <int, List<SessionData>>{};
    for (final s in mine) {
      (mineByDay[s.day] ??= []).add(s);
    }

    return Column(
      children: [
        AppHeader(
          title: 'My Agenda',
          trailing: _ThemeButton(onTap: widget.onThemeToggle),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
            children: [
              // Timeline
              SectionLabel(
                icon: PhosphorIconsRegular.calendarCheck,
                text: 'Your timeline',
              ),
              if (mine.isEmpty)
                EmptyState(
                  icon: PhosphorIconsRegular.star,
                  title: 'No favorites yet',
                  body:
                      'Tap the star on any talk to start building your agenda.',
                )
              else
                ..._buildTimeline(mineByDay, mine, jp),
            ],
          ),
        ),
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
        child: PhosphorIcon(
          isDark ? PhosphorIconsFill.sun : PhosphorIconsFill.moonStars,
          size: 19,
          color: jp.fg,
        ),
      ),
    );
  }
}
