import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_label.dart';
import '../../core/widgets/jp_chip.dart';
import '../../core/widgets/jp_button.dart';
import '../connect/linkedin_webview_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final void Function(String? linkedInUrl) onDone;

  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  String? _role;
  final _linkedInController = TextEditingController();
  static const _totalSteps = 3;

  final _roles = [
    'Backend',
    'Frontend',
    'Full-stack',
    'Mobile',
    'DevOps / SRE',
    'Architect',
    'Student',
  ];

  @override
  void dispose() {
    _linkedInController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      final url = _linkedInController.text.trim();
      widget.onDone(url.isNotEmpty ? url : null);
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
            // Progress bar + skip
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: List.generate(
                        _totalSteps,
                        (i) => Expanded(
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.only(
                                right: i < _totalSteps - 1 ? 5 : 0),
                            decoration: BoxDecoration(
                              color: i <= _step ? jp.accent : jp.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => widget.onDone(null),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: jp.fgMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStep(),
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: JPButton(
                  label: _step == _totalSteps - 1 ? 'Enter jPrime' : 'Continue',
                  icon: Icon(Icons.arrow_forward, size: 18, color: jp.onAccent),
                  onTap: _next,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    final jp = context.jp;
    switch (_step) {
      case 0:
        return _WelcomeStep(key: const ValueKey(0));
      case 1:
        return Padding(
          key: const ValueKey(1),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(text: 'Step 2 of 3'),
              const SizedBox(height: 6),
              Text(
                'What\'s your role?',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.56,
                  color: jp.fg,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _roles
                    .map((r) => JPChip(
                          label: r,
                          selected: _role == r,
                          onTap: () => setState(() => _role = r),
                        ))
                    .toList(),
              ),
            ],
          ),
        );
      case 2:
        final hasLinkedIn = _linkedInController.text.trim().isNotEmpty;
        return Padding(
          key: const ValueKey(2),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(text: 'Step 3 of 3'),
              const SizedBox(height: 6),
              Text(
                'Add your LinkedIn',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.56,
                  color: jp.fg,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Share your profile via QR code at the conference. This is optional.',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  color: jp.fgSecondary,
                ),
              ),
              const SizedBox(height: 24),
              // Sign in with LinkedIn button
              GestureDetector(
                onTap: () async {
                  final url = await LinkedInFlowScreen.show(context);
                  if (url != null && mounted) {
                    setState(() => _linkedInController.text = url);
                  }
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
                      FaIcon(FontAwesomeIcons.linkedin,
                          size: 20, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        hasLinkedIn ? 'Linked' : 'Sign in with LinkedIn',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (hasLinkedIn) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.check_circle,
                            size: 18, color: Colors.white),
                      ],
                    ],
                  ),
                ),
              ),
              if (hasLinkedIn) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: jp.accentSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 18, color: jp.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _linkedInController.text.trim(),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: jp.accent,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // Divider with "or"
              Row(
                children: [
                  Expanded(child: Divider(color: jp.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'or enter manually',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        color: jp.fgMuted,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: jp.border)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _linkedInController,
                onChanged: (_) => setState(() {}),
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
                    child: FaIcon(FontAwesomeIcons.linkedin,
                        size: 20, color: jp.fgMuted),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  filled: true,
                  fillColor: jp.surface,
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
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset('assets/jprime-logo.png', width: 64, height: 64),
          const SizedBox(height: 20),
          Text(
            'Welcome to jPrime.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              height: 1.08,
              letterSpacing: -0.68,
              color: jp.fg,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Two days, three tracks, one busy hallway. Let\'s build a schedule that keeps up with you.',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              height: 1.55,
              color: jp.fgSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
