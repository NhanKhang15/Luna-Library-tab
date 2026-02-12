import 'package:flutter/material.dart';

/// Central color definitions for the app
class AppColors {
  AppColors._();

  // Primary Purple Accent
  static const Color primary = Color(0xFF9B59B6);
  static const Color primaryDark = Color(0xFF8E44AD);
  static const Color primaryLight = Color(0xFFBB8FCE);

  // Gradient for active buttons
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Background Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color cardBackground = Colors.white;
  static const Color surfaceLight = Color(0xFFF5F5F5);

  // Text Colors
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textMuted = Color(0xFF999999);
  static const Color textOnPrimary = Colors.white;

  // Border Colors
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderMedium = Color(0xFFCCCCCC);

  // Chip Colors
  static const Color chipSelected = Color(0xFFFCE4EC);
  static const Color chipBorder = Color(0xFFE91E63);
  static const Color chipText = Color(0xFFE91E63);

  // Category Icons
  static const Color categoryPsychology = Color(0xFFE8D5E8);
  static const Color categoryPhysiology = Color(0xFFFFE0B2);
  static const Color categoryLegal = Color(0xFFE3F2FD);

  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x26000000);

  // Overlay
  static const Color overlayDark = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);

  // Navigation
  static const Color navActive = primary;
  static const Color navInactive = Color(0xFF9E9E9E);

  // Badge
  static const Color badge = Color(0xFFE53935);
}
