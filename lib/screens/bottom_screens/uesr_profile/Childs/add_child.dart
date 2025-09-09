import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/Childs/child_intrest.dart';
import 'package:http/http.dart' as http;
import '../../../../services/user_child/get_ChildServices.dart';
import '../../../../services/auth/login_service.dart';
import '../../../../utils/styles/fonts.dart';
import 'package:klayons/utils/colour.dart';
import 'package:flutter_svg/svg.dart';

import '../profile_page.dart';

class ChildData {
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String gender;
  final int? childId;
  final List<int>? existingInterestIds;

  ChildData({
    required this.firstName,
    required this.lastName,
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

  @override
  void initState() {
    super.initState();

    // If editing, populate fields with existing data
    if (widget.isEditMode && widget.childToEdit != null) {
      _populateFieldsForEdit();
    }
  }

  void _populateFieldsForEdit() {
    final child = widget.childToEdit!;

    // Split the name into first and last name
    List<String> nameParts = child.name.split(' ');
    _firstNameController.text = nameParts.isNotEmpty ? nameParts[0] : '';
    _lastNameController.text = nameParts.length > 1
        ? nameParts.sublist(1).join(' ')
        : '';

    // Parse and set the date
    try {
      _selectedDate = DateTime.parse(child.dob);
      _birthdayController.text =
          "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}";
    } catch (e) {
      print('Error parsing date: $e');
    }

    // Set gender - convert from API format to UI format
    _selectedGender = child.gender.toLowerCase() == 'male' ? 'Boy' : 'Girl';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthdayController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  // Delete child API call
  // Updated delete child API call with proper authentication
  Future<bool> _deleteChild(int childId) async {
    try {
      // Use LoginAuthService.getToken() instead of getToken()
      String? authToken = await LoginAuthService.getToken();

      if (authToken == null || authToken.isEmpty) {
        print('No authentication token found');
        throw Exception('No authentication token found');
      }

      // Also check if user is properly authenticated
      bool isAuthenticated = await LoginAuthService.isAuthenticated();
      if (!isAuthenticated) {
        print('User is not authenticated');
        throw Exception('User is not authenticated');
      }

      print('Attempting to delete child with ID: $childId');
      print('Using token: ${authToken.substring(0, 20)}...');

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

      print('Delete response status: ${response.statusCode}');
      print('Delete response body: ${response.body}');
      print('Delete response headers: ${response.headers}');

      // According to your API docs, successful deletion returns 204
      if (response.statusCode == 204) {
        print('Child deleted successfully');
        return true;
      } else if (response.statusCode == 200) {
        // Some APIs return 200 instead of 204
        print('Child deleted successfully (200 response)');
        return true;
      } else if (response.statusCode == 401) {
        print('Authentication failed - token may be expired');

        // Clear invalid token
        await LoginAuthService.clearAuthData();

        throw Exception('Authentication failed - please login again');
      } else if (response.statusCode == 403) {
        throw Exception('Access forbidden - insufficient permissions');
      } else if (response.statusCode == 404) {
        throw Exception('Child not found or already deleted');
      } else {
        throw Exception(
          'Failed to delete child. Status code: ${response.statusCode}, Response: ${response.body}',
        );
      }
    } catch (e) {
      print('Error deleting child: $e');

      if (e.toString().contains('authentication') ||
          e.toString().contains('token')) {}

      return false;
    }
  }

  // Enhanced error handling for delete child process
  Future<void> _handleDeleteChild([Function? dialogSetState]) async {
    if (widget.childToEdit?.id == null) {
      if (dialogSetState != null) Navigator.of(context).pop();
      _showErrorDialog('Invalid child data');
      return;
    }

    // Update both the main widget state and dialog state
    setState(() {
      _isDeletingChild = true;
    });

    if (dialogSetState != null) {
      dialogSetState(() {
        _isDeletingChild = true;
      });
    }

    try {
      // First, check if user is authenticated
      bool isAuth = await LoginAuthService.isAuthenticated();
      if (!isAuth) {
        setState(() {
          _isDeletingChild = false;
        });
        if (dialogSetState != null) {
          dialogSetState(() {
            _isDeletingChild = false;
          });
        }
        Navigator.of(context).pop(); // Close dialog
        _showErrorDialog('Session expired. Please login again.');
        return;
      }

      final success = await _deleteChild(widget.childToEdit!.id);

      setState(() {
        _isDeletingChild = false;
      });
      if (dialogSetState != null) {
        dialogSetState(() {
          _isDeletingChild = false;
        });
      }

      if (success) {
        Navigator.of(context).pop(); // Close dialog
        _showSuccessDialog(
          'Child profile deleted successfully!',
          isDelete: true,
        );
      } else {
        Navigator.of(context).pop(); // Close dialog
        _showErrorDialog('Failed to delete child profile. Please try again.');
      }
    } catch (e) {
      setState(() {
        _isDeletingChild = false;
      });
      if (dialogSetState != null) {
        dialogSetState(() {
          _isDeletingChild = false;
        });
      }
      Navigator.of(context).pop(); // Close dialog

      // Handle specific error messages
      String errorMessage = 'An error occurred while deleting.';

      if (e.toString().contains('authentication') ||
          e.toString().contains('token')) {
        errorMessage = 'Session expired. Please login again.';
        await LoginAuthService.clearAuthData();
      } else if (e.toString().contains('not found')) {
        errorMessage = 'Child profile not found or already deleted.';
      } else if (e.toString().contains('forbidden')) {
        errorMessage = 'You don\'t have permission to delete this child.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage =
            'Network error. Please check your connection and try again.';
      }

      _showErrorDialog(errorMessage);
    }
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Delete Child',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isDeletingChild) ...[
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Deleting child profile...',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    Text(
                      'Do you want to delete ${widget.childToEdit?.name}\'s profile? This action cannot be undone and will remove all associated data.',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ],
              ),
              actions: _isDeletingChild
                  ? [] // Hide buttons while deleting
                  : [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _handleDeleteChild(setState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
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

  // Handle delete child process

  // Validate form fields
  bool _validateForm() {
    if (_firstNameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter first name');
      return false;
    }
    if (_birthdayController.text.trim().isEmpty) {
      _showErrorDialog('Please select birthday');
      return false;
    }
    if (_selectedGender.isEmpty) {
      _showErrorDialog('Please select gender');
      return false;
    }
    return true;
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Show success dialog
  void _showSuccessDialog(String message, {bool isDelete = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isDelete ? 'Deleted' : 'Success',
            style: TextStyle(
              color: isDelete ? Colors.red : Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(
                  context,
                ).pop(true); // Go back to profile page with success
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Convert UI gender to API format
  String _convertGenderToApiFormat(String uiGender) {
    return uiGender.toLowerCase() == 'boy' ? 'male' : 'female';
  }

  // Format date for API (YYYY-MM-DD)
  String _formatDateForApi(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Navigate to interests page with child data
  void _navigateToInterests() {
    if (!_validateForm()) return;

    final childData = ChildData(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
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
          widget.isEditMode ? 'EDIT CHILD' : 'ADD CHILD',
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
          ),
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Centered title text
                Center(
                  child: Text(
                    widget.isEditMode
                        ? 'UPDATE YOUR CHILD\'S INFO'
                        : 'TELL US ABOUT YOUR CHILD',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Profile Image Section
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
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
                                ? (widget.childToEdit!.gender.toLowerCase() ==
                                          'male'
                                      ? Icons.boy
                                      : Icons.girl)
                                : Icons.person,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.purple,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.isEditMode ? Icons.edit : Icons.add,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    widget.isEditMode ? 'Edit Photo' : 'Add Photo',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 40),

                // First Name Field
                const Text(
                  'What do we call your child? *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _firstNameController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'First Name',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.orange),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Birthday Field
                const Text(
                  'When is the Birthday? *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _birthdayController,
                  readOnly: true,
                  enabled: !_isLoading,
                  onTap: _isLoading ? null : () => _selectDate(context),
                  decoration: InputDecoration(
                    hintText: 'Date',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: Icon(Icons.calendar_month),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.orange),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Gender Selection
                const Text(
                  'Gender? *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _selectedGender = 'Boy';
                                });
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _selectedGender == 'Boy'
                                ? Colors.orange[100]
                                : Colors.white,
                            border: Border.all(
                              color: _selectedGender == 'Boy'
                                  ? Colors.orange
                                  : Colors.grey[300]!,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Boy',
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedGender == 'Boy'
                                    ? Colors.orange[700]
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _selectedGender = 'Girl';
                                });
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _selectedGender == 'Girl'
                                ? Colors.orange[100]
                                : Colors.white,
                            border: Border.all(
                              color: _selectedGender == 'Girl'
                                  ? Colors.orange
                                  : Colors.grey[300]!,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Girl',
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedGender == 'Girl'
                                    ? Colors.orange[700]
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Add sufficient spacing before the button
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),

                // Next Button - Always navigates to interests page
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _navigateToInterests,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
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
                        : const Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
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
