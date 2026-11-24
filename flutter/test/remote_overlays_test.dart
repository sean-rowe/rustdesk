import 'package:flutter/material.dart';
import 'package:flutter_hbb/common/shared_state.dart';
import 'package:flutter_hbb/common/theme/nimbus.dart';
import 'package:flutter_hbb/common/widgets/overlay.dart';
import 'package:flutter_hbb/generated_bridge.dart';
import 'package:flutter_hbb/models/model.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

final _sessionId = UuidValue('00000000-0000-0000-0000-000000000000');

class _FakeFFI implements FFI {
  @override
  UuidValue get sessionId => _sessionId;

  @override
  late final FfiModel ffiModel = FfiModel(WeakReference(this));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Binding extends Fake implements RustdeskImpl {
  @override
  String translate(
          {required String name, required String locale, dynamic hint}) =>
      name;

  @override
  Future<bool?> sessionGetToggleOption(
          {required UuidValue sessionId,
          required String arg,
          dynamic hint}) async =>
      arg == 'show-quality-monitor';
}

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  setUpAll(() => platformFFI.setBindingForTesting(_Binding()));

  testWidgets('the quality monitor is a dark glass card', (tester) async {
    final model = QualityMonitorModel(WeakReference(_FakeFFI()));
    await tester.pumpWidget(_host(QualityMonitor(model)));
    expect(find.text('Speed'), findsNothing);

    await model.checkShowQualityMonitor(_sessionId);
    await tester.pump();

    final card = tester.widget<Container>(find
        .ancestor(of: find.text('Speed'), matching: find.byType(Container))
        .first);
    final decoration = card.decoration as BoxDecoration;
    expect(decoration.color, NimbusColors.surfaceTerminal);
    expect(decoration.borderRadius, NimbusRadii.all(NimbusRadii.md));

    final label = tester.widget<Text>(find.text('Speed'));
    expect(label.style!.color, NimbusColors.textTertiary);
    final delay = tester.widget<Text>(find.text('-ms'));
    expect(delay.style!.color, NimbusColors.success);
    expect(delay.style!.fontFeatures,
        contains(const FontFeature.tabularFigures()));
  });

  testWidgets('the blocked pill follows the block input state', (tester) async {
    const id = 'peer-1';
    BlockInputState.init(id);
    addTearDown(() => BlockInputState.delete(id));
    const message = 'Remote keyboard and mouse are blocked';

    await tester.pumpWidget(_host(const InputBlockedPill(id: id)));
    expect(find.text(message), findsNothing);

    BlockInputState.find(id).value = true;
    await tester.pump();
    expect(find.text(message), findsOneWidget);
    final pill = tester.widget<Container>(find
        .ancestor(of: find.text(message), matching: find.byType(Container))
        .first);
    expect((pill.decoration as BoxDecoration).color,
        NimbusColors.warning.withOpacity(0.9));

    BlockInputState.find(id).value = false;
    await tester.pump();
    expect(find.text(message), findsNothing);
  });

  testWidgets('the blocked pill shows nothing without a session state',
      (tester) async {
    await tester.pumpWidget(_host(const InputBlockedPill(id: 'no-session')));
    expect(find.byType(Container), findsNothing);
  });
}
