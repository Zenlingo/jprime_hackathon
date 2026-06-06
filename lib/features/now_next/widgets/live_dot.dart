import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class LiveDot extends StatefulWidget {
  final double size;

  const LiveDot({super.key, this.size = 8});

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.jp.accent;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final opacity = 0.4 + 0.6 * _ctrl.value;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: opacity),
          ),
        );
      },
    );
  }
}
