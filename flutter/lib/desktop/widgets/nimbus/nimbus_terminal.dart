import 'package:flutter/widgets.dart';
import 'package:flutter_hbb/common/theme/nimbus.dart';
import 'package:xterm/xterm.dart';

/// Terminal text: monospace at 12.5 px with a 1.6 line height.
const TerminalStyle nimbusTerminalStyle =
    TerminalStyle(fontSize: NimbusType.footnote, height: 1.6);

/// The terminal palette, built from the Nimbus terminal tokens. Errors use
/// [NimbusColors.danger], dim output [NimbusColors.terminalDim] and blue the
/// accent. ANSI colors with no Nimbus token keep the xterm defaults. What
/// the prompt looks like still depends on the remote shell's PS1.
const TerminalTheme nimbusTerminalTheme = TerminalTheme(
  cursor: NimbusColors.accent,
  selection: NimbusColors.accentFill,
  foreground: NimbusColors.terminalText,
  background: NimbusColors.surfaceTerminal,
  black: Color(0XFF000000),
  red: NimbusColors.danger,
  green: NimbusColors.terminalGreen,
  yellow: NimbusColors.warning,
  blue: NimbusColors.accent,
  magenta: NimbusColors.brandMagenta,
  cyan: Color(0XFF11A8CD),
  white: NimbusColors.terminalText,
  brightBlack: NimbusColors.terminalDim,
  brightRed: NimbusColors.danger,
  brightGreen: NimbusColors.terminalGreen,
  brightYellow: NimbusColors.warningBright,
  brightBlue: NimbusColors.accent,
  brightMagenta: NimbusColors.brandMagenta,
  brightCyan: Color(0XFF29B8DB),
  brightWhite: NimbusColors.textPrimary,
  searchHitBackground: Color(0XFFFFFF2B),
  searchHitBackgroundCurrent: Color(0XFF31FF26),
  searchHitForeground: Color(0XFF000000),
);
