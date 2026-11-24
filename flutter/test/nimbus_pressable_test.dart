import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common/theme/nimbus.dart';
import 'package:flutter_hbb/desktop/widgets/nimbus/nimbus_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(List<Widget> children) => MaterialApp(
      home: Material(child: Row(children: children)),
    );

Widget _pressable(String label, VoidCallback? onTap) => NimbusPressable(
      onTap: onTap,
      semanticLabel: label,
      builder: (context, hovered, focused) =>
          SizedBox(width: 20, height: 20, child: Text(label)),
    );

bool _hasFocusRing(WidgetTester tester, String label) {
  final container = tester.widget<Container>(find
      .ancestor(of: find.text(label), matching: find.byType(Container))
      .first);
  final decoration = container.foregroundDecoration as BoxDecoration?;
  return decoration?.border == Border.all(color: NimbusColors.accent, width: 2);
}

void main() {
  testWidgets('Enter and Space activate a focused pressable', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host([_pressable('a', () => taps++)]));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(taps, 2);
    expect(_hasFocusRing(tester, 'a'), isTrue);
  });

  testWidgets('a disabled pressable is skipped by keyboard traversal',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host([
      _pressable('disabled', null),
      _pressable('enabled', () => taps++),
    ]));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(taps, 1);
    expect(_hasFocusRing(tester, 'disabled'), isFalse);
    expect(_hasFocusRing(tester, 'enabled'), isTrue);
  });
}
