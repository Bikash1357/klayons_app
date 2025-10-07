import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for input formatters
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:klayons/utils/colour.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/UserProfileServices/updateUserProfileServices.dart';
import '../../../services/UserProfileServices/userProfileModels.dart';
import '../../../services/auth/login_service.dart';
import '../../../services/UserProfileServices/get_userprofile_service.dart';
import '../../../utils/styles/fonts.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Loading states
  bool _isLoading = true;
  bool _isUpdating = false;
  bool _isVerifyingEmail = false;
  bool _isVerifyingPhone = false;
  bool _isVerifyingOTP = false;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _flatController = TextEditingController();
  final TextEditingController _societyNameController = TextEditingController();
  final TextEditingController _towerController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // OTP controllers
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  // State variables
  UserProfile? _userProfile;
  bool _isEmailValid = true;
  bool _isPhoneValid = true;
  bool _isNameValid = true;
  bool _showEmailOTP = false;
  bool _showPhoneOTP = false;
  String _pendingVerificationType = '';

  // Add these new state variables to track user input
  bool _hasEmailInput = false;
  bool _hasPhoneInput = false;

  // Constants
  static const String baseUrl = 'https://dev-klayons.onrender.com/api';
  static const Duration snackBarDuration = Duration(seconds: 2);
  static const Duration errorDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _flatController.dispose();
    _societyNameController.dispose();
    _towerController.dispose();
    _addressController.dispose();

    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
  }

  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      debugPrint('Error getting auth token: $e');
      return null;
    }
  }

  bool _validateName(String name) => name.trim().length >= 2;

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _validatePhone(String phone) {
    final phoneRegex = RegExp(r'^\d{10}$'); // Exactly 10 digits
    return phoneRegex.hasMatch(phone.trim());
  }

  bool get _hasSocietyInfo {
    return _userProfile != null &&
        ((_userProfile?.societyName ?? '').isNotEmpty ||
            (_userProfile?.societyId ?? 0) > 0);
  }

  bool get _hasEmailData {
    return _userProfile != null && (_userProfile?.userEmail ?? '').isNotEmpty;
  }

  bool get _hasPhoneData {
    return _userProfile != null && (_userProfile?.userPhone ?? '').isNotEmpty;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: isError ? errorDuration : snackBarDuration,
      ),
    );
  }

  void _clearOTPFields() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final profile = await GetUserProfileService.getUserProfile();
      if (profile != null && mounted) {
        setState(() {
          _userProfile = profile;
          _populateFormFields(profile);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(
        'Failed to load profile: ${_getErrorMessage(e)}',
        isError: true,
      );
    }
  }

  void _populateFormFields(UserProfile profile) {
    _nameController.text = profile.name ?? '';
    _emailController.text = profile.userEmail ?? '';
    _phoneController.text = profile.userPhone ?? '';
    _flatController.text = profile.flatNo ?? '';
    _societyNameController.text = profile.societyName ?? '';
    _towerController.text = profile.tower ?? '';
    _addressController.text = profile.address ?? '';

    _isNameValid = profile.name.isEmpty || _validateName(profile.name);
    _isEmailValid =
        profile.userEmail.isEmpty || _validateEmail(profile.userEmail);
    _isPhoneValid =
        profile.userPhone.isEmpty || _validatePhone(profile.userPhone);

    _hasEmailInput = (profile.userEmail ?? '').isNotEmpty;
    _hasPhoneInput = (profile.userPhone ?? '').isNotEmpty;
  }

  String _getErrorMessage(dynamic error) {
    return error.toString().replaceAll('Exception: ', '');
  }

  Future<void> _updateProfile() async {
    if (!_validateForm()) return;

    setState(() => _isUpdating = true);

    try {
      final updatedProfile = await UpdateUserProfileService.updateUserProfile(
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        userEmail: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        userPhone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        societyName: _societyNameController.text.trim().isEmpty
            ? null
            : _societyNameController.text.trim(),
        residenceType: 'society',
        tower: _towerController.text.trim().isEmpty
            ? null
            : _towerController.text.trim(),
        flatNo: _flatController.text.trim().isEmpty
            ? null
            : _flatController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
      );

      if (updatedProfile != null && mounted) {
        setState(() => _userProfile = updatedProfile);
        _showSnackBar('Profile updated successfully');
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/user_profile_page',
            (Route<dynamic> route) => false,
          );
        }
      }
    } catch (e) {
      _showSnackBar(
        'Failed to update profile: ${_getErrorMessage(e)}',
        isError: true,
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  bool _validateForm() {
    final nameValid =
        _nameController.text.isEmpty || _validateName(_nameController.text);
    final emailValid =
        _emailController.text.isEmpty || _validateEmail(_emailController.text);
    final phoneValid =
        _phoneController.text.isEmpty || _validatePhone(_phoneController.text);

    setState(() {
      _isNameValid = nameValid;
      _isEmailValid = emailValid;
      _isPhoneValid = phoneValid;
    });

    if (!nameValid || !emailValid || !phoneValid) {
      _showSnackBar('Please fix the validation errors', isError: true);
      return false;
    }
    return true;
  }

  Future<Map<String, dynamic>> _makeApiCall(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final token = await _getAuthToken();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      debugPrint('API POST $endpoint');
      debugPrint('Headers: $headers');
      debugPrint('Body: ${json.encode(body)}');

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: json.encode(body),
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        String errorMessage =
            responseData['message'] ??
            responseData['error'] ??
            responseData['detail'] ??
            'Unknown error';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Error in $endpoint: $e');
      rethrow;
    }
  }

  Future<void> _linkEmail() async {
    if (!_validateEmailInput()) return;

    setState(() => _isVerifyingEmail = true);

    try {
      final email = _emailController.text.trim();
      await _makeApiCall('/auth/link-email/', {'email': email});
      setState(() {
        _showEmailOTP = true;
        _pendingVerificationType = 'email';
        _clearOTPFields();
      });
      _showSnackBar('OTP sent to your email');

      if (_otpFocusNodes.isNotEmpty) {
        _otpFocusNodes[0].requestFocus();
      }
    } catch (e) {
      _showSnackBar(
        'Failed to send OTP: ${_getErrorMessage(e)}',
        isError: true,
      );
    } finally {
      setState(() => _isVerifyingEmail = false);
    }
  }

  Future<void> _linkPhone() async {
    if (!_validatePhoneInput()) return;

    setState(() => _isVerifyingPhone = true);

    try {
      final phone = _phoneController.text.trim().replaceAll(' ', '');
      await _makeApiCall('/auth/link-phone/', {'phone': phone});
      setState(() {
        _showPhoneOTP = true;
        _pendingVerificationType = 'phone';
        _clearOTPFields();
      });
      _showSnackBar('OTP sent to your phone');

      if (_otpFocusNodes.isNotEmpty) {
        _otpFocusNodes[0].requestFocus();
      }
    } catch (e) {
      _showSnackBar(
        'Failed to send OTP: ${_getErrorMessage(e)}',
        isError: true,
      );
    } finally {
      setState(() => _isVerifyingPhone = false);
    }
  }

  bool _validateEmailInput() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Please enter an email address', isError: true);
      return false;
    }
    if (!_validateEmail(email)) {
      _showSnackBar('Please enter a valid email address', isError: true);
      return false;
    }
    return true;
  }

  bool _validatePhoneInput() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnackBar('Please enter a phone number', isError: true);
      return false;
    }
    if (!_validatePhone(phone)) {
      _showSnackBar('Please enter exactly 10 digits', isError: true);
      return false;
    }
    return true;
  }

  Future<void> _verifyOTP() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      _showSnackBar('Please enter complete 6-digit OTP', isError: true);
      return;
    }

    setState(() => _isVerifyingOTP = true);

    try {
      final token = await _getAuthToken();

      String otpString = otp.toString().trim();
      Map<String, dynamic> requestBody = {'otp': otpString};

      if (_pendingVerificationType == 'email') {
        requestBody['email'] = _emailController.text.trim();
      } else if (_pendingVerificationType == 'phone') {
        requestBody['phone'] = _phoneController.text.trim().replaceAll(' ', '');
      }

      // Log full request info
      debugPrint('=== VERIFY OTP DEBUG START ===');
      debugPrint('POST URL: $baseUrl/auth/verify-otp/');
      debugPrint('Headers:');
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      headers.forEach((key, value) => debugPrint(' - $key: $value'));
      debugPrint('Request Body: ${json.encode(requestBody)}');
      debugPrint('OTP Type: ${otpString.runtimeType}, Value: "$otpString"');
      debugPrint('Verification Type: $_pendingVerificationType');

      final stopwatch = Stopwatch()..start();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp/'),
        headers: headers,
        body: json.encode(requestBody),
      );
      stopwatch.stop();

      debugPrint('Response time: ${stopwatch.elapsedMilliseconds} ms');
      debugPrint('OTP verification response status: ${response.statusCode}');
      debugPrint('OTP verification response body: ${response.body}');

      // Full raw response body logging for error inspection
      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData.containsKey('access')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', responseData['access']);
          debugPrint('New auth token saved!');
        }

        final verifiedType = _pendingVerificationType;

        setState(() {
          _showEmailOTP = false;
          _showPhoneOTP = false;
          _pendingVerificationType = '';
          _clearOTPFields();
        });

        await _fetchUserProfile();

        _showSnackBar(
          '${verifiedType == 'email' ? 'Email' : 'Phone'} verified successfully!',
        );
      } else {
        String errorMsg =
            responseData['message'] ??
            responseData['error'] ??
            'OTP verification failed';
        debugPrint('Verification Error Message: $errorMsg');
        _showSnackBar(errorMsg, isError: true);
        _clearOTPFields();
        if (_otpFocusNodes.isNotEmpty) {
          _otpFocusNodes[0].requestFocus();
        }
      }

      debugPrint('=== VERIFY OTP DEBUG END ===');
    } catch (e, stacktrace) {
      debugPrint('OTP verification error: $e');
      debugPrint('Stack trace: $stacktrace');
      _showSnackBar(
        'Network error: Please check your connection and try again',
        isError: true,
      );
      _clearOTPFields();
      if (_otpFocusNodes.isNotEmpty) {
        _otpFocusNodes[0].requestFocus();
      }
    } finally {
      setState(() => _isVerifyingOTP = false);
    }
  }

  // UI builder methods (unchanged from your original code)...

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool isValid = true,
    String? errorText,
    Function(String)? onChanged,
    int maxLines = 1,
    bool enabled = true,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isValid ? Colors.grey.shade300 : Colors.red,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            maxLines: maxLines,
            enabled: enabled,
            inputFormatters: inputFormatters,
            style: TextStyle(
              fontSize: 16,
              color: enabled ? Colors.black87 : Colors.grey.shade600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: enabled ? Colors.grey.shade500 : Colors.grey.shade400,
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (!isValid && errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 24),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildVerifyButton({
    required String text,
    required VoidCallback onPressed,
    required bool isLoading,
    Color? backgroundColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? const Color(0xFFFF5722),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildOTPFields() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Text(
          'Enter 6-digit OTP',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return Container(
              width: 45,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) => _handleOTPInput(value, index),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isVerifyingOTP ? null : _verifyOTP,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: _isVerifyingOTP
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Verify OTP',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _handleOTPInput(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all 6 digits are entered
    if (index == 5 && value.isNotEmpty) {
      final otp = _otpControllers.map((controller) => controller.text).join();
      if (otp.length == 6) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && otp.length == 6) {
            _verifyOTP();
          }
        });
      }
    }
  }

  Widget _buildInfoCard(String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _userProfile == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'Settings',
          style: AppTextStyles.formLarge(context).copyWith(
            color: AppColors.darkElements,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/App_icons/iconBack.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              AppColors.darkElements,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/user_profile_page'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Information Section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Basic Information'),
                      _buildTextField(
                        controller: _nameController,
                        hint: 'Enter your name',
                        isValid: _isNameValid,
                        errorText: _isNameValid
                            ? null
                            : 'Name must be at least 2 characters',
                        onChanged: (value) => setState(
                          () => _isNameValid =
                              value.isEmpty || _validateName(value),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Dynamic email/phone layout based on existing data
                      if (_hasEmailData) ...[
                        _buildTextField(
                          controller: _emailController,
                          hint: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          isValid: _isEmailValid,
                          errorText: _isEmailValid
                              ? null
                              : 'Please enter a valid email',
                          enabled: false,
                          onChanged: (value) => setState(
                            () => _isEmailValid =
                                value.isEmpty || _validateEmail(value),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _phoneController,
                          hint: 'Enter your phone number',
                          keyboardType: TextInputType.phone,
                          isValid: _isPhoneValid,
                          errorText: _isPhoneValid
                              ? null
                              : 'Please enter exactly 10 digits',
                          enabled: !_hasPhoneData,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          onChanged: (value) => setState(() {
                            _isPhoneValid =
                                value.isEmpty || _validatePhone(value);
                            _hasPhoneInput = value.trim().isNotEmpty;
                          }),
                        ),
                        if (!_hasPhoneData &&
                            !_showPhoneOTP &&
                            _hasPhoneInput &&
                            _isPhoneValid) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _buildVerifyButton(
                              text: 'Verify Phone',
                              onPressed: _linkPhone,
                              isLoading: _isVerifyingPhone,
                            ),
                          ),
                        ],
                        if (_showPhoneOTP) _buildOTPFields(),
                      ] else if (_hasPhoneData) ...[
                        _buildTextField(
                          controller: _phoneController,
                          hint: 'Enter your phone number',
                          keyboardType: TextInputType.phone,
                          isValid: _isPhoneValid,
                          errorText: _isPhoneValid
                              ? null
                              : 'Please enter exactly 10 digits',
                          enabled: false,
                          onChanged: (value) => setState(
                            () => _isPhoneValid =
                                value.isEmpty || _validatePhone(value),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _emailController,
                          hint: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          isValid: _isEmailValid,
                          errorText: _isEmailValid
                              ? null
                              : 'Please enter a valid email',
                          enabled: !_hasEmailData,
                          onChanged: (value) => setState(() {
                            _isEmailValid =
                                value.isEmpty || _validateEmail(value);
                            _hasEmailInput = value.trim().isNotEmpty;
                          }),
                        ),
                        if (!_hasEmailData &&
                            !_showEmailOTP &&
                            _hasEmailInput &&
                            _isEmailValid) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _buildVerifyButton(
                              text: 'Verify Email',
                              onPressed: _linkEmail,
                              isLoading: _isVerifyingEmail,
                            ),
                          ),
                        ],
                        if (_showEmailOTP) _buildOTPFields(),
                      ] else ...[
                        _buildTextField(
                          controller: _emailController,
                          hint: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          isValid: _isEmailValid,
                          errorText: _isEmailValid
                              ? null
                              : 'Please enter a valid email',
                          enabled: true,
                          onChanged: (value) => setState(() {
                            _isEmailValid =
                                value.isEmpty || _validateEmail(value);
                            _hasEmailInput = value.trim().isNotEmpty;
                          }),
                        ),
                        if (!_showEmailOTP &&
                            _hasEmailInput &&
                            _isEmailValid) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _buildVerifyButton(
                              text: 'Verify Email',
                              onPressed: _linkEmail,
                              isLoading: _isVerifyingEmail,
                            ),
                          ),
                        ],
                        if (_showEmailOTP) _buildOTPFields(),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _phoneController,
                          hint: 'Enter your phone number',
                          keyboardType: TextInputType.phone,
                          isValid: _isPhoneValid,
                          errorText: _isPhoneValid
                              ? null
                              : 'Please enter exactly 10 digits',
                          enabled: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          onChanged: (value) => setState(() {
                            _isPhoneValid =
                                value.isEmpty || _validatePhone(value);
                            _hasPhoneInput = value.trim().isNotEmpty;
                          }),
                        ),
                        if (!_showPhoneOTP &&
                            _hasPhoneInput &&
                            _isPhoneValid) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _buildVerifyButton(
                              text: 'Verify Phone',
                              onPressed: _linkPhone,
                              isLoading: _isVerifyingPhone,
                            ),
                          ),
                        ],
                        if (_showPhoneOTP) _buildOTPFields(),
                      ],
                      SizedBox(height: 20),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Address Information'),
                      if (_hasSocietyInfo) ...[
                        _buildTextField(
                          controller: _societyNameController,
                          hint: 'Society',
                          enabled: false,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _towerController,
                                hint: 'Tower',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _flatController,
                                hint: 'Flat',
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        _buildTextField(
                          controller: _addressController,
                          hint: 'Address',
                        ),
                      ],

                      const SizedBox(height: 16),
                      _buildInfoCard(
                        'If you wish to change your address, please send us a mail at support@klayons.com',
                        AppColors.primaryOrange,
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUpdating ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isUpdating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Save Details',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
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
}
