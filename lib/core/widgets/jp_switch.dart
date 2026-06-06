import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class JPSwitch extends StatelessWidget {
  final bool value;
  final VoidCallback? onToggle;

  const JPSwitch({super.key, required this.value, this.onToggle});

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 46,
        height: 28,
        decoration: BoxDecoration(
          color: value ? jp.accent : jp.borderStrong,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
