import 'package:flutter/material.dart';

class AppColors {
  static const bgPrimary = Color(0xFF1A1613);
  static const bgSecondary = Color(0xFF14110E);
  static const bgCard = Color(0xFF211D19);
  static const bgCardHover = Color(0xFF23201B);
  static const bgInput = Color(0xFF17130F);
  static const border = Color(0xFF3A3028);
  static const textPrimary = Color(0xFFEDE6DC);
  static const textSecondary = Color(0xFF9A8F82);
  static const accentPrimary = Color(0xFFC17A54);
  static const accentSuccess = Color(0xFF7A9B7E);
  static const accentWarning = Color(0xFFC17A54);
  static const accentDanger = Color(0xFFB8563A);
  static const accentInfo = Color(0xFF8A9BB0);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgPrimary,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accentPrimary,
      secondary: AppColors.accentInfo,
      error: AppColors.accentDanger,
      surface: AppColors.bgCard,
      onSurface: AppColors.textPrimary,
    ),
    cardTheme: CardThemeData(
      color: AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 27,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgInput,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.accentPrimary,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textPrimary),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: AppColors.bgSecondary,
      indicatorColor: AppColors.accentPrimary.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? AppColors.accentPrimary
              : AppColors.textSecondary,
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.accentPrimary
              : AppColors.textSecondary,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accentPrimary,
      foregroundColor: AppColors.bgPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(17)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentPrimary,
        foregroundColor: AppColors.bgPrimary,
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    dividerColor: AppColors.border,
  );
}
