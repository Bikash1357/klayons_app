import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:klayons/screens/bottom_screens/uesr_profile/add_child.dart';
import '../../../services/addchildservice.dart';

// Interest model class
class Interest {
  final int id;
  final String name;

  Interest({required this.id, required this.name});

  factory Interest.fromJson(Map<String, dynamic> json) {
    return Interest(id: json['id'] as int, name: json['name'] as String);
  }
}

// Interest service class
class InterestService {
  static const String baseUrl = 'https://klayons-backend.vercel.app/api';

  static Future<List<Interest>> getInterests() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profiles/interests/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Interest.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load interests. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

class AddChildInterestsPage extends StatefulWidget {
  final ChildData childData;

  const AddChildInterestsPage({Key? key, required this.childData})
    : super(key: key);

  @override
  _AddChildInterestsPageState createState() => _AddChildInterestsPageState();
}

class _AddChildInterestsPageState extends State<AddChildInterestsPage> {
  Set<int> selectedInterestIds = {};
  bool _isLoading = false;
  bool _isLoadingInterests = true;
  List<Interest> interests = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInterests();
  }

  // Load interests from API
  Future<void> _loadInterests() async {
    try {
      setState(() {
        _isLoadingInterests = true;
        _errorMessage = null;
      });

      final loadedInterests = await InterestService.getInterests();

      setState(() {
        interests = loadedInterests;
        _isLoadingInterests = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingInterests = false;
        _errorMessage = 'Failed to load interests: ${e.toString()}';
      });
    }
  }

  // Retry loading interests
  Future<void> _retryLoadingInterests() async {
    await _loadInterests();
  }

  // Get color for interest based on index (since API doesn't provide colors)
  Color _getInterestColor(int index) {
    final colors = [Colors.orange];
    return colors[index % colors.length];
  }

  // Get icon for interest based on name (basic mapping)
  IconData _getInterestIcon(String name) {
    final iconMap = {
      'robotics': Icons.precision_manufacturing,
      'speech': Icons.record_voice_over,
      'drama': Icons.theater_comedy,
      'chess': Icons.casino,
      'taekwondo': Icons.sports_martial_arts,
      'karate': Icons.sports_martial_arts,
      'drawing': Icons.brush,
      'science': Icons.science,
      'painting': Icons.palette,
      'reading': Icons.menu_book,
      'dance': Icons.music_note,
      'singing': Icons.mic,
      'music': Icons.piano,
      'sports': Icons.sports_soccer,
      'coding': Icons.code,
      'crafting': Icons.handyman,
      'languages': Icons.language,
      'swimming': Icons.pool,
      'cooking': Icons.restaurant,
      'photography': Icons.camera_alt,
    };

    String lowerName = name.toLowerCase();
    for (String key in iconMap.keys) {
      if (lowerName.contains(key)) {
        return iconMap[key]!;
      }
    }
    return Icons.interests; // Default icon
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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Child profile created successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous page
                Navigator.of(context).pop(); // Go back to profile page
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Submit child data with interests
  Future<void> _submitChildData() async {
    if (selectedInterestIds.isEmpty) {
      _showErrorDialog('Please select at least one interest');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AddChildService.createChild(
        firstName: widget.childData.firstName,
        lastName: widget.childData.lastName,
        dateOfBirth: widget.childData.dateOfBirth,
        gender: widget.childData.gender,
        interestIds: selectedInterestIds.toList(),
      );

      if (result['success']) {
        _showSuccessDialog();
      } else {
        _showErrorDialog(result['error']);
      }
    } catch (e) {
      _showErrorDialog('An unexpected error occurred. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Build error state
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.grey[400], size: 64),
          SizedBox(height: 16),
          Text(
            'Failed to load interests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _retryLoadingInterests,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Retry',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange!),
          ),
          SizedBox(height: 16),
          Text(
            'Loading interests...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // Build interests grid
  Widget _buildInterestsGrid() {
    if (interests.isEmpty) {
      return Center(
        child: Text(
          'No interests available',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: interests.length,
      itemBuilder: (context, index) {
        final interest = interests[index];
        final isSelected = selectedInterestIds.contains(interest.id);
        final color = _getInterestColor(index);
        final icon = _getInterestIcon(interest.name);

        return GestureDetector(
          onTap: _isLoading
              ? null
              : () {
                  setState(() {
                    if (isSelected) {
                      selectedInterestIds.remove(interest.id);
                    } else {
                      selectedInterestIds.add(interest.id);
                    }
                  });
                },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected ? color : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? color : Colors.grey[600],
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      interest.name,
                      style: TextStyle(
                        color: isSelected ? color : Colors.grey[700],
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ADD CHILD',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text(
              'WHAT INTERESTS YOUR CHILD?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Select interests for ${widget.childData.firstName}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 30),
            Expanded(
              child: _isLoadingInterests
                  ? _buildLoadingState()
                  : _errorMessage != null
                  ? _buildErrorState()
                  : _buildInterestsGrid(),
            ),
            SizedBox(height: 20),
            if ((selectedInterestIds.isNotEmpty || _isLoading) &&
                !_isLoadingInterests)
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitChildData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
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
                          'Save Child Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
