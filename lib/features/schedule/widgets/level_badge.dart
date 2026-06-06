import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class LevelBadge extends StatelessWidget {
  final String level;
  final bool small;

  const LevelBadge({super.key, required this.level, this.small = false});

  @override
  Widget build(BuildContext context) {
    if (level.isEmpty) return const SizedBox.shrink();

    final jp = context.jp;
    final (color, softColor) = _levelColors(jp, level);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 9,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(JPSpacing.rXs),
      ),
      child: Text(
        level,
        style: GoogleFonts.hankenGrotesk(
          fontSize: small ? 11 : 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  static (Color, Color) _levelColors(JPThemeColors jp, String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return (jp.success, jp.successSoft);
      case 'intermediate':
        return (jp.warning, jp.warningSoft);
      case 'advanced':
        return (jp.danger, jp.dangerSoft);
      default:
        return (jp.fgMuted, jp.surface2);
    }
  }
}
