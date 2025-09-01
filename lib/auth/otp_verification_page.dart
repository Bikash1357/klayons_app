import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klayons/services/auth/signup_service.dart';
import 'package:klayons/services/auth/login_service.dart';
import 'package:klayons/utils/styles/fonts.dart';
import '../utils/colour.dart';
import '../screens/home_screen.dart';
import 'dart:async';

import '../utils/styles/button.dart'; // Adjust the import path as needed

class OTPVerificationPage extends StatefulWidget {
  final String email;
  final String purpose;

  const OTPVerificationPage({
    Key? key,
    required this.email,
    required this.purpose,
  }) : super(key: key);

  @override
  _OTPVerificationPageState createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _currentFocusIndex = 0;

  // Timer for resend functionality
  Timer? _resendTimer;
  int _resendCountdown = 0;
  bool _canResend = true;

  bool _isEmail(String input) {
    return input.contains('@');
  }

  @override
  void initState() {
    super.initState();
    // Auto focus on first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
      _currentFocusIndex = 0;
    });

    // Add focus listeners to track current focus
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          setState(() {
            _currentFocusIndex = i;
          });
        }
      });
    }

    // Start resend timer
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendCountdown = 30;
    });

    _resendTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with background image and back button
              Stack(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.35,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/Auth_Header_img.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // iOS-style back button
                  Positioned(
                    top: 16,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.black87,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  // Rounded overlay to blend with form section
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 15,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Title
              Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'Verify Profile',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),

              // OTP Form Section
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 8),

                    // Description Text
                    Text(
                      'We have sent you an OTP on ${_isEmail(widget.email) ? 'email' : 'WhatsApp'} at',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),

                    // Email/Phone display
                    Text(
                      widget.email,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.primaryOrange,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40),

                    // OTP Input Boxes with timer and resend
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      child: Column(
                        children: [
                          // OTP Boxes
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(
                              6,
                              (index) => _buildOTPBox(index),
                            ),
                          ),
                          SizedBox(height: 12),

                          // Timer and Resend Code aligned with OTP boxes
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Timer display on left - aligned with first OTP box
                              Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Text(
                                  '00:${_resendCountdown.toString().padLeft(2, '0')}',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),

                              // Resend Code on right - aligned with last OTP box
                              TextButton(
                                onPressed: (_canResend && !_isResending)
                                    ? _resendOTP
                                    : null,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  _isResending ? 'Resending...' : 'Resend Code',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: (_canResend && !_isResending)
                                        ? AppColors.primaryOrange
                                        : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 60),

                    // Submit Button using OrangeButton
                    OrangeButton(
                      onPressed: _verifyOTP,
                      isDisabled: _isLoading || !_isOTPComplete(),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Verifying...',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Submit',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOTPBox(int index) {
    bool isCurrentFocus = _currentFocusIndex == index;
    bool isFilled = _otpControllers[index].text.isNotEmpty;

    return Flexible(
      child: Container(
        width: 45,
        height: 50,
        margin: EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isCurrentFocus
                ? AppColors
                      .primaryOrange // Orange border only for focused field
                : Colors.grey[300]!, // Grey border for unfocused fields
            width: isCurrentFocus ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isCurrentFocus
              ? [
                  BoxShadow(
                    color: AppColors.primaryOrange.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: RawKeyboardListener(
          focusNode: FocusNode(),
          onKey: (RawKeyEvent event) {
            if (event is RawKeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.backspace) {
                if (_otpControllers[index].text.isEmpty && index > 0) {
                  // Move to previous field and clear it
                  _focusNodes[index - 1].requestFocus();
                  _otpControllers[index - 1].clear();
                  setState(() {
                    _currentFocusIndex = index - 1;
                  });
                } else if (_otpControllers[index].text.isNotEmpty) {
                  // Clear current field
                  _otpControllers[index].clear();
                  setState(() {});
                }
              }
            }
          },
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
            keyboardType: TextInputType.number,
            maxLength: 1,
            decoration: InputDecoration(
              border: InputBorder.none,
              counterText: '',
              contentPadding: EdgeInsets.zero,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              setState(() {}); // Refresh to update border color

              if (value.isNotEmpty) {
                // If user types a new digit, replace existing and move to next
                if (value.length > 1) {
                  _otpControllers[index].text = value.substring(
                    value.length - 1,
                  );
                }

                // Move to next field
                if (index < 5) {
                  _focusNodes[index + 1].requestFocus();
                  _currentFocusIndex = index + 1;
                } else {
                  // Last field, remove focus
                  _focusNodes[index].unfocus();
                }
              }
            },
            onTap: () {
              setState(() {
                _currentFocusIndex = index;
              });
              // Select all text when tapped, so typing replaces it
              _otpControllers[index].selection = TextSelection(
                baseOffset: 0,
                extentOffset: _otpControllers[index].text.length,
              );
            },
          ),
        ),
      ),
    );
  }

  String _getOTPCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  bool _isOTPComplete() {
    return _getOTPCode().length == 6;
  }

  Future<void> _verifyOTP() async {
    if (!_isOTPComplete()) {
      _showErrorMessage('Please enter complete 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Starting OTP verification for email: ${widget.email}');
      print('🎯 Purpose: ${widget.purpose}');
      print('🔢 OTP Code: ${_getOTPCode()}');

      // Use AuthService for OTP verification
      final result = await AuthService.verifyOTP(
        email: widget.email,
        otpCode: _getOTPCode(),
        purpose: widget.purpose,
      );

      print('📋 OTP verification result: $result');
      print('✅ Success: ${result.isSuccess}');
      print('💬 Message: ${result.message}');
      print('🔑 Token: ${result.token}');

      if (result.isSuccess) {
        print('🎉 OTP verification successful!');
        _showSuccessMessage(
          result.message.isNotEmpty
              ? result.message
              : 'Verification successful!',
        );

        // Save the authentication token
        if (result.token != null && result.token!.isNotEmpty) {
          await TokenStorage.saveToken(result.token!);
          print('💾 Token saved successfully: ${result.token}');

          // Navigate to home screen
          await Future.delayed(Duration(seconds: 1));
          if (mounted) {
            // Use direct navigation instead of named routes
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => KlayonsHomePage()),
              (route) => false,
            );
          }
        } else {
          print('⚠️ No token received');
          _showErrorMessage('Verification successful but no token received');
        }
      } else {
        print('❌ OTP verification failed');
        String errorMessage = result.message.isNotEmpty
            ? result.message
            : 'Invalid OTP. Please try again.';
        _showErrorMessage(errorMessage);
        _clearOTPFields();
      }
    } catch (e) {
      print('🚨 OTP verification error: $e');
      _showErrorMessage(
        'Network error. Please check your connection and try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend || _isResending) return;

    setState(() {
      _isResending = true;
    });

    try {
      print('Resending OTP to: ${widget.email} for purpose: ${widget.purpose}');

      // Use AuthService for consistent API handling
      final result = await AuthService.resendOTP(
        email: widget.email,
        purpose: widget.purpose,
      );

      print('Resend OTP result: $result');

      if (result.isSuccess) {
        print('OTP resent successfully');
        _showSuccessMessage(
          result.message.isNotEmpty
              ? result.message
              : 'OTP has been resent to your ${_isEmail(widget.email) ? 'email' : 'WhatsApp'}.',
        );
        _clearOTPFields();
        _focusNodes[0].requestFocus();
        _currentFocusIndex = 0;

        // Restart the timer
        _startResendTimer();
      } else {
        print('Failed to resend OTP: ${result.message}');
        _showErrorMessage(
          result.message.isNotEmpty ? result.message : 'Failed to resend OTP.',
        );
      }
    } catch (e) {
      print('Resend OTP error: $e');
      _showErrorMessage('Network error. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _clearOTPFields() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    setState(() {}); // Refresh UI
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}
