import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:klayons/config/api_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AddChildPage extends StatefulWidget {
  const AddChildPage({Key? key}) : super(key: key);

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

  // API endpoint
  String apiUrl = ApiConfig.getFullUrl(ApiConfig.addChildrenEndpoint);

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  // Get token from SharedPreferences with debugging
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Debug: Check all keys in SharedPreferences
      Set<String> keys = prefs.getKeys();
      print('All SharedPreferences keys: $keys');

      // Try multiple possible token keys
      String? token =
          prefs.getString('auth_token') ??
          prefs.getString('token') ??
          prefs.getString('access_token') ??
          prefs.getString('user_token');

      print(
        'Retrieved token: ${token != null ? "Token found (${token.length} chars)" : "No token found"}',
      );

      return token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Child profile created successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.pushReplacementNamed(
                  context,
                  '/user_profile_page',
                ); // Go back to previous page
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // No conversion needed - backend accepts "Boy" and "Girl" directly

  // Format date for API (YYYY-MM-DD format)
  String _formatDateForAPI(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Submit child data to API
  Future<void> _submitChildData() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get authentication token
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        _showErrorDialog('Authentication required. Please login again.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Prepare data for API with correct field names and formats
      final Map<String, dynamic> childData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'date_of_birth': _formatDateForAPI(
          _selectedDate!,
        ), // Fixed: changed from 'birthdate' to 'date_of_birth'
        'gender': _selectedGender, // Send "Boy" or "Girl" directly
      };

      print('Sending child data: $childData');
      print('API URL: $apiUrl');

      // Try Django Token format first
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      };

      print('Using headers: $headers');

      // Make API call with Django Token authentication
      http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode(childData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // If Token format fails with 401, try Bearer format
      if (response.statusCode == 401) {
        print('Trying Bearer token format...');
        headers['Authorization'] = 'Bearer $token';

        response = await http.post(
          Uri.parse(apiUrl),
          headers: headers,
          body: json.encode(childData),
        );

        print('Bearer response status: ${response.statusCode}');
        print('Bearer response body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        _showSuccessDialog();
      } else {
        // Handle API error
        String errorMessage = 'Failed to create child profile';

        try {
          final errorData = json.decode(response.body);

          // Handle detailed field errors from Django
          if (errorData['errors'] != null) {
            List<String> fieldErrors = [];
            errorData['errors'].forEach((field, messages) {
              if (messages is List) {
                fieldErrors.add('$field: ${messages.join(', ')}');
              } else {
                fieldErrors.add('$field: $messages');
              }
            });
            errorMessage = fieldErrors.join('\n');
          } else if (errorData['detail'] != null) {
            errorMessage = errorData['detail'];
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (e) {
          // If response is not JSON, use status code
          if (response.statusCode == 401) {
            errorMessage = 'Authentication failed. Please login again.';
          } else if (response.statusCode == 400) {
            errorMessage = 'Invalid data provided. Please check your inputs.';
          } else {
            errorMessage =
                'Server error (${response.statusCode}). Please try again later.';
          }
        }

        _showErrorDialog(errorMessage);
      }
    } catch (error) {
      // Handle network or other errors
      _showErrorDialog('Network error: Please check your internet connection');
      print('Error submitting child data: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/user_profile_page'),
        ),
        title: const Text(
          'ADD CHILD',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'TELL US ABOUT YOUR CHILD',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 40),

            // Profile Image Section
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(Icons.person, size: 40, color: Colors.white),
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
                        child: const Icon(
                          Icons.add,
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
            const Center(
              child: Text(
                'Add Photo',
                style: TextStyle(fontSize: 12, color: Colors.black54),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Last Name Field
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                hintText: 'Last Name',
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
              onTap: () => _selectDate(context),
              decoration: InputDecoration(
                hintText: 'Date',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: const Icon(
                  Icons.calendar_today,
                  color: Colors.grey,
                  size: 20,
                ),
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
                    onTap: () {
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
                    onTap: () {
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
            const Spacer(),

            // Next Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitChildData,
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
    );
  }
}
