import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/theme/nimbus.dart';
import 'package:flutter_hbb/desktop/widgets/nimbus/nimbus_widgets.dart';
import 'package:flutter_hbb/models/model.dart';

/// Rebuilds [builder] with the elapsed recording time once a second while
/// [model] records. The timer runs only while recording and is cancelled
/// in dispose.
class RecordingTicker extends StatefulWidget {
  final RecordingModel model;
  final Widget Function(BuildContext context, Duration elapsed) builder;

  const RecordingTicker({Key? key, required this.model, required this.builder})
      : super(key: key);

  @override
  State<RecordingTicker> createState() => _RecordingTickerState();
}

class _RecordingTickerState extends State<RecordingTicker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_sync);
    _sync();
  }

  @override
  void didUpdateWidget(RecordingTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model != widget.model) {
      oldWidget.model.removeListener(_sync);
      widget.model.addListener(_sync);
      _sync();
    }
  }

  void _sync() {
    final recording = widget.model.startedAt != null;
    if (recording && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!recording) {
      _timer?.cancel();
      _timer = null;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.model.removeListener(_sync);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, widget.model.elapsed ?? Duration.zero);
}

/// The pill at the top left of the remote canvas while the session is being
/// recorded: a blinking red dot, "REC", the elapsed time and a Stop button.
class RecordingPill extends StatelessWidget {
  final RecordingModel model;

  const RecordingPill({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => !model.start
          ? const SizedBox.shrink()
          : RecordingTicker(
              model: model,
              builder: (context, elapsed) => Container(
                padding: const EdgeInsets.fromLTRB(NimbusSpace.s5,
                    NimbusSpace.s2, NimbusSpace.s2, NimbusSpace.s2),
                decoration: BoxDecoration(
                  color: NimbusColors.surfaceTerminal,
                  borderRadius: NimbusRadii.all(NimbusRadii.pill),
                  border: Border.all(color: NimbusColors.borderWindow),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _BlinkingDot(),
                    const SizedBox(width: NimbusSpace.s3),
                    const Text('REC',
                        style: TextStyle(
                            fontSize: NimbusType.caption,
                            fontWeight: NimbusType.bold,
                            letterSpacing: 0.4,
                            color: NimbusColors.danger)),
                    const SizedBox(width: NimbusSpace.s4),
                    Text(formatRecordingElapsed(elapsed),
                        style: const TextStyle(
                            fontSize: NimbusType.caption,
                            fontWeight: NimbusType.semibold,
                            color: NimbusColors.textPrimary,
                            fontFeatures: [FontFeature.tabularFigures()])),
                    const SizedBox(width: NimbusSpace.s3),
                    NimbusIconButton(
                      icon: Icons.stop_rounded,
                      tooltip: translate('Stop'),
                      size: 22,
                      onTap: () => model.toggle(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// A red dot that blinks once a second, or stays lit with reduced motion.
class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 1));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Opacity(
        opacity: still || _controller.value < 0.5 ? 1 : 0,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
              color: NimbusColors.danger, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
