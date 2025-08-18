import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/profile_page.dart';

import '../../../services/auth/login_auth_service.dart';
import '../../../services/get_userprofile_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoggingOut = false;
  bool _isLoading = true;
  bool _isUpdating = false;

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _flatController = TextEditingController();
  final TextEditingController _societyController = TextEditingController();

  // User data
  UserProfile? _userProfile;
  String? _userAvatar;

  // Validation states
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
    _societyController.dispose();
    super.dispose();
  }

  // Name validation
  bool _validateName(String name) {
    return name.trim().length >= 2;
  }

  // Email validation
  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Phone validation
  bool _validatePhone(String phone) {
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
    return phone.length >= 10 && phoneRegex.hasMatch(phone);
  }

  // Fetch user profile using the service
  Future<void> _fetchUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final profile = await GetUserProfileService.getUserProfile();

      if (profile != null) {
        setState(() {
          _userProfile = profile;

          // Populate all form fields
          _nameController.text = profile.name;
          _emailController.text = profile.userEmail;
          _phoneController.text = profile.userPhone;
          _flatController.text = profile.flatNo;
          _societyController.text = profile.societyId.toString();

          // Set validation states
          _isNameValid = profile.name.isEmpty || _validateName(profile.name);
          _isEmailValid =
              profile.userEmail.isEmpty || _validateEmail(profile.userEmail);
          _isPhoneValid =
              profile.userPhone.isEmpty || _validatePhone(profile.userPhone);

          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user profile: $e');
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

  // Update user profile using the service
  Future<void> _updateProfile() async {
    try {
      // Validate all fields before sending
      final nameValid =
          _nameController.text.isEmpty || _validateName(_nameController.text);
      final emailValid =
          _emailController.text.isEmpty ||
          _validateEmail(_emailController.text);
      final phoneValid =
          _phoneController.text.isEmpty ||
          _validatePhone(_phoneController.text);

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

      // Parse society ID, default to current value if invalid
      int? societyId;
      if (_societyController.text.trim().isNotEmpty) {
        societyId = int.tryParse(_societyController.text.trim());
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
        flatNo: _flatController.text.trim().isEmpty
            ? null
            : _flatController.text.trim(),
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
      print('Error updating profile: $e');
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

  // Show logout confirmation dialog
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Confirm Logout',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout();
              },
              child: const Text(
                'Yes',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Perform the actual logout
  Future<void> _performLogout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      print('Starting logout process...');

      final success = await LoginAuthService.logout();

      if (success) {
        print('Logout successful');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged out successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
        }
      } else {
        print('Logout failed');
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
      print('Logout error: $e');
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

  Widget _buildProfileAvatar() {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 2),
          ),
          child: ClipOval(
            child: _userAvatar != null && _userAvatar!.isNotEmpty
                ? Image.network(
                    _userAvatar!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultAvatar(),
                  )
                : _buildDefaultAvatar(),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Avatar change feature coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.orange[100],
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person, size: 40, color: Colors.orange[600]),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool isValid = true,
    String? errorText,
    Widget? suffixIcon,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isValid ? Colors.grey[300]! : Colors.red,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isValid ? Colors.grey[300]! : Colors.red,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isValid ? Colors.orange : Colors.red,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        if (!isValid && errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SETTINGS',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UserProfilePage()),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      _buildProfileAvatar(),
                      const SizedBox(height: 30),

                      // Name Field - Now functional with backend data
                      _buildTextField(
                        controller: _nameController,
                        label: 'Name',
                        hint: 'Enter your name',
                        isValid: _isNameValid,
                        errorText: _isNameValid
                            ? null
                            : 'Name must be at least 2 characters',
                        suffixIcon:
                            _isNameValid && _nameController.text.isNotEmpty
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : null,
                        onChanged: (value) {
                          setState(() {
                            _isNameValid =
                                value.isEmpty || _validateName(value);
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email Field
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'Enter your email',
                        keyboardType: TextInputType.emailAddress,
                        isValid: _isEmailValid,
                        errorText: _isEmailValid
                            ? null
                            : 'Please enter a valid email',
                        suffixIcon:
                            _isEmailValid && _emailController.text.isNotEmpty
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : null,
                        onChanged: (value) {
                          setState(() {
                            _isEmailValid =
                                value.isEmpty || _validateEmail(value);
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Phone Field
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone',
                        hint: 'Enter your phone number',
                        keyboardType: TextInputType.phone,
                        isValid: _isPhoneValid,
                        errorText: _isPhoneValid
                            ? null
                            : 'That doesn\'t look right',
                        onChanged: (value) {
                          setState(() {
                            _isPhoneValid =
                                value.isEmpty || _validatePhone(value);
                          });
                        },
                      ),
                      const SizedBox(height: 30),

                      // Change Address Section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'CHANGE ADDRESS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Society ID Field - Now functional with backend data
                      _buildTextField(
                        controller: _societyController,
                        label: 'Society ID',
                        hint: 'Enter society ID',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // Flat Number Field - Now functional with backend data
                      _buildTextField(
                        controller: _flatController,
                        label: 'Flat Number',
                        hint: 'Enter flat number',
                      ),
                      const SizedBox(height: 30),

                      // Save Details Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isUpdating ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 60),

                      // Log Out Section
                      GestureDetector(
                        onTap: _isLoggingOut ? null : _showLogoutConfirmation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isLoggingOut) ...[
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.orange,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Logging out...',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ] else ...[
                                const Text(
                                  'Log Out',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
