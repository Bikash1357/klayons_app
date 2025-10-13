import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klayons/auth/signupPage.dart' hide OTPVerificationPage;
import 'package:klayons/utils/styles/button.dart';
import 'package:klayons/utils/styles/fonts.dart';
import 'package:klayons/utils/styles/textButton.dart';
import 'package:klayons/utils/styles/textboxes.dart';
import 'package:klayons/services/auth/login_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/styles/errorMessage.dart';
import 'otp_verification_page.dart';
import '../utils/colour.dart';

// Import the reusable error widget
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _emailFocusNode = FocusNode();
  bool _isLoading = false;
  bool _showGuestButton = false;

  // Guest mode constants - For App Store/Play Store review only
  // Token is pre-configured and saved in backend for review purposes
  // Does not affect regular user authentication flow
  static const String GUEST_EMAIL = "guest@klayons.com";
  static const String GUEST_TOKEN =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjo0OTEzOTM3MjU2LCJpYXQiOjE3NjAzMzcyNTYsImp0aSI6IjkzNzY3NTg0NmFlYzRlYmRiN2JhNGMyM2I1ZjhjMmNmIiwidXNlcl9pZCI6IjE0In0.AyeWhdym62tg0bD2e9Zf2S6P8EidE0nIimaOldsl4xM";

  // Error and success state management
  String? _errorMessage;
  String? _successMessage;
  bool _showError = false;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();

    // Add listener to text controller to enable/disable button
    _emailController.addListener(_onTextChanged);

    // Add focus listener to auto-scroll when keyboard appears
    _emailFocusNode.addListener(_onFocusChanged);
  }

  void _onTextChanged() {
    setState(() {
      // Check if guest email is entered (for app store reviewers only)
      // Regular users won't see this option unless they know the exact email
      _showGuestButton =
          _emailController.text.trim().toLowerCase() ==
          GUEST_EMAIL.toLowerCase();

      // Clear messages when user starts typing
      if (_showError) {
        _showError = false;
        _errorMessage = null;
      }
      if (_showSuccess) {
        _showSuccess = false;
        _successMessage = null;
      }
    });
  }

  void _onFocusChanged() {
    if (_emailFocusNode.hasFocus) {
      // Delay scroll to allow keyboard to appear
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  // Method to show error message
  void _showErrorMessage(String message) {
    setState(() {
      _errorMessage = message;
      _showError = true;
      _showSuccess = false;
      _successMessage = null;
    });
  }

  // Method to show success message
  void _showSuccessMessage(String message) {
    setState(() {
      _successMessage = message;
      _showSuccess = true;
      _showError = false;
      _errorMessage = null;
    });
  }

  // Method to clear all messages
  void _clearMessages() {
    setState(() {
      _showError = false;
      _showSuccess = false;
      _errorMessage = null;
      _successMessage = null;
    });
  }

  // Guest mode login - For App Store/Play Store review process only
  // This allows reviewers to access the app without creating an account
  // Real users will go through normal email/phone -> OTP -> homepage flow
  Future<void> _loginAsGuest() async {
    setState(() {
      _isLoading = true;
    });

    _clearMessages();

    try {
      print('🎭 Guest mode login initiated for app review...');

      // Use LoginAuthService to save guest token (reusing existing methods)
      await LoginAuthService.saveToken(GUEST_TOKEN);

      // Store additional guest user data using saveAuthData
      await LoginAuthService.saveAuthData(
        token: GUEST_TOKEN,
        userData: {
          'name': 'Guest',
          'user_email': 'guest@klayons.com',
          'user_phone': null,
          'residence_type': 'society',
          'society_id': 1,
          'society_name': 'Tata Primanti',
          'tower': null,
          'flat_no': null,
          'address': '',
          'avatar_url': null,
          'profile_complete': false,
          'is_guest': true,
        },
      );

      print('✅ Guest credentials stored successfully');
      _showSuccessMessage('Welcome! Loading your dashboard...');

      // Navigate to home page
      await Future.delayed(Duration(milliseconds: 1000));

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      print('❌ Guest login error: $e');
      _showErrorMessage('Unable to login as guest. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.only(bottom: 100),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: MediaQuery.of(context).size.height * 0.40,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(
                                  'assets/images/auth_Background_Image.png',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Rounded overlay to blend with form section
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 25,
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

                      // Form section
                      Container(
                        width: double.infinity,
                        color: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 12.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Login form header
                            Center(
                              child: Text(
                                'Log in to your account',
                                style: AppTextStyles.titleMedium(
                                  context,
                                ).copyWith(color: AppColors.textSecondary),
                              ),
                            ),

                            SizedBox(height: 16),

                            // Email/Phone input field with input formatter
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: CustomTextField(
                                hintText: "Email or Phone",
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                keyboardType: TextInputType.text,
                                inputFormatters: [PhoneNumberInputFormatter()],
                              ),
                            ),

                            // Error message display
                            if (_showError && _errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: ErrorMessageWidget(
                                  message: _errorMessage!,
                                  onClose: _clearMessages,
                                  showCloseButton: true,
                                ),
                              ),

                            // Success message display using reusable widget
                            if (_showSuccess && _successMessage != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: SuccessMessageWidget(
                                  message: _successMessage!,
                                  onClose: _clearMessages,
                                  showCloseButton: true,
                                ),
                              ),

                            SizedBox(height: 16),

                            // Guest Mode Button - Only for App Store/Play Store reviewers
                            // Hidden from regular users, appears only when "guest@klayons.com" is entered
                            // This allows reviewers to test the app without creating a real account
                            // Regular user flow: Email/Phone -> OTP -> Homepage (unchanged)
                            if (_showGuestButton)
                              SizedBox(
                                width: double.infinity,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _loginAsGuest,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryOrange,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                "Logging in...",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.person_outline,
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                "Continue as Guest",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),

                            if (_showGuestButton) SizedBox(height: 16),

                            // Send OTP Button - Standard user authentication flow
                            // All regular users go through: Email/Phone -> OTP -> Homepage
                            // Only hidden when guest mode is active (for reviewers)
                            if (!_showGuestButton)
                              SizedBox(
                                width: double.infinity,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: OrangeButton(
                                    onPressed: _isLoading
                                        ? null
                                        : (_emailController.text
                                                  .trim()
                                                  .isNotEmpty
                                              ? _sendLoginOTP
                                              : null),
                                    child: _isLoading
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
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
                                            style:
                                                AppTextStyles.bodyLargeEmphasized(
                                                  context,
                                                ).copyWith(color: Colors.white),
                                          ),
                                  ),
                                ),
                              ),

                            SizedBox(height: 28),

                            // Divider with "or"
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey[300],
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      'or',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey[300],
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 28),

                            // Register link
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    "Don't have an account?",
                                    style: AppTextStyles.titleMedium(
                                      context,
                                    ).copyWith(color: AppColors.textSecondary),
                                  ),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Fixed bottom Terms & Privacy
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).size.height * 0.04,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: Text(
                          "By continuing, you agree to the ",
                          style: AppTextStyles.bodySmall(
                            context,
                          ).copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                      TextSpan(text: "\n"),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () async {
                            final url = Uri.parse(
                              'https://www.klayons.com/terms-conditions',
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          child: Text(
                            "Terms of Use ",
                            style: AppTextStyles.bodySmall(context).copyWith(
                              decorationColor: AppColors.textSecondary,
                              decoration: TextDecoration.underline,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      TextSpan(text: " & "),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () async {
                            final url = Uri.parse(
                              'https://www.klayons.com/privacy-policy',
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          child: Text(
                            "Privacy Policy",
                            style: AppTextStyles.bodySmall(context).copyWith(
                              decorationColor: AppColors.textSecondary,
                              decoration: TextDecoration.underline,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
      // Validate phone format - check for exactly 10 digits
      if (!_isValidPhone(emailOrPhone)) {
        _showErrorMessage('Please enter a valid 10-digit phone number');
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    // Clear any existing messages
    _clearMessages();

    try {
      print('🔄 Sending login OTP to: $emailOrPhone');

      // Use the updated LoginAuthService
      final response = await LoginAuthService.sendLoginOTP(
        emailOrPhone: emailOrPhone,
      );

      print('📡 Login OTP response: ${response.isSuccess}');
      print('💬 Message: ${response.message}');
      print('🔢 Status Code: ${response.httpStatusCode}');

      if (response.isSuccess) {
        // OTP sent successfully
        _showSuccessMessage(
          response.message.isNotEmpty
              ? response.message
              : 'OTP sent successfully!',
        );

        // Navigate to OTP verification page after a short delay
        Future.delayed(Duration(milliseconds: 1500), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OTPVerificationPage(email: emailOrPhone, purpose: 'login'),
            ),
          );
        });
      } else {
        // Handle error responses with detailed logging
        String errorMessage = 'Failed to send OTP. Please try again.';
        bool shouldNavigateToSignup = false;

        print('❌ Error Response Details:');
        print('   - Success: ${response.isSuccess}');
        print('   - Message: ${response.message}');
        print('   - Status Code: ${response.httpStatusCode}');

        // Handle specific error cases
        if (response.httpStatusCode == 400) {
          if (response.message.toLowerCase().contains('not found') ||
              response.message.toLowerCase().contains('not registered') ||
              response.message.toLowerCase().contains('does not exist')) {
            errorMessage = 'Account does not exist. Please signup first.';
            shouldNavigateToSignup = true;
          } else if (response.message.toLowerCase().contains(
            'already registered',
          )) {
            errorMessage =
                'This account is already registered. Please check your credentials.';
          } else {
            errorMessage = response.message.isNotEmpty
                ? response.message
                : 'Invalid request. Please check your input.';
          }
        } else if (response.httpStatusCode == 401) {
          errorMessage = 'Authentication failed. Please try again.';
        } else if (response.httpStatusCode == 404) {
          errorMessage = 'Account does not exist. Please signup first.';
          shouldNavigateToSignup = true;
        } else if (response.httpStatusCode == 429) {
          errorMessage = 'Too many attempts. Please try again later.';
        } else if (response.httpStatusCode == 500) {
          errorMessage = 'Server error. Please try again later.';
        } else if (response.message.isNotEmpty) {
          errorMessage = response.message;
        }

        _showErrorMessage(errorMessage);

        // Navigate to signup page if account doesn't exist
        if (shouldNavigateToSignup) {
          Future.delayed(Duration(milliseconds: 800), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SignUnPage()),
              );
            }
          });
        }
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

  // Enhanced phone validation - must be exactly 10 digits
  bool _isValidPhone(String phone) {
    // Remove any non-digit characters for validation
    String digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Check if it's exactly 10 digits for phone numbers
    return digitsOnly.length == 10;
  }

  @override
  void dispose() {
    _emailController.removeListener(_onTextChanged);
    _emailController.dispose();
    _emailFocusNode.removeListener(_onFocusChanged);
    _emailFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// Custom input formatter for phone number limitation
class PhoneNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;

    // If the new text contains '@', it's likely an email, so allow it
    if (newText.contains('@')) {
      return newValue;
    }

    // Remove any non-digit characters
    String digitsOnly = newText.replaceAll(RegExp(r'[^\d]'), '');

    // If all characters are digits, limit to 10 digits
    if (digitsOnly == newText) {
      if (digitsOnly.length > 10) {
        // Limit to 10 digits
        digitsOnly = digitsOnly.substring(0, 10);
        return TextEditingValue(
          text: digitsOnly,
          selection: TextSelection.collapsed(offset: digitsOnly.length),
        );
      }
    }

    return newValue;
  }
}
