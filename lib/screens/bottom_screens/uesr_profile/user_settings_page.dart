import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/profile_page.dart';
import 'package:klayons/utils/colour.dart';
import '../../../services/auth/login_service.dart';
import '../../../services/get_userprofile_service.dart';
import '../../../utils/styles/fonts.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoggingOut = false;
  bool _isLoading = true;
  bool _isUpdating = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _flatController = TextEditingController();
  final TextEditingController _societyIdController = TextEditingController();
  final TextEditingController _societyNameController = TextEditingController();
  final TextEditingController _towerController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  UserProfile? _userProfile;
  String? _userAvatar;

  bool _isEmailValid = true;
  bool _isPhoneValid = true;
  bool _isNameValid = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _flatController.dispose();
    _societyIdController.dispose();
    _societyNameController.dispose();
    _towerController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool _validateName(String name) {
    return name.trim().length >= 2;
  }

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _validatePhone(String phone) {
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
    return phone.length >= 10 && phoneRegex.hasMatch(phone);
  }

  bool get _hasSocietyInfo {
    return _userProfile != null &&
        ((_userProfile?.societyName ?? '').isNotEmpty ||
            (_userProfile?.societyId ?? 0) > 0);
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final profile = await GetUserProfileService.getUserProfile();
      if (profile != null) {
        setState(() {
          _userProfile = profile;
          _nameController.text = profile.name ?? '';
          _emailController.text = profile.userEmail ?? '';
          _phoneController.text = profile.userPhone ?? '';
          _flatController.text = profile.flatNo ?? '';
          _societyIdController.text = (profile.societyId != 0)
              ? profile.societyId.toString()
              : '';
          _societyNameController.text = profile.societyName ?? '';
          _towerController.text = profile.tower ?? '';
          _addressController.text = profile.address ?? '';
          _isNameValid = profile.name.isEmpty || _validateName(profile.name);
          _isEmailValid =
              profile.userEmail.isEmpty || _validateEmail(profile.userEmail);
          _isPhoneValid =
              profile.userPhone.isEmpty || _validatePhone(profile.userPhone);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load profile: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the validation errors'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    int? societyId;
    if (_societyIdController.text.trim().isNotEmpty) {
      societyId = int.tryParse(_societyIdController.text.trim());
      if (societyId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid society ID (numbers only)'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {
          _isUpdating = false;
        });
        return;
      }
    }

    try {
      final updatedProfile = await GetUserProfileService.updateUserProfile(
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        userEmail: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        userPhone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        societyId: societyId,
        societyName: _societyNameController.text.trim().isEmpty
            ? null
            : _societyNameController.text.trim(),
        tower: _towerController.text.trim().isEmpty
            ? null
            : _towerController.text.trim(),
        flatNo: _flatController.text.trim().isEmpty
            ? null
            : _flatController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        residenceType: 'society',
      );
      if (updatedProfile != null) {
        setState(() {
          _userProfile = updatedProfile;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update profile: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm Logout',
            style: AppTextStyles.titleLarge(context),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: AppTextStyles.bodyLargeEmphasized(context),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppTextStyles.bodyLargeEmphasized(
                  context,
                ).copyWith(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout();
              },
              child: Text(
                'Yes',
                style: AppTextStyles.bodyLargeEmphasized(
                  context,
                ).copyWith(color: Colors.orange, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    setState(() {
      _isLoggingOut = true;
    });
    try {
      final success = await LoginAuthService.logout();
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged out successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logout failed. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred during logout'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool isValid = true,
    String? errorText,
    Function(String)? onChanged,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
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
            style: TextStyle(
              fontSize: 16,
              color: enabled ? Colors.black87 : Colors.grey,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              filled: !enabled,
              fillColor: enabled ? null : Colors.grey.shade100,
            ),
          ),
        ),
        if (!isValid && errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              errorText,
              style: TextStyle(color: Colors.red, fontSize: 12),
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
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
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
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
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
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UserProfilePage()),
          ),
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
                _buildSectionTitle('Basic Information'),
                _buildTextField(
                  controller: _nameController,
                  hint: 'Enter your name',
                  isValid: _isNameValid,
                  errorText: _isNameValid
                      ? null
                      : 'Name must be at least 2 characters',
                  onChanged: (value) {
                    setState(() {
                      _isNameValid = value.isEmpty || _validateName(value);
                    });
                  },
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
                  onChanged: (value) {
                    setState(() {
                      _isEmailValid = value.isEmpty || _validateEmail(value);
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _phoneController,
                  hint: 'Enter your phone number',
                  keyboardType: TextInputType.phone,
                  isValid: _isPhoneValid,
                  errorText: _isPhoneValid ? null : 'That doesn\'t look right',
                  onChanged: (value) {
                    setState(() {
                      _isPhoneValid = value.isEmpty || _validatePhone(value);
                    });
                  },
                ),

                // Address Information Section
                _buildSectionTitle('Address Information'),

                if (_hasSocietyInfo) ...[
                  _buildTextField(
                    controller: _addressController,
                    hint: 'Address',
                    maxLines: 1,
                    enabled: false,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _towerController,
                          hint: 'Tower',
                          enabled: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _flatController,
                          hint: 'Flat',
                          enabled: false,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  _buildTextField(
                    controller: _addressController,
                    hint: 'Address',
                    maxLines: 1,
                    enabled: false,
                  ),
                ],

                const SizedBox(height: 16),

                // Info message
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    'If you wish to change your address, please send us a mail at support@klayons.com',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                  ),
                ),

                const SizedBox(height: 40),

                // Save Button
                SizedBox(
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
                        : Text(
                            'Save Details',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
