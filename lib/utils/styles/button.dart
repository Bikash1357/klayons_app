import 'package:flutter/material.dart';
import 'package:klayons/utils/colour.dart';
import 'package:klayons/utils/styles/fonts.dart';

class OrangeButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isDisabled;

  const OrangeButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive height based on screen height
    //     // This ensures the button scales proportionally with screen size
    double buttonHeight = screenHeight * 0.045; // 4.5% of screen height

    // Set minimum and maximum height bounds for better UX
    buttonHeight = buttonHeight.clamp(50.0, 70.0);

    // Alternative approach: You can also use screen width for calculation
    // double buttonHeight = screenWidth * 0.15; // 15% of screen width
    // buttonHeight = buttonHeight.clamp(45.0, 65.0);

    return SizedBox(
      height: buttonHeight,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled
              ? AppColors.textInactive
              : AppColors.primaryOrange,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: child,
      ),
    );
  }
}
