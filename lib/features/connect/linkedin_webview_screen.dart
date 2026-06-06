import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

/// Opens LinkedIn app/browser to get the user's profile URL.
/// Auto-checks clipboard when returning from LinkedIn.
class LinkedInFlowScreen extends StatefulWidget {
  /// When true, skips the initial clipboard check (used for reconnect).
  final bool skipInitialCheck;

  const LinkedInFlowScreen({super.key, this.skipInitialCheck = false});

  static Future<String?> show(BuildContext context,
      {bool skipInitialCheck = false}) {
    return Navigator.of(context).push<String?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            LinkedInFlowScreen(skipInitialCheck: skipInitialCheck),
      ),
    );
  }

  @override
  State<LinkedInFlowScreen> createState() => _LinkedInFlowScreenState();
}

class _LinkedInFlowScreenState extends State<LinkedInFlowScreen>
    with WidgetsBindingObserver {
  String _status = 'checking'; // checking | ready | opened
  bool _popped = false;

  static final _linkedInPattern = RegExp(
    r'https?://(www\.)?linkedin\.com/in/([a-zA-Z0-9\-_%]+)',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.skipInitialCheck) {
      _status = 'ready';
    } else {
      _checkClipboard();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _status == 'opened') {
      _checkClipboard();
    }
  }

  Future<void> _openLinkedIn() async {
    setState(() => _status = 'opened');
    final appUrl = Uri.parse('linkedin://in/me');
    if (await canLaunchUrl(appUrl)) {
      await launchUrl(appUrl, mode: LaunchMode.externalApplication);
    } else {
      final webUrl = Uri.parse('https://www.linkedin.com/in/me');
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _checkClipboard() async {
    if (_popped) return;
    setState(() => _status = 'checking');
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      final url = _extractLinkedInUrl(text);
      if (url != null && mounted && !_popped) {
        _popped = true;
        Navigator.of(context).pop(url);
        return;
      }
    } catch (_) {}
    if (mounted && !_popped) setState(() => _status = 'ready');
  }

  String? _extractLinkedInUrl(String text) {
    final match = _linkedInPattern.firstMatch(text);
    if (match != null) {
      final username = match.group(2);
      if (username != null && username != 'me') {
        return 'https://www.linkedin.com/in/$username';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;

    if (_status == 'checking') {
      return Scaffold(
        backgroundColor: jp.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: jp.accent),
              const SizedBox(height: 16),
              Text(
                'Checking for LinkedIn URL\u2026',
                style: GoogleFonts.hankenGrotesk(
                    fontSize: 14, color: jp.fgSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: jp.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: jp.surface,
                border: Border(bottom: BorderSide(color: jp.border)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(null),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: jp.surface2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.close, size: 18, color: jp.fg),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Link your LinkedIn',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: jp.fg,
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0A66C2)
                            .withValues(alpha: 0.12),
                      ),
                      alignment: Alignment.center,
                      child: FaIcon(FontAwesomeIcons.linkedin,
                          size: 36, color: const Color(0xFF0A66C2)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Link your LinkedIn',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: jp.fg,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Open LinkedIn and copy your profile link.\nWe\'ll pick it up automatically.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        height: 1.5,
                        color: jp.fgSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Open LinkedIn button
                    GestureDetector(
                      onTap: _openLinkedIn,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A66C2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(FontAwesomeIcons.linkedin,
                                size: 20, color: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              'Open LinkedIn',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
