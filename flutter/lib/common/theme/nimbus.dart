import 'package:flutter/material.dart';

/// Nimbus design tokens, taken from the "Nimbus for OS-XFCE" design system
/// (`tokens.json`). Names mirror the `--nim-*` tokens so values can be traced
/// back to the system.
///
/// Nimbus surfaces are translucent glass over a blurred wallpaper. A Flutter
/// window cannot blur the desktop behind it, so every glass surface also has
/// an opaque value: the token composited over [NimbusColors.desktopBase].
/// Use the opaque value for window and dialog backgrounds, and the
/// translucent value for fills that sit on top of another Nimbus surface.
abstract final class NimbusColors {
  // Brand
  static const Color brandIndigo = Color(0xFF7C6CF0);
  static const Color brandMagenta = Color(0xFFEC72C4);

  // Accent: the only action and selection color.
  static const Color accent = Color(0xFF7C6CF0);
  static const Color accentStrong = Color(0xFF5B46D6);
  static const Color accentFill = Color(0xD97C6CF0);
  static const Color accentSoft = Color(0x297C6CF0);

  // Ground behind every surface.
  static const Color desktopBase = Color(0xFF0C1018);

  // Glass surfaces (translucent).
  static const Color surfaceWindow = Color(0xC71A1632);
  static const Color surfaceWindowSolid = Color(0xDB18142C);
  static const Color surfaceMenu = Color(0xD1221C40);
  static const Color surfacePanel = Color(0x8028224A);
  static const Color surfaceOverlay = Color(0x9E282634);
  static const Color surfaceTerminal = Color(0xDB0C0A1A);
  static const Color surfaceSidebar = Color(0x2E000000);
  static const Color surfaceRaise = Color(0x0DFFFFFF);

  // Glass surfaces composited over [desktopBase] (opaque).
  static const Color windowOpaque = Color(0xFF17152C);
  static const Color windowSolidOpaque = Color(0xFF161329);
  static const Color menuOpaque = Color(0xFF1E1A39);
  static const Color sidebarOpaque = Color(0xFF131124);
  static const Color raiseOpaque = Color(0xFF232137);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textOnGlass = Color(0xFFECE9FF);
  static const Color textSecondary = Color(0xFFCFC8EE);
  static const Color textTertiary = Color(0xFF9B93C9);
  static const Color textOnLight = Color(0xFF16141F);
  static const Color textOnLightSoft = Color(0xFF4A4759);

  // Lines and washes
  static const Color borderWindow = Color(0x1FFFFFFF);
  static const Color divider = Color(0x12FFFFFF);
  static const Color dividerStrong = Color(0x1AFFFFFF);
  static const Color hoverRow = Color(0x0FFFFFFF);
  static const Color hoverControl = Color(0x29FFFFFF);

  // Window controls
  static const Color trafficClose = Color(0xFFEC6A8C);
  static const Color trafficMinimize = Color(0xFFE0A23A);
  static const Color trafficMaximize = Color(0xFF5EC98A);

  // Semantic
  static const Color success = Color(0xFF5EC98A);
  static const Color successBright = Color(0xFF3BE36B);
  static const Color warning = Color(0xFFE0A23A);
  static const Color warningBright = Color(0xFFFF9F0A);
  static const Color danger = Color(0xFFEF5D6C);
  static const Color dangerDeep = Color(0xFFC43F4F);
}

/// The Nimbus corner ladder. Do not add steps.
abstract final class NimbusRadii {
  static const double xs = 6;
  static const double sm = 7;
  static const double md = 9;
  static const double lg = 12;
  static const double window = 14;
  static const double xl = 16;
  static const double pill = 20;
  static const double overlay = 22;
  static const double dock = 26;

  static BorderRadius all(double radius) =>
      BorderRadius.all(Radius.circular(radius));
}

/// The Nimbus spacing scale and fixed chrome sizes.
abstract final class NimbusSpace {
  static const double s1 = 2;
  static const double s2 = 4;
  static const double s3 = 6;
  static const double s4 = 8;
  static const double s5 = 10;
  static const double s6 = 12;
  static const double s7 = 14;
  static const double s8 = 16;
  static const double s9 = 18;
  static const double s10 = 20;
  static const double s12 = 24;
  static const double s16 = 32;

  static const double trafficSize = 12;
  static const double trafficGap = 8;
}

/// The dense, AppKit-sized Nimbus type ramp.
abstract final class NimbusType {
  static const double micro = 10.5;
  static const double caption2 = 11;
  static const double caption = 11.5;
  static const double footnote = 12.5;
  static const double body = 13;
  static const double callout = 13.5;
  static const double headline = 14.5;
  static const double title3 = 16;
  static const double title2 = 19;
  static const double title1 = 21;
  static const double display = 28;

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight heavy = FontWeight.w800;

  static const double leadingBody = 1.5;
}

/// Nimbus motion: one standard curve, one spring reserved for the dock.
abstract final class NimbusMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 180);
  static const Duration slow = Duration(milliseconds: 250);

  static const Curve standard = Cubic(0.4, 0.0, 0.2, 1);
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1);
}

/// The Nimbus shadow ladder: soft, large, low-opacity.
abstract final class NimbusShadows {
  static const List<BoxShadow> icon = [
    BoxShadow(offset: Offset(0, 6), blurRadius: 16, color: Color(0x4D000000)),
  ];
  static const List<BoxShadow> tile = [
    BoxShadow(offset: Offset(0, 8), blurRadius: 20, color: Color(0x59000000)),
  ];
  static const List<BoxShadow> menu = [
    BoxShadow(offset: Offset(0, 18), blurRadius: 50, color: Color(0x80000000)),
  ];
  static const List<BoxShadow> window = [
    BoxShadow(offset: Offset(0, 30), blurRadius: 80, color: Color(0x8C000000)),
  ];
}
