import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart' show readableFileSize;
import 'package:flutter_hbb/common/theme/nimbus.dart';
import 'package:flutter_hbb/desktop/pages/file_manager_page.dart';
import 'package:flutter_hbb/generated_bridge.dart';
import 'package:flutter_hbb/models/file_model.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _Binding extends Fake implements RustdeskImpl {
  @override
  String translate(
          {required String name, required String locale, dynamic hint}) =>
      name;
}

Entry _entry(String name, {int size = 0, bool file = true}) => Entry()
  ..name = name
  ..path = '/$name'
  ..entryType = file ? 4 : 0
  ..size = size;

JobProgress _job(JobState state, {int finished = 0, int total = 0}) =>
    JobProgress()
      ..type = JobType.transfer
      ..jobName = '/home/sean/mix-v3-final.wav'
      ..state = state
      ..finishedSize = finished
      ..totalSize = total;

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: SizedBox(width: 700, child: child)));

void main() {
  setUpAll(() => platformFFI.setBindingForTesting(_Binding()));

  test('the footer counts items, or the selection and its file sizes', () {
    expect(fileListFooterText(6, []), '6 items');
    final selected = [
      _entry('a.wav', size: 1024),
      _entry('b.wav', size: 1024),
      _entry('Music', file: false),
    ];
    expect(fileListFooterText(6, selected),
        '3 Selected · ${readableFileSize(2048)}');
  });

  testWidgets('a running transfer shows an accent bar and its percentage',
      (tester) async {
    await tester.pumpWidget(_host(TransferJobRow(
        job: _job(JobState.inProgress, finished: 25, total: 100),
        divider: false,
        onResume: () {},
        onCancel: () {})));
    final bar = tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(bar.value, 0.25);
    expect(bar.color, NimbusColors.accent);
    expect(find.text('25%'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
  });

  testWidgets('a finished transfer turns its bar green', (tester) async {
    await tester.pumpWidget(_host(TransferJobRow(
        job: _job(JobState.done, finished: 100, total: 100),
        divider: true,
        onResume: () {},
        onCancel: () {})));
    final bar = tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(bar.value, 1);
    expect(bar.color, NimbusColors.success);
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('a paused transfer offers Resume, and Delete cancels',
      (tester) async {
    var resumed = 0;
    var cancelled = 0;
    await tester.pumpWidget(_host(TransferJobRow(
        job: _job(JobState.paused, finished: 10, total: 100),
        divider: false,
        onResume: () => resumed++,
        onCancel: () => cancelled++)));
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.tap(find.byIcon(Icons.close));
    expect(resumed, 1);
    expect(cancelled, 1);
  });
}
