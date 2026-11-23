import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/widgets/dialog.dart';
import 'package:flutter_hbb/generated_bridge.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _Binding extends Fake implements RustdeskImpl {
  String myId = '123456789';
  String? changedTo;
  List<String> statuses = [];

  @override
  String translate(
          {required String name, required String locale, dynamic hint}) =>
      name;

  @override
  String mainGetLocalOption({required String key, dynamic hint}) => '';

  @override
  String getLocalFlutterOption({required String k, dynamic hint}) => '';

  @override
  String mainGetBuildinOption({required String key, dynamic hint}) => '';

  @override
  bool isDisableAb({dynamic hint}) => false;

  @override
  bool isDisableAccount({dynamic hint}) => false;

  @override
  bool isDisableGroupPanel({dynamic hint}) => false;

  @override
  Future<void> mainChangeId({required String newId, dynamic hint}) async {
    changedTo = newId;
  }

  @override
  Future<String> mainGetAsyncStatus({dynamic hint}) async =>
      statuses.isEmpty ? '' : statuses.removeAt(0);

  @override
  Future<String> mainGetMyId({dynamic hint}) async => myId;
}

void main() {
  final binding = _Binding();

  setUpAll(() async {
    isTest = true;
    platformFFI.setBindingForTesting(binding);
    await initGlobalFFI();
  });

  Future<void> openChangeId(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      navigatorKey: globalKey,
      theme: MyTheme.darkTheme,
      home: const Scaffold(),
    ));
    changeIdDialog();
    addTearDown(gFFI.dialogManager.dismissAll);
    await tester.pumpAndSettle();
  }

  testWidgets('rule errors show inline under the field, with no chips',
      (tester) async {
    binding.changedTo = null;
    await openChangeId(tester);
    expect(find.byType(Chip), findsNothing);

    await tester.enterText(find.byType(TextField), '1abc');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(
        field.decoration!.errorText,
        'starts with a letter, length %min% to %max%'
            .replaceAll('%min%', '6')
            .replaceAll('%max%', '16'));
    expect(find.textContaining('Prompt'), findsNothing);
    expect(binding.changedTo, isNull);
  });

  testWidgets('a status from the server shows inline under the field',
      (tester) async {
    binding.statuses = ['Not available'];
    await openChangeId(tester);

    await tester.enterText(find.byType(TextField), 'studio-mini');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(binding.changedTo, 'studio-mini');
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration!.errorText, 'Not available');
    expect(find.byType(CustomAlertDialog), findsOneWidget);
  });

  testWidgets('success closes the dialog, refreshes the ID and confirms',
      (tester) async {
    binding.statuses = [];
    await openChangeId(tester);

    await tester.enterText(find.byType(TextField), 'studio-mini');
    binding.myId = 'studio-mini';
    await tester.tap(find.text('OK'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(CustomAlertDialog), findsNothing);
    expect(gFFI.serverModel.serverId.text, contains('studio-mini'));
    expect(find.text('Successful'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });
}
