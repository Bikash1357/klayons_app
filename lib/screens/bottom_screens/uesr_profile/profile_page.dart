import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/Childs/add_child.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/user_settings_page.dart';
import 'package:klayons/screens/home_screen.dart';
import 'package:klayons/utils/colour.dart';
import '../../../services/UserProfileServices/userProfileModels.dart';
import '../../../services/auth/login_service.dart';
import '../../../services/user_child/get_ChildServices.dart';
import '../../../services/UserProfileServices/get_userprofile_service.dart';
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
  bool isLoggingOut = false;
  String? errorMessage;
  String? childrenErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadChildren();
  }

  Future<void> _loadUserProfile({bool forceRefresh = false}) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final profile = await GetUserProfileService.getUserProfile(
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          userProfile = profile;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Failed to load profile'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _loadUserProfile(forceRefresh: true),
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadChildren({bool forceRefresh = false}) async {
    try {
      setState(() {
        isLoadingChildren = true;
        childrenErrorMessage = null;
      });

      if (forceRefresh) {
        GetChildservices.clearAllCache();
        print('🗑️ Children cache cleared for refresh');
      }

      final childrenData = await GetChildservices.fetchChildren(
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          children = childrenData;
          isLoadingChildren = false;
        });

        print('✅ Children loaded (${childrenData.length} items)');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          childrenErrorMessage = e.toString();
          isLoadingChildren = false;
        });

        print('❌ Error loading children: $e');
      }
    }
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

      GetChildservices.clearAllCache();

      await Future.wait([
        _loadUserProfile(forceRefresh: true),
        _loadChildren(forceRefresh: true),
      ]);

      print('✅ All data refreshed successfully');
    } catch (e) {
      print('❌ Error during refresh: $e');
    }
  }

  Future<void> _showLogoutConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Confirm Logout',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(fontSize: 16, color: Color(0xFF4A5568)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF718096), fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Logout', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _performLogout();
    }
  }

  Future<void> _performLogout() async {
    try {
      setState(() {
        isLoggingOut = true;
      });

      print('🔄 Starting logout process...');

      final success = await LoginAuthService.logout();

      if (success) {
        print('✅ Logout successful');

        GetChildservices.clearAllCache();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged out successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } else {
        throw Exception('Logout failed');
      }
    } catch (e) {
      print('❌ Logout error: $e');

      if (mounted) {
        setState(() {
          isLoggingOut = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _showLogoutConfirmation,
            ),
          ),
        );
      }
    }
  }

  String _getUserName() {
    if (userProfile?.name.isNotEmpty == true) {
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

  String _getAddress() {
    if (userProfile == null) return 'SOCIETY NAME';

    switch (userProfile!.residenceType) {
      case 'society':
        if (userProfile!.societyName.isNotEmpty) {
          return userProfile!.societyName;
        } else if (userProfile!.societyId != null &&
            userProfile!.societyId! > 0) {
          return 'Society ID: ${userProfile!.societyId}';
        }
        return 'Society Resident';

      case 'society_other':
        if (userProfile!.societyName.isNotEmpty) {
          return userProfile!.societyName;
        }
        return 'Other Society';

      case 'individual':
        if (userProfile!.address?.isNotEmpty == true) {
          return userProfile!.address!;
        }
        return 'Individual Residence';

      default:
        if (userProfile!.societyName.isNotEmpty) {
          return userProfile!.societyName;
        } else if (userProfile!.address?.isNotEmpty == true) {
          return userProfile!.address!;
        }
        return 'Location not set';
    }
  }

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      DateTime now = DateTime.now();
      int age = now.year - date.year;
      if (now.month < date.month ||
          (now.month == date.month && now.day < date.day)) {
        age--;
      }
      return '$age years';
    } catch (e) {
      return 'Unknown age';
    }
  }

  Color _getAvatarColor(String gender) {
    return gender.toLowerCase() == 'male'
        ? AppColors.primaryOrange
        : AppColors.primaryOrange;
  }

  IconData _getGenderIcon(String gender) {
    return gender.toLowerCase() == 'male' ? Icons.boy : Icons.girl;
  }

  String _getDisplayEmail() {
    if (userProfile?.userEmail == null ||
        userProfile!.userEmail.trim().isEmpty) {
      return 'Email not provided';
    }
    return userProfile!.userEmail;
  }

  String _getDisplayPhone() {
    if (userProfile?.userPhone == null ||
        userProfile!.userPhone.trim().isEmpty) {
      return 'Add Phone';
    }
    return userProfile!.userPhone;
  }

  bool _isPhoneAvailable() {
    return userProfile?.userPhone != null &&
        userProfile!.userPhone.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
              Navigator.pop(context), // Fixed: proper back navigation
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Your Profile',
          style: AppTextStyles.titleLarge(
            context,
          ).copyWith(color: AppColors.darkElements),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Color(0xFF2D3748),
              size: 24,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.primaryOrange,
            onRefresh: _refreshAll,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildUserProfileSection(context),
                  _buildChildrenProfilesSection(context),
                  _buildMenuSection(context),
                ],
              ),
            ),
          ),
          if (isLoggingOut)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.deepOrange,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Logging out...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserProfileSection(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SettingsPage()),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
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
        child: isLoading
            ? _buildLoadingProfile()
            : errorMessage != null
            ? _buildErrorProfile()
            : _buildUserProfileContent(),
      ),
    );
  }

  Widget _buildLoadingProfile() {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
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
              const SizedBox(height: 12),
              Container(
                width: 100,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
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
        const Text(
          'Failed to load profile',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => _loadUserProfile(forceRefresh: true),
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
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/profile_bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.1)),
                child: const Icon(Icons.person, color: Colors.white, size: 32),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getUserName(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Color(0xFF718096)),
                  const SizedBox(width: 6),
                  Text(
                    _getDisplayPhone(),
                    style: TextStyle(
                      fontSize: 14,
                      color: _isPhoneAvailable()
                          ? const Color(0xFF4A5568)
                          : const Color(0xFF718096),
                      fontStyle: _isPhoneAvailable()
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: Color(0xFF718096),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _getAddress(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4A5568),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChildrenProfilesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Children Profiles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              InkWell(
                onTap: () async {
                  print('🔄 Navigating to Add Child screen...');

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddChildPage()),
                  );

                  if (result == true && mounted) {
                    print('✅ Child added successfully, refreshing profile...');

                    await _loadChildren(forceRefresh: true);
                    await _loadUserProfile(forceRefresh: true);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Child profile added successfully!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add,
                    color: AppColors.primaryOrange,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildChildrenCards(),
        ],
      ),
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

    List<Widget> childCards = [];
    for (int i = 0; i < children!.length; i += 2) {
      List<Widget> rowChildren = [];

      rowChildren.add(Expanded(child: _buildChildCard(child: children![i])));

      if (i + 1 < children!.length) {
        rowChildren.add(const SizedBox(width: 16));
        rowChildren.add(
          Expanded(child: _buildChildCard(child: children![i + 1])),
        );
      } else {
        rowChildren.add(const SizedBox(width: 16));
        rowChildren.add(const Expanded(child: SizedBox()));
      }

      childCards.add(Row(children: rowChildren));

      if (i + 2 < children!.length) {
        childCards.add(const SizedBox(height: 16));
      }
    }

    return Column(children: childCards);
  }

  Widget _buildLoadingChildrenCards() {
    return Row(
      children: [
        Expanded(child: _buildLoadingChildCard()),
        const SizedBox(width: 16),
        Expanded(child: _buildLoadingChildCard()),
      ],
    );
  }

  Widget _buildLoadingChildCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
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
              const SizedBox(height: 6),
              Container(
                width: 60,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
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
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Failed to load children profiles',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _loadChildren(forceRefresh: true),
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
      width: 170,
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          IconButton(
            iconSize: 50.0,
            onPressed: () async {
              print('🔄 Adding first child...');

              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddChildPage()),
              );

              if (result == true && mounted) {
                print('✅ First child added, refreshing...');
                await _loadChildren(forceRefresh: true);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Child profile added successfully!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.add, color: Color(0xFF718096)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add child',
            style: TextStyle(fontSize: 14, color: Color(0xFF718096)),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard({required Child child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getAvatarColor(child.gender),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getGenderIcon(child.gender),
                  color: Colors.white,
                  size: 18,
                ),
              ),
              InkWell(
                onTap: () async {
                  print('✏️ Editing child with ID: ${child.id}');

                  try {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddChildPage(childToEdit: child, isEditMode: true),
                      ),
                    );

                    if (result == true && mounted) {
                      print('✅ Child updated, refreshing...');

                      await _loadChildren(forceRefresh: true);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Child profile updated successfully!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    print('❌ Error in child edit flow: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
                child: const Icon(
                  Icons.edit,
                  color: Color(0xFF718096),
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                child.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Age: ${_formatDate(child.dob)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
              ),
              const SizedBox(height: 4),
              Text(
                'Gender: ${child.gender.toLowerCase() == 'male' ? 'Boy' : 'Girl'}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
        children: [
          _buildMenuItem('About Klayons', Icons.info_outline, () {}),
          const Divider(color: Color(0xFFE2E8F0)),
          _buildMenuItem(
            'Child Protection Policy',
            Icons.shield_outlined,
            () {},
          ),
          const Divider(color: Color(0xFFE2E8F0)),
          _buildMenuItem(
            'Payments & Refund Policy',
            Icons.payment_outlined,
            () {},
          ),
          const Divider(color: Color(0xFFE2E8F0)),
          _buildMenuItem('Terms of Service', Icons.description_outlined, () {}),
          const Divider(color: Color(0xFFE2E8F0)),
          _buildMenuItem('Privacy Policy', Icons.privacy_tip_outlined, () {}),
          const Divider(color: Color(0xFFE2E8F0)),
          _buildMenuItem(
            'Log Out',
            Icons.logout,
            _showLogoutConfirmation,
            isLogout: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isLogout ? Colors.red : const Color(0xFF718096),
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isLogout ? Colors.red : const Color(0xFF4A5568),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (!isLogout)
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF718096),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
