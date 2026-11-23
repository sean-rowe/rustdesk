import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/hbbs/hbbs.dart';
import 'package:flutter_hbb/common/widgets/login.dart';
import 'package:flutter_hbb/common/widgets/my_group.dart';
import 'package:flutter_hbb/common/widgets/peer_card.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/generated_bridge.dart';
import 'package:flutter_hbb/models/peer_model.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _Binding extends Fake implements RustdeskImpl {
  @override
  String translate(
          {required String name, required String locale, dynamic hint}) =>
      name.replaceAll('{', '').replaceAll('}', '');

  @override
  String mainGetBuildinOption({required String key, dynamic hint}) => '';

  @override
  String mainGetLocalOption({required String key, dynamic hint}) =>
      key == kOptionEnableFlutterHttpOnRust ? 'Y' : '';

  @override
  String getLocalFlutterOption({required String k, dynamic hint}) => '';

  @override
  bool isDisableAb({dynamic hint}) => false;

  @override
  bool isDisableAccount({dynamic hint}) => false;

  @override
  bool isDisableGroupPanel({dynamic hint}) => false;

  @override
  Future<String> mainGetApiServer({dynamic hint}) async =>
      'https://example.com';

  @override
  Future<void> mainHttpRequest(
      {required String url,
      required String method,
      String? body,
      required String header,
      dynamic hint}) async {}

  @override
  Future<String?> mainGetHttpStatus(
          {required String url, dynamic hint}) async =>
      jsonEncode({
        'body': '["oidc/github","oidc/google"]',
        'headers': {},
        'status_code': 200
      });

  @override
  Future<void> mainAccountAuthCancel({dynamic hint}) async {}
}

Peer _peer(String loginName) =>
    Peer.fromJson({'id': '123456789', 'loginName': loginName});

UserPayload _user(String name, String displayName) =>
    UserPayload.fromJson({'name': name, 'display_name': displayName});

void main() {
  setUpAll(() async {
    isTest = true;
    platformFFI.setBindingForTesting(_Binding());
    await initGlobalFFI();
  });

  test('group cards name the owner', () {
    final users = [_user('alison', 'Alison Park'), _user('sean', '')];
    expect(groupPeerOwnerLine(_peer('sean'), 'sean', users), 'Yours');
    expect(groupPeerOwnerLine(_peer('alison'), 'sean', users),
        'Shared by Alison Park');
    expect(groupPeerOwnerLine(_peer('lab-admin'), 'sean', users),
        'Shared by lab-admin',
        reason: 'an owner the group does not list shows by username');
    expect(groupPeerOwnerLine(_peer(''), 'sean', users), isNull);
  });

  testWidgets('logged out, Accessible devices explains and offers Log In',
      (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AccessibleDevicesLoggedOut())));
    expect(find.text('accessible-devices-login-tip'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });

  testWidgets('login providers sit two to a row', (tester) async {
    await tester.pumpWidget(MaterialApp(
      navigatorKey: globalKey,
      home: const Scaffold(),
    ));
    loginDialog();
    addTearDown(gFFI.dialogManager.dismissAll);
    await tester.pumpAndSettle();

    final github = tester.getRect(find.text('Continue with GitHub'));
    final google = tester.getRect(find.text('Continue with Google'));
    expect(github.center.dy, closeTo(google.center.dy, 1));
    expect(github.left, lessThan(google.left));
    expect(find.text('login-sync-tip'), findsOneWidget);
    gFFI.dialogManager.dismissAll();
    await tester.pumpAndSettle();
  });
}
