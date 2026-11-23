import 'package:flutter/material.dart';
import 'package:flutter_hbb/desktop/widgets/nimbus/recording_pill.dart';
import 'package:flutter_hbb/generated_bridge.dart';
import 'package:flutter_hbb/models/model.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

class _FakeFFI implements FFI {
  @override
  UuidValue get sessionId => UuidValue('00000000-0000-0000-0000-000000000000');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Binding extends Fake implements RustdeskImpl {
  @override
  String translate(
          {required String name, required String locale, dynamic hint}) =>
      name;
}

void main() {
  setUpAll(() => platformFFI.setBindingForTesting(_Binding()));

  test('elapsed time reads as HH:MM:SS', () {
    expect(formatRecordingElapsed(Duration.zero), '00:00:00');
    expect(formatRecordingElapsed(const Duration(seconds: 75)), '00:01:15');
    expect(formatRecordingElapsed(const Duration(hours: 2, minutes: 3)),
        '02:03:00');
  });

  test('the model keeps the start time only while recording', () {
    var time = DateTime(2026, 11, 23, 9, 0, 0);
    final model = RecordingModel(WeakReference(_FakeFFI()))..now = () => time;
    expect(model.startedAt, isNull);
    expect(model.elapsed, isNull);

    model.updateStatus(true);
    expect(model.startedAt, DateTime(2026, 11, 23, 9, 0, 0));
    time = time.add(const Duration(seconds: 42));
    expect(model.elapsed, const Duration(seconds: 42));

    model.updateStatus(false);
    expect(model.startedAt, isNull);
    expect(model.elapsed, isNull);
  });

  testWidgets('the REC pill counts up every second and goes away on stop',
      (tester) async {
    var time = DateTime(2026, 11, 23, 9, 0, 0);
    final model = RecordingModel(WeakReference(_FakeFFI()))..now = () => time;
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(body: RecordingPill(model: model)),
      ),
    ));
    expect(find.text('REC'), findsNothing);

    model.updateStatus(true);
    await tester.pump();
    expect(find.text('REC'), findsOneWidget);
    expect(find.text('00:00:00'), findsOneWidget);

    for (var second = 1; second <= 3; second++) {
      time = time.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:00:0$second'), findsOneWidget);
    }

    model.updateStatus(false);
    await tester.pump();
    expect(find.text('REC'), findsNothing);
    // No timer is left running after the pill goes away.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('the ticker cancels its timer when disposed', (tester) async {
    final model = RecordingModel(WeakReference(_FakeFFI()));
    model.updateStatus(true);
    await tester.pumpWidget(MaterialApp(
        home: RecordingTicker(
            model: model,
            builder: (context, elapsed) => const SizedBox.shrink())));
    await tester.pumpWidget(const SizedBox.shrink());
    // A live Timer.periodic would fail the test here as a pending timer.
  });
}
