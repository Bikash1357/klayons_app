// File: lib/widgets/bottom_success_message.dart
import 'package:flutter/material.dart';
import 'package:klayons/utils/colour.dart';

// Static UI functions for bottom messages
class BottomMessages {
  // Bottom Success Message UI
  static Widget buildSuccessMessage({
    required String message,
    required bool isVisible,
    VoidCallback? onDismiss,
  }) {
    if (!isVisible) return SizedBox.shrink();

    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFE8F5E8), // Light green background
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(0xFF4CAF50),
            width: 1,
          ), // Green border
        ),
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Success checkmark icon
            Container(
              margin: EdgeInsets.only(right: 12),
              child: Icon(
                Icons.check_circle,
                color: Color(0xFF4CAF50), // Green color
                size: 20,
              ),
            ),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Color(0xFF2E7D32), // Dark green text
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, color: Color(0xFF4CAF50), size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom Error Message UI
  static Widget buildErrorMessage({
    required String message,
    required bool isVisible,
    VoidCallback? onDismiss,
  }) {
    if (!isVisible) return SizedBox.shrink();

    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFFFEBEE), // Light red background
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE57373), width: 1),
        ),
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              margin: EdgeInsets.only(right: 12),
              child: Icon(
                Icons.error_outline,
                color: Color(0xFFD32F2F),
                size: 20,
              ),
            ),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Color(0xFFD32F2F), // Dark red text
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, color: Color(0xFFD32F2F), size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// Enhanced mixin for both error and success handling
mixin BottomMessageHandler<T extends StatefulWidget> on State<T> {
  bool _showBottomError = false;
  String _bottomErrorMessage = '';
  bool _showBottomSuccess = false;
  String _bottomSuccessMessage = '';

  // Error methods
  void showBottomError(String message) {
    setState(() {
      _showBottomError = true;
      _bottomErrorMessage = message;
      // Hide success if showing
      _showBottomSuccess = false;
    });

    // Auto-hide after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        hideBottomError();
      }
    });
  }

  void hideBottomError() {
    setState(() {
      _showBottomError = false;
      _bottomErrorMessage = '';
    });
  }

  // Success methods
  void showBottomSuccess(String message) {
    setState(() {
      _showBottomSuccess = true;
      _bottomSuccessMessage = message;
      // Hide error if showing
      _showBottomError = false;
    });

    // Auto-hide after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        hideBottomSuccess();
      }
    });
  }

  void hideBottomSuccess() {
    setState(() {
      _showBottomSuccess = false;
      _bottomSuccessMessage = '';
    });
  }

  // Build methods using static UI functions
  Widget buildBottomErrorMessage() {
    return BottomMessages.buildErrorMessage(
      message: _bottomErrorMessage,
      isVisible: _showBottomError,
      onDismiss: hideBottomError,
    );
  }

  Widget buildBottomSuccessMessage() {
    return BottomMessages.buildSuccessMessage(
      message: _bottomSuccessMessage,
      isVisible: _showBottomSuccess,
      onDismiss: hideBottomSuccess,
    );
  }

  // Combined widget that shows either error or success
  Widget buildBottomMessages() {
    return Stack(
      children: [buildBottomErrorMessage(), buildBottomSuccessMessage()],
    );
  }
}
