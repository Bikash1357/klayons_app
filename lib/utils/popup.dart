import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:klayons/utils/colour.dart';

class ConfirmationDialog {
  /// Shows a confirmation dialog with customizable content
  ///
  /// Parameters:
  /// - [context]: BuildContext for showing the dialog
  /// - [title]: Main title text (e.g., "Are you sure?")
  /// - [message]: Description/warning message
  /// - [confirmText]: Text for confirm button (e.g., "Delete Profile")
  /// - [cancelText]: Text for cancel button (default: "Cancel")
  /// - [confirmColor]: Color for confirm button (default: Colors.orange)
  /// - [iconColor]: Color for the warning icon (default: Colors.orange)
  /// - [icon]: Icon to display (default: Icons.error_outline)
  /// - [customIcon]: Custom widget to display instead of icon (e.g., SvgPicture)
  ///
  /// Returns: Future<bool?> - true if confirmed, false if cancelled, null if dismissed
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    String cancelText = 'Cancel',
    Color? confirmColor,
    Color? iconColor,
    IconData? icon,
    Widget? customIcon,
  }) {
    final Color buttonColor = confirmColor ?? AppColors.primaryOrange;
    final Color circleColor = iconColor ?? AppColors.primaryOrange;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular icon - FIXED to support customIcon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                child: customIcon != null
                    ? Center(child: customIcon) // Use custom widget if provided
                    : Icon(
                        icon ?? Icons.error_outline,
                        color: Colors.white,
                        size: 50,
                      ), // Fallback to IconData
              ),
              SizedBox(height: 24),

              // Title text
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 16),

              // Message text
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24),

              // Buttons in a row
              // Update the Buttons Row section in the ConfirmationDialog.show method:

              // Update the Buttons Row section in the ConfirmationDialog.show method:

              // Buttons in a row
              Row(
                children: [
                  // Cancel button - takes remaining space on the left
                  if (cancelText.isNotEmpty) ...[
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              cancelText,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                  ],

                  // Confirm button - always sticks to right, never wraps text
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: Text(
                        confirmText,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================
// USAGE EXAMPLES
// ============================================

// Example 1: Delete Profile Confirmation
void showDeleteProfileDialog(BuildContext context) async {
  final result = await ConfirmationDialog.show(
    context: context,
    title: 'Are you sure?',
    message:
        'Deleting this profile will unenroll from all the activities booked for the child!',
    confirmText: 'Delete Profile',
    cancelText: 'Cancel',
    confirmColor: Colors.orange,
    iconColor: Colors.orange,
    icon: Icons.error_outline,
  );

  if (result == true) {
    // User confirmed - proceed with deletion
    print('Profile deleted');
  } else {
    // User cancelled
    print('Deletion cancelled');
  }
}

// Example 2: Logout Confirmation
void showLogoutDialog(BuildContext context) async {
  final result = await ConfirmationDialog.show(
    context: context,
    title: 'Logout?',
    message: 'Are you sure you want to logout from your account?',
    confirmText: 'Logout',
    cancelText: 'Stay',
    confirmColor: Colors.red,
    iconColor: Colors.red,
    icon: Icons.logout,
  );

  if (result == true) {
    // User confirmed logout
    print('User logged out');
  }
}

// Example 3: Unenroll Confirmation
void showUnenrollDialog(BuildContext context) async {
  final result = await ConfirmationDialog.show(
    context: context,
    title: 'Confirm Unenrollment',
    message:
        'This action will remove the child from the activity. You can re-enroll later if needed.',
    confirmText: 'Yes, Unenroll',
    cancelText: 'No, Keep',
    confirmColor: Colors.deepOrange,
    iconColor: Colors.deepOrange,
  );

  if (result == true) {
    // Proceed with unenrollment
    print('Unenrolled from activity');
  }
}

// Example 4: Delete Item Confirmation
void showDeleteItemDialog(BuildContext context) async {
  final result = await ConfirmationDialog.show(
    context: context,
    title: 'Delete Item?',
    message: 'This item will be permanently deleted and cannot be recovered.',
    confirmText: 'Delete',
    confirmColor: Colors.red,
    iconColor: Colors.red,
    icon: Icons.delete_outline,
  );

  if (result == true) {
    // Delete the item
    print('Item deleted');
  }
}

// Example 5: Cancel Booking Confirmation
void showCancelBookingDialog(BuildContext context) async {
  final result = await ConfirmationDialog.show(
    context: context,
    title: 'Cancel Booking?',
    message:
        'Cancelling this booking may result in cancellation charges. Do you want to proceed?',
    confirmText: 'Yes, Cancel',
    cancelText: 'Keep Booking',
    confirmColor: Colors.orange[700]!,
    iconColor: Colors.orange[700]!,
    icon: Icons.cancel_outlined,
  );

  if (result == true) {
    // Cancel the booking
    print('Booking cancelled');
  }
}

// Example 6: With Custom SVG Icon (Your Use Case)
// Make sure to import: import 'package:flutter_svg/flutter_svg.dart';
void showDeleteWithSvgDialog(BuildContext context, String childName) async {
  final result = await ConfirmationDialog.show(
    context: context,
    title: 'Are you sure?',
    message:
        'Deleting this profile will unenroll $childName from all the activities booked for the child!',
    confirmText: 'Delete',
    cancelText: 'Cancel',
    confirmColor: Colors.red,
    iconColor: Colors.red,
    customIcon: SvgPicture.asset(
      'assets/App_icons/Exclamation_mark.svg',
      width: 50,
      height: 50,
      colorFilter: ColorFilter.mode(
        Colors.white, // White color to show on red background
        BlendMode.srcIn,
      ),
    ),
  );

  if (result == true) {
    // Proceed with deletion
    print('Child profile deleted');
  }
}
