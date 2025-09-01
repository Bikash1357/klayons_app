import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:klayons/screens/notification.dart';
import 'package:klayons/services/activity/activities_batchServices/batchWithActivity.dart';
import 'package:klayons/services/notification/notification_service.dart';
import 'package:klayons/utils/styles/fonts.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _loadBatchData();
    _loadNotificationCount(); // Load notification count on init
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    final bool hasPermission =
        await LocalNotificationService.areNotificationsEnabled();

    if (!hasPermission) {
      // Show dialog explaining why notifications are needed
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
              // Use the correct method name
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
      // Silently handle notification count loading errors
      print('Error loading notification count: $e');
    }
  }

  // Method to refresh notification count (call this when returning from notifications page)
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
    // Refresh notification count when returning from notifications page
    _refreshNotificationCount();
  }

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
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Text(
          'klayons',
          style: GoogleFonts.poetsenOne(
            textStyle: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryOrange,
            ),
          ),
        ),
        actions: [
          // Notification icon with badge
          Row(
            children: [
              Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: Colors.black54,
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
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
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
              SizedBox(width: 10),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadBatchData(),
            _refreshNotificationCount(), // Also refresh notification count on pull-to-refresh
          ]);
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildSearchField(),
              if (searchQuery.isEmpty && !isLoading && batchData.isNotEmpty)
                _buildSectionTitle(),
              SizedBox(height: 16),
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
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) => setState(() => searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search activities...',
          hintStyle: AppTextStyles.titleMedium.copyWith(
            color: Colors.grey[500],
          ),
          prefixIcon: Icon(Icons.search, color: Colors.grey, size: 22),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey, size: 20),
                  onPressed: () => setState(() {
                    searchQuery = '';
                    searchController.clear();
                  }),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildFeeReminderCard() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8A50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FEE REMINDER',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    batchData.isNotEmpty
                        ? batchData.first.activity.name
                        : 'Activity',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Due date on 5th June',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.notifications, color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            searchQuery.isEmpty
                ? 'Explore Activities'
                : 'Search Results (${filteredBatches.length})',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (searchQuery.isNotEmpty)
            Text(
              'for "$searchQuery"',
              style: AppTextStyles.titleSmall.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
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
              padding: EdgeInsets.only(bottom: 16),
              child: BatchCard(
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
            style: AppTextStyles.titleMedium.copyWith(color: Colors.grey[600]),
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
            style: AppTextStyles.titleMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            errorMessage!,
            style: AppTextStyles.titleSmall.copyWith(color: Colors.grey[600]),
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
            style: AppTextStyles.titleMedium.copyWith(
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
            style: AppTextStyles.titleSmall.copyWith(color: Colors.grey[500]),
          ),
          if (searchQuery.isEmpty) ...[
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
                'Refresh',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
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
          BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Color(0xFFFF6B35),
            unselectedItemColor: Colors.grey,
            currentIndex: selectedIndex,
            onTap: _onBottomNavTapped,
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: '',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.school), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
            ],
          ),
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              double screenWidth = MediaQuery.of(context).size.width;
              double tabWidth = screenWidth / 4;
              double lineWidth = 40;
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

  @override
  void dispose() {
    searchController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}

// BatchCard widget remains the same
class BatchCard extends StatelessWidget {
  final BatchWithActivity batch;
  final VoidCallback onTap;

  const BatchCard({Key? key, required this.batch, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildImageHeader(), _buildContentSection()],
        ),
      ),
    );
  }

  Widget _buildImageHeader() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        gradient: LinearGradient(
          colors: [Color(0xFFE8F5E8), Color(0xFFF0F8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Banner Image
          if (batch.activity.bannerImageUrl.isNotEmpty)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                image: DecorationImage(
                  image: NetworkImage(batch.activity.bannerImageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  _getActivityIcon(batch.activity.category),
                  size: 60,
                  color: Colors.blue[600],
                ),
              ),
            ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),

          // Age Tag
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFFFF6B35),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                batch.ageRange.isNotEmpty ? batch.ageRange : 'All Ages',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Activity Status
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: batch.isActive
                    ? Colors.green.withOpacity(0.9)
                    : Colors.grey.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                batch.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Activity Category
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Text(
              batch.activity.categoryDisplay.isNotEmpty
                  ? batch.activity.categoryDisplay
                  : batch.activity.category,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.8),
                    offset: Offset(1, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity Name and Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batch.activity.name,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (batch.name != batch.activity.name) ...[
                      SizedBox(height: 4),
                      Text(
                        batch.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                batch.priceDisplay,
                style: AppTextStyles.titleLarge.copyWith(
                  color: Color(0xFFFF6B35),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Details
          if (batch.activity.societyName.isNotEmpty) ...[
            _buildInfoRow(Icons.location_on, batch.activity.societyName),
            SizedBox(height: 12),
          ],
          if (batch.activity.instructorName.isNotEmpty) ...[
            _buildInfoRow(Icons.person, batch.activity.instructorName),
            SizedBox(height: 12),
          ],
          _buildInfoRow(
            Icons.schedule,
            '${batch.startDate} - ${batch.endDate}',
          ),
          SizedBox(height: 16),
          _buildInfoRow(Icons.people, 'Capacity: ${batch.capacity}'),
          SizedBox(height: 20),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: batch.isActive ? onTap : null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: batch.isActive ? Color(0xFFFF6B35) : Colors.grey,
                  width: 1.5,
                ),
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                batch.isActive ? 'View Details' : 'Not Available',
                style: AppTextStyles.titleMedium.copyWith(
                  color: batch.isActive ? Color(0xFFFF6B35) : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 18),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.titleSmall.copyWith(color: Colors.grey[600]),
          ),
        ),
      ],
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
      default:
        return Icons.extension;
    }
  }
}
