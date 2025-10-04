import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/Childs/child_intrest.dart';
import 'package:http/http.dart' as http;
import '../../../../services/user_child/get_ChildServices.dart';
import '../../../../services/auth/login_service.dart';
import '../../../../utils/styles/button.dart';
import '../../../../utils/styles/fonts.dart';
import 'package:klayons/utils/colour.dart';
import '../../../../utils/styles/textboxes.dart';
import '../profile_page.dart';

class ChildData {
  final String firstName;
  final DateTime dateOfBirth;
  final String gender;
  final int? childId;
  final List<int>? existingInterestIds;

  ChildData({
    required this.firstName,
    required this.dateOfBirth,
    required this.gender,
    this.childId,
    this.existingInterestIds,
  });
}

class AddChildPage extends StatefulWidget {
  final Child? childToEdit;
  final bool isEditMode;

  const AddChildPage({Key? key, this.childToEdit, this.isEditMode = false})
    : super(key: key);

  @override
  State<AddChildPage> createState() => _AddChildPageState();
}

class _AddChildPageState extends State<AddChildPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();

  String _selectedGender = '';
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isDeletingChild = false;

  // Simple error/success handling
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppColors.primaryOrange,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Success',
                style: AppTextStyles.titleLarge(
                  context,
                ).copyWith(color: AppColors.primaryOrange),
              ),
            ],
          ),
          content: Text(message, style: AppTextStyles.bodyMedium(context)),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close success dialog
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => UserProfilePage()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'OK',
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode && widget.childToEdit != null) {
      _populateFieldsForEdit();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  void _populateFieldsForEdit() {
    final child = widget.childToEdit!;
    List<String> nameParts = child.name.split(' ');

    _firstNameController.text = nameParts.isNotEmpty ? nameParts[0] : '';
    _lastNameController.text = nameParts.length > 1
        ? nameParts.sublist(1).join(' ')
        : '';

    try {
      _selectedDate = DateTime.parse(child.dob);
      _birthdayController.text =
          "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}";
    } catch (e) {
      _showErrorSnackBar('Error parsing date');
    }

    _selectedGender = child.gender.toLowerCase() == 'male' ? 'Boy' : 'Girl';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryOrange, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryOrange, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthdayController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<bool> _deleteChild(int childId) async {
    try {
      String? authToken = await LoginAuthService.getToken();
      if (authToken == null || authToken.isEmpty) {
        throw Exception('No authentication token found');
      }

      bool isAuthenticated = await LoginAuthService.isAuthenticated();
      if (!isAuthenticated) {
        throw Exception('User is not authenticated');
      }

      final response = await http.delete(
        Uri.parse(
          'https://dev-klayonsapi.vercel.app/api/profiles/children/$childId/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        await LoginAuthService.clearAuthData();
        throw Exception('Authentication failed - please login again');
      } else if (response.statusCode == 403) {
        throw Exception('Access forbidden - insufficient permissions');
      } else if (response.statusCode == 404) {
        throw Exception('Child not found or already deleted');
      } else {
        throw Exception(
          'Failed to delete child. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _handleDeleteChild(StateSetter dialogSetState) async {
    if (widget.childToEdit?.id == null) {
      _showErrorSnackBar('Invalid child data');
      return;
    }

    dialogSetState(() => _isDeletingChild = true);
    setState(() => _isDeletingChild = true);

    try {
      bool isAuth = await LoginAuthService.isAuthenticated();
      if (!isAuth) {
        dialogSetState(() => _isDeletingChild = false);
        setState(() => _isDeletingChild = false);
        Navigator.of(context).pop(); // Close dialog
        _showErrorSnackBar('Session expired. Please login again.');
        return;
      }

      final success = await _deleteChild(widget.childToEdit!.id);
      dialogSetState(() => _isDeletingChild = false);
      setState(() => _isDeletingChild = false);

      if (success) {
        Navigator.of(context).pop(); // Close dialog
        _showSuccessDialog('Child profile deleted successfully!');
      } else {
        Navigator.of(context).pop(); // Close dialog
        _showErrorSnackBar('Failed to delete child profile. Please try again.');
      }
    } catch (e) {
      dialogSetState(() => _isDeletingChild = false);
      setState(() => _isDeletingChild = false);
      Navigator.of(context).pop(); // Close dialog

      String errorMessage = 'An error occurred while deleting.';
      if (e.toString().contains('authentication') ||
          e.toString().contains('token')) {
        errorMessage = 'Session expired. Please login again.';
        await LoginAuthService.clearAuthData();
      } else if (e.toString().contains('not found')) {
        errorMessage = 'Child profile not found or already deleted.';
      } else if (e.toString().contains('forbidden')) {
        errorMessage = 'You don\'t have permission to delete this child.';
      }

      _showErrorSnackBar(errorMessage);
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: Text(
                'Delete Child',
                style: AppTextStyles.titleLarge(
                  context,
                ).copyWith(color: Colors.red),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isDeletingChild) ...[
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.025,
                    ),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    Text(
                      'Deleting child profile...',
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: Colors.grey),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.025,
                    ),
                  ] else ...[
                    Text(
                      'Do you want to delete ${widget.childToEdit?.name}\'s profile? This action cannot be undone.',
                      style: AppTextStyles.bodyMedium(context),
                    ),
                  ],
                ],
              ),
              actions: _isDeletingChild
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: AppTextStyles.bodyMedium(
                            context,
                          ).copyWith(color: Colors.grey),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _handleDeleteChild(dialogSetState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  bool _validateForm() {
    if (_firstNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter first name');
      return false;
    }
    if (_birthdayController.text.trim().isEmpty) {
      _showErrorSnackBar('Please select birthday');
      return false;
    }
    if (_selectedGender.isEmpty) {
      _showErrorSnackBar('Please select gender');
      return false;
    }
    return true;
  }

  void _navigateToInterests() {
    if (!_validateForm()) return;

    final childData = ChildData(
      firstName: _firstNameController.text.trim(),
      dateOfBirth: _selectedDate!,
      gender: _selectedGender,
      childId: widget.isEditMode ? widget.childToEdit?.id : null,
      existingInterestIds: widget.isEditMode
          ? widget.childToEdit?.interests.map((i) => i.id).toList()
          : null,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddChildInterestsPage(
          childData: childData,
          isEditMode: widget.isEditMode,
        ),
      ),
    );
  }

  Widget _buildGenderSelection() {
    final screenHeight = MediaQuery.of(context).size.height;

    return Row(
      children: [
        Expanded(child: _buildGenderOption('Boy', screenHeight)),
        SizedBox(width: MediaQuery.of(context).size.width * 0.03),
        Expanded(child: _buildGenderOption('Girl', screenHeight)),
      ],
    );
  }

  Widget _buildGenderOption(String gender, double screenHeight) {
    final isSelected = _selectedGender == gender;

    return GestureDetector(
      onTap: _isLoading ? null : () => setState(() => _selectedGender = gender),
      child: Container(
        height: screenHeight * 0.06, // 6% of screen height
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOrange.withOpacity(0.2)
              : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            gender,
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: isSelected ? Colors.orange[700] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageSize = screenHeight * 0.1; // 10% of screen height

    return Center(
      child: Column(
        children: [
          Container(
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              color: widget.isEditMode
                  ? (widget.childToEdit!.gender.toLowerCase() == 'male'
                        ? Colors.blue[200]
                        : Colors.pink[200])
                  : Colors.grey[600],
              shape: BoxShape.circle,
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    widget.isEditMode
                        ? (widget.childToEdit!.gender.toLowerCase() == 'male'
                              ? Icons.boy
                              : Icons.girl)
                        : Icons.person,
                    size: imageSize * 0.5,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: imageSize * 0.3,
                    height: imageSize * 0.3,
                    decoration: const BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isEditMode ? Icons.edit : Icons.add,
                      size: imageSize * 0.2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            widget.isEditMode ? 'Edit Photo' : 'Add Photo',
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
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
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UserProfilePage()),
          ),
        ),
        title: Text(
          widget.isEditMode ? 'Edit Child' : 'Add Child',
          style: AppTextStyles.titleLarge(
            context,
          ).copyWith(color: AppColors.darkElements),
        ),
        centerTitle: false,
        actions: widget.isEditMode
            ? [
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/App_icons/iconDelete.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(Colors.red, BlendMode.srcIn),
                  ),
                  onPressed: _isDeletingChild
                      ? null
                      : _showDeleteConfirmationDialog,
                  tooltip: 'Delete Child',
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: screenHeight * 0.020,
                right: screenHeight * 0.020,
                top: screenHeight * 0.020,
                bottom: 80, // Space for the fixed button
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: screenHeight * 0.025),

                        // Title
                        Center(
                          child: Text(
                            widget.isEditMode
                                ? 'Update Your Child\'S Info'
                                : 'Tell Us About Your Child',
                            style: AppTextStyles.titleMedium(context).copyWith(
                              color: Colors.black87,
                              letterSpacing: 0.1,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.05),

                        // Profile Image
                        _buildProfileImageSection(),
                        SizedBox(height: screenHeight * 0.01),

                        // First Name Field
                        Text(
                          'Your Child\'s name *',
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        CustomTextField(
                          hintText: 'Full Name',
                          controller: _firstNameController,
                          heightPercentage: 0.06, // 6% of screen height
                          showDynamicBorders: false,
                        ),
                        SizedBox(height: screenHeight * 0.03),

                        // Birthday Field
                        Text(
                          'Date of Birth *',
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        GestureDetector(
                          onTap: _isLoading ? null : () => _selectDate(context),
                          child: AbsorbPointer(
                            child: CustomTextField(
                              hintText: 'Date',
                              controller: _birthdayController,
                              heightPercentage: 0.06, // 6% of screen height
                              showDynamicBorders: false,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),

                        // Gender Selection
                        Text(
                          'Gender? *',
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        _buildGenderSelection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Fixed button at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHeight * 0.020),
              child: OrangeButton(
                onPressed: _navigateToInterests,
                isDisabled: _isLoading,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Next',
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
