import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_theme.dart';
import '../data/sample_data.dart';
import '../widgets/app_header.dart';
import '../widgets/track_tag.dart';
import '../widgets/live_dot.dart';
import '../widgets/progress_bar.dart';
import '../widgets/fav_star.dart';
import '../widgets/avatar.dart';
import '../widgets/section_label.dart';
import '../widgets/jp_switch.dart';
import '../widgets/jp_button.dart';

class SessionDetailScreen extends StatefulWidget {
  final SessionData session;
  final int nowMin;
  final bool fav;
  final VoidCallback onFav;
  final VoidCallback onClose;
  final void Function(SessionData session) onFindRoom;

  const SessionDetailScreen({
    super.key,
    required this.session,
    required this.nowMin,
    required this.fav,
    required this.onFav,
    required this.onClose,
    required this.onFindRoom,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  bool _remind = false;

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    final s = widget.session;
    final status = s.statusAt(widget.nowMin);
    final isLive = status == 'live';
    final sp = s.speakerId != null ? JPData.speakers[s.speakerId] : null;

    return Scaffold(
      backgroundColor: jp.bg,
      body: Column(
        children: [
          AppHeader(
            title: 'Session',
            onBack: widget.onClose,
            trailing: FavStar(
              on: widget.fav,
              onToggle: widget.onFav,
              size: 24,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
              children: [
                // Tags row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TrackTag(trackId: s.trackId),
                    _Pill(label: s.level),
                    if (isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: jp.accentSoft,
                          borderRadius:
                              BorderRadius.circular(JPSpacing.rPill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const LiveDot(size: 7),
                            const SizedBox(width: 6),
                            Text(
                              'LIVE',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: jp.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  s.title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: -0.52,
                    color: jp.fg,
                  ),
                ),
                const SizedBox(height: 14),

                // Time + room
                Row(
                  children: [
                    PhosphorIcon(PhosphorIconsRegular.clock,
                        size: 18, color: jp.fgMuted),
                    const SizedBox(width: 7),
                    Text(
                      '${s.start}\u2013${s.end}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: jp.fg,
                      ),
                    ),
                    const SizedBox(width: 16),
                    PhosphorIcon(PhosphorIconsRegular.mapPin,
                        size: 18, color: jp.fgMuted),
                    const SizedBox(width: 7),
                    Text(
                      s.room,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: jp.fg,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Live progress
                if (isLive) ...[
                  JPProgressBar(value: s.progressAt(widget.nowMin)),
                  const SizedBox(height: 6),
                  Text(
                    '${s.minsLeftAt(widget.nowMin)} min left',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: jp.accent,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Abstract
                Text(
                  s.abstract_,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    height: 1.6,
                    color: jp.fg,
                  ),
                ),
                const SizedBox(height: 22),

                // Speaker
                if (sp != null) ...[
                  SectionLabel(
                    icon: PhosphorIconsRegular.user,
                    text: 'Speaker',
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: jp.surface,
                      border: Border.all(color: jp.border),
                      borderRadius: BorderRadius.circular(JPSpacing.rMd),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SpeakerAvatar(
                                speakerId: s.speakerId!, size: 48),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sp.name,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: jp.fg,
                                  ),
                                ),
                                Text(
                                  sp.role,
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 13,
                                    color: jp.fgSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            PhosphorIconsRegular.githubLogo,
                            PhosphorIconsRegular.linkedinLogo,
                            PhosphorIconsRegular.xLogo,
                          ]
                              .map((icon) => Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: jp.surface2,
                                        border: Border.all(color: jp.border),
                                        borderRadius: BorderRadius.circular(
                                            JPSpacing.rSm),
                                      ),
                                      alignment: Alignment.center,
                                      child: PhosphorIcon(icon,
                                          size: 18, color: jp.fgSecondary),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Reminder toggle
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: jp.surface,
                    border: Border.all(color: jp.border),
                    borderRadius: BorderRadius.circular(JPSpacing.rMd),
                  ),
                  child: Row(
                    children: [
                      PhosphorIcon(
                        _remind
                            ? PhosphorIconsFill.bell
                            : PhosphorIconsRegular.bell,
                        size: 20,
                        color: _remind ? jp.accent : jp.fgSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Remind me 10 min before',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: jp.fg,
                          ),
                        ),
                      ),
                      JPSwitch(
                        value: _remind,
                        onToggle: () =>
                            setState(() => _remind = !_remind),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom CTA
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  18,
                  14,
                  18,
                  18 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: jp.bg.withValues(alpha: 0.88),
                  border:
                      Border(top: BorderSide(color: jp.border)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: JPButton(
                    label: 'Find room \u00B7 ${s.room}',
                    icon: PhosphorIcon(PhosphorIconsFill.navigationArrow,
                        size: 18, color: jp.onAccent),
                    onTap: () => widget.onFindRoom(s),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;

  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: jp.surface2,
        border: Border.all(color: jp.border),
        borderRadius: BorderRadius.circular(JPSpacing.rPill),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: jp.fgSecondary,
        ),
      ),
    );
  }
}
