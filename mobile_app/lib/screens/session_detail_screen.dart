import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_theme.dart';
import '../data/sample_data.dart';
import '../widgets/app_header.dart';
import '../widgets/track_tag.dart';
import '../widgets/level_badge.dart';
import '../widgets/live_dot.dart';
import '../widgets/progress_bar.dart';
import '../widgets/fav_star.dart';
import '../widgets/section_label.dart';
import '../widgets/jp_switch.dart';
import '../widgets/jp_button.dart';
import 'session_qa_section.dart';

class SessionDetailScreen extends StatefulWidget {
  final SessionData session;
  final int nowMin;
  final bool fav;
  final VoidCallback onFav;
  final VoidCallback onClose;
  final void Function(SessionData session) onFindRoom;
  final void Function(SpeakerData speaker)? onOpenSpeaker;
  final String? displayName;
  final bool remind;
  final VoidCallback onRemind;

  const SessionDetailScreen({
    super.key,
    required this.session,
    required this.nowMin,
    required this.fav,
    required this.onFav,
    required this.onClose,
    required this.onFindRoom,
    this.onOpenSpeaker,
    this.displayName,
    this.remind = false,
    required this.onRemind,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  int _tabIndex = 0; // 0 = Info, 1 = Q&A

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    final s = widget.session;
    final status = s.statusAt(widget.nowMin);
    final isLive = status == 'live';
    final sp = s.speakerId != null ? JPData.speakers[s.speakerId] : null;

    // Session IDs from the API are numeric; sample/offline IDs start with 's'
    final isOnline = int.tryParse(s.id) != null;

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
          // Segmented control (only when online)
          if (isOnline)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: jp.surfaceSunken,
                  borderRadius: BorderRadius.circular(JPSpacing.rSm),
                ),
                child: Row(
                  children: [
                    _SegTab(label: 'Info', active: _tabIndex == 0,
                      onTap: () => setState(() => _tabIndex = 0)),
                    _SegTab(label: 'Q&A', active: _tabIndex == 1,
                      onTap: () => setState(() => _tabIndex = 1)),
                  ],
                ),
              ),
            ),
          if (_tabIndex == 1 && isOnline) ...[
            Expanded(
              child: SessionQASection(
                sessionId: s.id,
                displayName: widget.displayName,
              ),
            ),
          ] else ...[
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
                    if (s.level.isNotEmpty)
                      LevelBadge(level: s.level),
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

                // Speaker(s)
                if (sp != null) ...[
                  SectionLabel(
                    icon: PhosphorIconsRegular.user,
                    text: s.coSpeakerName != null ? 'Speakers' : 'Speaker',
                  ),
                  _SpeakerCard(
                    speaker: sp,
                    onTap: widget.onOpenSpeaker != null
                        ? () => widget.onOpenSpeaker!(sp)
                        : null,
                  ),
                  if (s.coSpeakerName != null) ...[
                    const SizedBox(height: 10),
                    Builder(builder: (context) {
                      final coSlug = s.coSpeakerName!
                          .toLowerCase()
                          .replaceAll(RegExp(r'[^a-z0-9]'), '-')
                          .replaceAll(RegExp(r'-+'), '-')
                          .replaceAll(RegExp(r'^-|-$'), '');
                      final coSp = JPData.speakers[coSlug];
                      if (coSp == null) return const SizedBox.shrink();
                      return _SpeakerCard(
                        speaker: coSp,
                        onTap: widget.onOpenSpeaker != null
                            ? () => widget.onOpenSpeaker!(coSp)
                            : null,
                      );
                    }),
                  ],
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
                        widget.remind
                            ? PhosphorIconsFill.bell
                            : PhosphorIconsRegular.bell,
                        size: 20,
                        color: widget.remind ? jp.accent : jp.fgSecondary,
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
                        value: widget.remind,
                        onToggle: widget.onRemind,
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
          ], // end else (Info tab)
        ],
      ),
    );
  }
}

class _SegTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SegTab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? jp.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(JPSpacing.rXs),
            boxShadow: active
                ? [BoxShadow(color: jp.border, blurRadius: 2, offset: const Offset(0, 1))]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: active ? jp.fg : jp.fgMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeakerCard extends StatelessWidget {
  final SpeakerData speaker;
  final VoidCallback? onTap;

  const _SpeakerCard({required this.speaker, this.onTap});

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    final sp = speaker;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: jp.surface,
          border: Border.all(color: jp.border),
          borderRadius: BorderRadius.circular(JPSpacing.rMd),
        ),
        child: Row(
          children: [
            // Photo
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: sp.gradient,
              ),
              clipBehavior: Clip.antiAlias,
              child: sp.imageUrl != null
                  ? Image.network(
                      sp.imageUrl!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(
                        child: Text(
                          sp.initials,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        sp.initials,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            // Name, headline, social icons
            Expanded(
              child: Column(
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
                  if (sp.role.isNotEmpty)
                    Text(
                      sp.role,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        color: jp.fgSecondary,
                      ),
                    ),
                  if (sp.twitter != null || sp.bsky != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (sp.twitter != null) ...[
                          PhosphorIcon(PhosphorIconsRegular.xLogo,
                              size: 14, color: jp.fgMuted),
                          const SizedBox(width: 4),
                          Text(
                            '@${sp.twitter}',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 12,
                              color: jp.fgMuted,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (sp.bsky != null) ...[
                          PhosphorIcon(PhosphorIconsRegular.butterfly,
                              size: 14, color: jp.fgMuted),
                          const SizedBox(width: 4),
                          Text(
                            sp.bsky!,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 12,
                              color: jp.fgMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              PhosphorIcon(PhosphorIconsRegular.caretRight,
                  size: 18, color: jp.fgMuted),
          ],
        ),
      ),
    );
  }
}

