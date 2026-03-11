import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFCC0000);
  static const Color primaryDark = Color(0xFF990000);
  static const Color secondary = Color(0xFF1A1A4E);
  static const Color accent = Color(0xFF28A745);
  static const Color background = Color(0xFFF5F5F5);
  static const Color white = Colors.white;
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textGrey = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
  static const Color warning = Color(0xFFF59E0B);
  static const Color statusDelivered = Color(0xFFCC0000);
  static const Color statusProcessing = Color(0xFF3B82F6);
  static const Color statusPending = Color(0xFF6B7280);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color redeemGreen = Color(0xFF16A34A);
}

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 14,
    color: AppColors.white,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.textDark,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: AppColors.textGrey,
  );

  static const TextStyle points = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );
}

class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A4E), Color(0xFFCC0000)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A4E), Color(0xFFCC0000)],
  );
}
