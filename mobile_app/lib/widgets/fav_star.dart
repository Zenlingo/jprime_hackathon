import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_theme.dart';

class FavStar extends StatefulWidget {
  final bool on;
  final VoidCallback? onToggle;
  final double size;

  const FavStar({super.key, required this.on, this.onToggle, this.size = 22});

  @override
  State<FavStar> createState() => _FavStarState();
}

class _FavStarState extends State<FavStar> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _tap() {
    _ctrl.forward(from: 0);
    widget.onToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    return GestureDetector(
      onTap: _tap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: JPSpacing.hit,
        height: JPSpacing.hit,
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              final scale = 1.0 + 0.3 * Curves.elasticOut.transform(_ctrl.value);
              return Transform.scale(scale: scale, child: child);
            },
            child: PhosphorIcon(
              widget.on ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
              size: widget.size,
              color: widget.on ? jp.accent : jp.fgMuted,
            ),
          ),
        ),
      ),
    );
  }
}
