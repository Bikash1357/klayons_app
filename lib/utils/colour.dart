import 'dart:ui';

import 'package:flutter/cupertino.dart';

class AppColors {
  AppColors._(); //its a private constructor.

  //primary colours - Used for buttons, highlights, main app color.
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFF8A5A);
  static const Color primaryDark = Color(0xFFE55A2B);

  //secondary colour - A supporting theme color used with primary for contrast.
  static const Color secondary = Color(0xFFF4A261);

  //Background & Surface Colors - Used for page background (Scaffold), cards, containers, etc.
  static const Color background = Color(0xFFFFFBF5);
  static const Color surface = Color(0xFFFFFFFF);

  //Text Colors - Used for text elements. textOnPrimary is white—used on colored backgrounds like buttons.
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  //Accent Colors - Used for icons, links, focus states, etc.
  static const Color accent = Color(0xFF4A90E2);

  //Neutral Colors (Gray Scale) - Used for borders, placeholders, disabled states, etc.
  static const Color grey100 = Color(0xFF000000);

  //Gradient Colors - Used for beautiful UI effects on buttons, backgrounds, cards, etc.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFF4A261)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFFFFBF5), Color(0xFFFFF8F0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFFF8F0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Border Colors & Shadows - These are used for container borders, elevation shadows.
  static const Color border = Color(0xFFA0AEC0);
  static const Color shadow = Color(0x33000000);

  // Input Colors - Used for textfields, dropdowns, and form-related styling.
  static const Color inputBackground = Color(0xFFF7FAFC);
  static const Color inputBorder = Color(0xFFE2E8F0);
  static const Color inputFocus = Color(0xFFFF6B35);
  static const Color inputError = Color(0xFFE53E3E);

  // Status Colors - Used for online/offline indicators or tags.
  static const Color online = Color(0xFF48BB78);
  static const Color offline = Color(0xFF718096);
  static const Color pending = Color(0xFFED8936);
}
