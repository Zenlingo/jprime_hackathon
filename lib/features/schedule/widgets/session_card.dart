import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/sample_data.dart';
import '../../../core/widgets/avatar.dart';
import 'track_tag.dart';
import 'level_badge.dart';
import '../../now_next/widgets/live_dot.dart';
import 'progress_bar.dart';
import '../../../core/widgets/fav_star.dart';

class SessionCard extends StatelessWidget {
  final SessionData session;
  final int nowMin;
  final bool fav;
  final VoidCallback? onFav;
  final VoidCallback? onTap;

  const SessionCard({
    super.key,
    required this.session,
    required this.nowMin,
    this.fav = false,
    this.onFav,
    this.onTap,
  });

  String _speakerNames() {
    final primary = session.speakerName ??
        JPData.speakers[session.speakerId]?.name ??
        '';
    if (session.coSpeakerName != null) {
      return '$primary & ${session.coSpeakerName}';
    }
    return primary;
  }

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    final status = session.statusAt(nowMin);
    final isLive = status == 'live';
    final isFinished = status == 'finished';
    final tColor = trackColor(context, session.trackId);

    final leftColor = isLive
        ? jp.accent
        : isFinished
            ? jp.finishedFg
            : tColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: isFinished ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 220),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(JPSpacing.rMd),
          child: Container(
            decoration: BoxDecoration(
              color: isLive ? null : jp.surface,
              gradient: isLive
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [jp.accentSoft, jp.surface],
                      stops: const [0.0, 0.72],
                    )
                  : null,
              borderRadius: BorderRadius.circular(JPSpacing.rMd),
              border: Border.all(color: jp.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _LeftBorderPainter(color: leftColor, width: 3),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: time/live badge + fav star
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: isLive
                        ? Row(
                            children: [
                              const LiveDot(),
                              const SizedBox(width: 6),
                              Text(
                                'LIVE NOW',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: jp.accent,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            '${session.start}\u2013${session.end} \u00B7 ${session.room}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isFinished ? jp.finishedFg : jp.fgSecondary,
                            ),
                          ),
                  ),
                  FavStar(on: fav, onToggle: onFav),
                ],
              ),
              // Title
              Padding(
                padding: const EdgeInsets.only(right: 40, top: 6, bottom: 10),
                child: Text(
                  session.title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    letterSpacing: -0.16,
                    color: isFinished ? jp.finishedFg : jp.fg,
                  ),
                ),
              ),
              // Speaker + track
              Row(
                children: [
                  if (session.speakerId != null) ...[
                    SpeakerAvatar(speakerId: session.speakerId!, size: 24),
                    if (session.coSpeakerName != null) ...[
                      const SizedBox(width: 4),
                      Builder(builder: (context) {
                        final coSlug = session.coSpeakerName!
                            .toLowerCase()
                            .replaceAll(RegExp(r'[^a-z0-9]'), '-')
                            .replaceAll(RegExp(r'-+'), '-')
                            .replaceAll(RegExp(r'^-|-$'), '');
                        if (JPData.speakers.containsKey(coSlug)) {
                          return SpeakerAvatar(speakerId: coSlug, size: 24);
                        }
                        return const SizedBox.shrink();
                      }),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _speakerNames(),
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: jp.fgSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Spacer(),
                  if (session.level.isNotEmpty) ...[
                    LevelBadge(level: session.level, small: true),
                    const SizedBox(width: 6),
                  ],
                  TrackTag(trackId: session.trackId, small: true),
                ],
              ),
              // Progress bar for live
              if (isLive) ...[
                const SizedBox(height: 12),
                JPProgressBar(value: session.progressAt(nowMin)),
                const SizedBox(height: 6),
                Text(
                  '${session.minsLeftAt(nowMin)} min left',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: jp.accent,
                  ),
                ),
              ],
            ],
          ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeftBorderPainter extends CustomPainter {
  final Color color;
  final double width;

  _LeftBorderPainter({required this.color, required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, size.height), paint);
  }

  @override
  bool shouldRepaint(_LeftBorderPainter oldDelegate) =>
      color != oldDelegate.color || width != oldDelegate.width;
}
