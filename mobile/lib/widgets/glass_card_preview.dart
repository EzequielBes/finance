// mobile/lib/widgets/glass_card_preview.dart
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:mobile/theme/liquid_glass_theme.dart';
import 'package:mobile/widgets/glass_card.dart';
import 'package:mobile/widgets/pill_button.dart';

@Preview(name: 'GlassCard — múltiplos cards, intensidades diferentes')
Widget glassCardIntensityPreview() {
  return Container(
    color: LiquidGlassColors.background,
    padding: const EdgeInsets.all(LiquidGlassSpacing.lg),
    child: SingleChildScrollView(
      child: Column(
        children: [
          GlassCard(
            intensity: GlassIntensity.full,
            child: Text('full', style: LiquidGlassTypography.body),
          ),
          const SizedBox(height: LiquidGlassSpacing.md),
          GlassCard(
            intensity: GlassIntensity.reduced,
            child: Text('reduced', style: LiquidGlassTypography.body),
          ),
          const SizedBox(height: LiquidGlassSpacing.md),
          GlassCard(
            intensity: GlassIntensity.opaque,
            child: Text('opaque', style: LiquidGlassTypography.body),
          ),
        ],
      ),
    ),
  );
}

@Preview(name: 'PillButton — estados normal, selected, disabled')
Widget pillButtonStatesPreview() {
  return Container(
    color: LiquidGlassColors.background,
    padding: const EdgeInsets.all(LiquidGlassSpacing.lg),
    child: Wrap(
      spacing: LiquidGlassSpacing.md,
      runSpacing: LiquidGlassSpacing.md,
      children: [
        PillButton(label: 'Normal', onPressed: () {}),
        PillButton(label: 'Selecionado', selected: true, onPressed: () {}),
        const PillButton(label: 'Desabilitado', onPressed: null),
        PillButton(
          label: 'Rótulo bastante longo para testar quebra de linha',
          onPressed: () {},
        ),
      ],
    ),
  );
}

@Preview(
  name: 'PillButton — texto em escala 200%',
  textScaleFactor: 2.0,
)
Widget pillButtonTextScalePreview() {
  return Container(
    color: LiquidGlassColors.background,
    padding: const EdgeInsets.all(LiquidGlassSpacing.lg),
    child: PillButton(label: 'Importar extrato', onPressed: () {}),
  );
}
