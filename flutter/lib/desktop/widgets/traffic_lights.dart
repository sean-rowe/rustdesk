import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/theme/nimbus.dart';

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
/// pointer is over the group. A control without a callback is shown at 40%
/// opacity and ignores input; a hidden control takes no space.
class TrafficLights extends StatefulWidget {
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
    final lights = <Widget>[
      if (widget.showClose) _light(TrafficLight.close, widget.onClose),
      if (widget.showMinimize)
        _light(TrafficLight.minimize, widget.onMinimize),
      if (widget.showMaximize)
        _light(TrafficLight.maximize, widget.onMaximize,
            tooltip: widget.isMaximized ? 'Restore' : null),
    ];
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: NimbusSpace.s7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _spaced(lights),
        ),
      ),
    );
  }

  Widget _light(TrafficLight light, VoidCallback? onTap, {String? tooltip}) {
    return _TrafficLightDot(
      light: light,
      onTap: onTap,
      revealed: _hovered,
      tooltip: translate(tooltip ?? light.tooltip),
    );
  }

  static List<Widget> _spaced(List<Widget> lights) => [
        for (var i = 0; i < lights.length; i++) ...[
          if (i > 0) const SizedBox(width: NimbusSpace.trafficGap),
          lights[i],
        ],
      ];
}

class _TrafficLightDot extends StatelessWidget {
  static const Color _glyphInk = Color(0x99000000);

  final TrafficLight light;
  final VoidCallback? onTap;
  final bool revealed;
  final String tooltip;

  const _TrafficLightDot({
    required this.light,
    required this.onTap,
    required this.revealed,
    required this.tooltip,
  });

  bool get _enabled => onTap != null;

  @override
  Widget build(BuildContext context) {
    final active = revealed && _enabled;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(seconds: 1),
      child: MouseRegion(
        cursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTap: onTap,
          child: Opacity(
            opacity: _enabled ? 1 : 0.4,
            child: AnimatedContainer(
              duration: NimbusMotion.fast,
              curve: NimbusMotion.standard,
              width: NimbusSpace.trafficSize,
              height: NimbusSpace.trafficSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? Color.lerp(light.color, Colors.white, 0.12)
                    : light.color,
              ),
              child: active
                  ? Icon(light.glyph, size: 9, color: _glyphInk)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
