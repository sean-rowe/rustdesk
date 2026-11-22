import 'package:flutter/material.dart';
import 'package:flutter_hbb/common/theme/nimbus.dart';

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
class NimbusSidebarRow extends StatefulWidget {
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
  State<NimbusSidebarRow> createState() => _NimbusSidebarRowState();
}

class _NimbusSidebarRowState extends State<NimbusSidebarRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final foreground =
        widget.selected ? NimbusColors.textPrimary : NimbusColors.textSecondary;
    final fill = widget.selected
        ? NimbusColors.accentFill
        : (_hovered ? NimbusColors.hoverRow : Colors.transparent);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: NimbusMotion.fast,
          curve: NimbusMotion.standard,
          margin: const EdgeInsets.symmetric(vertical: NimbusSpace.s1 / 2),
          padding: const EdgeInsets.symmetric(
              horizontal: NimbusSpace.s5, vertical: 7),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: NimbusRadii.all(NimbusRadii.sm),
          ),
          child: Row(children: [
            Icon(widget.icon,
                size: 16,
                color: widget.selected
                    ? NimbusColors.textPrimary
                    : NimbusColors.accent),
            const SizedBox(width: NimbusSpace.s5),
            Expanded(
              child: Text(
                widget.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: NimbusType.footnote,
                  fontWeight: widget.selected
                      ? NimbusType.semibold
                      : NimbusType.regular,
                  color: foreground,
                ),
              ),
            ),
            if (widget.trailing != null) widget.trailing!,
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: NimbusMotion.fast,
          curve: NimbusMotion.standard,
          padding: const EdgeInsets.symmetric(
              horizontal: NimbusSpace.s8, vertical: NimbusSpace.s2),
          decoration: BoxDecoration(
            color: selected ? NimbusColors.hoverControl : Colors.transparent,
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
      ),
    );
  }
}
