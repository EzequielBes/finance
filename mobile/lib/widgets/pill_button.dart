import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/theme/liquid_glass_theme.dart';

enum PillButtonSize { medium, small }

class PillButton extends StatefulWidget {
  const PillButton({
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.size = PillButtonSize.medium,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final PillButtonSize size;

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final verticalPadding = widget.size == PillButtonSize.small
        ? LiquidGlassSpacing.sm
        : LiquidGlassSpacing.md;

    return Semantics(
      button: true,
      selected: widget.selected,
      enabled: enabled,
      label: widget.label,
      child: Listener(
        onPointerDown: enabled ? (_) => _setPressed(true) : null,
        onPointerUp: enabled ? (_) => _setPressed(false) : null,
        onPointerCancel: enabled ? (_) => _setPressed(false) : null,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: LiquidGlassMotion.press,
          curve: LiquidGlassMotion.curveEnter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Opacity(
              opacity: enabled ? 1.0 : 0.5,
              child: Material(
                color: widget.selected
                    ? LiquidGlassColors.accentPrimary
                    : LiquidGlassColors.glassFill,
                borderRadius: BorderRadius.circular(LiquidGlassRadius.pill),
                child: InkWell(
                  onTap: widget.onPressed == null
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          widget.onPressed!();
                        },
                  borderRadius: BorderRadius.circular(LiquidGlassRadius.pill),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: LiquidGlassSpacing.lg,
                      vertical: verticalPadding,
                    ),
                    decoration: widget.selected
                        ? BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(LiquidGlassRadius.pill),
                            border: Border.all(
                              color: LiquidGlassColors.glassBorder,
                              width: 1.5,
                            ),
                          )
                        : null,
                    alignment: Alignment.center,
                    child: Text(
                      widget.label,
                      style: LiquidGlassTypography.body.copyWith(
                        fontWeight:
                            widget.selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
