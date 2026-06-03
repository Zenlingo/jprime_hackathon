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
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: sp.imageUrl != null
          ? Image.network(
              sp.imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _Initials(sp: sp, size: size),
            )
          : _Initials(sp: sp, size: size),
    );
  }
}

class _Initials extends StatelessWidget {
  final SpeakerData sp;
  final double size;

  const _Initials({required this.sp, required this.size});

  @override
  Widget build(BuildContext context) {
    return Text(
      sp.initials,
      style: GoogleFonts.spaceGrotesk(
        fontSize: size * 0.36,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: -0.02 * size * 0.36,
      ),
    );
  }
}
