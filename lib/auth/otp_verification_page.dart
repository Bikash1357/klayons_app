import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:klayons/config/api_config.dart';
import 'package:klayons/services/login_auth_service.dart';

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
        child: Column(
          children: [
            // Header with background image
            Container(
              height: MediaQuery.of(context).size.height * 0.35,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // OTP Form Section
            Expanded(
              child: Container(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 40),

                    // Title Text
                    Text(
                      'We have sent you an One-Time\nPassword on your email',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40),

                    // OTP Input Boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        6,
                        (index) => _buildOTPBox(index),
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

                    Spacer(),

                    // Submit Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLoading
                              ? Colors.grey[300]
                              : Colors
                                    .grey[600], // Keep grey for submit button as in image
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 0,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOTPBox(int index) {
    return Container(
      width: 50,
      height: 50,
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
            // Move to next field
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              // Last field, remove focus
              _focusNodes[index].unfocus();
            }
          } else {
            // Move to previous field on backspace
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
        },
        onTap: () {
          // Clear the field when tapped
          _otpControllers[index].clear();
        },
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
      final response = await http.post(
        Uri.parse(ApiConfig.getFullUrl('/api/auth/verify-otp/')),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'email': widget.email,
          'otp_code': _getOTPCode(),
          'purpose': widget.purpose,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // OTP verification successful
        _showSuccessMessage(data['message'] ?? 'Verification successful!');

        // Save authentication data using your auth service
        if (data.containsKey('token') || data.containsKey('access_token')) {
          String token = data['token'] ?? data['access_token'];
          Map<String, dynamic> userData = data['user'] ?? {};

          // Use your LoginAuthService to save authentication data
          await LoginAuthService.saveAuthData(token: token, userData: userData);

          print('Authentication data saved successfully via LoginAuthService');
        } else {
          // If no token in response, but user data is available, update user data only
          if (data.containsKey('user')) {
            final existingToken = await LoginAuthService.getToken();
            if (existingToken != null) {
              await LoginAuthService.saveAuthData(
                token: existingToken,
                userData: data['user'],
              );
            }
          }
        }

        // Wait a moment to show success message
        await Future.delayed(Duration(seconds: 1));

        // Navigate to home or dashboard
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }

        // If you don't have named routes, use this instead:
        // Navigator.pushAndRemoveUntil(
        //   context,
        //   MaterialPageRoute(builder: (context) => HomePage()),
        //   (route) => false,
        // );
      } else {
        _showErrorMessage(data['message'] ?? 'Invalid OTP. Please try again.');
        _clearOTPFields();
      }
    } catch (e) {
      _showErrorMessage(
        'Network error. Please check your connection and try again.',
      );
      print('OTP verification error: $e'); // For debugging
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
      final response = await http.post(
        Uri.parse(ApiConfig.getFullUrl('/api/auth/resend-otp/')),
        headers: ApiConfig.getHeaders(),
        body: json.encode({'email': widget.email, 'purpose': widget.purpose}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _showSuccessMessage('OTP has been resent to your email.');
        _clearOTPFields();
        _focusNodes[0].requestFocus();
      } else {
        _showErrorMessage(data['message'] ?? 'Failed to resend OTP.');
      }
    } catch (e) {
      _showErrorMessage('Network error. Please try again.');
      print('Resend OTP error: $e'); // For debugging
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
          content: Text(message),
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
          content: Text(message),
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
