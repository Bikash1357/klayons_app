import 'package:flutter/material.dart';
import 'package:klayons/utils/colour.dart';
import 'fonts.dart';

class CustomTextButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color textColor;
  final double? fontSize; // Made nullable for responsive sizing
  final bool useResponsiveSize; // Option to use responsive or fixed size

  const CustomTextButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.textColor = AppColors.primaryOrange,
    this.fontSize, // If null, will use responsive sizing
    this.useResponsiveSize = true, // Default to responsive
  }) : super(key: key);

  // Calculate responsive font size
  double _getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = MediaQuery.of(context).size.width;

    double scaleFactor;
    if (screenWidth < 350) {
      scaleFactor = 1.0; // Small phones
    } else if (screenWidth < 400) {
      scaleFactor = 1.1; // Medium phones
    } else if (screenWidth < 450) {
      scaleFactor = 1.2; // Large phones
    } else {
      scaleFactor = 1.3; // Very large phones/tablets
    }

    return (baseFontSize * scaleFactor).clamp(
      baseFontSize * 0.8,
      baseFontSize * 1.3,
    );
  }

  // Calculate responsive padding for better touch targets
  EdgeInsets _getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Base padding values
    double horizontalPadding = 8.0;
    double verticalPadding = 4.0;

    // Scale based on screen size
    double scaleFactor = (screenWidth / 375.0).clamp(0.8, 1.2);

    return EdgeInsets.symmetric(
      horizontal: (horizontalPadding * scaleFactor).clamp(6.0, 12.0),
      vertical: (verticalPadding * scaleFactor).clamp(2.0, 8.0),
    );
  }

  // Calculate responsive minimum size for better accessibility
  Size _getResponsiveMinimumSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Ensure minimum touch target size for accessibility
    double minHeight = screenWidth < 350 ? 32.0 : 36.0;
    double minWidth = screenWidth < 350 ? 48.0 : 54.0;

    return Size(minWidth, minHeight);
  }

  @override
  Widget build(BuildContext context) {
    // Determine final font size
    final double finalFontSize = useResponsiveSize
        ? (fontSize != null
              ? _getResponsiveFontSize(context, fontSize!)
              : _getResponsiveFontSize(context, 14.0)) // Default base size
        : fontSize ?? 14.0;

    final responsivePadding = useResponsiveSize
        ? _getResponsivePadding(context)
        : EdgeInsets.zero;

    final responsiveMinSize = useResponsiveSize
        ? _getResponsiveMinimumSize(context)
        : const Size(0, 0);

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: responsivePadding,
        minimumSize: responsiveMinSize,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        // Add visual feedback
        overlayColor: textColor.withOpacity(0.1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: finalFontSize,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
