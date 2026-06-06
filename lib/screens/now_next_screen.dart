import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../data/sample_data.dart';
import '../widgets/app_header.dart';
import '../widgets/section_label.dart';
import '../widgets/live_dot.dart';
import '../widgets/progress_bar.dart';

class NowNextScreen extends StatelessWidget {
  final int nowMin;
  final int currentDay;
  final VoidCallback? onThemeToggle;
  final void Function(SessionData session)? onOpenSession;

  const NowNextScreen({
    super.key,
    required this.nowMin,
    this.currentDay = 0,
    this.onThemeToggle,
    this.onOpenSession,
  });

  @override
  Widget build(BuildContext context) {
    // Filter sessions for the current conference day
    final todaySessions = currentDay > 0
        ? JPData.sessions.where((s) => s.day == currentDay && !s.isBreak).toList()
        : JPData.sessions.where((s) => !s.isBreak).toList();

    final rooms = todaySessions
        .map((s) => s.room)
        .toSet()
        .toList()
      ..sort();

    final subtitle = currentDay > 0
        ? 'jPrime \u00B7 Day $currentDay'
        : 'jPrime ${JPData.totalDays > 0 ? '\u00B7 ${JPData.totalDays} days' : ''}';

    // Determine overall state
    final hasLive = todaySessions.any((s) => s.statusAt(nowMin) == 'live');
    final hasUpcoming = todaySessions.any((s) => s.statusAt(nowMin) == 'upcoming');
    final allDone = todaySessions.isNotEmpty && !hasLive && !hasUpcoming;
    final isLastDay = currentDay >= JPData.totalDays;

    Widget body;
    if (rooms.isEmpty) {
      body = _EmptyState();
    } else if (allDone && isLastDay) {
      body = _ConferenceEndedState();
    } else if (allDone && !isLastDay) {
      body = _DayDoneState(currentDay: currentDay);
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
        children: [
          SectionLabel(
            icon: Icons.podcasts,
            text: 'All rooms',
          ),
          ...rooms.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RoomCard(
                  room: r,
                  nowMin: nowMin,
                  currentDay: currentDay,
                  onOpenSession: onOpenSession,
                ),
              )),
        ],
      );
    }

    return Column(
      children: [
        AppHeader(
          title: 'Now & Next',
          subtitle: subtitle,
          trailing: _ThemeButton(onTap: onThemeToggle),
        ),
        Expanded(child: body),
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  final String room;
  final int nowMin;
  final int currentDay;
  final void Function(SessionData session)? onOpenSession;

  const _RoomCard({
    required this.room,
    required this.nowMin,
    this.currentDay = 0,
    this.onOpenSession,
  });

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    final inRoom = JPData.sessions
        .where((s) =>
            s.room == room &&
            !s.isBreak &&
            (currentDay == 0 || s.day == currentDay))
        .toList();
    final now = inRoom.where((s) => s.statusAt(nowMin) == 'live').firstOrNull;
    final next = inRoom
        .where((s) => s.statusAt(nowMin) == 'upcoming')
        .toList()
      ..sort((a, b) => a.startMin.compareTo(b.startMin));
    final nextSession = next.firstOrNull;

    return GestureDetector(
      onTap: now != null
          ? () => onOpenSession?.call(now)
          : nextSession != null
              ? () => onOpenSession?.call(nextSession)
              : null,
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
            // Room name header
            Text(
              room,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.18,
                color: jp.fg,
              ),
            ),
            const SizedBox(height: 12),

            // Now section
            if (now != null) ...[
              Row(
                children: [
                  const LiveDot(),
                  const SizedBox(width: 6),
                  Text(
                    'NOW',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: jp.accent,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${now.minsLeftAt(nowMin)} min left',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: jp.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                now.title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.15,
                  color: jp.fg,
                ),
              ),
              if (now.speakerName != null) ...[
                const SizedBox(height: 4),
                Text(
                  now.speakerName!,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    color: jp.fgSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              JPProgressBar(value: now.progressAt(nowMin)),
            ] else ...[
              Row(
                children: [
                  Icon(Icons.local_cafe, size: 16, color: jp.fgMuted),
                  const SizedBox(width: 6),
                  Text(
                    'Between sessions',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: jp.fgMuted,
                    ),
                  ),
                ],
              ),
            ],

            // Next section
            if (nextSession != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: jp.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'NEXT',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: jp.fgMuted,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          nextSession.start,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: jp.fgSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      nextSession.title,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: jp.fgSecondary,
                      ),
                    ),
                    if (nextSession.speakerName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        nextSession.speakerName!,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          color: jp.fgMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayDoneState extends StatelessWidget {
  final int currentDay;

  const _DayDoneState({required this.currentDay});

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dark_mode, size: 48, color: jp.accent),
            const SizedBox(height: 16),
            Text(
              'That\u2019s a wrap for Day $currentDay!',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: jp.fg,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sessions continue tomorrow.\nGet some rest and see you in the morning!',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 15,
                height: 1.5,
                color: jp.fgSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConferenceEndedState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.celebration, size: 48, color: jp.accent),
            const SizedBox(height: 16),
            Text(
              'jPrime is over!',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: jp.fg,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Thanks for joining. Hope you had a great time!\nSee you next year.',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 15,
                height: 1.5,
                color: jp.fgSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 48, color: jp.fgMuted),
            const SizedBox(height: 16),
            Text(
              'No sessions today',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: jp.fgSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check the Schedule tab for the full programme.',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                color: jp.fgMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
        child: Icon(
          isDark ? Icons.light_mode : Icons.dark_mode,
          size: 19,
          color: jp.fg,
        ),
      ),
    );
  }
}
