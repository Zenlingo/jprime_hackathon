import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_theme.dart';

class SectionLabel extends StatelessWidget {
  final PhosphorIconData? icon;
  final String text;

  const SectionLabel({super.key, this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            PhosphorIcon(icon!, size: 15, color: jp.fgMuted),
            const SizedBox(width: 7),
          ],
          Text(
            text.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.88,
              color: jp.fgMuted,
            ),
          ),
        ],
      ),
    );
  }
}
