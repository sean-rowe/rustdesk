import 'package:flutter/material.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/widgets/nimbus/camera_overlays.dart';
import 'package:flutter_hbb/generated_bridge.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _Binding extends Fake implements RustdeskImpl {
  @override
  String translate(
          {required String name, required String locale, dynamic hint}) =>
      name;
}

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  setUpAll(() => platformFFI.setBindingForTesting(_Binding()));

  test('the Live label names the camera by its number', () {
    expect(cameraLiveLabel(0), 'Live · Camera 1');
    expect(cameraLiveLabel(2), 'Live · Camera 3');
    expect(cameraLiveLabel(kAllDisplayValue), 'Live');
  });

  test('the clock reads HH:MM:SS', () {
    expect(formatCameraClock(DateTime(2026, 11, 23, 9, 5, 7)), '09:05:07');
    expect(formatCameraClock(DateTime(2026, 11, 23, 23, 59, 59)), '23:59:59');
  });

  testWidgets('the Live pill shows the label', (tester) async {
    await tester.pumpWidget(_host(const CameraLivePill(display: 0)));
    expect(find.text('Live · Camera 1'), findsOneWidget);
  });

  testWidgets('the clock ticks every second and stops when disposed',
      (tester) async {
    var time = DateTime(2026, 11, 23, 9, 0, 0);
    await tester.pumpWidget(_host(CameraClock(now: () => time)));
    expect(find.text('09:00:00'), findsOneWidget);

    time = time.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('09:00:01'), findsOneWidget);

    final text = tester.widget<Text>(find.text('09:00:01'));
    expect(text.style!.fontFamily, 'monospace');

    await tester.pumpWidget(const SizedBox.shrink());
    // A live Timer.periodic would fail the test here as a pending timer.
  });
}
