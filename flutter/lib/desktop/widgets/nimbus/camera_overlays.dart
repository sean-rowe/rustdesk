import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/theme/nimbus.dart';
import 'package:flutter_hbb/consts.dart';

/// The Live pill's text: "Live · Camera N" for one camera, "Live" when the
/// feed shows all of them.
String cameraLiveLabel(int display) {
  final live = translate('Live');
  if (display == kAllDisplayValue || display < 0) return live;
  return '$live · ${translate('Camera')} ${display + 1}';
}

/// A time of day as HH:MM:SS.
String formatCameraClock(DateTime time) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
}

BoxDecoration _glass() => BoxDecoration(
      color: NimbusColors.surfaceTerminal,
      borderRadius: NimbusRadii.all(NimbusRadii.pill),
      border: Border.all(color: NimbusColors.borderWindow),
    );

/// The top left pill once the camera feed shows: a green dot and
/// "Live · Camera N".
class CameraLivePill extends StatelessWidget {
  final int display;

  const CameraLivePill({Key? key, required this.display}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: NimbusSpace.s5, vertical: NimbusSpace.s2),
      decoration: _glass(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: NimbusColors.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: NimbusSpace.s3),
          Text(cameraLiveLabel(display),
              style: const TextStyle(
                  fontSize: NimbusType.caption,
                  fontWeight: NimbusType.semibold,
                  color: NimbusColors.textPrimary)),
        ],
      ),
    );
  }
}

/// The bottom left timestamp: the local time in monospace, updated every
/// second. The timer is cancelled in dispose.
class CameraClock extends StatefulWidget {
  /// The clock the time is read from; tests replace it.
  final DateTime Function() now;

  const CameraClock({Key? key, this.now = DateTime.now}) : super(key: key);

  @override
  State<CameraClock> createState() => _CameraClockState();
}

class _CameraClockState extends State<CameraClock> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: NimbusSpace.s4, vertical: NimbusSpace.s1),
      decoration: _glass(),
      child: Text(formatCameraClock(widget.now()),
          style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: NimbusType.caption,
              color: NimbusColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()])),
    );
  }
}
