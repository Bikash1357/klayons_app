import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this for clipboard
import 'package:klayons/services/auth/registration_auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'otp_verification_page.dart';

class Society {
  final int id;
  final String name;
  final String address;

  Society({required this.id, required this.name, required this.address});

  factory Society.fromJson(Map<String, dynamic> json) {
    return Society(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
    );
  }

  @override
  String toString() => name;
}

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _flatController = TextEditingController();

  Society? _selectedSociety;
  bool _isLoading = false;
  bool _isSocietiesLoading = true;

  List<Society> _societies = [];

  @override
  void initState() {
    super.initState();
    _fetchSocieties();
  }

  // Method to launch Terms of Use URL
  Future<void> _launchTermsOfUseUrl() async {
    const url = 'https://www.klayons.com/terms-conditions';
    await _launchUrlWithFallback(url, 'Terms of Use');
  }

  // Method to launch Privacy Policy URL
  Future<void> _launchPrivacyPolicyUrl() async {
    const url = 'https://www.klayons.com/privacy-policy';
    await _launchUrlWithFallback(url, 'Privacy Policy');
  }

  // Generic method to launch URLs with fallback
  Future<void> _launchUrlWithFallback(String url, String title) async {
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

  Future<void> _fetchSocieties() async {
    setState(() {
      _isSocietiesLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://klayons-backend.vercel.app/api/societies'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          _societies = data
              .map((societyJson) => Society.fromJson(societyJson))
              .toList();
          _isSocietiesLoading = false;
        });
      } else {
        setState(() {
          _isSocietiesLoading = false;
        });
        _showErrorMessage('Failed to load societies. Please try again.');
      }
    } catch (e) {
      setState(() {
        _isSocietiesLoading = false;
      });
      _showErrorMessage(
        'Error loading societies. Please check your connection.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with background image and Stack overlay
              Stack(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.35,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                          'assets/images/klayons_auth_cover.png',
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

              // Form Section
              Container(
                width: double.infinity,
                color: Colors.white,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.65,
                ),
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 10),

                      // Title
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Fill in the details to get started',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32),

                      // Name Field
                      _buildTextField(
                        controller: _nameController,
                        hint: 'Name',
                      ),
                      SizedBox(height: 16.0),

                      // Email Field
                      _buildTextField(
                        controller: _emailController,
                        hint: 'Email',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 16.0),

                      // Phone Field
                      _buildTextField(
                        controller: _phoneController,
                        hint: 'Phone',
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 16.0),

                      // Society Dropdown
                      _buildSocietyDropdown(),
                      SizedBox(height: 16.0),

                      // Flat Number Field
                      _buildTextField(
                        controller: _flatController,
                        hint: 'Flat number',
                      ),
                      SizedBox(height: 24.0),

                      // Terms and Conditions with separate clickable links
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12.0,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(text: 'By continuing, I agree to the '),
                              // Terms of Use - Clickable
                              WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                                child: GestureDetector(
                                  onTap: _launchTermsOfUseUrl,
                                  child: Text(
                                    'Terms of Use',
                                    style: TextStyle(
                                      color: Color(0xFFFF6B35), // Orange color
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ),
                              ),
                              TextSpan(text: ' & '),
                              // Privacy Policy - Clickable
                              WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                                child: GestureDetector(
                                  onTap: _launchPrivacyPolicyUrl,
                                  child: Text(
                                    'Privacy Policy',
                                    style: TextStyle(
                                      color: Color(0xFFFF6B35), // Orange color
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24.0),

                      // Register Button
                      Container(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegistration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isLoading
                                ? Colors.grey[300]
                                : Color(0xFFFF6B35), // Orange color
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text('Creating Account...'),
                                  ],
                                )
                              : Text(
                                  'Send OTP',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 24.0),

                      // Login Link
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey[700],
                            ),
                            children: [
                              TextSpan(text: 'Already have an account? '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    'Log in',
                                    style: TextStyle(
                                      color: Color(0xFFFF6B35), // Orange color
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 24.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocietyDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: _isSocietiesLoading
          ? Container(
              height: 56,
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFFF6B35),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Loading societies...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Society>(
                    value: _selectedSociety,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Select Society',
                      hintStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    items: _societies.map((Society society) {
                      return DropdownMenuItem<Society>(
                        value: society,
                        child: Text(
                          society.name,
                          style: TextStyle(color: Colors.black87, fontSize: 16),
                        ),
                      );
                    }).toList(),
                    onChanged: (Society? newValue) {
                      setState(() {
                        _selectedSociety = newValue;
                      });
                    },
                    dropdownColor: Colors.white,
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a society';
                      }
                      return null;
                    },
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                    ),
                    isExpanded: true,
                  ),
                ),
                // Refresh button for societies
                IconButton(
                  onPressed: _isSocietiesLoading ? null : _fetchSocieties,
                  icon: Icon(Icons.refresh, color: Colors.grey[600], size: 20),
                  tooltip: 'Refresh societies',
                ),
              ],
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 16.0,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter ${hint.toLowerCase()}';
          }
          if (hint == 'Email' &&
              !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Please enter a valid email address';
          }
          if (hint == 'Phone' && value.length < 10) {
            return 'Please enter a valid phone number';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await RegistrationAuthService.registerUser(
        username: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        societyId: _selectedSociety!.id,
        flatNo: _flatController.text.trim(),
      );

      if (result['success']) {
        _showSuccessMessage(result['message']);
        _navigateToOTPVerification();
      } else {
        String errorMessage = result['data'] != null
            ? RegistrationAuthService.parseErrorMessage(result['data'])
            : result['message'];
        _showErrorMessage(errorMessage);
      }
    } catch (e) {
      _showErrorMessage('An unexpected error occurred. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToOTPVerification() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OTPVerificationPage(
          email: _emailController.text.trim(),
          purpose: 'registration',
        ),
      ),
    );
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _flatController.dispose();
    super.dispose();
  }
}
