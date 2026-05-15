import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF5B4FCF);
  static const primaryLight = Color(0xFF7B6FE8);
  static const primaryDark = Color(0xFF3D32A8);
  static const accent = Color(0xFF4ECDC4);
  static const coral = Color(0xFFFF9A3C);
  static const yellow = Color(0xFFFFE066);
  static const success = Color(0xFF06D6A0);
  static const warning = Color(0xFFFFBE0B);
  static const error = Color(0xFFEF476F);
  static const surface = Color(0xFFF7F6FF);
  static const cardBg = Colors.white;
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B6B8A);
  static const divider = Color(0xFFEEEEF5);

  static const darkSurface = Color(0xFF12121A);
  static const darkCardBg = Color(0xFF1E1E2E);
  static const darkTextPrimary = Color(0xFFE8E8F0);
  static const darkTextSecondary = Color(0xFF9B9BB8);
  static const darkDivider = Color(0xFF2A2A3E);
  static const darkInputBg = Color(0xFF252538);
  static const darkBorder = Color(0xFF3A3A52);

  static const List<Color> heroGradient = [Color(0xFF5B4FCF), Color(0xFF7B6FE8)];
  static const List<Color> heroGradientWarm = [Color(0xFF5B4FCF), Color(0xFF8B5CF6)];
  static const List<Color> cardGradientTeal = [Color(0xFF4ECDC4), Color(0xFF38B2AC)];
  static const List<Color> cardGradientCoral = [Color(0xFFFF9A3C), Color(0xFFFF6B35)];
}

class AppThemeColors {
  final bool isDark;
  AppThemeColors(this.isDark);

  Color get surface => isDark ? AppColors.darkSurface : AppColors.surface;
  Color get cardBg => isDark ? AppColors.darkCardBg : AppColors.cardBg;
  Color get textPrimary => isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get textSecondary => isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get divider => isDark ? AppColors.darkDivider : AppColors.divider;
  Color get inputBg => isDark ? AppColors.darkInputBg : const Color(0xFFF8F8FC);
  Color get border => isDark ? AppColors.darkBorder : const Color(0xFFE0E0F0);
  Color get shadowColor => isDark ? Colors.black.withOpacity(0.3) : const Color(0x145B4FCF);
  Color get appBarBg => isDark ? AppColors.darkCardBg : Colors.white;
  Color get scaffoldBg => isDark ? AppColors.darkSurface : AppColors.surface;
  Color get bottomSheetBg => isDark ? AppColors.darkCardBg : Colors.white;
}

class AppShadows {
  static List<BoxShadow> card(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))]
        : [BoxShadow(color: const Color(0xFF5B4FCF).withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))];
  }

  static List<BoxShadow> hero(BuildContext context) {
    return [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.35),
        blurRadius: 24,
        offset: const Offset(0, 10),
        spreadRadius: -4,
      ),
    ];
  }
}
