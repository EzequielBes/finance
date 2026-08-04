import 'package:flutter/material.dart';

class AppColors {
  static const bgPrimary = Color(0xFF1A1613);
  static const bgSecondary = Color(0xFF14110E);
  static const bgCard = Color(0xFF211D19);
  static const bgCardHover = Color(0xFF23201B);
  static const bgInput = Color(0xFF17130F);
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgInput,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textPrimary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bgSecondary,
      selectedItemColor: AppColors.accentPrimary,
      unselectedItemColor: AppColors.textPrimary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentPrimary,
        foregroundColor: AppColors.bgPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}
