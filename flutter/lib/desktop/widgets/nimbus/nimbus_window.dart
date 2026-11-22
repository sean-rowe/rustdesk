import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/theme/nimbus.dart';
import 'package:flutter_hbb/desktop/widgets/tabbar_widget.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:get/get.dart';

/// The fill behind a Nimbus window. On Linux the runner gives the window an
/// RGBA visual when a compositor runs, so the translucent glass lets the
/// compositor blur the desktop behind it. Elsewhere the window is opaque.
Color nimbusWindowFill() =>
    isLinux ? NimbusColors.surfaceWindow : NimbusColors.windowOpaque;

/// The Nimbus window body: glass fill, hairline edge and the window corner.
/// Corners square off while the window is maximized or full screen.
class NimbusWindowFrame extends StatelessWidget {
  final Widget child;

  const NimbusWindowFrame({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isMacOS || kUseCompatibleUiMode) {
      return ColoredBox(color: nimbusWindowFill(), child: child);
    }
    return Obx(() {
      final square =
          stateGlobal.isMaximized.isTrue || stateGlobal.fullscreen.isTrue;
      final radius = NimbusRadii.all(square ? 0 : NimbusRadii.window);
      return ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: nimbusWindowFill(),
            borderRadius: radius,
          ),
          position: DecorationPosition.background,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: square
                  ? null
                  : Border.all(color: NimbusColors.borderWindow),
            ),
            position: DecorationPosition.foreground,
            child: child,
          ),
        ),
      );
    });
  }
}

/// A Nimbus title bar: window controls on the left, a centered title or
/// control, and an optional trailing slot. Dragging moves the window and a
/// double click toggles maximize.
class NimbusTitleBar extends StatelessWidget {
  static const double height = 46;
  static const double _macOSControlsWidth = 78;

  final bool isMainWindow;
  final Widget controls;
  final Widget center;
  final Widget? trailing;
  final bool canMaximize;

  const NimbusTitleBar({
    Key? key,
    required this.isMainWindow,
    required this.controls,
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

/// The plain centered window title used when there is nothing to switch.
class NimbusWindowTitle extends StatelessWidget {
  const NimbusWindowTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Text(
        bind.mainGetAppNameSync(),
        style: const TextStyle(
          fontSize: NimbusType.callout,
          fontWeight: NimbusType.semibold,
          color: NimbusColors.textPrimary,
        ),
      ),
    );
  }
}
