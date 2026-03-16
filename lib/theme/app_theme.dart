import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const bg = Color(0xFF0A0A0F);
  static const surface = Color(0xFF0E0E16);
  static const card = Color(0xFF13131E);
  static const cardBorder = Color(0xFF1E1E2E);
  static const elevated = Color(0xFF1A1A2A);

  // Brand
  static const primary = Color(0xFF6366F1);
  static const primaryLight = Color(0xFF818CF8);
  static const primaryMuted = Color(0x1F6366F1);
  static const primaryBorder = Color(0x336366F1);

  // Text
  static const textPrimary = Color(0xFFE2E2F0);
  static const textSecondary = Color(0xFFC2C2D8);
  static const textMuted = Color(0xFF4A4A6A);
  static const textDim = Color(0xFF2A2A4A);

  // Status
  static const success = Color(0xFF22C55E);
  static const successMuted = Color(0x1A22C55E);
  static const successBorder = Color(0x3322C55E);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.surface,
          background: AppColors.bg,
        ),
        fontFamily: 'DMSans',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bg,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primaryLight,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      );
}
