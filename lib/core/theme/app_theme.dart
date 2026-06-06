import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens mapped from colors_and_type.css
/// Light + dark themes for the jPrime Companion app.

class JPColors {
  // Raw palette
  static const ink = Color(0xFF0E1726);
  static const coral = Color(0xFFFF5A3C);
  static const coralDeep = Color(0xFFE8431F);
  static const coralBright = Color(0xFFFF6F54);
  static const blue = Color(0xFF2D6CDF);
  static const blueBright = Color(0xFF5B8DEF);
  static const slate = Color(0xFF5A6472);
  static const mist = Color(0xFFF2F4F8);

  // Track palette
  static const trackALight = Color(0xFF0E9C8C);
  static const trackADark = Color(0xFF2DD4BF);
  static const trackBLight = Color(0xFF6D4AED);
  static const trackBDark = Color(0xFFA78BFA);
  static const trackWorkshopLight = Color(0xFFC0712A);
  static const trackWorkshopDark = Color(0xFFE0A04B);
}

class JPSpacing {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 24;
  static const double s6 = 32;
  static const double s7 = 48;
  static const double s8 = 64;

  static const double rXs = 6;
  static const double rSm = 10;
  static const double rMd = 16;
  static const double rLg = 22;
  static const double rPill = 999;

  static const double hit = 44;
}

/// Extended color roles accessible via Theme extensions
class JPThemeColors extends ThemeExtension<JPThemeColors> {
  final Color bg;
  final Color bgSubtle;
  final Color surface;
  final Color surface2;
  final Color surfaceSunken;
  final Color scrim;
  final Color fg;
  final Color fgSecondary;
  final Color fgMuted;
  final Color fgOnAccent;
  final Color border;
  final Color borderStrong;
  final Color accent;
  final Color accentHover;
  final Color accentPressed;
  final Color accentSoft;
  final Color onAccent;
  final Color link;
  final Color selected;
  final Color selectedSoft;
  final Color live;
  final Color liveSoft;
  final Color liveTrack;
  final Color finishedFg;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color trackA;
  final Color trackB;
  final Color trackWorkshop;
  final Color trackASoft;
  final Color trackBSoft;
  final Color trackWorkshopSoft;

  const JPThemeColors({
    required this.bg,
    required this.bgSubtle,
    required this.surface,
    required this.surface2,
    required this.surfaceSunken,
    required this.scrim,
    required this.fg,
    required this.fgSecondary,
    required this.fgMuted,
    required this.fgOnAccent,
    required this.border,
    required this.borderStrong,
    required this.accent,
    required this.accentHover,
    required this.accentPressed,
    required this.accentSoft,
    required this.onAccent,
    required this.link,
    required this.selected,
    required this.selectedSoft,
    required this.live,
    required this.liveSoft,
    required this.liveTrack,
    required this.finishedFg,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.trackA,
    required this.trackB,
    required this.trackWorkshop,
    required this.trackASoft,
    required this.trackBSoft,
    required this.trackWorkshopSoft,
  });

