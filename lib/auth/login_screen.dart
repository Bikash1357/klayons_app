import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:klayons/utils/styles/button.dart';
import 'package:klayons/utils/styles/checkbox.dart';
import 'package:klayons/utils/styles/klayonsFont.dart';
import 'package:klayons/utils/styles/textButton.dart';
import 'package:klayons/utils/styles/textboxes.dart';
import 'package:klayons/config/api_config.dart';
import 'package:klayons/services/login_auth_service.dart'; // Import your auth service

import 'otp_verification_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isAgreeChecked = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top,
            ),
            child: Column(
              children: [
                // Top section with background image
                Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/bg.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.1),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Form section
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  transform: Matrix4.translationValues(0, -24, 0),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Welcome text
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Welcome Back',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Sign in to continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 32),

                        // Email input field
                        Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        CustomTextField(
                          hintText: "Enter your email",
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        SizedBox(height: 20),

                        // Password input field
                        Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        CustomTextField(
                          hintText: "Enter your password",
                          controller: _passwordController,
                          obscureText: true,
                        ),

                        SizedBox(height: 24),

                        // Terms and Privacy Policy
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomeCheckbox(
                              value: _isAgreeChecked,
                              onChanged: (bool? value) {
                                setState(() {
                                  _isAgreeChecked = value ?? false;
                                });
                              },
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    "By clicking, I agree to the ",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  CustomTextButton(
                                    text: "Privacy Policy",
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 32),

                        // Send OTP Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OrangeButton(
                            onPressed: _isLoading
                                ? null
                                : (_isAgreeChecked &&
                                          _emailController.text
                                              .trim()
                                              .isNotEmpty &&
                                          _passwordController.text
                                              .trim()
                                              .isNotEmpty
                                      ? _sendLoginOTP
                                      : null),
                            child: _isLoading
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        "Sending OTP...",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    "Send OTP",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        SizedBox(height: 32),

                        // Register link
                        Center(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              CustomTextButton(
                                text: "Register Here",
                                onPressed: () {
                                  Navigator.pushNamed(context, '/register');
                                },
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendLoginOTP() async {
    // Basic email validation
    if (!_isValidEmail(_emailController.text.trim())) {
      _showErrorMessage('Please enter a valid email address');
      return;
    }

    if (_passwordController.text.trim().length < 8) {
      _showErrorMessage('Password must be at least 8 characters long');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getFullUrl(ApiConfig.loginEndpoint)),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Check if token is provided immediately (some APIs do this)
        if (data.containsKey('token') || data.containsKey('access_token')) {
          String token = data['token'] ?? data['access_token'];
          Map<String, dynamic> userData = data['user'] ?? {};

          // Save authentication data using your auth service
          await LoginAuthService.saveAuthData(token: token, userData: userData);

          print('Authentication data saved via LoginAuthService');
        }

        // Login credentials verified, OTP sent
        _showSuccessMessage(data['message'] ?? 'OTP sent to your email');

        // Navigate to OTP verification page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationPage(
              email: _emailController.text.trim(),
              purpose: 'login',
            ),
          ),
        );
      } else {
        // Handle error responses
        String errorMessage = data['message'] ?? 'Login failed';
        if (data.containsKey('error')) {
          errorMessage = data['error'];
        } else if (data.containsKey('detail')) {
          errorMessage = data['detail'];
        }
        _showErrorMessage(errorMessage);
      }
    } catch (e) {
      _showErrorMessage(
        'Network error. Please check your connection and try again.',
      );
      print('Login error: $e'); // For debugging
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showSuccessMessage(String message) {
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

  void _showErrorMessage(String message) {
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
