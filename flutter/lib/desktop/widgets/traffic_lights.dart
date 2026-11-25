import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/theme/nimbus.dart';
import 'package:flutter_hbb/desktop/widgets/nimbus/nimbus_widgets.dart';

/// A window control rendered as one Nimbus traffic light.
enum TrafficLight {
  close(NimbusColors.trafficClose, 'Close'),
  minimize(NimbusColors.trafficMinimize, 'Minimize'),
  maximize(NimbusColors.trafficMaximize, 'Maximize');

  const TrafficLight(this.color, this.tooltip);

  final Color color;
  final String tooltip;
}

/// Nimbus window controls: close, minimize and maximize as rose, amber and
/// mint dots. The dots dim when the window is unfocused and reveal their
/// glyphs while the pointer is over the group. Each dot sits centered in a
/// larger target that spans half the gap to its neighbours, so the targets
/// touch but never overlap. A control without a callback is shown at 40%
/// opacity and is left out of keyboard traversal; a hidden control takes no
/// space.
class TrafficLights extends StatefulWidget {
  static const double targetHeight = 28;

  final VoidCallback? onClose;
  final VoidCallback? onMinimize;
  final VoidCallback? onMaximize;
  final bool showClose;
  final bool showMinimize;
  final bool showMaximize;
  final bool isMaximized;
  final bool isFocused;

  const TrafficLights({
    Key? key,
    this.onClose,
    this.onMinimize,
    this.onMaximize,
    this.showClose = true,
    this.showMinimize = true,
    this.showMaximize = true,
    this.isMaximized = false,
    this.isFocused = true,
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
              windowFocused: widget.isFocused,
              revealed: _hovered || focused,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrafficLightDot extends StatelessWidget {
  final TrafficLight light;
  final bool enabled;
  final bool windowFocused;
  final bool revealed;

  const _TrafficLightDot({
    required this.light,
    required this.enabled,
    required this.windowFocused,
    required this.revealed,
  });

  @override
  Widget build(BuildContext context) {
    final active = revealed && enabled;
    final dotOpacity = !enabled
        ? 0.4
        : (windowFocused || active ? 1.0 : NimbusColors.trafficUnfocusedOpacity);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      curve: Curves.ease,
      opacity: dotOpacity,
      child: Container(
        width: NimbusSpace.trafficSize,
        height: NimbusSpace.trafficSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: light.color,
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          curve: Curves.ease,
          opacity: active ? 1.0 : 0.0,
          child: CustomPaint(
            painter: _TrafficGlyphPainter(light),
          ),
        ),
      ),
    );
  }
}

class _TrafficGlyphPainter extends CustomPainter {
  // Matches PineUI TrafficLightDot: half-extent 0.22 * 12, 1.6px round stroke
  // in (0.2, 0.05, 0.0).
  static const double _halfExtent = NimbusSpace.trafficSize * 0.22;
  static const double _strokeWidth = 1.6;

  final TrafficLight light;

  const _TrafficGlyphPainter(this.light);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    const s = _halfExtent;
    final paint = Paint()
      ..color = NimbusColors.trafficGlyph
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    switch (light) {
      case TrafficLight.close:
        canvas.drawLine(Offset(cx - s, cy - s), Offset(cx + s, cy + s), paint);
        canvas.drawLine(Offset(cx + s, cy - s), Offset(cx - s, cy + s), paint);
        break;
      case TrafficLight.minimize:
        canvas.drawLine(Offset(cx - s, cy), Offset(cx + s, cy), paint);
        break;
      case TrafficLight.maximize:
        canvas.drawLine(Offset(cx - s, cy + s), Offset(cx + s, cy - s), paint);
        break;
    }
  }

  @override
  bool shouldRepaint(_TrafficGlyphPainter oldDelegate) =>
      oldDelegate.light != light;
}