  static const light = JPThemeColors(
    bg: Color(0xFFFFFFFF),
    bgSubtle: Color(0xFFF2F4F8),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF7F9FC),
    surfaceSunken: Color(0xFFEDF0F6),
    scrim: Color(0x730E1726),
    fg: Color(0xFF0E1726),
    fgSecondary: Color(0xFF5A6472),
    fgMuted: Color(0xFF8A93A3),
    fgOnAccent: Color(0xFFFFFFFF),
    border: Color(0xFFE3E7EF),
    borderStrong: Color(0xFFCDD4E0),
    accent: Color(0xFFFF5A3C),
    accentHover: Color(0xFFE54420),
    accentPressed: Color(0xFFB22F13),
    accentSoft: Color(0xFFFFEDE8),
    onAccent: Color(0xFFFFFFFF),
    link: Color(0xFF2D6CDF),
    selected: Color(0xFF2D6CDF),
    selectedSoft: Color(0xFFE7EFFC),
    live: Color(0xFFFF5A3C),
    liveSoft: Color(0xFFFFEDE8),
    liveTrack: Color(0xFFFFD9CF),
    finishedFg: Color(0xFFA6AEBC),
    success: Color(0xFF1E9E6A),
    successSoft: Color(0xFFE4F5ED),
    warning: Color(0xFFC0712A),
    warningSoft: Color(0xFFFBF0E2),
    danger: Color(0xFFDC3B3B),
    dangerSoft: Color(0xFFFCE8E8),
    trackA: JPColors.trackALight,
    trackB: JPColors.trackBLight,
    trackWorkshop: JPColors.trackWorkshopLight,
    trackASoft: Color(0xFFE0F4F1),
    trackBSoft: Color(0xFFEEE9FE),
    trackWorkshopSoft: Color(0xFFF7ECDF),
  );

  static const dark = JPThemeColors(
    bg: Color(0xFF0A111E),
    bgSubtle: Color(0xFF0E1726),
    surface: Color(0xFF141E30),
    surface2: Color(0xFF1C2840),
    surfaceSunken: Color(0xFF0A111E),
    scrim: Color(0x9903070E),
    fg: Color(0xFFEDF1F8),
    fgSecondary: Color(0xFF9FAABC),
    fgMuted: Color(0xFF6B7689),
    fgOnAccent: Color(0xFFFFFFFF),
    border: Color(0xFF243049),
    borderStrong: Color(0xFF33415C),
    accent: Color(0xFFFF6F54),
    accentHover: Color(0xFFFF8A72),
    accentPressed: Color(0xFFE4502F),
    accentSoft: Color(0xFF2A1A1C),
    onAccent: Color(0xFF1A0E0B),
    link: Color(0xFF5B8DEF),
    selected: Color(0xFF5B8DEF),
    selectedSoft: Color(0xFF16243F),
    live: Color(0xFFFF6F54),
    liveSoft: Color(0xFF2A1A1C),
    liveTrack: Color(0xFF4A2A23),
    finishedFg: Color(0xFF586071),
    success: Color(0xFF34C285),
    successSoft: Color(0xFF10241C),
    warning: Color(0xFFE0A04B),
    warningSoft: Color(0xFF2A2113),
    danger: Color(0xFFFF5F5F),
    dangerSoft: Color(0xFF2C1515),
    trackA: JPColors.trackADark,
    trackB: JPColors.trackBDark,
    trackWorkshop: JPColors.trackWorkshopDark,
    trackASoft: Color(0xFF0E2A28),
    trackBSoft: Color(0xFF1E1740),
    trackWorkshopSoft: Color(0xFF2A2113),
  );

  @override
  JPThemeColors copyWith({Color? bg, Color? fg}) => this;

  @override
  JPThemeColors lerp(JPThemeColors? other, double t) {
    if (other == null) return this;
    return JPThemeColors(
      bg: Color.lerp(bg, other.bg, t)!,
      bgSubtle: Color.lerp(bgSubtle, other.bgSubtle, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      fg: Color.lerp(fg, other.fg, t)!,
      fgSecondary: Color.lerp(fgSecondary, other.fgSecondary, t)!,
      fgMuted: Color.lerp(fgMuted, other.fgMuted, t)!,
      fgOnAccent: Color.lerp(fgOnAccent, other.fgOnAccent, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      accentPressed: Color.lerp(accentPressed, other.accentPressed, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      link: Color.lerp(link, other.link, t)!,
      selected: Color.lerp(selected, other.selected, t)!,
      selectedSoft: Color.lerp(selectedSoft, other.selectedSoft, t)!,
      live: Color.lerp(live, other.live, t)!,
      liveSoft: Color.lerp(liveSoft, other.liveSoft, t)!,
      liveTrack: Color.lerp(liveTrack, other.liveTrack, t)!,
      finishedFg: Color.lerp(finishedFg, other.finishedFg, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      trackA: Color.lerp(trackA, other.trackA, t)!,
      trackB: Color.lerp(trackB, other.trackB, t)!,
      trackWorkshop: Color.lerp(trackWorkshop, other.trackWorkshop, t)!,
      trackASoft: Color.lerp(trackASoft, other.trackASoft, t)!,
      trackBSoft: Color.lerp(trackBSoft, other.trackBSoft, t)!,
      trackWorkshopSoft: Color.lerp(trackWorkshopSoft, other.trackWorkshopSoft, t)!,
    );
  }
}

class AppTheme {
  static TextStyle _display(double size, double height, FontWeight weight) =>
      GoogleFonts.spaceGrotesk(fontSize: size, height: height / size, fontWeight: weight, letterSpacing: -0.02 * size);

  static TextStyle _body(double size, double height, FontWeight weight) =>
      GoogleFonts.hankenGrotesk(fontSize: size, height: height / size, fontWeight: weight);

  static TextStyle _mono(double size, double height, FontWeight weight) =>
      GoogleFonts.jetBrainsMono(fontSize: size, height: height / size, fontWeight: weight, letterSpacing: -0.01 * size);

  static TextTheme get _textTheme => TextTheme(
        displayLarge: _display(34, 38, FontWeight.w700),
        displayMedium: _display(26, 30, FontWeight.w700),
        headlineLarge: _display(24, 28, FontWeight.w700),
        headlineMedium: _display(20, 26, FontWeight.w600),
        titleLarge: _display(17, 22, FontWeight.w600),
        titleMedium: _body(15, 24, FontWeight.w400),
        titleSmall: _body(13, 18, FontWeight.w500),
        bodyLarge: _body(15, 24, FontWeight.w400),
        bodyMedium: _body(13, 18, FontWeight.w500),
        bodySmall: _body(12, 16, FontWeight.w400),
        labelLarge: _mono(13, 18, FontWeight.w500),
        labelMedium: _mono(11, 14, FontWeight.w600),
        labelSmall: _mono(10, 14, FontWeight.w700),
      );

  static ThemeData light() {
    const c = JPThemeColors.light;
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: c.bg,
      colorScheme: ColorScheme.light(
        primary: c.accent,
        secondary: c.link,
        surface: c.surface,
        error: c.danger,
      ),
      textTheme: _textTheme.apply(bodyColor: c.fg, displayColor: c.fg),
      extensions: const [c],
    );
  }

  static ThemeData dark() {
    const c = JPThemeColors.dark;
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: c.bg,
      colorScheme: ColorScheme.dark(
        primary: c.accent,
        secondary: c.link,
        surface: c.surface,
        error: c.danger,
      ),
      textTheme: _textTheme.apply(bodyColor: c.fg, displayColor: c.fg),
      extensions: const [c],
    );
  }
}

/// Convenience accessor
extension JPThemeX on BuildContext {
  JPThemeColors get jp => Theme.of(this).extension<JPThemeColors>()!;
}
