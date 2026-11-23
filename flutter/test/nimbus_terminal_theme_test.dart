import 'package:flutter/material.dart';
import 'package:flutter_hbb/common/theme/nimbus.dart';
import 'package:flutter_hbb/desktop/widgets/nimbus/nimbus_terminal.dart';
import 'package:flutter_hbb/models/terminal_mouse_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xterm/xterm.dart';

void main() {
  test('the terminal theme is built from the Nimbus terminal tokens', () {
    expect(NimbusColors.terminalText, const Color(0xFFD8F5E0));
    expect(NimbusColors.terminalGreen, const Color(0xFF7EE0A4));
    expect(NimbusColors.terminalDim, const Color(0xFF9B93C9));
    expect(nimbusTerminalTheme.background, NimbusColors.surfaceTerminal);
    expect(nimbusTerminalTheme.foreground, NimbusColors.terminalText);
    expect(nimbusTerminalTheme.green, NimbusColors.terminalGreen);
    expect(nimbusTerminalTheme.brightBlack, NimbusColors.terminalDim);
    expect(nimbusTerminalTheme.red, NimbusColors.danger);
    expect(nimbusTerminalTheme.cursor, NimbusColors.accent);
    expect(nimbusTerminalStyle.fontSize, 12.5);
    expect(nimbusTerminalStyle.height, 1.6);
  });

  testWidgets('TerminalMouseInteraction passes the theme and style through',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 400,
        height: 120,
        child: TerminalMouseInteraction(
          Terminal(),
          controller: TerminalController(),
          textStyle: nimbusTerminalStyle,
          theme: nimbusTerminalTheme,
        ),
      ),
    ));
    final view = tester.widget<TerminalView>(find.byType(TerminalView));
    expect(view.theme, same(nimbusTerminalTheme));
    expect(view.textStyle, same(nimbusTerminalStyle));
  });

  testWidgets('TerminalMouseInteraction keeps the xterm default theme',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 400,
        height: 120,
        child: TerminalMouseInteraction(Terminal(),
            controller: TerminalController()),
      ),
    ));
    final view = tester.widget<TerminalView>(find.byType(TerminalView));
    expect(view.theme, same(TerminalThemes.defaultTheme));
  });
}
