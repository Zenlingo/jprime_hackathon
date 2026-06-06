import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/sample_data.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/app_header.dart';

class SpeakerDetailScreen extends StatefulWidget {
  final SpeakerData speaker;
  final VoidCallback onClose;

  const SpeakerDetailScreen({
    super.key,
    required this.speaker,
    required this.onClose,
  });

  @override
  State<SpeakerDetailScreen> createState() => _SpeakerDetailScreenState();
}

class _SpeakerDetailScreenState extends State<SpeakerDetailScreen> {
  bool _loadingBio = false;

  @override
  void initState() {
    super.initState();
    _loadBio();
  }

  Future<void> _loadBio() async {
    final sp = widget.speaker;
    if (sp.bio != null || sp.numericId == null) return;
    setState(() => _loadingBio = true);
    final bio = await JPrimeApi.fetchSpeakerBio(sp.numericId!);
    if (mounted) {
      setState(() {
        sp.bio = bio;
        _loadingBio = false;
      });
    }
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    final sp = widget.speaker;

    return Scaffold(
      backgroundColor: jp.bg,
      body: Column(
        children: [
          AppHeader(
            title: 'Speaker',
            onBack: widget.onClose,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
              children: [
                // Photo + name card
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: sp.gradient,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: sp.imageUrl != null
                            ? Image.network(
                                sp.imageUrl!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Center(
                                  child: Text(
                                    sp.initials,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 42,
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
                                    fontSize: 42,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        sp.name,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.48,
                          color: jp.fg,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (sp.role.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          sp.role,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 15,
                            color: jp.fgSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Social links
                if (sp.twitter != null || sp.bsky != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (sp.twitter != null)
                          _SocialButton(
                            icon: FontAwesomeIcons.xTwitter,
                            label: '@${sp.twitter}',
                            onTap: () =>
                                _openUrl('https://x.com/${sp.twitter}'),
                          ),
                        if (sp.twitter != null && sp.bsky != null)
                          const SizedBox(width: 10),
                        if (sp.bsky != null)
                          _SocialButton(
                            icon: FontAwesomeIcons.bluesky,
                            label: sp.bsky!,
                            onTap: () => _openUrl(
                                'https://bsky.app/profile/${sp.bsky}'),
                          ),
                      ],
                    ),
                  ),

                // Bio
                if (_loadingBio)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: jp.accent,
                        ),
                      ),
                    ),
                  )
                else if (sp.bio != null && sp.bio!.isNotEmpty)
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
                            Icon(Icons.person_outline,
                                size: 16, color: jp.fgMuted),
                            const SizedBox(width: 8),
                            Text(
                              'About',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: jp.fgSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          sp.bio!,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 15,
                            height: 1.6,
                            color: jp.fg,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Sessions by this speaker
                const SizedBox(height: 20),
                _SpeakerSessions(speakerName: sp.name),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: jp.surface,
          border: Border.all(color: jp.border),
          borderRadius: BorderRadius.circular(JPSpacing.rPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 16, color: jp.fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: jp.fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeakerSessions extends StatelessWidget {
  final String speakerName;

  const _SpeakerSessions({required this.speakerName});

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    final sessions = JPData.sessions
        .where((s) =>
            !s.isBreak &&
            (s.speakerName == speakerName || s.coSpeakerName == speakerName))
        .toList();

    if (sessions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.mic, size: 16, color: jp.fgMuted),
            const SizedBox(width: 8),
            Text(
              'Sessions',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: jp.fgSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...sessions.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: jp.surface,
                  border: Border.all(color: jp.border),
                  borderRadius: BorderRadius.circular(JPSpacing.rMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: jp.fg,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Day ${s.day} \u00B7 ${s.start}\u2013${s.end} \u00B7 ${s.room}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: jp.fgSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
