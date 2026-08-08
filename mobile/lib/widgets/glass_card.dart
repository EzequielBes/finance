import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mobile/theme/liquid_glass_theme.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.intensity = GlassIntensity.full,
    this.padding = const EdgeInsets.all(LiquidGlassSpacing.lg),
    this.borderRadius,
    super.key,
  });

  final Widget child;
  final GlassIntensity intensity;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final effectiveIntensity = MediaQuery.of(context).highContrast
        ? GlassIntensity.opaque
        : intensity;

    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(LiquidGlassRadius.card);

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: LiquidGlassColors.glassFill.withValues(
          alpha: effectiveIntensity.fillAlpha,
        ),
        borderRadius: effectiveRadius,
        border: Border.all(color: LiquidGlassColors.glassBorder),
        boxShadow: const [
          BoxShadow(color: Colors.white24, blurRadius: 12, spreadRadius: -8),
        ],
      ),
      child: child,
    );

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: effectiveIntensity.blurSigma == 0
          ? content
          : BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: effectiveIntensity.blurSigma,
                sigmaY: effectiveIntensity.blurSigma,
              ),
              child: content,
            ),
    );
  }
}
