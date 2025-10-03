import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:klayons/screens/notification.dart';
import 'package:klayons/utils/styles/fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/UserProfileServices/userProfileModels.dart';
import '../services/activity/allActivityServices.dart';
import '../services/UserProfileServices/get_userprofile_service.dart';
import '../services/notification/announcementService.dart';
import '../services/notification/modelAnnouncement.dart' hide Activity;
import '../utils/colour.dart';
import 'activity_details_page.dart';
import 'user_calender/calander.dart';
import 'bottom_screens/enrolledpage.dart';
import 'bottom_screens/uesr_profile/profile_page.dart';

class KlayonsHomePage extends StatefulWidget {
  const KlayonsHomePage({super.key});

  @override
  _KlayonsHomePageState createState() => _KlayonsHomePageState();
}

class _KlayonsHomePageState extends State<KlayonsHomePage>
    with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  final ScrollController _scrollController = ScrollController();

  // State variables
  String _searchQuery = '';
  int _selectedIndex = 0;
  bool _isAppBarVisible = true;
  bool _isScrolled = false;

  // Activity data
  List<Activity> _activityData = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Notification state
  int _unreadNotificationCount = 0;
  bool _isLoadingNotifications = false;
  List<Announcement> _allAnnouncements = [];

  // User profile data
  UserProfile? _userProfile;
  bool _isLoadingUserProfile = false;
  String _userName = 'User';

  // Announcement service
  final AnnouncementService _announcementService = AnnouncementService();

  // Pages for bottom navigation
  final List<Widget> _pages = [
    Container(), // Home content handled separately
    CalendarScreen(),
    EnrolledPage(),
    UserProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _loadInitialData();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Setup scroll listener for AppBar hide/show behavior
  // Update the _setupScrollListener method (around line 95)
  void _setupScrollListener() {
    _scrollController.addListener(() {
      final isVisible = _scrollController.offset < 100;
      final hasScrolled = _scrollController.offset > 0; // Check if scrolled

      if (isVisible != _isAppBarVisible || hasScrolled != _isScrolled) {
        setState(() {
          _isAppBarVisible = isVisible;
          _isScrolled = hasScrolled; // Update scroll state
        });
      }
    });
  }

  // Initialize animation controller
  void _initializeAnimation() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );
  }

  // Load all initial data
  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadActivityData(),
      _loadUserProfile(),
      _loadNotificationCount(),
    ]);
  }

  // Load notification count
  Future<void> _loadNotificationCount() async {
    setState(() => _isLoadingNotifications = true);

    try {
      // Get all announcements
      final announcements = await _announcementService.getAnnouncements();

      if (mounted) {
        setState(() {
          _allAnnouncements = announcements;
        });

        // Calculate unread count
        await _calculateUnreadCount();
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _unreadNotificationCount = 0;
          _isLoadingNotifications = false;
        });
      }
    }
  }

  // Calculate unread notification count
  Future<void> _calculateUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get last seen notification timestamp
      final lastSeenTimestamp = prefs.getString('last_seen_notification') ?? '';
      DateTime? lastSeenDate;

      if (lastSeenTimestamp.isNotEmpty) {
        lastSeenDate = DateTime.tryParse(lastSeenTimestamp);
      }

      // Get read notification IDs
      final readNotificationIds =
          prefs.getStringList('read_notifications') ?? [];
      final readIds = readNotificationIds
          .map((id) => int.tryParse(id))
          .where((id) => id != null)
          .cast<int>()
          .toSet();

      int unreadCount = 0;

      for (final announcement in _allAnnouncements) {
        // Check if notification is unread
        bool isUnread = true;

        // If user has read this specific notification
        if (readIds.contains(announcement.id)) {
          isUnread = false;
        }
        // If user visited notifications after this announcement was created
        else if (lastSeenDate != null &&
            announcement.createdAt.isBefore(lastSeenDate)) {
          isUnread = false;
        }

        if (isUnread) {
          unreadCount++;
        }
      }

      if (mounted) {
        setState(() {
          _unreadNotificationCount = unreadCount;
          _isLoadingNotifications = false;
        });
      }
    } catch (e) {
      print('Error calculating unread count: $e');
      if (mounted) {
        setState(() {
          _unreadNotificationCount = 0;
          _isLoadingNotifications = false;
        });
      }
    }
  }

  // Mark notifications as seen when user opens notification page
  Future<void> _markNotificationsAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_seen_notification',
        DateTime.now().toIso8601String(),
      );

      // Reset unread count
      setState(() {
        _unreadNotificationCount = 0;
      });
    } catch (e) {
      print('Error marking notifications as seen: $e');
    }
  }

  // Load activity data
  Future<void> _loadActivityData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final activities = await ActivityService.getAllActivities(
        page: 1,
        pageSize: 20,
      );
      if (mounted) {
        setState(() {
          _activityData = activities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load activities';
          _isLoading = false;
        });
        _showErrorSnackBar();
      }
    }
  }

  // Load user profile data
  Future<void> _loadUserProfile() async {
    setState(() => _isLoadingUserProfile = true);

    try {
      final profile = await GetUserProfileService.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _userName = profile?.name.isNotEmpty == true
              ? profile!.name.split(' ').first
              : 'User';
          _isLoadingUserProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'User';
          _isLoadingUserProfile = false;
        });
      }
    }
  }

  // Show error snackbar
  void _showErrorSnackBar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load activities. Please check your connection.',
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _loadActivityData,
          ),
        ),
      );
    }
  }

  // Handle bottom navigation tap
  void _onBottomNavTapped(int index) {
    if (_selectedIndex == index) return;

    _slideAnimation =
        Tween<double>(
          begin: _selectedIndex.toDouble(),
          end: index.toDouble(),
        ).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );

    _slideController.reset();
    _slideController.forward();

    setState(() => _selectedIndex = index);
  }

  // Get filtered activities based on search query
  List<Activity> get _filteredActivities {
    if (_searchQuery.isEmpty) return _activityData;

    final query = _searchQuery.toLowerCase();
    return _activityData.where((activity) {
      return activity.name.toLowerCase().contains(query) ||
          activity.category.toLowerCase().contains(query) ||
          activity.subcategory.toLowerCase().contains(query) ||
          activity.ageRange.toLowerCase().contains(query) ||
          activity.venue.toLowerCase().contains(query) ||
          activity.society.toLowerCase().contains(query) ||
          activity.instructor.name.toLowerCase().contains(query);
    }).toList();
  }

  // Navigate to activity detail
  void _navigateToActivityDetail(Activity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ActivityBookingPage(batchId: activity.id, activityId: activity.id),
      ),
    );
  }

  // Navigate to notifications
  Future<void> _navigateToNotifications() async {
    // Mark notifications as seen before navigation
    await _markNotificationsAsSeen();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NotificationsPage()),
    );

    // Refresh notification count when returning from notifications page
    if (result == true || result == null) {
      await _loadNotificationCount();
    }
  }

  // Refresh all data
  Future<void> _refreshData() async {
    await Future.wait([
      _loadActivityData(),
      _loadUserProfile(),
      _loadNotificationCount(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _selectedIndex == 0 ? _buildHomePage() : _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Build home page content
  Widget _buildHomePage() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main content with CustomScrollView
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Flexible AppBar that can hide/show
              SliverAppBar(
                expandedHeight: 40,
                floating: true,
                snap: true,
                pinned: false,
                leadingWidth: 200,
                backgroundColor: AppColors.background,
                automaticallyImplyLeading: false,
                elevation: 0,
                leading: _isLoadingUserProfile
                    ? Container(
                        width: 80,
                        height: 16,
                        margin: const EdgeInsets.only(left: 16),
                        decoration: BoxDecoration(
                          color: Colors.white60,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.only(left: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Hi, $_userName!',
                              style: GoogleFonts.poetsenOne(
                                textStyle: AppTextStyles.titleLarge(
                                  context,
                                ).copyWith(color: AppColors.primaryOrange),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                actions: [
                  Stack(
                    children: [
                      IconButton(
                        icon: _isLoadingNotifications
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.darkElements,
                                  ),
                                ),
                              )
                            : SvgPicture.asset(
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
                      if (_unreadNotificationCount > 0 &&
                          !_isLoadingNotifications)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              _unreadNotificationCount > 99
                                  ? '99+'
                                  : _unreadNotificationCount.toString(),
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // Pinned search bar
              // Update the SliverPersistentHeader delegate (around line 485)
              SliverPersistentHeader(
                pinned: true,
                delegate: _SearchBarDelegate(
                  child: _buildSearchField(),
                  height: 80,
                  isScrolled: _isScrolled, // Pass scroll state
                ),
              ),
              // Section title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _buildSectionTitle(),
                ),
              ),
              // Main content
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: _buildContent()),
              ),
              // Bottom spacing
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ],
      ),
    );
  }

  // Build search field
  // Build search field
  Widget _buildSearchField() {
    String hintText = 'Find Activities';
    if (_userProfile?.societyName.isNotEmpty == true) {
      hintText = 'Find activities in ${_userProfile!.societyName}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.bodyMedium(
            context,
          ).copyWith(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                  onPressed: () => setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  }),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
        style: AppTextStyles.bodyMedium(context),
      ),
    );
  }

  // Build section title
  Widget _buildSectionTitle() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Explore Activities',
        style: AppTextStyles.titleMedium(context).copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.01,
          color: Colors.black87,
        ),
      ),
    );
  }

  // Build main content
  Widget _buildContent() {
    if (_isLoading) return _buildLoadingWidget();
    if (_errorMessage != null) return _buildErrorWidget();
    if (_filteredActivities.isEmpty) return _buildEmptyWidget();

    return Column(
      children: _filteredActivities
          .map(
            (activity) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CompactActivityCard(
                activity: activity,
                onTap: () => _navigateToActivityDetail(activity),
              ),
            ),
          )
          .toList(),
    );
  }

  // Build loading widget
  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const CircularProgressIndicator(color: Color(0xFFFF6B35)),
          const SizedBox(height: 16),
          Text(
            'Loading activities...',
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Build error widget
  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: AppTextStyles.titleLarge(
              context,
            ).copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadActivityData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'Try Again',
              style: AppTextStyles.titleMedium(
                context,
              ).copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Build empty widget
  Widget _buildEmptyWidget() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No activities available'
                : 'No activities found',
            style: AppTextStyles.titleLarge(
              context,
            ).copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Check back later for new activities'
                : 'Try searching with different keywords',
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Build bottom navigation bar
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
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
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              final screenWidth = MediaQuery.of(context).size.width;
              final tabWidth = screenWidth / 4;
              const lineWidth = 32.0;
              final currentPosition = _slideAnimation.value;
              return Positioned(
                bottom: 0,
                left: (tabWidth * currentPosition) + (tabWidth - lineWidth) / 2,
                child: Container(
                  width: lineWidth,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
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

  // Build custom navigation item
  Widget _buildCustomNavItem(String assetPath, int index) {
    final isSelected = _selectedIndex == index;
    final iconColor = isSelected
        ? AppColors.primaryOrange
        : const Color(0xFF433C39).withOpacity(0.5);

    return Expanded(
      child: GestureDetector(
        onTap: () => _onBottomNavTapped(index),
        behavior: HitTestBehavior.translucent,
        child: SizedBox(
          height: 70,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 5),
              SvgPicture.asset(
                assetPath,
                width: 32,
                height: 32,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
              const SizedBox(height: 23),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom delegate for pinned search bar
class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  final bool isScrolled;

  _SearchBarDelegate({
    required this.child,
    required this.height,
    this.isScrolled = false,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Add spacing when scrolled
          if (isScrolled) const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  @override
  double get maxExtent => height + (isScrolled ? 20 : 0);

  @override
  double get minExtent => height + (isScrolled ? 20 : 0);

  @override
  bool shouldRebuild(covariant _SearchBarDelegate oldDelegate) {
    // CRITICAL: Must rebuild when scroll state changes to update the layout
    return oldDelegate.isScrolled != isScrolled ||
        oldDelegate.height != height ||
        oldDelegate.child != child;
  }
}

// Compact Activity Card Widget
// Compact Activity Card Widget
class CompactActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onTap;

  const CompactActivityCard({
    Key? key,
    required this.activity,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image container
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.40,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: activity.bannerImageUrl.isNotEmpty
                      ? Image.network(
                          activity.bannerImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActivityInfo(context),
                      _buildActionButton(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build activity information section
  Widget _buildActivityInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Activity name and batch
        Row(
          children: [
            Flexible(
              child: Text(
                activity.batchName.isNotEmpty
                    ? '${activity.name} - ${activity.batchName}'
                    : activity.name,
                style: AppTextStyles.titleSmall(context),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Age range
        Row(
          children: [
            const Icon(Icons.person, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              'Age: ${activity.ageRange.isNotEmpty ? activity.ageRange : 'All Ages'}',
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Location
        Row(
          children: [
            const Icon(Icons.location_on, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                activity.venue.isNotEmpty ? activity.venue : activity.society,
                style: AppTextStyles.bodySmall(
                  context,
                ).copyWith(color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Price
        Row(
          children: [
            Text(
              '₹ ${_formatPrice(activity.priceDisplay)}',
              style: AppTextStyles.titleMedium(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryOrange,
              ),
            ),
            if (_getPaymentTypeDisplay(activity.paymentType).isNotEmpty)
              Flexible(
                child: Text(
                  _getPaymentTypeDisplay(activity.paymentType),
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.primaryOrange),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
          ],
        ),
      ],
    );
  }

  // Build action button
  Widget _buildActionButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: activity.isActive ? onTap : null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: activity.isActive ? const Color(0xFFFF6B35) : Colors.grey,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(
            activity.isActive ? 'View Details' : 'Not Available',
            style: AppTextStyles.bodySmall(context).copyWith(
              color: activity.isActive ? const Color(0xFFFF6B35) : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  String _getPaymentTypeDisplay(String paymentType) {
    switch (paymentType.toLowerCase()) {
      case 'monthly':
        return '/month';
      case 'annual':
        return '/year';
      case 'quarterly':
        return '/quarter';
      case 'one-time':
        return '';
      default:
        return '';
    }
  }

  // Format price string
  String _formatPrice(String priceDisplay) {
    final cleanPrice = priceDisplay.replaceAll(RegExp(r'[₹Rs.]'), '').trim();
    final numberMatch = RegExp(r'[\d,]+').firstMatch(cleanPrice);
    return numberMatch?.group(0) ?? cleanPrice;
  }

  // Build placeholder image
  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF6B35).withOpacity(0.1),
            const Color(0xFFFF6B35).withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _getActivityIcon(activity.category),
          size: 36,
          color: const Color(0xFFFF6B35).withOpacity(0.7),
        ),
      ),
    );
  }

  // Get activity icon based on category
  IconData _getActivityIcon(String category) {
    switch (category.toLowerCase()) {
      case 'sports & fitness':
      case 'sports':
        return Icons.sports_soccer;
      case 'creative arts':
      case 'arts':
        return Icons.palette;
      case 'cognitive development':
      case 'technology':
      case 'tech':
      case 'stem & robotics':
        return Icons.computer;
      case 'music & performing arts':
      case 'music':
        return Icons.music_note;
      case 'dance':
        return Icons.music_video;
      case 'academic support':
      case 'academic':
        return Icons.school;
      case 'robotics':
        return Icons.precision_manufacturing;
      case 'martial arts':
      case 'karate':
      case 'judo':
        return Icons.sports_martial_arts;
      case 'language learning':
        return Icons.language;
      case 'wellness & mindfulness':
        return Icons.self_improvement;
      default:
        return Icons.extension;
    }
  }
}
