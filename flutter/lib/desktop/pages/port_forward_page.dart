import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common/theme/nimbus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/desktop/widgets/nimbus/nimbus_widgets.dart';
import 'package:flutter_hbb/desktop/widgets/tabbar_widget.dart';
import 'package:flutter_hbb/models/model.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:get/get.dart';

const double _kColumn1Width = 30;
const double _kRowHeight = 60;
const double _kTextLeftMargin = 20;

/// The language key saying why a new rule can't be added, or null when it can.
/// Ports must be 1 to 65535, and a local port can be forwarded only once.
@visibleForTesting
String? portForwardAddError(
    String localPort, String remotePort, Iterable<int> forwardedLocalPorts) {
  bool valid(int? port) => port != null && port >= 1 && port <= 65535;
  final local = int.tryParse(localPort.trim());
  final remote = int.tryParse(remotePort.trim());
  if (!valid(local) || !valid(remote)) return 'Invalid port';
  if (forwardedLocalPorts.contains(local)) {
    return 'This local port is already forwarded';
  }
  return null;
}

class _PortForward {
  int localPort;
  String remoteHost;
  int remotePort;

  _PortForward.fromJson(List<dynamic> json)
      : localPort = json[0] as int,
        remoteHost = json[1] as String,
        remotePort = json[2] as int;
}

class PortForwardPage extends StatefulWidget {
  PortForwardPage({
    Key? key,
    required this.id,
    required this.password,
    this.loginMethod = '',
    required this.tabController,
    required this.isRDP,
    required this.isSharedPassword,
    this.forceRelay,
    this.connToken,
  }) : super(key: key);
  final String id;
  final String? password;
  final String loginMethod;
  final DesktopTabController tabController;
  final bool isRDP;
  final bool? forceRelay;
  final bool? isSharedPassword;
  final String? connToken;
  final SimpleWrapper<State<PortForwardPage>?> _lastState = SimpleWrapper(null);

  FFI get ffi => (_lastState.value! as _PortForwardPageState)._ffi;

  @override
  State<PortForwardPage> createState() {
    final state = _PortForwardPageState();
    _lastState.value = state;
    return state;
  }
}

