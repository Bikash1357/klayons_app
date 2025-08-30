import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klayons/services/auth/signup_service.dart';
import 'package:klayons/services/auth/login_service.dart';

import '../screens/home_screen.dart';

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
  bool _isEmail(String input) {
    return input.contains('@');
  }

  bool _isLoading = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    // Auto focus on first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
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
              // Header with background image and back button - UPDATED TO 45%
              Stack(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.45,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                          'assets/images/cropped_cover_img.png',
                        ),
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
                  // Rounded overlay to blend with form section with "Verify OTP" text
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Text(
                            'Verify OTP',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // OTP Form Section - ADJUSTED FOR NEW LAYOUT
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 8,
                    ), // Reduced spacing since text is now in overlay
                    // Title Text
                    Text(
                      'We have sent otp on your ${_isEmail(widget.email) ? 'email' : 'Whatsapp'}',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),

                    // Show email for clarity
                    Text(
                      widget.email,
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xFFFF6B35),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40),

                    // OTP Input Boxes
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          6,
                          (index) => _buildOTPBox(index),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),

                    // Resend Code
                    TextButton(
                      onPressed: _isResending ? null : _resendOTP,
                      child: Text(
                        _isResending ? 'Resending...' : 'Resend Code',
                        style: TextStyle(
                          color: _isResending
                              ? Colors.grey
                              : Color(0xFFFF6B35), // Orange color
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    SizedBox(height: 60), // Adjusted spacing
                    // Submit Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLoading
                              ? Colors.grey[300]
                              : Color(
                                  0xFFFF6B35,
                                ), // Match registration page color
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 2,
                        ),
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
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'Submit',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w600,
                                ),
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
    return Flexible(
      child: Container(
        width: 50,
        height: 55,
        margin: EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border.all(
            color: _otpControllers[index].text.isNotEmpty
                ? Color(0xFFFF6B35) // Orange border when filled
                : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
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
                  setState(() {});
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
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
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
                } else {
                  // Last field, remove focus
                  _focusNodes[index].unfocus();
                }
              }
            },
            onTap: () {
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
              MaterialPageRoute(
                builder: (context) => KlayonsHomePage(),
              ), // Make sure to import this
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
              : 'OTP has been resent to your email.',
        );
        _clearOTPFields();
        _focusNodes[0].requestFocus();
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
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}
