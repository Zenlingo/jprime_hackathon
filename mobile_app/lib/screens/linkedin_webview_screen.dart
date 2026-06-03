import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';

/// Opens LinkedIn in a WebView, navigating to /in/me which redirects to the
/// user's actual profile after login. Returns the captured profile URL.
class LinkedInWebViewScreen extends StatefulWidget {
  const LinkedInWebViewScreen({super.key});

  static Future<String?> show(BuildContext context) {
    return Navigator.of(context).push<String?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const LinkedInWebViewScreen(),
      ),
    );
  }

  @override
  State<LinkedInWebViewScreen> createState() => _LinkedInWebViewScreenState();
}

class _LinkedInWebViewScreenState extends State<LinkedInWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  static final _profilePattern = RegExp(r'^/in/([^/?]+)');

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _loading = true);
        },
        onPageFinished: (url) {
          if (mounted) setState(() => _loading = false);
          _tryCapture(url);
        },
        onUrlChange: (change) {
          if (change.url != null) _tryCapture(change.url!);
        },
      ))
      ..loadRequest(Uri.parse('https://www.linkedin.com/in/me'));
  }

  void _tryCapture(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (uri.host != 'www.linkedin.com' && uri.host != 'linkedin.com') return;

    final match = _profilePattern.firstMatch(uri.path);
    if (match != null && match.group(1) != 'me') {
      // Strip query params — keep clean profile URL
      final profileUrl = 'https://www.linkedin.com/in/${match.group(1)}';
      Navigator.of(context).pop(profileUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    return Scaffold(
      backgroundColor: jp.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      child: PhosphorIcon(PhosphorIconsRegular.x,
                          size: 18, color: jp.fg),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sign in with LinkedIn',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: jp.fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Loading bar
            if (_loading)
              LinearProgressIndicator(
                color: jp.accent,
                backgroundColor: jp.border,
                minHeight: 2,
              ),
            // WebView
            Expanded(child: WebViewWidget(controller: _controller)),
          ],
        ),
      ),
    );
  }
}
