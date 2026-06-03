import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class JPButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? icon;
  final bool ghost;

  const JPButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.ghost = false,
  });

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: JPSpacing.hit,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: ghost ? Colors.transparent : jp.accent,
          border: ghost ? Border.all(color: jp.border) : null,
          borderRadius: BorderRadius.circular(JPSpacing.rSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 8)],
            Text(
              label,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ghost ? jp.fg : jp.onAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
