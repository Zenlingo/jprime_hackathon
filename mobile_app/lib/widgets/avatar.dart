import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/sample_data.dart';

class SpeakerAvatar extends StatelessWidget {
  final String speakerId;
  final double size;

  const SpeakerAvatar({super.key, required this.speakerId, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final sp = JPData.speakers[speakerId];
    if (sp == null) return SizedBox(width: size, height: size);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: sp.gradient),
      alignment: Alignment.center,
      child: Text(
        sp.initials,
        style: GoogleFonts.spaceGrotesk(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.02 * size * 0.36,
        ),
      ),
    );
  }
}
