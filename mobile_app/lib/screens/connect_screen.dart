import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/segmented_control.dart';
import '../widgets/avatar.dart';
import 'linkedin_webview_screen.dart';

class ConnectScreen extends StatefulWidget {
  final VoidCallback? onThemeToggle;
  final String? linkedInUrl;
  final void Function(String) onLinkedInChanged;

  const ConnectScreen({
    super.key,
    this.onThemeToggle,
    this.linkedInUrl,
    required this.onLinkedInChanged,
  });

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  String _tab = 'me';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppHeader(
          title: 'Connect',
          trailing: _ThemeButton(onTap: widget.onThemeToggle),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          child: Row(
            children: [
              SegmentedControl<String>(
                value: _tab,
                onChanged: (v) => setState(() => _tab = v),
                options: [
                  (value: 'me', label: 'My QR'),
                  (value: 'scan', label: 'Scan'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _tab == 'me'
              ? _MyQR(
                  linkedInUrl: widget.linkedInUrl,
                  onLinkedInChanged: widget.onLinkedInChanged,
                )
              : const _ScanView(),
        ),
      ],
    );
  }
}

class _MyQR extends StatefulWidget {
  final String? linkedInUrl;
  final void Function(String) onLinkedInChanged;

  const _MyQR({required this.linkedInUrl, required this.onLinkedInChanged});

  @override
  State<_MyQR> createState() => _MyQRState();
}

class _MyQRState extends State<_MyQR> {
  bool _editing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.linkedInUrl ?? '');
  }

  @override
  void didUpdateWidget(_MyQR oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.linkedInUrl != widget.linkedInUrl && !_editing) {
      _controller.text = widget.linkedInUrl ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final url = _controller.text.trim();
    if (url.isNotEmpty) {
      widget.onLinkedInChanged(url);
      setState(() => _editing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    final hasUrl = widget.linkedInUrl != null && widget.linkedInUrl!.isNotEmpty;

    if (!hasUrl && !_editing) {
      return _AddLinkedInPrompt(
        onAdd: () => setState(() => _editing = true),
        onLinkedInChanged: widget.onLinkedInChanged,
      );
    }

    if (_editing) {
      return _LinkedInEditor(
        controller: _controller,
        onSave: _save,
        onCancel: () => setState(() {
          _editing = false;
          _controller.text = widget.linkedInUrl ?? '';
        }),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: jp.surface,
            border: Border.all(color: jp.border),
            borderRadius: BorderRadius.circular(JPSpacing.rLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              const SpeakerAvatar(speakerId: 'venkat', size: 64),
              const SizedBox(height: 10),
              Text(
                'You \u00B7 Alex Petrov',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: jp.fg,
                ),
              ),
              Text(
                'Backend engineer \u00B7 Sofia',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  color: jp.fgSecondary,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(JPSpacing.rMd),
                  border: Border.all(color: jp.border),
                ),
                child: QrImageView(
                  data: widget.linkedInUrl!,
                  version: QrVersions.auto,
                  size: 168,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0E1726),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0E1726),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Show this to swap contacts',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: jp.fgMuted,
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => setState(() => _editing = true),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(PhosphorIconsRegular.pencilSimple,
                        size: 14, color: jp.accent),
                    const SizedBox(width: 5),
                    Text(
                      'Change LinkedIn URL',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: jp.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddLinkedInPrompt extends StatelessWidget {
  final VoidCallback onAdd;
  final void Function(String) onLinkedInChanged;

  const _AddLinkedInPrompt({
    required this.onAdd,
    required this.onLinkedInChanged,
  });

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: jp.surface,
          border: Border.all(color: jp.border),
          borderRadius: BorderRadius.circular(JPSpacing.rLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0A66C2).withValues(alpha: 0.12),
              ),
              alignment: Alignment.center,
              child: PhosphorIcon(PhosphorIconsFill.linkedinLogo,
                  size: 28, color: const Color(0xFF0A66C2)),
            ),
            const SizedBox(height: 16),
            Text(
              'Share your LinkedIn',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: jp.fg,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sign in to auto-fetch your profile, or enter the URL manually.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                color: jp.fgSecondary,
              ),
            ),
            const SizedBox(height: 22),
            // Sign in with LinkedIn button
            GestureDetector(
              onTap: () async {
                final url = await LinkedInWebViewScreen.show(context);
                if (url != null) onLinkedInChanged(url);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A66C2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PhosphorIcon(PhosphorIconsFill.linkedinLogo,
                        size: 20, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      'Sign in with LinkedIn',
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
            const SizedBox(height: 16),
            // Or enter manually
            GestureDetector(
              onTap: onAdd,
              child: Text(
                'Enter URL manually',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: jp.fgMuted,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedInEditor extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _LinkedInEditor({
    required this.controller,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: jp.surface,
          border: Border.all(color: jp.border),
          borderRadius: BorderRadius.circular(JPSpacing.rLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LinkedIn Profile URL',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: jp.fg,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 15,
                color: jp.fg,
              ),
              decoration: InputDecoration(
                hintText: 'https://linkedin.com/in/yourname',
                hintStyle: GoogleFonts.hankenGrotesk(
                  fontSize: 15,
                  color: jp.fgMuted,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 10),
                  child: PhosphorIcon(PhosphorIconsRegular.linkedinLogo,
                      size: 20, color: jp.fgMuted),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
                filled: true,
                fillColor: jp.bg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: jp.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: jp.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: jp.accent, width: 1.5),
                ),
              ),
              keyboardType: TextInputType.url,
              onSubmitted: (_) => onSave(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onCancel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: jp.border),
                        borderRadius: BorderRadius.circular(JPSpacing.rPill),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: jp.fgSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onSave,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: jp.accent,
                        borderRadius: BorderRadius.circular(JPSpacing.rPill),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Save',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: jp.onAccent,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanView extends StatelessWidget {
  const _ScanView();

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: jp.bgSubtle,
            border: Border.all(color: jp.border),
            borderRadius: BorderRadius.circular(JPSpacing.rLg),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: jp.accent, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              Positioned(
                bottom: 18,
                child: Text(
                  'Point at someone\'s jPrime QR',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    color: jp.fgSecondary,
                  ),
                ),
              ),
            ],
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
