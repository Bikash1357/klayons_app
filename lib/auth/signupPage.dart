import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:klayons/config/api_config.dart';
import 'package:klayons/utils/styles/fonts.dart';
import 'package:klayons/utils/styles/button.dart';
import 'package:klayons/utils/colour.dart';
import 'package:klayons/utils/styles/textboxes.dart';
import '../utils/styles/textButton.dart';
import 'login_screen.dart';
import 'otp_verification_page.dart';
import 'package:klayons/utils/styles/button.dart';

class Society {
  final int id;
  final String name;
  final String address;

  Society({required this.id, required this.name, required this.address});
  factory Society.fromJson(Map<String, dynamic> json) => Society(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    address: json['address'] ?? '',
  );
}

class SignUnPage extends StatefulWidget {
  @override
  State<SignUnPage> createState() => _SignUnPageState();
}

class _SignUnPageState extends State<SignUnPage> {
  final _nameController = TextEditingController();
  final _emailOrPhoneController = TextEditingController();
  final _searchController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoadingLocation = false;
  String? _selectedResidence;
  List<Society> _societies = [];
  List<Society> _filteredSocieties = [];
  Society? _selectedSociety;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _fetchSocieties();
    _searchController.addListener(_onSearchChanged);
  }

  _fetchSocieties() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getFullUrl(ApiConfig.getSocieties)),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          _societies = data.map((json) => Society.fromJson(json)).toList();
        });
      }
    } catch (e) {
      _showMessage('Failed to load societies', false);
    }
  }

  _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSocieties = [];
        _showSuggestions = false;
        _selectedSociety = null;
      } else {
        _filteredSocieties = _societies
            .where((s) => s.name.toLowerCase().contains(query))
            .toList();
        _showSuggestions = _filteredSocieties.isNotEmpty;
      }
    });
  }

  _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('Location permission denied', false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String area = place.subLocality ?? place.locality ?? '';
        String pincode = place.postalCode ?? '';
        setState(() {
          _addressController.text = '$area, $pincode';
        });
        _showMessage('Location auto-filled', true);
      }
    } catch (e) {
      _showMessage('Failed to get location', false);
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  _submitForm() async {
    if (!_isFormValid()) return;

    setState(() => _isSubmitting = true);

    try {
      String emailOrPhone = _emailOrPhoneController.text.trim();
      String? email = emailOrPhone.contains('@') ? emailOrPhone : null;
      String? phone = emailOrPhone.contains('@') ? null : emailOrPhone;

      Map<String, dynamic> requestBody = {
        'name': _nameController.text.trim(),
        'residence_type': _selectedResidence,
        'address': _selectedResidence == 'society'
            ? _selectedSociety!.address
            : _addressController.text.trim(),
      };

      if (email != null) requestBody['email'] = email;
      if (phone != null) requestBody['phone'] = phone;
      if (_selectedResidence == 'society')
        requestBody['society_name'] = _selectedSociety!.name;

      final response = await http.post(
        Uri.parse('https://dev-klayonsapi.vercel.app/api/auth/signup/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _showMessage('OTP sent successfully!', true);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationPage(
              email: emailOrPhone,
              purpose: 'registration',
            ),
          ),
        );
      } else {
        String message = data['message'] ?? 'Registration failed';
        if (message.toLowerCase().contains('already')) {
          _showAlreadyRegisteredDialog(emailOrPhone);
        } else {
          _showMessage(message, false);
        }
      }
    } catch (e) {
      _showMessage('Network error', false);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  _isFormValid() {
    bool basic =
        _nameController.text.trim().isNotEmpty &&
        _emailOrPhoneController.text.trim().isNotEmpty &&
        _selectedResidence != null;

    if (_selectedResidence == 'society') {
      return basic && _selectedSociety != null;
    } else if (_selectedResidence == 'individual') {
      return basic && _addressController.text.trim().isNotEmpty;
    }
    return basic;
  }

  _showMessage(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  _showAlreadyRegisteredDialog(String emailOrPhone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Already Registered',
          style: AppTextStyles.titleMedium.copyWith(color: Color(0xFFFF6B35)),
        ),
        content: Text(
          'You have already registered with this ${emailOrPhone.contains('@') ? 'email' : 'phone'}. Please login instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          OrangeButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            child: Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top section with background image - SAME AS LOGIN PAGE
              Stack(
                children: [
                  Container(
                    height:
                        MediaQuery.of(context).size.height *
                        0.35, // Same as login page
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/Auth_Header_img.png'),
                        fit: BoxFit.cover, // Same as login page
                      ),
                    ),
                  ),
                  // Back Button positioned at top-left
                  Positioned(
                    top: 8,
                    left: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.black,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        padding: EdgeInsets.all(8),
                      ),
                    ),
                  ),
                  // Rounded overlay to blend with form section - SAME AS LOGIN PAGE
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 15, // Same as login page
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

              // Form section - SAME STRUCTURE AS LOGIN PAGE
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Signup form header - SAME STYLING AS LOGIN PAGE
                    Center(
                      child: Text(
                        'Register your account',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                    SizedBox(height: 32),

                    // Name
                    CustomTextField(
                      hintText: 'Name*',
                      controller: _nameController,
                      keyboardType: TextInputType.text,
                    ),
                    SizedBox(height: 16),

                    // Email or Phone
                    CustomTextField(
                      hintText: 'Email or Phone*',
                      controller: _emailOrPhoneController,
                      keyboardType: TextInputType.text,
                    ),
                    SizedBox(height: 24),

                    // Residence Type
                    Text(
                      'Where do you reside?',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        _buildResidenceOption(
                          'Society Complex',
                          Icons.apartment,
                          'society',
                        ),
                        SizedBox(width: 12),
                        _buildResidenceOption(
                          'Individual Housing',
                          Icons.home,
                          'individual',
                        ),
                      ],
                    ),

                    // Dynamic Fields
                    if (_selectedResidence == 'society') _buildSocietyField(),
                    if (_selectedResidence == 'individual')
                      _buildAddressField(),

                    SizedBox(height: 32),

                    // Submit Button - SAME STYLING AS LOGIN PAGE
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OrangeButton(
                        onPressed: _isFormValid() && !_isSubmitting
                            ? _submitForm
                            : null,
                        child: _isSubmitting
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
                                'Send OTP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Divider with "or" - SAME AS LOGIN PAGE
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

                    // Login Link - SAME STYLING AS LOGIN PAGE
                    Center(
                      child: Column(
                        children: [
                          Text(
                            "Already have an account?",
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 8),
                          CustomTextButton(
                            text: "Log in",
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginPage(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32),

                    // Terms and Privacy Policy - SAME AS LOGIN PAGE
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

  Widget _buildTextField(TextEditingController controller, String hint) {
    return StatefulBuilder(
      builder: (context, setState) {
        return TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey[500],
            ),
            // Grey border when inactive
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey!, width: 1),
            ),
            // Grey border when enabled but not focused
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: controller.text.isNotEmpty
                    ? Color(0xFFFF6B35)
                    : Colors.grey[300]!,
                width: controller.text.isNotEmpty ? 2 : 1,
              ),
            ),
            // Orange border when focused
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFFFF6B35), width: 2),
            ),
            contentPadding: EdgeInsets.all(16),
          ),
          onChanged: (value) {
            setState(() {}); // Rebuild to update border color
          },
        );
      },
    );
  }

  Widget _buildResidenceOption(String title, IconData icon, String value) {
    bool isSelected = _selectedResidence == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedResidence = value;
          if (value == 'society')
            _addressController.clear();
          else {
            _searchController.clear();
            _selectedSociety = null;
          }
        }),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Color(0xFFFF6B35) : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? Color(0xFFFF6B35).withOpacity(0.1)
                : Colors.white,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Color(0xFFFF6B35) : Colors.grey[600],
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? Color(0xFFFF6B35) : Colors.grey,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocietyField() {
    return Column(
      children: [
        SizedBox(height: 16),
        CustomTextField(
          hintText: 'Search Society Complex*',
          controller: _searchController,
          keyboardType: TextInputType.text,
        ),
        if (_showSuggestions)
          Container(
            margin: EdgeInsets.only(top: 4),
            constraints: BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFFF6B35)),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredSocieties.length,
              itemBuilder: (context, index) {
                final society = _filteredSocieties[index];
                return ListTile(
                  title: Text(society.name),
                  subtitle: Text(
                    society.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    _searchController.text = society.name;
                    setState(() {
                      _selectedSociety = society;
                      _showSuggestions = false;
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAddressField() {
    return Column(
      children: [
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OrangeButton(
            onPressed: _isLoadingLocation ? null : _getCurrentLocation,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isLoadingLocation
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.my_location, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  _isLoadingLocation ? 'Getting Location...' : 'locality',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        CustomTextField(
          hintText: 'Area, Pincode*',
          controller: _addressController,
          keyboardType: TextInputType.text,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailOrPhoneController.dispose();
    _searchController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
