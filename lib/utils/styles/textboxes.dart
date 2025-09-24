import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klayons/utils/colour.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? style;
  final bool showDynamicBorders;
  final double heightPercentage; // Percentage of screen height (0.0 to 1.0)
  final double? minHeight; // Minimum height constraint
  final double? maxHeight; // Maximum height constraint

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.focusNode,
    this.inputFormatters,
    this.style,
    this.showDynamicBorders = true,
    this.heightPercentage = 0.07, // Default 7% of screen height
    this.minHeight = 50.0, // Minimum height for very small screens
    this.maxHeight = 80.0, // Maximum height for very large screens
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  @override
  void initState() {
    super.initState();
    // Listen to controller changes to rebuild UI
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.showDynamicBorders) {
      setState(() {}); // Rebuild to update border color
    }
  }

  // Calculate height based on screen percentage with constraints
  double _getPercentageHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    double calculatedHeight = screenHeight * widget.heightPercentage;

    // Apply min/max constraints if provided
    if (widget.minHeight != null) {
      calculatedHeight = calculatedHeight.clamp(
        widget.minHeight!,
        double.infinity,
      );
    }
    if (widget.maxHeight != null) {
      calculatedHeight = calculatedHeight.clamp(0.0, widget.maxHeight!);
    }

    return calculatedHeight;
  }

  // Get responsive text size based on calculated height
  double _getResponsiveTextSize(BuildContext context) {
    final textFieldHeight = _getPercentageHeight(context);

    // Base text size on the height of the text field
    // Typically 25-35% of the text field height works well
    double baseTextSize = textFieldHeight * 0.3;

    // Clamp to reasonable bounds
    return baseTextSize.clamp(12.0, 24.0);
  }

  // Get responsive hint text size
  double _getResponsiveHintSize(BuildContext context) {
    final textSize = _getResponsiveTextSize(context);
    return (textSize * 0.9).clamp(
      10.0,
      20.0,
    ); // Slightly smaller than main text
  }

  // Get responsive padding based on height
  EdgeInsets _getResponsivePadding(BuildContext context) {
    final textFieldHeight = _getPercentageHeight(context);

    // Padding should be proportional to height
    double verticalPadding = textFieldHeight * 0.2; // 20% of height
    double horizontalPadding = textFieldHeight * 0.25; // 25% of height

    // Ensure minimum padding
    verticalPadding = verticalPadding.clamp(8.0, 16.0);
    horizontalPadding = horizontalPadding.clamp(12.0, 20.0);

    return EdgeInsets.symmetric(
      vertical: verticalPadding,
      horizontal: horizontalPadding,
    );
  }

  // Get responsive border radius based on height
  double _getResponsiveBorderRadius(BuildContext context) {
    final textFieldHeight = _getPercentageHeight(context);
    // Border radius should be proportional to height
    double radius = textFieldHeight * 0.15; // 15% of height
    return radius.clamp(8.0, 16.0);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textFieldHeight = _getPercentageHeight(context);
    final responsiveTextSize = _getResponsiveTextSize(context);
    final responsiveHintSize = _getResponsiveHintSize(context);
    final responsivePadding = _getResponsivePadding(context);
    final borderRadius = _getResponsiveBorderRadius(context);

    return Container(
      width: screenWidth, // Full screen width
      height: textFieldHeight,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        inputFormatters: widget.inputFormatters,
        style:
            widget.style ??
            TextStyle(
              fontSize: responsiveTextSize,
              fontWeight: FontWeight.w400,
            ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            fontSize: responsiveHintSize,
            color: Colors.grey[500],
          ),
          // Default border when inactive
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: Colors.grey, width: 1),
          ),
          // Enabled border (when not focused)
          enabledBorder: widget.showDynamicBorders
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide(
                    color: widget.controller.text.isNotEmpty
                        ? AppColors.primaryOrange
                        : Colors.grey[300]!,
                    width: widget.controller.text.isNotEmpty ? 2 : 1,
                  ),
                )
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
          // Focused border
          focusedBorder: widget.showDynamicBorders
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide(
                    color: AppColors.primaryOrange,
                    width: 2,
                  ),
                )
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide(
                    color: AppColors.primaryOrange,
                    width: 2,
                  ),
                ),
          contentPadding: responsivePadding,
        ),
      ),
    );
  }
}
