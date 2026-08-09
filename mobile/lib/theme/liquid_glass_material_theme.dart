// mobile/lib/theme/liquid_glass_material_theme.dart
import 'package:flutter/material.dart';
import 'package:mobile/theme/liquid_glass_theme.dart';

ThemeData buildLiquidGlassMaterialTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: LiquidGlassColors.background,
    colorScheme: const ColorScheme.dark(
      primary: LiquidGlassColors.accentPrimary,
      secondary: LiquidGlassColors.accentPrimary,
      error: LiquidGlassColors.negative,
      surface: LiquidGlassColors.surface,
      onSurface: LiquidGlassColors.textPrimary,
    ),
    cardTheme: CardThemeData(
      color: LiquidGlassColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: LiquidGlassColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: LiquidGlassColors.textPrimary,
        fontSize: 27,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LiquidGlassColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LiquidGlassColors.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LiquidGlassColors.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: LiquidGlassColors.accentPrimary,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: LiquidGlassColors.textSecondary),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: LiquidGlassColors.textPrimary),
      bodyMedium: TextStyle(color: LiquidGlassColors.textPrimary),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: LiquidGlassColors.background,
      indicatorColor: LiquidGlassColors.accentPrimary.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? LiquidGlassColors.accentPrimary
              : LiquidGlassColors.textSecondary,
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? LiquidGlassColors.accentPrimary
              : LiquidGlassColors.textSecondary,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: LiquidGlassColors.accentPrimary,
      foregroundColor: LiquidGlassColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(17)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: LiquidGlassColors.accentPrimary,
        foregroundColor: LiquidGlassColors.background,
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: LiquidGlassColors.textPrimary,
        minimumSize: const Size(48, 52),
        side: const BorderSide(color: LiquidGlassColors.glassBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    dividerColor: LiquidGlassColors.glassBorder,
  );
}
