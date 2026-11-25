import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/pages/desktop_home_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
import 'package:flutter_hbb/desktop/widgets/nimbus/nimbus_widgets.dart';
import 'package:flutter_hbb/desktop/widgets/nimbus/nimbus_window.dart';
import 'package:flutter_hbb/desktop/widgets/tabbar_widget.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';
// import 'package:flutter/services.dart';

import '../../common/shared_state.dart';

class DesktopTabPage extends StatefulWidget {
  const DesktopTabPage({Key? key}) : super(key: key);

  @override
  State<DesktopTabPage> createState() => _DesktopTabPageState();

  static void onAddSetting(
      {SettingsTabKey initialPage = SettingsTabKey.general}) {
    try {
      DesktopTabController tabController = Get.find<DesktopTabController>();
      tabController.add(TabInfo(
          key: kTabLabelSettingPage,
          label: kTabLabelSettingPage,
          selectedIcon: Icons.build_sharp,
          unselectedIcon: Icons.build_outlined,
          page: DesktopSettingPage(
            key: const ValueKey(kTabLabelSettingPage),
            initialTabkey: initialPage,
          )));
    } catch (e) {
      debugPrintStack(label: '$e');
    }
  }
}

class _DesktopTabPageState extends State<DesktopTabPage> {
  final tabController = DesktopTabController(tabType: DesktopTabType.main);

  _DesktopTabPageState() {
    RemoteCountState.init();
    Get.put<DesktopTabController>(tabController);
    tabController.add(TabInfo(
        key: kTabLabelHomePage,
        label: kTabLabelHomePage,
        selectedIcon: Icons.home_sharp,
        unselectedIcon: Icons.home_outlined,
        closable: false,
        page: DesktopHomePage(
          key: const ValueKey(kTabLabelHomePage),
        )));
    if (bind.isIncomingOnly()) {
      tabController.onSelected = (key) {
        if (key == kTabLabelHomePage) {
          windowManager.setSize(getIncomingOnlyHomeSize());
          setResizable(false);
        } else {
          windowManager.setSize(getIncomingOnlySettingsSize());
          setResizable(true);
        }
      };
    }
  }

  @override
  void initState() {
    super.initState();
    // HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  /*
  bool _handleKeyEvent(KeyEvent event) {
    if (!mouseIn && event is KeyDownEvent) {
      print('key down: ${event.logicalKey}');
      shouldBeBlocked(_block, canBeBlocked);
    }
    return false; // allow it to propagate
  }
  */

  @override
  void dispose() {
    // HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    Get.delete<DesktopTabController>();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabWidget = Scaffold(
      backgroundColor: Colors.transparent,
      body: NimbusWindowFrame(
        child: Column(children: [
          if (!kUseCompatibleUiMode) _buildTitleBar(),
          Expanded(
            // Compatible UI mode has no title bar, so it keeps the tab bar
            // and its Settings button as the way between Home and Settings.
            child: DesktopTab(
              controller: tabController,
              showTabBar: kUseCompatibleUiMode,
              tail: kUseCompatibleUiMode
                  ? Offstage(
                      offstage:
                          bind.isIncomingOnly() || bind.isDisableSettings(),
                      child: ActionIcon(
                        message: 'Settings',
                        icon: IconFont.menu,
                        onTap: DesktopTabPage.onAddSetting,
                        isClose: false,
                      ),
                    )
                  : null,
            ),
          ),
        ]),
      ),
    );
    return isMacOS || kUseCompatibleUiMode
        ? tabWidget
        : Obx(
            () => DragToResizeArea(
              resizeEdgeSize: stateGlobal.resizeEdgeSize.value,
              enableResizeEdges: windowManagerEnableResizeEdges,
              child: tabWidget,
            ),
          );
  }

  Widget _buildTitleBar() {
    final canOpenSettings = !bind.isIncomingOnly() && !bind.isDisableSettings();
    return NimbusTitleBar(
      isMainWindow: true,
      canMaximize: !(bind.isIncomingOnly() && isInHomePage()),
      controls: WindowActionPanel(
        isMainWindow: true,
        state: tabController.state,
        tabController: tabController,
        invisibleTabKeys: RxList.empty(),
        showExtras: false,
      ),
      leading: const NimbusWindowBrandTitle(),
      // Incoming-only mode has no Settings entry here, but Settings can still
      // be opened from the ID board, so the switch appears while it is open
      // to give a way back to Home.
      center: Obx(() {
        final selected = _selectedTabKey();
        if (!canOpenSettings && selected != kTabLabelSettingPage) {
          return const SizedBox.shrink();
        }
        return NimbusSegmentedControl<String>(
          segments: [
            (kTabLabelHomePage, translate('Home')),
            (kTabLabelSettingPage, translate('Settings')),
          ],
          value: selected,
          onChanged: _selectTab,
        );
      }),
    );
  }

  String _selectedTabKey() {
    final state = tabController.state.value;
    return state.tabs.isEmpty ? kTabLabelHomePage : state.selectedTabInfo.key;
  }

  void _selectTab(String key) {
    if (key == kTabLabelSettingPage) {
      DesktopTabPage.onAddSetting();
    } else {
      tabController.jumpToByKey(kTabLabelHomePage);
    }
  }
}
