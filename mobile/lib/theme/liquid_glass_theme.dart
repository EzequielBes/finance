import 'package:flutter/material.dart';

/// Paleta de cores do tema Liquid Glass (dark + wellness, accent terracota
/// mantido do tema atual — ver docs/superpowers/specs/2026-08-08-liquid-glass-theme-design.md).
class LiquidGlassColors {
  static const background = Color(0xFF12161A);
  static const surface = Color(0xFF1B2127);
  static const glassFill = Color(0xFF2A3138);
  static const glassBorder = Colors.white;
  static const textPrimary = Color(0xFFEDF1F4);
  static const textSecondary = Color(0xFF8B94A0);
  static const accentPrimary = Color(0xFFC17A54);
  static const positive = Color(0xFF7A9B7E);
  static const warning = Color(0xFFC17A54);
  static const negative = Color(0xFFB8563A);
}

/// Nível de efeito de vidro: controla blur e opacidade da camada de vidro
/// juntos, como um único knob que os widgets consumidores escolhem.
enum GlassIntensity {
  /// Efeito completo — uso padrão em dispositivos capazes.
  full,

  /// Blur reduzido, ainda visível — para listas longas ou dispositivos modestos.
  reduced,

  /// Sem blur, superfície sólida — fallback de acessibilidade/performance
  /// (highContrast, disableAnimations, ou hardware muito limitado).
  opaque;

  double get blurSigma => switch (this) {
    GlassIntensity.full => 12.0,
    GlassIntensity.reduced => 6.0,
    GlassIntensity.opaque => 0.0,
  };

  double get fillAlpha => switch (this) {
    GlassIntensity.full => 0.55,
    GlassIntensity.reduced => 0.70,
    GlassIntensity.opaque => 0.95,
  };
}

/// Raios de borda nomeados por uso — pílula só em botões/chips, não em cards.
class LiquidGlassRadius {
  static const pill = 999.0;
  static const card = 20.0;
  static const input = 14.0;
}

/// Escala de espaçamento nomeada.
class LiquidGlassSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Escala tipográfica: display, title, body, label, e data (tabular, para
/// valores monetários alinhados em listas).
class LiquidGlassTypography {
  static const display = TextStyle(
    color: LiquidGlassColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
  );

  static const title = TextStyle(
    color: LiquidGlassColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  static const body = TextStyle(
    color: LiquidGlassColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  static const label = TextStyle(
    color: LiquidGlassColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static const data = TextStyle(
    color: LiquidGlassColors.textPrimary,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

/// Durações e curvas de motion, nomeadas por categoria de interação
/// (não durações avulsas — ver spec para as faixas de referência).
class LiquidGlassMotion {
  static const press = Duration(milliseconds: 100);
  static const stateChange = Duration(milliseconds: 190);
  static const navigation = Duration(milliseconds: 290);
  static const reveal = Duration(milliseconds: 470);

  static const curveEnter = Curves.easeOutCubic;
  static const curveSettle = Curves.easeOutBack;
}

/// Resolve uma duração de [LiquidGlassMotion] para instantâneo/crossfade
/// curto quando o usuário pede movimento reduzido.
class MotionProfile {
  const MotionProfile();

  Duration resolve(Duration base, {required bool reducedMotion}) {
    if (!reducedMotion) return base;
    return const Duration(milliseconds: 1);
  }
}
