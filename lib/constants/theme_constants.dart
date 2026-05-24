import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF3949AB);
  static const primaryLight = Color(0xFF5C6BC0);
  static const primaryDark = Color(0xFF1A237E);
  static const secondary = Color(0xFF2196F3);
  static const accent = Color(0xFF7C4DFF);

  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFF44336);
  static const info = Color(0xFF2196F3);

  static const background = Color(0xFFF8F9FA);
  static const surface = Colors.white;
  static const cardBackground = Colors.white;

  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const textLight = Color(0xFF9CA3AF);

  static const gradientStart = Color(0xFF3949AB);
  static const gradientEnd = Color(0xFF2196F3);

  static const gradeA = Color(0xFF10B981);
  static const gradeB = Color(0xFF3B82F6);
  static const gradeC = Color(0xFFF59E0B);
  static const gradeD = Color(0xFFF97316);
  static const gradeF = Color(0xFFEF4444);
}

class AppTheme {
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  static const EdgeInsets paddingScreen = EdgeInsets.all(16);
  static const EdgeInsets paddingCard = EdgeInsets.all(20);
  static const EdgeInsets paddingItem = EdgeInsets.all(12);

  static BoxDecoration glassCard = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.9),
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration gradientCard = BoxDecoration(
    gradient: const LinearGradient(
      colors: [AppColors.gradientStart, AppColors.gradientEnd],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.3),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration whiteCard = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration outlinedCard = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(color: Colors.grey.shade200),
  );

  static EdgeInsets screenPadding = const EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
  );

  static EdgeInsets cardPadding = const EdgeInsets.all(20);
}

class AppTextStyles {
  static const h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const bodySmall = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const caption = TextStyle(
    fontSize: 11,
    color: AppColors.textLight,
    fontWeight: FontWeight.w500,
  );

  static const button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static TextStyle gradeColor(String letter) {
    switch (letter) {
      case 'A+':
      case 'A':
        return const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.gradeA,
        );
      case 'A-':
      case 'B+':
      case 'B':
        return const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.gradeB,
        );
      case 'C+':
      case 'C':
        return const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.gradeC,
        );
      default:
        return const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.gradeD,
        );
    }
  }

  static Color gradeBgColor(String letter) {
    switch (letter) {
      case 'A+':
      case 'A':
        return AppColors.gradeA;
      case 'A-':
      case 'B+':
      case 'B':
        return AppColors.gradeB;
      case 'C+':
      case 'C':
        return AppColors.gradeC;
      default:
        return AppColors.gradeD;
    }
  }
}