class _PortForwardPageState extends State<PortForwardPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController localPortController = TextEditingController();
  final TextEditingController remoteHostController = TextEditingController();
  final TextEditingController remotePortController = TextEditingController();
  RxList<_PortForward> pfs = RxList.empty(growable: true);
  final RxString _addError = ''.obs;
  late FFI _ffi;

  @override
  void initState() {
    super.initState();
    _ffi = FFI(null);
    _ffi.start(widget.id,
        isPortForward: true,
        password: widget.password,
        loginMethod: widget.loginMethod,
        isSharedPassword: widget.isSharedPassword,
        forceRelay: widget.forceRelay,
        connToken: widget.connToken,
        isRdp: widget.isRDP);
    Get.put<FFI>(_ffi, tag: 'pf_${widget.id}');
    debugPrint("Port forward page init success with id ${widget.id}");
    // Call onSelected in post frame callback, since we cannot guarantee that the callback will not call setState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.tabController.onSelected?.call(widget.id);
    });
  }

  @override
  void dispose() {
    _ffi.close();
    _ffi.dialogManager.dismissAll();
    Get.delete<FFI>(tag: 'pf_${widget.id}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder(future: () async {
        if (!widget.isRDP) {
          refreshTunnelConfig();
        }
      }(), builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (!widget.isRDP) {
            return Padding(
              padding: const EdgeInsets.all(NimbusSpace.s8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildTunnelTip(context),
                  Flexible(child: buildTunnel(context)),
                ],
              ),
            );
          }
          return Container(
            decoration: BoxDecoration(
                border: Border.all(
                    width: 20,
                    color: Theme.of(context).scaffoldBackgroundColor)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildPrompt(context),
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.background,
                        border: Border.all(width: 1, color: MyTheme.border)),
                    child: buildRdp(context),
                  ),
                ),
              ],
            ),
          );
        }
        return const Offstage();
      }),
    );
  }

  buildPrompt(BuildContext context) {
    return Container(
        height: 45,
        color: NimbusColors.success.withOpacity(0.24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(
            translate('Listening ...'),
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          Text(
            translate('not_close_tcp_tip'),
            style: const TextStyle(
                fontSize: 10, color: Color(0xFFDDDDDD), height: 1.2),
          )
        ])).marginOnly(bottom: 8);
  }

  /// One sentence on what forwarding does, plus the keep-open tip while
  /// a rule is listening.
  Widget buildTunnelTip(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(translate('port-forward-tip'),
            style: const TextStyle(
                color: NimbusColors.textSecondary,
                fontSize: NimbusType.body,
                height: 1.45)),
        Obx(() => pfs.isEmpty
            ? const SizedBox.shrink()
            : Text(translate('not_close_tcp_tip'),
                    style: const TextStyle(
                        color: NimbusColors.textTertiary,
                        fontSize: NimbusType.footnote))
                .marginOnly(top: NimbusSpace.s2)),
      ],
    ).marginOnly(bottom: NimbusSpace.s6);
  }

  static const double _kActionWidth = 32;

  Widget _tunnelRow(List<Widget> cells, {bool divider = true}) {
    return Container(
      decoration: divider
          ? const BoxDecoration(
              border: Border(top: BorderSide(color: NimbusColors.divider)))
          : null,
      padding: const EdgeInsets.symmetric(
          horizontal: NimbusSpace.s4, vertical: NimbusSpace.s3),
      child: Row(children: [
        Expanded(flex: 2, child: cells[0]),
        Expanded(flex: 3, child: cells[1]),
        Expanded(flex: 2, child: cells[2]),
        Expanded(flex: 2, child: cells[3]),
        SizedBox(width: _kActionWidth, child: cells[4]),
      ]),
    );
  }

  /// The rules as a table in one Nimbus card, with the input row last.
  buildTunnel(BuildContext context) {
    head(String label) => Text(translate(label).toUpperCase(),
        style: const TextStyle(
            fontSize: NimbusType.caption2,
            fontWeight: NimbusType.semibold,
            letterSpacing: 0.4,
            color: NimbusColors.textTertiary));

    return Align(
      alignment: Alignment.topCenter,
      child: NimbusPanel(
        padding: const EdgeInsets.symmetric(
            horizontal: NimbusSpace.s3, vertical: NimbusSpace.s2),
        child: Obx(() => ListView(
              controller: ScrollController(),
              shrinkWrap: true,
              children: [
                _tunnelRow([
                  head('Local Port'),
                  head('Remote Host'),
                  head('Remote Port'),
                  head('Status'),
                  const SizedBox.shrink(),
                ], divider: false),
                ...pfs.map((pf) => buildTunnelDataRow(context, pf)),
                buildTunnelAddRow(context),
                if (_addError.value.isNotEmpty)
                  Text(translate(_addError.value),
                          style: const TextStyle(
                              color: NimbusColors.danger,
                              fontSize: NimbusType.footnote))
                      .marginOnly(
                          left: NimbusSpace.s4, bottom: NimbusSpace.s3),
              ],
            )),
      ),
    );
  }

  Widget buildTunnelDataRow(BuildContext context, _PortForward pf) {
    cell(String value, {bool numeric = false}) => Text(value,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            fontSize: NimbusType.body,
            color: NimbusColors.textPrimary,
            fontFeatures:
                numeric ? const [FontFeature.tabularFigures()] : null));

    return _tunnelRow([
      cell(pf.localPort.toString(), numeric: true),
      cell(pf.remoteHost),
      cell(pf.remotePort.toString(), numeric: true),
      Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: NimbusSpace.s4, vertical: NimbusSpace.s1),
          decoration: BoxDecoration(
              color: NimbusColors.success.withOpacity(0.16),
              borderRadius: NimbusRadii.all(NimbusRadii.pill)),
          child: Text(translate('Listening'),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: NimbusType.semibold,
                  color: NimbusColors.success)),
        ),
      ),
      NimbusIconButton(
        icon: Icons.delete_outline,
        tooltip: translate('Remove'),
        onTap: () async {
          await bind.sessionRemovePortForward(
              sessionId: _ffi.sessionId, localPort: pf.localPort);
          refreshTunnelConfig();
        },
      ),
    ]);
  }

  buildTunnelAddRow(BuildContext context) {
    var portInputFormatter = [
      FilteringTextInputFormatter.allow(RegExp(
          r'^([0-9]|[1-9]\d|[1-9]\d{2}|[1-9]\d{3}|[1-5]\d{4}|6[0-4]\d{3}|65[0-4]\d{2}|655[0-2]\d|6553[0-5])$'))
    ];

    add() async {
      final error = portForwardAddError(localPortController.text,
          remotePortController.text, pfs.map((pf) => pf.localPort));
      _addError.value = error ?? '';
      if (error != null) return;
      await bind.sessionAddPortForward(
          sessionId: _ffi.sessionId,
          localPort: int.parse(localPortController.text.trim()),
          remoteHost: remoteHostController.text.trim().isEmpty
              ? 'localhost'
              : remoteHostController.text.trim(),
          remotePort: int.parse(remotePortController.text.trim()));
      localPortController.clear();
      remoteHostController.clear();
      remotePortController.clear();
      refreshTunnelConfig();
    }

    return _tunnelRow([
      buildTunnelInputCell(context,
          controller: localPortController,
          inputFormatters: portInputFormatter,
          label: 'Local Port'),
      buildTunnelInputCell(context,
          controller: remoteHostController,
          hint: 'localhost',
          label: 'Remote Host'),
      buildTunnelInputCell(context,
          controller: remotePortController,
          inputFormatters: portInputFormatter,
          label: 'Remote Port'),
      Align(
        alignment: Alignment.centerLeft,
        child: ElevatedButton(onPressed: add, child: Text(translate('Add'))),
      ),
      const SizedBox.shrink(),
    ]);
  }

  buildTunnelInputCell(BuildContext context,
      {required TextEditingController controller,
      List<TextInputFormatter>? inputFormatters,
      String? hint,
      required String label}) {
    return Padding(
        padding: const EdgeInsets.only(right: NimbusSpace.s4),
        child: Semantics(
          label: translate(label),
          child: TextField(
              controller: controller,
              inputFormatters: inputFormatters,
              onChanged: (_) => _addError.value = '',
              style: const TextStyle(
                  fontSize: NimbusType.body,
                  fontFeatures: [FontFeature.tabularFigures()]),
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
              )).workaroundFreezeLinuxMint(),
        ));
  }

  void refreshTunnelConfig() async {
    String peer = bind.mainGetPeerSync(id: widget.id);
    Map<String, dynamic> config = jsonDecode(peer);
    List<dynamic> infos = config['port_forwards'] as List;
    List<_PortForward> result = List.empty(growable: true);
    for (var e in infos) {
      result.add(_PortForward.fromJson(e));
    }
    pfs.value = result;
  }

  buildRdp(BuildContext context) {
    text1(String label) => Expanded(
        child: Text(translate(label)).marginOnly(left: _kTextLeftMargin));
    text2(String label) => Expanded(
            child: Text(
          label,
          style: const TextStyle(fontSize: 20),
        ).marginOnly(left: _kTextLeftMargin));
    return Theme(
      data: Theme.of(context)
          .copyWith(colorScheme: Theme.of(context).colorScheme),
      child: ListView.builder(
          controller: ScrollController(),
          itemCount: 2,
          itemBuilder: ((context, index) {
            if (index == 0) {
              return Container(
                height: 25,
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Row(children: [
                  text1('Local Port'),
                  const SizedBox(width: _kColumn1Width),
                  text1('Remote Host'),
                  text1('Remote Port'),
                ]),
              );
            } else {
              return Container(
                height: _kRowHeight,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background),
                child: Row(children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 120,
                        child: ElevatedButton(
                          onPressed: () =>
                              bind.sessionNewRdp(sessionId: _ffi.sessionId),
                          child: Text(
                            translate('New RDP'),
                          ),
                        ).marginSymmetric(vertical: 10),
                      ).marginOnly(left: 20),
                    ),
                  ),
                  const SizedBox(
                      width: _kColumn1Width,
                      child: Icon(Icons.arrow_forward_sharp)),
                  text2('localhost'),
                  text2('RDP'),
                ]),
              );
            }
          })),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
