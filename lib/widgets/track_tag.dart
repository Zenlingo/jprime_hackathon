import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../data/sample_data.dart';

Color trackColor(BuildContext context, String trackId) {
  final jp = context.jp;
  switch (trackId) {
    case 'a':
      return jp.trackA;
    case 'b':
      return jp.trackB;
    case 'workshop':
      return jp.trackWorkshop;
    default:
      return jp.fgMuted;
  }
}

Color trackSoftColor(BuildContext context, String trackId) {
  final jp = context.jp;
  switch (trackId) {
    case 'a':
      return jp.trackASoft;
    case 'b':
      return jp.trackBSoft;
    case 'workshop':
      return jp.trackWorkshopSoft;
    default:
      return jp.surface2;
  }
}

class TrackTag extends StatelessWidget {
  final String trackId;
  final bool small;

  const TrackTag({super.key, required this.trackId, this.small = false});

  @override
  Widget build(BuildContext context) {
    final track = JPData.tracks[trackId];
    final color = trackColor(context, trackId);
    final soft = trackSoftColor(context, trackId);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 9,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(JPSpacing.rXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            track?.label ?? trackId,
            style: GoogleFonts.hankenGrotesk(
              fontSize: small ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
