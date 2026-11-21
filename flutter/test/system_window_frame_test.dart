import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/common.dart';

void main() {
  final framingWindowManager = kFramingWindowManagers.first;
  const gnomeShell = "GNOME Shell";

  test('every framing window manager on Linux draws the window controls', () {
    for (final name in kFramingWindowManagers) {
      expect(
        usesSystemWindowFrame(
          isCompatibleUiMode: false,
          isLinux: true,
          windowManagerName: name,
        ),
        isTrue,
        reason: name,
      );
    }
  });

  test('other or unknown Linux window managers keep our own controls', () {
    for (final name in [gnomeShell, "unknown", ""]) {
      expect(
        usesSystemWindowFrame(
          isCompatibleUiMode: false,
          isLinux: true,
          windowManagerName: name,
        ),
        isFalse,
        reason: name,
      );
    }
  });

  test('the window manager name only counts on Linux', () {
    expect(
      usesSystemWindowFrame(
        isCompatibleUiMode: false,
        isLinux: false,
        windowManagerName: framingWindowManager,
      ),
      isFalse,
    );
  });

  test('compatible ui mode always uses the system frame', () {
    expect(
      usesSystemWindowFrame(
        isCompatibleUiMode: true,
        isLinux: false,
        windowManagerName: "",
      ),
      isTrue,
    );
  });

  testWidgets('virtual window frame is omitted when the system draws the frame',
      (tester) async {
    const inner = SizedBox(key: Key('inner'));
    late Widget result;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          result = buildVirtualWindowFrame(
            context,
            inner,
            useSystemWindowFrame: true,
          );
          return result;
        },
      ),
    );
    expect(identical(result, inner), isTrue);
    expect(find.byType(ClipRRect), findsNothing);
  });
}
