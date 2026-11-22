import 'package:flutter/material.dart';
import 'package:flutter_hbb/common/theme/nimbus.dart';

/// Builds a pressable's look from its pointer and keyboard state.
typedef NimbusPressableBuilder = Widget Function(
    BuildContext context, bool hovered, bool focused);

/// A press target that works with pointer and keyboard alike. It joins focus
/// traversal while enabled, activates on Enter or Space, and draws an accent
/// focus ring around its child. A pressable without [onTap] is disabled and
/// left out of traversal.
class NimbusPressable extends StatefulWidget {
  final VoidCallback? onTap;
  final String? semanticLabel;
  final BorderRadius focusRadius;
  final NimbusPressableBuilder builder;

  const NimbusPressable({
    Key? key,
    required this.onTap,
    required this.builder,
    this.semanticLabel,
    this.focusRadius = const BorderRadius.all(Radius.circular(NimbusRadii.sm)),
  }) : super(key: key);

  @override
  State<NimbusPressable> createState() => _NimbusPressableState();
}

class _NimbusPressableState extends State<NimbusPressable> {
  bool _hovered = false;
  bool _focused = false;

  bool get _enabled => widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: _enabled,
      mouseCursor:
          _enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => widget.onTap?.call()),
      },
      child: Semantics(
        button: true,
        enabled: _enabled,
        label: widget.semanticLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            foregroundDecoration: _focused
                ? BoxDecoration(
                    borderRadius: widget.focusRadius,
                    border: Border.all(color: NimbusColors.accent, width: 2),
                  )
                : null,
            child: widget.builder(context, _hovered && _enabled, _focused),
          ),
        ),
      ),
    );
  }
}

/// Uppercase micro-label that heads a group of sidebar rows.
class NimbusSectionLabel extends StatelessWidget {
  final String text;

  const NimbusSectionLabel(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          NimbusSpace.s5, NimbusSpace.s6, NimbusSpace.s5, NimbusSpace.s3),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: NimbusType.caption2,
          fontWeight: NimbusType.semibold,
          letterSpacing: 0.4,
          color: NimbusColors.textPrimary.withOpacity(0.5),
        ),
      ),
    );
  }
}

/// A sidebar list row: icon, label and optional trailing widget. A selected
/// row is filled with the accent; a hovered row gets a faint white wash.
class NimbusSidebarRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;

  const NimbusSidebarRow({
    Key? key,
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NimbusSpace.s1 / 2),
      child: NimbusPressable(
        onTap: onTap,
        semanticLabel: label,
        builder: (context, hovered, _) => AnimatedContainer(
          duration: NimbusMotion.fast,
          curve: NimbusMotion.standard,
          padding: const EdgeInsets.symmetric(
              horizontal: NimbusSpace.s5, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? NimbusColors.accentFill
                : (hovered ? NimbusColors.hoverRow : Colors.transparent),
            borderRadius: NimbusRadii.all(NimbusRadii.sm),
          ),
          child: Row(children: [
            Icon(icon,
                size: 16,
                color: selected
                    ? NimbusColors.textPrimary
                    : NimbusColors.accent),
            const SizedBox(width: NimbusSpace.s5),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: NimbusType.footnote,
                  fontWeight:
                      selected ? NimbusType.semibold : NimbusType.regular,
                  color: selected
                      ? NimbusColors.textPrimary
                      : NimbusColors.textSecondary,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ]),
        ),
      ),
    );
  }
}

/// A raised card inside a window: a faint white lift with a hairline edge.
class NimbusPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const NimbusPanel({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(NimbusSpace.s6),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: NimbusColors.surfaceRaise,
        borderRadius: NimbusRadii.all(NimbusRadii.lg),
        border: Border.all(color: NimbusColors.divider),
      ),
      child: child,
    );
  }
}

/// A segmented control for two to four short, mutually exclusive options.
/// The selected segment is raised in translucent white.
class NimbusSegmentedControl<T> extends StatelessWidget {
  final List<(T, String)> segments;
  final T value;
  final ValueChanged<T> onChanged;

  const NimbusSegmentedControl({
    Key? key,
    required this.segments,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NimbusSpace.s1),
      decoration: BoxDecoration(
        color: const Color(0x38000000),
        borderRadius: NimbusRadii.all(NimbusRadii.md),
        border: Border.all(color: NimbusColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (segment, label) in segments)
            _Segment(
              label: label,
              selected: segment == value,
              onTap: () => onChanged(segment),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Segment(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NimbusPressable(
      onTap: onTap,
      semanticLabel: label,
      builder: (context, hovered, _) => AnimatedContainer(
        duration: NimbusMotion.fast,
        curve: NimbusMotion.standard,
        padding: const EdgeInsets.symmetric(
            horizontal: NimbusSpace.s8, vertical: NimbusSpace.s2),
        decoration: BoxDecoration(
          color: selected
              ? NimbusColors.hoverControl
              : (hovered ? NimbusColors.hoverRow : Colors.transparent),
          borderRadius: NimbusRadii.all(NimbusRadii.sm),
          boxShadow: selected
              ? const [
                  BoxShadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Color(0x4D000000))
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: NimbusType.body,
            fontWeight: NimbusType.semibold,
            color: selected
                ? NimbusColors.textPrimary
                : NimbusColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// A small square icon button for toolbars and panels.
class NimbusIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final double size;

  const NimbusIconButton({
    Key? key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: NimbusPressable(
        onTap: onTap,
        semanticLabel: tooltip,
        focusRadius: NimbusRadii.all(NimbusRadii.xs),
        builder: (context, hovered, _) => AnimatedContainer(
          duration: NimbusMotion.fast,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: hovered ? NimbusColors.hoverControl : Colors.transparent,
            borderRadius: NimbusRadii.all(NimbusRadii.xs),
          ),
          child: Icon(icon,
              size: size * 2 / 3,
              color: onTap == null
                  ? NimbusColors.textTertiary.withOpacity(0.4)
                  : (hovered
                      ? NimbusColors.textPrimary
                      : NimbusColors.textTertiary)),
        ),
      ),
    );
  }
}
