import 'package:flutter/material.dart';
import 'package:klayons/utils/colour.dart';

class AppTextStyles {
  // Method to get screen size factor for responsive text
  static double _getScaleFactor(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    // Calculate scale factor based on screen width
    // Base width assumption: 375px (iPhone SE/standard mobile)
    double widthScale = screenWidth / 375.0;

    // Consider both dimensions for better scaling
    double heightScale = screenHeight / 812.0; // Base height: iPhone X/11

    // Use average of both scales, with width having more influence
    double scaleFactor = (widthScale * 0.7 + heightScale * 0.3);

    // Clamp the scale factor to prevent extreme scaling
    return scaleFactor.clamp(0.8, 1.3);
  }

  // Alternative: Simple approach using just screen width
  static double _getSimpleScaleFactor(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 350) return 0.9; // Small phones
    if (screenWidth < 400) return 1.0; // Medium phones
    if (screenWidth < 450) return 1.1; // Large phones
    return 1.2; // Tablets/very large phones
  }

  // Responsive text styles
  static TextStyle headlineLarge(BuildContext context) {
    final scale = _getScaleFactor(context);
    return TextStyle(
      fontSize: (32 * scale).clamp(28.0, 40.0),
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle headlineSmall(BuildContext context) {
    final scale = _getScaleFactor(context);
    return TextStyle(
      fontSize: (24 * scale).clamp(20.0, 30.0),
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle titleLarge(BuildContext context) {
    final scale = _getScaleFactor(context);
    return TextStyle(
      fontSize: (22 * scale).clamp(18.0, 28.0),
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle formLarge(BuildContext context) {
    final scale = _getScaleFactor(context);
    return TextStyle(
      fontSize: (18 * scale).clamp(16.0, 22.0),
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle titleMedium(BuildContext context) {
    final scale = _getScaleFactor(context);
    return TextStyle(
      fontSize: (16 * scale).clamp(14.0, 20.0),
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle titleSmall(BuildContext context) {
    final scale = _getScaleFactor(context);
    return TextStyle(
      fontSize: (14 * scale).clamp(12.0, 18.0),
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle bodyLargeEmphasized(BuildContext context) {
    final scale = _getScaleFactor(context);
    return TextStyle(fontSize: (16 * scale).clamp(14.0, 20.0));
  }

  static TextStyle bodyMedium(BuildContext context) {
    final scale = _getScaleFactor(context);
    return TextStyle(fontSize: (14 * scale).clamp(12.0, 18.0));
  }

  static TextStyle bodySmall(BuildContext context) {
    final scale = _getScaleFactor(context);
    return TextStyle(fontSize: (12 * scale).clamp(10.0, 16.0));
  }
}
