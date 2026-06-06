import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class JPProgressBar extends StatelessWidget {
  final double value;

  const JPProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final jp = context.jp;
    return Container(
      height: 5,
      decoration: BoxDecoration(
        color: jp.liveTrack,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: jp.accent,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
