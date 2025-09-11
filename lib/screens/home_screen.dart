import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/user_settings_page.dart';
import 'package:klayons/screens/notification.dart';
import 'package:klayons/services/activity/activities_batchServices/batchWithActivity.dart';
import 'package:klayons/services/notification/notification_service.dart';
import 'package:klayons/utils/styles/fonts.dart';
import '../services/get_userprofile_service.dart';
import '../services/notification/local_notification_service.dart';
import '../utils/colour.dart';
import 'batch_details_page.dart';
import 'user_calender/calander.dart';
import 'bottom_screens/enrolledpage.dart';
import 'bottom_screens/uesr_profile/profile_page.dart';
import 'package:permission_handler/permission_handler.dart';

class KlayonsHomePage extends StatefulWidget {
  @override
  _KlayonsHomePageState createState() => _KlayonsHomePageState();
}

class _KlayonsHomePageState extends State<KlayonsHomePage>
    with TickerProviderStateMixin {
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();
  int selectedIndex = 0;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  final List<Widget> _pages = [
    Container(), // Home content handled separately
    CalendarScreen(),
    EnrolledPage(),
    UserProfilePage(),
  ];
  List<BatchWithActivity> batchData = [];
  bool isLoading = false;
  String? errorMessage;
  // Notification badge state
  int unreadNotificationCount = 0;
  bool isLoadingNotifications = false;
  // User profile data
  UserProfile? userProfile;
  bool isLoadingUserProfile = false;
  String userName = 'User'; // Default name
  String userAddress = ''; // Default address
  String? userProfileImage; // URL for user profile image
  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _loadBatchData();
    _loadUserProfile(); // Load user profile data
    _loadNotificationCount();
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    final bool hasPermission =
        await LocalNotificationService.areNotificationsEnabled();
    if (!hasPermission) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enable Notifications'),
        content: Text(
          'Please enable notifications to receive important announcements and updates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await LocalNotificationService.showPermissionDialog();
            },
            child: Text('Enable'),
          ),
        ],
      ),
    );
  }

  void _initializeAnimation() {
    _slideController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadBatchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final batches = await BatchService.getAllBatches(page: 1, pageSize: 20);
      setState(() {
        batchData = batches;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load activities: ${e.toString()}';
        isLoading = false;
      });
      _showErrorSnackBar();
    }
  }

  // Load user profile data
  Future<void> _loadUserProfile() async {
    setState(() {
      isLoadingUserProfile = true;
    });
    try {
      final profile = await GetUserProfileService.getUserProfile();
      if (profile != null) {
        setState(() {
          userProfile = profile;
          userName = profile.name.isNotEmpty
              ? profile.name.split(' ').first
              : 'User';
          // Create address from available location data
          userAddress = _buildUserAddress(profile);
          isLoadingUserProfile = false;
        });
      } else {
        setState(() {
          userName = 'User';
          userAddress = '';
          isLoadingUserProfile = false;
        });
      }
    } catch (e) {
      setState(() {
        userName = 'User';
        userAddress = '';
        isLoadingUserProfile = false;
      });
      print('Error loading user profile: $e');
    }
  }

  // Build user address from profile data
  String _buildUserAddress(UserProfile profile) {
    List<String> addressParts = [];
    if (profile.societyName.isNotEmpty) {
      addressParts.add(profile.societyName);
    }
    if (profile.tower.isNotEmpty && profile.flatNo.isNotEmpty) {
      addressParts.add('${profile.tower}-${profile.flatNo}');
    } else if (profile.tower.isNotEmpty) {
      addressParts.add(profile.tower);
    } else if (profile.flatNo.isNotEmpty) {
      addressParts.add(profile.flatNo);
    }
    if (profile.address.isNotEmpty && addressParts.isEmpty) {
      addressParts.add(profile.address);
    }
    return addressParts.join(', ');
  }

  // Load notification count
  Future<void> _loadNotificationCount() async {
    if (isLoadingNotifications) return;
    setState(() {
      isLoadingNotifications = true;
    });
    try {
      final announcements = await NotificationService.getAnnouncements();
      final unreadCount = announcements
          .where((announcement) => announcement.isUnread)
          .length;
      setState(() {
        unreadNotificationCount = unreadCount;
        isLoadingNotifications = false;
      });
    } catch (e) {
      setState(() {
        isLoadingNotifications = false;
      });
      print('Error loading notification count: $e');
    }
  }

  // Method to refresh notification count
  Future<void> _refreshNotificationCount() async {
    await _loadNotificationCount();
  }

  void _showErrorSnackBar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load activities. Please check your connection.',
          ),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _loadBatchData,
          ),
        ),
      );
    }
  }

  void _onBottomNavTapped(int index) {
    if (selectedIndex == index) return;
    _slideAnimation =
        Tween<double>(
          begin: selectedIndex.toDouble(),
          end: index.toDouble(),
        ).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );
    _slideController.reset();
    _slideController.forward();
    setState(() {
      selectedIndex = index;
    });
  }

  List<BatchWithActivity> get filteredBatches {
    if (searchQuery.isEmpty) return batchData;
    final query = searchQuery.toLowerCase();
    return batchData.where((batch) {
      return batch.ageRange.toLowerCase().contains(query) ||
          batch.activity.categoryDisplay.toLowerCase().contains(query) ||
          batch.activity.name.toLowerCase().contains(query) ||
          batch.name.toLowerCase().contains(query) ||
          batch.priceDisplay.toLowerCase().contains(query) ||
          batch.activity.societyName.toLowerCase().contains(query) ||
          batch.activity.instructorName.toLowerCase().contains(query);
    }).toList();
  }

  void _navigateToBatchDetail(BatchWithActivity batch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityBookingPage(
          batchId: batch.id,
          activityId: batch.activity.id,
        ),
      ),
    );
  }

  // Navigate to notifications page and refresh count on return
  void _navigateToNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NotificationsPage()),
    );
    _refreshNotificationCount();
  }

  // Helper method to build custom navigation icons
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 70, // Fixed height for the entire navigation bar
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Custom navigation row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCustomNavItem('assets/App_icons/iconHome.svg', 0),
                _buildCustomNavItem('assets/App_icons/iconCalendar.svg', 1),
                _buildCustomNavItem('assets/App_icons/iconTicket.svg', 2),
                _buildCustomNavItem('assets/App_icons/iconProfile.svg', 3),
              ],
            ),
          ),
          // Animated indicator line
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              double screenWidth = MediaQuery.of(context).size.width;
              double tabWidth = screenWidth / 4;
              double lineWidth = 32;
              double currentPosition = _slideAnimation.value;
              return Positioned(
                bottom: 0,
                left: (tabWidth * currentPosition) + (tabWidth - lineWidth) / 2,
                child: Container(
                  width: lineWidth,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Custom navigation item builder
  Widget _buildCustomNavItem(String assetPath, int index) {
    bool isSelected = selectedIndex == index;
    Color iconColor = isSelected
        ? AppColors.primaryOrange
        : Color(0xFF433C39).withOpacity(0.5);

    return Expanded(
      child: GestureDetector(
        onTap: () => _onBottomNavTapped(index),
        behavior: HitTestBehavior.translucent,
        child: Container(
          height: 70, // Full height of nav bar
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top spacing
              SizedBox(height: 15),
              // Icon
              SvgPicture.asset(
                assetPath,
                width: 32,
                height: 32,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
              // Bottom spacing (accounting for the 4px indicator line)
              SizedBox(height: 23), // 15 + 4 + 4 = 23 for visual balance
            ],
          ),
        ),
      ),
    );
  }

  // Remove the old _buildNavIcon method as it's no longer needed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: selectedIndex == 0 ? _buildHomePage() : _pages[selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHomePage() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // User greeting
                  isLoadingUserProfile
                      ? Container(
                          width: 80,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        )
                      : Text(
                          'Hi, $userName!',
                          style: GoogleFonts.poetsenOne(
                            textStyle: const TextStyle(
                              fontSize: 24,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Notification icon with badge
          Stack(
            children: [
              IconButton(
                icon: SvgPicture.asset(
                  'assets/App_icons/iconBell.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    AppColors.darkElements,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: _navigateToNotifications,
              ),
              // Badge for unread notifications
              if (unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF6B35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unreadNotificationCount > 99
                          ? '99+'
                          : unreadNotificationCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadBatchData(),
            _loadUserProfile(),
            _refreshNotificationCount(),
          ]);
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildSearchField(),
              if (searchQuery.isEmpty && !isLoading && batchData.isNotEmpty)
                _buildSectionTitle(),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _buildContent(),
              ),
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) => setState(() => searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Find Activities',
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey, size: 18),
                  onPressed: () => setState(() {
                    searchQuery = '';
                    searchController.clear();
                  }),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Explore Activities',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) return _buildLoadingWidget();
    if (errorMessage != null) return _buildErrorWidget();
    if (filteredBatches.isEmpty) return _buildEmptyWidget();
    return Column(
      children: filteredBatches
          .map(
            (batch) => Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: CompactBatchCard(
                batch: batch,
                onTap: () => _navigateToBatchDetail(batch),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          CircularProgressIndicator(color: Color(0xFFFF6B35)),
          SizedBox(height: 16),
          Text(
            'Loading activities...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            errorMessage!,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadBatchData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF6B35),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'Try Again',
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

  Widget _buildEmptyWidget() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            searchQuery.isEmpty
                ? 'No activities available'
                : 'No activities found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'Check back later for new activities'
                : 'Try searching with different keywords',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}

// Updated CompactBatchCard widget that exactly matches your image
// Updated CompactBatchCard widget that fixes overflow and image fitting
class CompactBatchCard extends StatelessWidget {
  final BatchWithActivity batch;
  final VoidCallback onTap;

  const CompactBatchCard({Key? key, required this.batch, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(16),
        child: IntrinsicHeight(
          // This ensures both sides have equal height
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image container with fixed width
              Container(
                width: 110,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: batch.activity.bannerImageUrl.isNotEmpty
                      ? Image.network(
                          batch.activity.bannerImageUrl,
                          fit: BoxFit.cover,
                          width: 110,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
              ),
              SizedBox(width: 16),
              // Details column with proper spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top content group
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          batch.activity.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          batch.name != batch.activity.name
                              ? batch.name
                              : batch.activity.categoryDisplay,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              'Age: ${batch.ageRange.isNotEmpty ? batch.ageRange : 'All Ages'}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                batch.activity.societyName.isNotEmpty
                                    ? batch.activity.societyName
                                    : 'Venue name',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '₹ ${_formatPrice(batch.priceDisplay)} / month',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                      ],
                    ),
                    // Bottom content - View Details button
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          onPressed: batch.isActive ? onTap : null,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: batch.isActive
                                  ? Color(0xFFFF6B35)
                                  : Colors.grey,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            batch.isActive ? 'View Details' : 'Not Available',
                            style: TextStyle(
                              fontSize: 13,
                              color: batch.isActive
                                  ? Color(0xFFFF6B35)
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(String priceDisplay) {
    // Remove ₹ symbol if it exists and any extra formatting
    String cleanPrice = priceDisplay
        .replaceAll('₹', '')
        .replaceAll('Rs.', '')
        .trim();
    // Extract just the number part
    final numberMatch = RegExp(r'[\d,]+').firstMatch(cleanPrice);
    if (numberMatch != null) {
      return numberMatch.group(0) ?? priceDisplay;
    }
    return cleanPrice;
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B35).withOpacity(0.1),
            Color(0xFFFF6B35).withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _getActivityIcon(batch.activity.category),
          size: 36,
          color: Color(0xFFFF6B35).withOpacity(0.7),
        ),
      ),
    );
  }

  IconData _getActivityIcon(String category) {
    switch (category.toLowerCase()) {
      case 'sports':
        return Icons.sports_soccer;
      case 'arts':
        return Icons.palette;
      case 'technology':
      case 'tech':
        return Icons.computer;
      case 'music':
        return Icons.music_note;
      case 'dance':
        return Icons.music_video;
      case 'academic':
        return Icons.school;
      case 'robotics':
        return Icons.precision_manufacturing;
      case 'martial arts':
      case 'karate':
      case 'judo':
        return Icons.sports_martial_arts;
      default:
        return Icons.extension;
    }
  }
}
