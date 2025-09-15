import 'package:flutter/material.dart';
import 'package:klayons/utils/colour.dart';

class AppTextStyles {
  // Get percentage-based font size
  static double _getPercentageBasedSize({
    required BuildContext context,
    required double heightPercent,
    required double widthPercent,
    double minSize = 10.0,
    double maxSize = 50.0,
  }) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    // Calculate size based on height percentage
    final heightBasedSize = screenHeight * (heightPercent / 100);

    // Calculate size based on width percentage
    final widthBasedSize = screenWidth * (widthPercent / 100);

    // Take the smaller of the two to ensure text fits well on all orientations
    // You can adjust this logic based on your preference
    final calculatedSize = (heightBasedSize + widthBasedSize) / 2;

    // Alternatively, you can use minimum of both:
    // final calculatedSize = math.min(heightBasedSize, widthBasedSize);

    // Clamp to prevent extreme sizes
    return calculatedSize.clamp(minSize, maxSize);
  }

  // Alternative method for more control over height vs width influence
  static double _getWeightedPercentageSize({
    required BuildContext context,
    required double heightPercent,
    required double widthPercent,
    double heightWeight = 0.6, // How much height influences the size
    double widthWeight = 0.4, // How much width influences the size
    double minSize = 10.0,
    double maxSize = 50.0,
  }) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    final heightBasedSize = screenHeight * (heightPercent / 100);
    final widthBasedSize = screenWidth * (widthPercent / 100);

    // Weighted average
    final calculatedSize =
        (heightBasedSize * heightWeight) + (widthBasedSize * widthWeight);

    return calculatedSize.clamp(minSize, maxSize);
  }

  // Responsive text styles using percentage approach
  static TextStyle headlineLarge(BuildContext context) {
    return TextStyle(
      fontSize: _getPercentageBasedSize(
        context: context,
        heightPercent: 4.0, // 4% of screen height
        widthPercent: 8.5, // 8.5% of screen width
        minSize: 28.0,
        maxSize: 40.0,
      ),
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle headlineSmall(BuildContext context) {
    return TextStyle(
      fontSize: _getPercentageBasedSize(
        context: context,
        heightPercent: 3.0, // 3% of screen height
        widthPercent: 6.5, // 6.5% of screen width
        minSize: 20.0,
        maxSize: 30.0,
      ),
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle titleLarge(BuildContext context) {
    return TextStyle(
      fontSize: _getPercentageBasedSize(
        context: context,
        heightPercent: 2.8, // 2.8% of screen height
        widthPercent: 6.0, // 6% of screen width
        minSize: 18.0,
        maxSize: 28.0,
      ),
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle formLarge(BuildContext context) {
    return TextStyle(
      fontSize: _getPercentageBasedSize(
        context: context,
        heightPercent: 2.3, // 2.3% of screen height
        widthPercent: 5.0, // 5% of screen width
        minSize: 16.0,
        maxSize: 22.0,
      ),
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle titleMedium(BuildContext context) {
    return TextStyle(
      fontSize: _getPercentageBasedSize(
        context: context,
        heightPercent: 2.0, // 2% of screen height
        widthPercent: 4.3, // 4.3% of screen width
        minSize: 14.0,
        maxSize: 20.0,
      ),
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle titleSmall(BuildContext context) {
    return TextStyle(
      fontSize: _getPercentageBasedSize(
        context: context,
        heightPercent: 1.8, // 1.8% of screen height
        widthPercent: 3.8, // 3.8% of screen width
        minSize: 12.0,
        maxSize: 18.0,
      ),
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle bodyLargeEmphasized(BuildContext context) {
    return TextStyle(
      fontSize: _getPercentageBasedSize(
        context: context,
        heightPercent: 2.0, // 2% of screen height
        widthPercent: 4.3, // 4.3% of screen width
        minSize: 14.0,
        maxSize: 20.0,
      ),
    );
  }

  static TextStyle bodyMedium(BuildContext context) {
    return TextStyle(
      fontSize: _getPercentageBasedSize(
        context: context,
        heightPercent: 1.8, // 1.8% of screen height
        widthPercent: 3.8, // 3.8% of screen width
        minSize: 12.0,
        maxSize: 18.0,
      ),
    );
  }

  static TextStyle bodySmall(BuildContext context) {
    return TextStyle(
      fontSize: _getPercentageBasedSize(
        context: context,
        heightPercent: 1.5, // 1.5% of screen height
        widthPercent: 3.2, // 3.2% of screen width
        minSize: 10.0,
        maxSize: 16.0,
      ),
    );
  }

  // Utility method to get screen dimensions for debugging
  static void debugScreenInfo(BuildContext context) {
    final size = MediaQuery.of(context).size;
    print('Screen Width: ${size.width}');
    print('Screen Height: ${size.height}');
    print('Aspect Ratio: ${size.aspectRatio}');
  }
}
