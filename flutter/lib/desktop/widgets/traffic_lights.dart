import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/theme/nimbus.dart';
import 'package:flutter_hbb/desktop/widgets/nimbus/nimbus_widgets.dart';

/// A window control rendered as one Nimbus traffic light.
enum TrafficLight {
  close(NimbusColors.trafficClose, Icons.close_rounded, 'Close'),
  minimize(NimbusColors.trafficMinimize, Icons.remove_rounded, 'Minimize'),
  maximize(NimbusColors.trafficMaximize, Icons.add_rounded, 'Maximize');

  const TrafficLight(this.color, this.glyph, this.tooltip);

  final Color color;
  final IconData glyph;
  final String tooltip;
}

/// Nimbus window controls: close, minimize and maximize as rose, amber and
/// mint dots. The dots brighten together and reveal their glyphs while the
/// pointer is over the group. Each dot sits centered in a larger target that
/// spans half the gap to its neighbours, so the targets touch but never
/// overlap. A control without a callback is shown at 40% opacity and is left
/// out of keyboard traversal; a hidden control takes no space.
class TrafficLights extends StatefulWidget {
  static const double targetHeight = 28;

  final VoidCallback? onClose;
  final VoidCallback? onMinimize;
  final VoidCallback? onMaximize;
  final bool showClose;
  final bool showMinimize;
  final bool showMaximize;
  final bool isMaximized;

  const TrafficLights({
    Key? key,
    this.onClose,
    this.onMinimize,
    this.onMaximize,
    this.showClose = true,
    this.showMinimize = true,
    this.showMaximize = true,
    this.isMaximized = false,
  }) : super(key: key);

  @override
  State<TrafficLights> createState() => _TrafficLightsState();
}

class _TrafficLightsState extends State<TrafficLights> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: NimbusSpace.s7 - NimbusSpace.trafficGap / 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showClose) _light(TrafficLight.close, widget.onClose),
            if (widget.showMinimize)
              _light(TrafficLight.minimize, widget.onMinimize),
            if (widget.showMaximize)
              _light(TrafficLight.maximize, widget.onMaximize,
                  tooltip: widget.isMaximized ? 'Restore' : null),
          ],
        ),
      ),
    );
  }

  Widget _light(TrafficLight light, VoidCallback? onTap, {String? tooltip}) {
    final message = translate(tooltip ?? light.tooltip);
    return Tooltip(
      message: message,
      waitDuration: const Duration(seconds: 1),
      child: NimbusPressable(
        onTap: onTap,
        semanticLabel: message,
        focusRadius: NimbusRadii.all(NimbusRadii.xs),
        builder: (context, _, focused) => SizedBox(
          width: NimbusSpace.trafficSize + NimbusSpace.trafficGap,
          height: TrafficLights.targetHeight,
          child: Center(
            child: _TrafficLightDot(
              light: light,
              enabled: onTap != null,
              revealed: _hovered || focused,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrafficLightDot extends StatelessWidget {
  static const Color _glyphInk = Color(0x99000000);

  final TrafficLight light;
  final bool enabled;
  final bool revealed;

  const _TrafficLightDot({
    required this.light,
    required this.enabled,
    required this.revealed,
  });

  @override
  Widget build(BuildContext context) {
    final active = revealed && enabled;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: AnimatedContainer(
        duration: NimbusMotion.fast,
        curve: NimbusMotion.standard,
        width: NimbusSpace.trafficSize,
        height: NimbusSpace.trafficSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              active ? Color.lerp(light.color, Colors.white, 0.12) : light.color,
        ),
        child: active ? Icon(light.glyph, size: 9, color: _glyphInk) : null,
      ),
    );
  }
}
