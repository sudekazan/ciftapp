import 'package:flutter/material.dart';

class AppColors {
  // Brand Romantic Primary Colors
  static const Color primary = Color(0xFFE25B6C); // Vibrant Rose
  static const Color primaryDark = Color(0xFFB83A4B);
  static const Color primaryLight = Color(0xFFFF8FA3);
  static const Color primarySoft = Color(0xFFFFF0F3);

  // Secondary & Accents
  static const Color secondary = Color(0xFF7E57C2); // Dreamy Purple / Evening
  static const Color secondaryLight = Color(0xFFB39DDB);
  static const Color secondarySoft = Color(0xFFF3E5F5);

  static const Color accentPeach = Color(0xFFFF8E72);
  static const Color accentTeal = Color(0xFF26A69A);
  static const Color accentGold = Color(0xFFFFB300);

  // Neutrals - Light Theme
  static const Color background = Color(0xFFFAFAFC);
  static const Color surface = Colors.white;
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF222B45);
  static const Color textSecondary = Color(0xFF8F9BB3);
  static const Color textMuted = Color(0xFFB5BAC9);
  static const Color divider = Color(0xFFEDF1F7);

  // Neutrals - Dark Theme
  static const Color darkBackground = Color(0xFF14171F);
  static const Color darkSurface = Color(0xFF1D222E);
  static const Color darkCardBg = Color(0xFF232938);
  static const Color darkTextPrimary = Color(0xFFF7F9FC);
  static const Color darkTextSecondary = Color(0xFF8F9BB3);
  static const Color darkDivider = Color(0xFF2D3548);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE25B6C), Color(0xFFFF7E67)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heartGradient = LinearGradient(
    colors: [Color(0xFFFF5376), Color(0xFFFF8E72)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF7E57C2), Color(0xFF5C6BC0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF282E3E), Color(0xFF1E2330)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
