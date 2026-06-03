import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_theme.dart';
import '../data/sample_data.dart';
import '../widgets/app_header.dart';
import '../widgets/section_label.dart';
import '../widgets/live_dot.dart';
import '../widgets/progress_bar.dart';

class NowNextScreen extends StatelessWidget {
  final int nowMin;
  final VoidCallback? onThemeToggle;
  final void Function(SessionData session)? onOpenSession;

  const NowNextScreen({
    super.key,
    required this.nowMin,
    this.onThemeToggle,
    this.onOpenSession,
  });

  @override
  Widget build(BuildContext context) {
    final rooms = ['Hall A', 'Hall B', 'Workshop'];
    final pinned = ['Hall A'];
    final yours = rooms.where((r) => pinned.contains(r)).toList();
    final others = rooms.where((r) => !pinned.contains(r)).toList();

    return Column(
      children: [
        AppHeader(
          title: 'Now & Next',
          subtitle: 'jPrime \u00B7 Day 1',
          trailing: _ThemeButton(onTap: onThemeToggle),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
            children: [
              SectionLabel(
                icon: PhosphorIconsRegular.pushPin,
                text: 'Your rooms',
              ),
              ...yours.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RoomCard(
                      room: r,
                      nowMin: nowMin,
                      pinned: true,
                      onOpenSession: onOpenSession,
                    ),
                  )),
              const SizedBox(height: 12),
              SectionLabel(
                icon: PhosphorIconsRegular.broadcast,
                text: 'All rooms',
              ),
              ...others.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RoomCard(
                      room: r,
                      nowMin: nowMin,
                      onOpenSession: onOpenSession,
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  final String room;
  final int nowMin;
  final bool pinned;
  final void Function(SessionData session)? onOpenSession;

  const _RoomCard({
    required this.room,
    required this.nowMin,
    this.pinned = false,
    this.onOpenSession,
  });

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    final inRoom =
        JPData.sessions.where((s) => s.room == room && !s.isBreak).toList();
    final now = inRoom.where((s) => s.statusAt(nowMin) == 'live').firstOrNull;
    final next = inRoom
        .where((s) => s.statusAt(nowMin) == 'upcoming')
        .toList()
      ..sort((a, b) => a.startMin.compareTo(b.startMin));
    final nextSession = next.firstOrNull;

    return GestureDetector(
      onTap: now != null ? () => onOpenSession?.call(now) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: jp.surface,
          border: Border.all(
            color: pinned ? jp.accent : jp.border,
            width: pinned ? 1.5 : 1,
          ),
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
            Row(
              children: [
                Text(
                  room,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.18,
                    color: jp.fg,
                  ),
                ),
                if (pinned) ...[
                  const Spacer(),
                  PhosphorIcon(PhosphorIconsFill.pushPin,
                      size: 16, color: jp.accent),
                ],
              ],
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
              const SizedBox(height: 10),
              JPProgressBar(value: now.progressAt(nowMin)),
            ] else ...[
              Row(
                children: [
                  PhosphorIcon(PhosphorIconsRegular.coffee,
                      size: 16, color: jp.fgMuted),
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
                child: Row(
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        nextSession.title,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: jp.fgSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
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
              ),
            ],
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
        child: PhosphorIcon(
          isDark ? PhosphorIconsFill.sun : PhosphorIconsFill.moonStars,
          size: 19,
          color: jp.fg,
        ),
      ),
    );
  }
}
