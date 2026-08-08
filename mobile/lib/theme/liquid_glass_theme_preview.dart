import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:mobile/theme/liquid_glass_theme.dart';

@Preview(name: 'Liquid Glass — Swatches de cor')
Widget liquidGlassColorSwatches() {
  Widget swatch(String label, Color color) => Column(
    children: [
      Container(width: 64, height: 64, color: color),
      const SizedBox(height: 4),
      Text(label, style: LiquidGlassTypography.label),
    ],
  );

  return Container(
    color: LiquidGlassColors.background,
    padding: const EdgeInsets.all(LiquidGlassSpacing.lg),
    child: Wrap(
      spacing: LiquidGlassSpacing.md,
      runSpacing: LiquidGlassSpacing.md,
      children: [
        swatch('background', LiquidGlassColors.background),
        swatch('surface', LiquidGlassColors.surface),
        swatch('glassFill', LiquidGlassColors.glassFill),
        swatch('accentPrimary', LiquidGlassColors.accentPrimary),
        swatch('positive', LiquidGlassColors.positive),
        swatch('warning', LiquidGlassColors.warning),
        swatch('negative', LiquidGlassColors.negative),
      ],
    ),
  );
}

@Preview(name: 'Liquid Glass — Card por GlassIntensity')
Widget liquidGlassIntensityCards() {
  Widget card(GlassIntensity intensity) => Container(
    width: 160,
    padding: const EdgeInsets.all(LiquidGlassSpacing.lg),
    margin: const EdgeInsets.all(LiquidGlassSpacing.sm),
    decoration: BoxDecoration(
      color: LiquidGlassColors.glassFill.withValues(alpha: intensity.fillAlpha),
      borderRadius: BorderRadius.circular(LiquidGlassRadius.card),
      border: Border.all(
        color: LiquidGlassColors.glassBorder.withValues(alpha: 0.12),
      ),
    ),
    child: Text(intensity.name, style: LiquidGlassTypography.body),
  );

  return Container(
    color: LiquidGlassColors.background,
    padding: const EdgeInsets.all(LiquidGlassSpacing.lg),
    child: Wrap(
      children: GlassIntensity.values.map(card).toList(),
    ),
  );
}

@Preview(name: 'Liquid Glass — Botão pílula e chip')
Widget liquidGlassPillShapes() {
  return Container(
    color: LiquidGlassColors.background,
    padding: const EdgeInsets.all(LiquidGlassSpacing.lg),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            color: LiquidGlassColors.accentPrimary,
            borderRadius: BorderRadius.circular(LiquidGlassRadius.pill),
          ),
          child: Text(
            'Importar extrato',
            style: LiquidGlassTypography.body.copyWith(
              color: LiquidGlassColors.background,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: LiquidGlassSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: LiquidGlassColors.positive.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(LiquidGlassRadius.pill),
          ),
          child: Text(
            '+ Receita',
            style: LiquidGlassTypography.label.copyWith(
              color: LiquidGlassColors.positive,
            ),
          ),
        ),
      ],
    ),
  );
}
