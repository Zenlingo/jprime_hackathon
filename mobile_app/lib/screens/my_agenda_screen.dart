import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_theme.dart';
import '../data/sample_data.dart';
import '../widgets/app_header.dart';
import '../widgets/section_label.dart';
import '../widgets/session_card.dart';
import '../widgets/jp_chip.dart';
import '../widgets/jp_button.dart';
import '../widgets/empty_state.dart';

class MyAgendaScreen extends StatefulWidget {
  final int nowMin;
  final Set<String> favs;
  final void Function(String id, {bool forceOn}) onToggleFav;
  final void Function(SessionData session) onOpenSession;
  final VoidCallback? onThemeToggle;

  const MyAgendaScreen({
    super.key,
    required this.nowMin,
    required this.favs,
    required this.onToggleFav,
    required this.onOpenSession,
    this.onThemeToggle,
  });

  @override
  State<MyAgendaScreen> createState() => _MyAgendaScreenState();
}

class _MyAgendaScreenState extends State<MyAgendaScreen> {
  int _gen = 0;
  final Set<String> _accepted = {};

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;

    final suggestions = JPData.suggestions
        .where((s) =>
            !_accepted.contains(s.sessionId) &&
            JPData.sessionById(s.sessionId) != null)
        .map((s) => (suggestion: s, session: JPData.sessionById(s.sessionId)!))
        .toList();

    final mine = JPData.sessions
        .where((s) => widget.favs.contains(s.id) && !s.isBreak)
        .toList()
      ..sort((a, b) => a.startMin.compareTo(b.startMin));

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
              // Suggestions header
              Row(
                children: [
                  Expanded(
                    child: SectionLabel(
                      icon: PhosphorIconsRegular.sparkle,
                      text: 'Suggested for you',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: JPChip(
                      label: 'Regenerate',
                      leading: PhosphorIcon(
                        PhosphorIconsRegular.arrowsClockwise,
                        size: 14,
                        color: jp.fg,
                      ),
                      onTap: () => setState(() {
                        _gen++;
                        _accepted.clear();
                      }),
                    ),
                  ),
                ],
              ),

              // Suggestion cards with staggered animation
              ...suggestions.asMap().entries.map((e) {
                final idx = e.key;
                final item = e.value;
                return _SuggestionCard(
                  key: ValueKey('${_gen}_${item.suggestion.sessionId}'),
                  session: item.session,
                  why: item.suggestion.why,
                  index: idx,
                  onAccept: () {
                    widget.onToggleFav(item.suggestion.sessionId,
                        forceOn: true);
                    setState(
                        () => _accepted.add(item.suggestion.sessionId));
                  },
                  onOpen: () => widget.onOpenSession(item.session),
                );
              }),

              if (suggestions.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'All caught up \u2014 tap Regenerate for more.',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      color: jp.fgSecondary,
                    ),
                  ),
                ),

              const SizedBox(height: 10),

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
                ...mine.asMap().entries.map((e) {
                  final s = e.value;
                  final hasConflict = mine
                      .where((o) => o.id != s.id && o.start == s.start)
                      .isNotEmpty;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasConflict)
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
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SessionCard(
                          session: s,
                          nowMin: widget.nowMin,
                          fav: true,
                          onFav: () => widget.onToggleFav(s.id),
                          onTap: () => widget.onOpenSession(s),
                        ),
                      ),
                    ],
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

class _SuggestionCard extends StatefulWidget {
  final SessionData session;
  final String why;
  final int index;
  final VoidCallback onAccept;
  final VoidCallback onOpen;

  const _SuggestionCard({
    super.key,
    required this.session,
    required this.why,
    required this.index,
    required this.onAccept,
    required this.onOpen,
  });

  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeSlide = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(Duration(milliseconds: widget.index * 90), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    final s = widget.session;

    return FadeTransition(
      opacity: _fadeSlide,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(_fadeSlide),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: jp.surface,
              border: Border.all(color: jp.border),
              borderRadius: BorderRadius.circular(JPSpacing.rMd),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: jp.selectedSoft,
                        borderRadius:
                            BorderRadius.circular(JPSpacing.rPill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PhosphorIcon(PhosphorIconsFill.sparkle,
                              size: 12, color: jp.link),
                          const SizedBox(width: 5),
                          Text(
                            'SUGGESTED',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: jp.link,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${s.start} \u00B7 ${s.room}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: jp.fgSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: widget.onOpen,
                  child: Text(
                    s.title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.17,
                      color: jp.fg,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    PhosphorIcon(PhosphorIconsFill.linkSimple,
                        size: 15, color: jp.link),
                    const SizedBox(width: 6),
                    Text(
                      widget.why,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        color: jp.fgSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: JPButton(
                        label: 'Add to agenda',
                        icon: PhosphorIcon(PhosphorIconsRegular.check,
                            size: 16, color: jp.onAccent),
                        onTap: widget.onAccept,
                      ),
                    ),
                    const SizedBox(width: 10),
                    JPButton(
                      label: 'Swap',
                      ghost: true,
                      icon: PhosphorIcon(
                        PhosphorIconsRegular.arrowsLeftRight,
                        size: 16,
                        color: jp.fg,
                      ),
                      onTap: widget.onOpen,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
