import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/theme/nimbus.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/widgets/tabbar_widget.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/state_model.dart';

/// The fill behind a Nimbus window. On Linux the runner gives the window an
/// RGBA visual when a compositor runs, so the translucent glass lets the
/// compositor blur the desktop behind it. Elsewhere the window is opaque.
Color nimbusWindowFill() =>
    isLinux ? NimbusColors.surfaceWindow : NimbusColors.windowOpaque;

/// The Nimbus window body: the glass fill behind a window's content. On
/// Linux the corner, hairline edge and shadow come from
/// [buildVirtualWindowFrame], which wraps every window.
class NimbusWindowFrame extends StatelessWidget {
  final Widget child;

  const NimbusWindowFrame({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: nimbusWindowFill(), child: child);
  }
}

/// A Nimbus title bar: window controls on the left, an optional leading slot
/// just right of the controls, a centered title or control, and an optional
/// trailing slot. Dragging moves the window and a double click toggles
/// maximize.
class NimbusTitleBar extends StatelessWidget {
  static const double height = 46;
  static const double _macOSControlsWidth = 78;

  final bool isMainWindow;
  final Widget controls;
  final Widget? leading;
  final Widget center;
  final Widget? trailing;
  final bool canMaximize;

  const NimbusTitleBar({
    Key? key,
    required this.isMainWindow,
    required this.controls,
    this.leading,
    required this.center,
    this.trailing,
    this.canMaximize = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Color(0x0AFFFFFF),
        border: Border(bottom: BorderSide(color: NimbusColors.divider)),
      ),
      child: Stack(children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: (_) => startDragging(isMainWindow),
            onDoubleTap: canMaximize
                ? () => toggleMaximize(isMainWindow)
                    .then((value) => stateGlobal.setMaximized(value))
                : null,
          ),
        ),
        Row(children: [
          if (isMacOS)
            const SizedBox(width: _macOSControlsWidth)
          else
            controls,
          if (leading != null) leading!,
          const Spacer(),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(right: NimbusSpace.s6),
              child: trailing!,
            ),
        ]),
        Center(child: center),
      ]),
    );
  }
}

/// The app icon tile and window title shown beside the traffic lights.
class NimbusWindowBrandTitle extends StatelessWidget {
  const NimbusWindowBrandTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.only(left: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: NimbusRadii.all(NimbusRadii.xs),
                gradient: const LinearGradient(
                  begin: Alignment(-0.42, -1),
                  end: Alignment(0.42, 1),
                  colors: [
                    NimbusColors.brandIndigo,
                    NimbusColors.brandMagenta,
                  ],
                ),
              ),
              child: const Icon(
                Icons.desktop_windows_outlined,
                size: 12,
                color: NimbusColors.textPrimary,
              ),
            ),
            const SizedBox(width: 9),
            const Text(
              kAppDisplayName,
              style: TextStyle(
                fontSize: NimbusType.callout,
                fontWeight: NimbusType.semibold,
                color: NimbusColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The plain centered window title used when there is nothing to switch.
class NimbusWindowTitle extends StatelessWidget {
  const NimbusWindowTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Text(
        kAppDisplayName,
        style: TextStyle(
          fontSize: NimbusType.callout,
          fontWeight: NimbusType.semibold,
          color: NimbusColors.textPrimary,
        ),
      ),
    );
  }
}
