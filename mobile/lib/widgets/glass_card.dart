import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mobile/theme/liquid_glass_theme.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.intensity = GlassIntensity.full,
    this.padding = const EdgeInsets.all(LiquidGlassSpacing.lg),
    super.key,
  });

  final Widget child;
  final GlassIntensity intensity;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: LiquidGlassColors.glassFill.withValues(alpha: intensity.fillAlpha),
        borderRadius: BorderRadius.circular(LiquidGlassRadius.card),
        border: Border.all(color: LiquidGlassColors.glassBorder),
        boxShadow: const [
          BoxShadow(
            color: Colors.white24,
            blurRadius: 12,
            spreadRadius: -8,
          ),
        ],
      ),
      child: child,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(LiquidGlassRadius.card),
      child: intensity.blurSigma == 0
          ? content
          : BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: intensity.blurSigma,
                sigmaY: intensity.blurSigma,
              ),
              child: content,
            ),
    );
  }
}
