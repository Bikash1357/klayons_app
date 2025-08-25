import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klayons/auth/signupPage.dart' hide OTPVerificationPage;
import 'package:klayons/utils/styles/button.dart';
import 'package:klayons/utils/styles/textButton.dart';
import 'package:klayons/utils/styles/textboxes.dart';
import 'package:klayons/services/auth/login_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'otp_verification_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isAgreeChecked = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top section with background image and branding overlay
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
                  // Branding overlay on the image
                  // Rounded overlay to blend with form section
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Form section
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Login form header
                    Center(
                      child: Text(
                        'Log in to your account',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),

                    SizedBox(height: 32),

                    // Email input field
                    CustomTextField(
                      hintText: "Email or Phone",
                      controller: _emailController,
                      keyboardType: TextInputType
                          .text, // Changed from emailAddress to text
                      style: TextStyle(
                        fontSize: 22, // Match OTP input size
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),

                    SizedBox(height: 32),

                    // Send OTP Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OrangeButton(
                        onPressed: _isLoading
                            ? null
                            : (_emailController.text.trim().isNotEmpty
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
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

                    SizedBox(height: 24),

                    // Divider with "or"
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: Colors.grey[300], thickness: 1),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: Colors.grey[300], thickness: 1),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // Register link
                    Center(
                      child: Column(
                        children: [
                          Text(
                            "Don't have an account?",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          CustomTextButton(
                            text: "Register here!",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignUnPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32),

                    // Terms and Privacy Policy moved to bottom
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(text: "By continuing, I agree to the "),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.alphabetic,
                              child: GestureDetector(
                                onTap: _launchTermsUrl,
                                child: Text(
                                  "Terms of Use",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFFF6B35),
                                  ),
                                ),
                              ),
                            ),
                            TextSpan(text: " & "),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.alphabetic,
                              child: GestureDetector(
                                onTap: _launchPrivacyPolicyUrl,
                                child: Text(
                                  "Privacy Policy",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFFF6B35),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add method for Terms of Use
  Future<void> _launchTermsUrl() async {
    const url = 'https://www.klayons.com/terms-of-use';
    await _launchUrl(url, 'Terms of Use');
  }

  // Updated privacy policy method
  Future<void> _launchPrivacyPolicyUrl() async {
    const url = 'https://www.klayons.com/privacy-policy';
    await _launchUrl(url, 'Privacy Policy');
  }

  // Generic URL launcher method
  Future<void> _launchUrl(String url, String title) async {
    try {
      final Uri uri = Uri.parse(url);

      // Try different launch modes in order of preference
      bool launched = false;

      // First, try platform default
      try {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e) {
        print('Platform default failed: $e');
      }

      // If that fails, try external application
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          print('External application failed: $e');
        }
      }

      // If that fails, try in-app web view
      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
            webViewConfiguration: const WebViewConfiguration(
              enableJavaScript: true,
              enableDomStorage: true,
            ),
          );
        } catch (e) {
          print('In-app webview failed: $e');
        }
      }

      // If still not launched, show fallback dialog
      if (!launched) {
        _showUrlFallbackDialog(url, title);
      }
    } catch (e) {
      print('Error launching URL: $e');
      _showUrlFallbackDialog(url, title);
    }
  }

  // Fallback dialog when URL launcher fails
  void _showUrlFallbackDialog(String url, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cannot open browser automatically.'),
              SizedBox(height: 16),
              Text('Please copy and paste this URL into your browser:'),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  url,
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: url));
                Navigator.of(context).pop();
                _showSuccessMessage('URL copied to clipboard!');
              },
              child: Text('Copy URL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendLoginOTP() async {
    String emailOrPhone = _emailController.text.trim();

    // Basic validation for email or phone
    if (emailOrPhone.isEmpty) {
      _showErrorMessage('Please enter your email or phone number');
      return;
    }

    // More thorough validation
    if (emailOrPhone.contains('@')) {
      // Validate email format
      if (!_isValidEmail(emailOrPhone)) {
        _showErrorMessage('Please enter a valid email address');
        return;
      }
    } else {
      // Validate phone format (basic check)
      if (!_isValidPhone(emailOrPhone)) {
        _showErrorMessage('Please enter a valid phone number');
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Sending login OTP to: $emailOrPhone');

      // Use the updated LoginAuthService
      final response = await LoginAuthService.sendLoginOTP(
        emailOrPhone: emailOrPhone,
      );

      print('📡 Login OTP response: ${response.isSuccess}');
      print('💬 Message: ${response.message}');

      if (response.isSuccess) {
        // OTP sent successfully
        _showSuccessMessage(
          response.message.isNotEmpty
              ? response.message
              : 'OTP sent successfully!',
        );

        // Navigate to OTP verification page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationPage(
              email: emailOrPhone, // Pass email or phone
              purpose: 'login',
            ),
          ),
        );
      } else {
        // Handle error responses
        String errorMessage = response.message.isNotEmpty
            ? response.message
            : 'Failed to send OTP. Please try again.';

        // Handle specific error cases
        if (response.httpStatusCode == 400) {
          errorMessage = response.message.isNotEmpty
              ? response.message
              : 'Account not found. Please register first.';
        } else if (response.httpStatusCode == 500) {
          errorMessage = 'Server error. Please try again later.';
        }

        _showErrorMessage(errorMessage);
      }
    } catch (e) {
      print('❌ Login OTP error: $e');
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

  // Email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Phone validation (basic check)
  bool _isValidPhone(String phone) {
    // Remove any non-digit characters for validation
    String digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Check if it's a valid phone number (between 7-15 digits)
    return digitsOnly.length >= 7 && digitsOnly.length <= 15;
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
    _emailController.dispose();
    super.dispose();
  }
}
