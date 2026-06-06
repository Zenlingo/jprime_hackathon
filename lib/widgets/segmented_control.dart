import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SegmentedControl<T> extends StatelessWidget {
  final T value;
  final ValueChanged<T> onChanged;
  final List<({T value, String label})> options;

  const SegmentedControl({
    super.key,
    required this.value,
    required this.onChanged,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: jp.surfaceSunken,
        borderRadius: BorderRadius.circular(JPSpacing.rPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((o) {
          final selected = o.value == value;
          return GestureDetector(
            onTap: () => onChanged(o.value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? jp.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(JPSpacing.rPill),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                o.label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? jp.fg : jp.fgSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
