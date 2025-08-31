import 'package:flutter/material.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/Childs/add_child.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/user_settings_page.dart';
import 'package:klayons/screens/home_screen.dart';

import '../../../services/user_child/get_ChildServices.dart';
import '../../../services/get_userprofile_service.dart';
import '../../../utils/styles/fonts.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  UserProfile? userProfile;
  List<Child>? children;
  bool isLoading = true;
  bool isLoadingChildren = true;
  String? errorMessage;
  String? childrenErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadChildren();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final profile = await GetUserProfileService.getUserProfile();

      setState(() {
        userProfile = profile;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });

      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Failed to load profile'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadUserProfile,
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadChildren({bool clearCache = false}) async {
    try {
      setState(() {
        isLoadingChildren = true;
        childrenErrorMessage = null;
      });

      // Clear cache if requested
      if (clearCache) {
        GetChildservices.clearAllCache();
        print('🗑️ Children cache cleared');
      }

      // First try to get cached data (unless we just cleared cache)
      if (!clearCache) {
        final cachedChildren = GetChildservices.getCachedChildren();
        if (cachedChildren != null) {
          setState(() {
            children = cachedChildren;
            isLoadingChildren = false;
          });
          print(
            '✅ Children loaded from cache (${cachedChildren.length} items)',
          );
          return;
        }
      }

      // If no valid cache, fetch from server
      final childrenData = await GetChildservices.fetchChildren();

      setState(() {
        children = childrenData;
        isLoadingChildren = false;
      });

      print('✅ Children loaded from server (${childrenData.length} items)');
    } catch (e) {
      setState(() {
        childrenErrorMessage = e.toString();
        isLoadingChildren = false;
      });

      print('❌ Error loading children: $e');
    }
  }

  // Add this helper method for refresh with cache clear
  Future<void> _loadChildrenWithCacheClear() async {
    return _loadChildren(clearCache: true);
  }

  Future<void> _refreshAll() async {
    print('🔄 Refreshing all data - clearing caches...');

    try {
      setState(() {
        isLoading = true;
        isLoadingChildren = true;
        errorMessage = null;
        childrenErrorMessage = null;
      });

      // Clear the children cache before refreshing
      GetChildservices.clearAllCache();

      // Clear user profile cache if your GetUserProfileService has cache
      // GetUserProfileService.clearCache(); // Add this if your service has cache

      // Fetch fresh data from both services
      await Future.wait([_loadUserProfile(), _loadChildren(clearCache: true)]);

      print('✅ All data refreshed successfully');
    } catch (e) {
      print('❌ Error during refresh: $e');
    }
  }

  String _getUserName() {
    if (userProfile?.name.isNotEmpty == true) {
      // Capitalize each word in the name
      return userProfile!.name
          .split(' ')
          .map(
            (word) => word.isNotEmpty
                ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                : '',
          )
          .join(' ');
    }
    return 'USER NAME';
  }

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      List<String> months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${date.day}${_getDaySuffix(date.day)} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  Color _getAvatarColor(String gender) {
    return gender.toLowerCase() == 'male'
        ? const Color(0xFF4A90E2)
        : const Color(0xFFE91E63);
  }

  IconData _getGenderIcon(String gender) {
    return gender.toLowerCase() == 'male' ? Icons.boy : Icons.girl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        title: const Text(
          'YOUR PROFILE',
          style: AppTextStyles.titleMedium,
        ),
        centerTitle: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => KlayonsHomePage()),
            );
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Profile Section
                _buildUserProfileSection(context),
                const SizedBox(height: 24),

                // Children Profiles Section
                _buildChildrenProfilesSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isLoading
          ? _buildLoadingProfile()
          : errorMessage != null
          ? _buildErrorProfile()
          : _buildUserProfileContent(),
    );
  }

  Widget _buildLoadingProfile() {
    return Row(
      children: [
        // Loading Profile Image
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
          ),
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
        const SizedBox(width: 16),

        // Loading User Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 180,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 140,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorProfile() {
    return Column(
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 12),
                  Text(
            'Failed to load profile',
            style: AppTextStyles.titleMedium.copyWith(
              color: Colors.grey[700],
            ),
          ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _loadUserProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A90E2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildUserProfileContent() {
    return Row(
      children: [
        // Profile Image
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              color: Colors.grey[300],
              child: const Icon(Icons.person, color: Colors.white, size: 30),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // User Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getUserName(),
                style: AppTextStyles.titleLarge.copyWith(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getDisplayEmail(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _getEmailTextColor(),
                  fontStyle: _isEmailAvailable()
                      ? FontStyle.normal
                      : FontStyle.italic,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _getDisplayPhone(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _getPhoneTextColor(),
                  fontStyle: _isPhoneAvailable()
                      ? FontStyle.normal
                      : FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper methods for email handling
  String _getDisplayEmail() {
    if (userProfile?.userEmail == null ||
        userProfile!.userEmail.trim().isEmpty) {
      return 'Email not provided';
    }
    return userProfile!.userEmail;
  }

  Color _getEmailTextColor() {
    return _isEmailAvailable() ? Colors.grey[600]! : Colors.grey[400]!;
  }

  bool _isEmailAvailable() {
    return userProfile?.userEmail != null &&
        userProfile!.userEmail.trim().isNotEmpty;
  }

  // Helper methods for phone handling
  String _getDisplayPhone() {
    if (userProfile?.userPhone == null ||
        userProfile!.userPhone.trim().isEmpty) {
      return 'Phone not provided';
    }
    return userProfile!.userPhone;
  }

  Color _getPhoneTextColor() {
    return _isPhoneAvailable() ? Colors.grey[600]! : Colors.grey[400]!;
  }

  bool _isPhoneAvailable() {
    return userProfile?.userPhone != null &&
        userProfile!.userPhone.trim().isNotEmpty;
  }

  Widget _buildChildrenProfilesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'CHILDREN PROFILES',
              style: AppTextStyles.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.black87, size: 24),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddChildPage()),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Children Cards - Dynamic from API
        _buildChildrenCards(),
      ],
    );
  }

  Widget _buildChildrenCards() {
    if (isLoadingChildren) {
      return _buildLoadingChildrenCards();
    }

    if (childrenErrorMessage != null) {
      return _buildChildrenError();
    }

    if (children == null || children!.isEmpty) {
      return _buildNoChildrenFound();
    }

    // Display children in a grid layout (2 columns max)
    List<Widget> childCards = [];
    for (int i = 0; i < children!.length; i += 2) {
      List<Widget> rowChildren = [];

      // Add first child in the row
      rowChildren.add(Expanded(child: _buildChildCard(child: children![i])));

      // Add second child in the row if exists
      if (i + 1 < children!.length) {
        rowChildren.add(const SizedBox(width: 12));
        rowChildren.add(
          Expanded(child: _buildChildCard(child: children![i + 1])),
        );
      } else {
        // Add empty expanded widget to maintain layout
        rowChildren.add(const SizedBox(width: 12));
        rowChildren.add(const Expanded(child: SizedBox()));
      }

      childCards.add(Row(children: rowChildren));

      // Add spacing between rows
      if (i + 2 < children!.length) {
        childCards.add(const SizedBox(height: 12));
      }
    }

    return Column(children: childCards);
  }

  Widget _buildLoadingChildrenCards() {
    return Row(
      children: [
        Expanded(child: _buildLoadingChildCard()),
        const SizedBox(width: 12),
        Expanded(child: _buildLoadingChildCard()),
      ],
    );
  }

  Widget _buildLoadingChildCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 100,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 70,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenError() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(
            'Failed to load children profiles',
            style: AppTextStyles.titleMedium.copyWith(
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadChildren,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoChildrenFound() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.child_care, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'No children profiles found',
            style: AppTextStyles.titleMedium.copyWith(
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first child profile',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // Replace your existing _buildChildCard method with this updated version
  // Updated _buildChildCard method for your UserProfilePage
  // Replace your existing _buildChildCard method with this one

  Widget _buildChildCard({required Child child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar and Edit Icon Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getAvatarColor(child.gender),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getGenderIcon(child.gender),
                  color: Colors.white,
                  size: 20,
                ),
              ),

              // Replace your existing edit button onPressed in _buildChildCard method with this:
              // In your _buildChildCard method, update the edit button onPressed:
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey, size: 16),
                onPressed: () async {
                  print('Editing child with ID: ${child.id}');

                  try {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddChildPage(childToEdit: child, isEditMode: true),
                      ),
                    );

                    // If changes were made, clear cache and refresh
                    if (result == true) {
                      print('Child updated, clearing cache and refreshing...');

                      // Clear cache and reload with fresh data
                      GetChildservices.clearAllCache();
                      await _loadChildren();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Child profile updated successfully!',
                            ),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    print('Error in child edit flow: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Child Details
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Child ID (for debugging - you can remove this in production)
              Text(
                'ID: ${child.id}',
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 10,
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 2),

              // Child Name
              Text(
                child.name,
                style: AppTextStyles.titleSmall.copyWith(
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),

              // Birth Date
              Text(
                'Birthdate: ${_formatDate(child.dob)}',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),

              // Gender
              Text(
                'Gender: ${child.gender.toLowerCase() == 'male' ? 'Boy' : 'Girl'}',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
              ),

              // Show interests if available
              if (child.interests.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Interests: ${child.interests.take(2).map((i) => i.name).join(', ')}${child.interests.length > 2 ? '...' : ''}',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ] else ...[
                const SizedBox(height: 4),
                Text(
                  'No interests added',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10,
                    color: Colors.grey[400],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Also, make sure your EditChildPage import is correct at the top of your UserProfilePage:
  // import 'Childs/editChild.dart'; // Update this path to match your new EditChildPage

  // You might also want to add this debug method to help troubleshoot:
  void _debugChildData(Child child) {
    print('=== Child Debug Info ===');
    print('ID: ${child.id}');
    print('Name: ${child.name}');
    print('DOB: ${child.dob}');
    print('Gender: ${child.gender}');
    print(
      'Interests: ${child.interests.map((i) => '${i.id}: ${i.name}').join(', ')}',
    );
    print('========================');
  }
}
