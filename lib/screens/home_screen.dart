import 'package:flutter/material.dart';
import 'package:klayons/screens/notification.dart';

import 'bottom_screens/calander.dart';
import 'bottom_screens/ticketbox_page.dart';
import 'bottom_screens/uesr_profile/profile_page.dart';

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

  // List of pages for bottom navigation
  final List<Widget> _pages = [
    HomePage(), // Index 0 - Home
    ActivitySchedulePage(), // Index 1 - Calendar
    ActivityBookingPage(), // Index 2 - School
    UserProfilePage(), // Index 3 - Profile
  ];

  // Sample batch data
  final List<Map<String, String>> batchData = [
    {
      'ageGroup': '8-14',
      'categoryName': 'Robotics Workshop',
      'activityName': 'Arduino Robot Building',
      'price': '₹699',
      'location': 'Tech Hub, Sector-15',
      'organiser': 'RoboTech Academy',
    },
    {
      'ageGroup': '6-14',
      'categoryName': 'Chess Masters',
      'activityName': 'Advanced Chess Strategies',
      'price': '₹499',
      'location': 'Chess Club, Sector-22',
      'organiser': 'GrandMaster Institute',
    },
    {
      'ageGroup': '5-12',
      'categoryName': 'Art & Craft',
      'activityName': 'Creative Painting Workshop',
      'price': '₹399',
      'location': 'Art Studio, Sector-18',
      'organiser': 'Creative Minds Academy',
    },
    {
      'ageGroup': '10-16',
      'categoryName': 'Programming',
      'activityName': 'Python Coding Basics',
      'price': '₹899',
      'location': 'Code Hub, Sector-12',
      'organiser': 'Tech Academy',
    },
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );
  }

  void _onBottomNavTapped(int index) {
    if (selectedIndex != index) {
      // Create new tween for sliding from current position to new position
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
  }

  List<Map<String, String>> getFilteredBatches() {
    if (searchQuery.isEmpty) {
      return batchData;
    }

    return batchData.where((batch) {
      final query = searchQuery.toLowerCase();
      return batch['ageGroup']!.toLowerCase().contains(query) ||
          batch['categoryName']!.toLowerCase().contains(query) ||
          batch['activityName']!.toLowerCase().contains(query) ||
          batch['price']!.toLowerCase().contains(query) ||
          batch['location']!.toLowerCase().contains(query) ||
          batch['organiser']!.toLowerCase().contains(query);
    }).toList();
  }

  // Method to get the current page content
  Widget _getCurrentPage() {
    // Only show the home content when selectedIndex is 0
    if (selectedIndex == 0) {
      return _getHomePageContent();
    } else {
      // For other tabs, return the respective pages
      return _pages[selectedIndex];
    }
  }

  // Extract home page content to a separate method
  Widget _getHomePageContent() {
    final filteredBatches = getFilteredBatches();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Search Field
          Container(
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
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search activities...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                prefixIcon: Icon(Icons.search, color: Colors.grey, size: 22),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey, size: 20),
                        onPressed: () {
                          setState(() {
                            searchQuery = '';
                            searchController.clear();
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
            ),
          ),

          // Fee Reminder Card (only show when not searching)
          if (searchQuery.isEmpty) ...[
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
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
                            'Robotics',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Due date on 5th June',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
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
                      child: Icon(
                        Icons.smart_toy_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
          ],

          // Section Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  searchQuery.isEmpty
                      ? 'Explore Activities'
                      : 'Search Results (${filteredBatches.length})',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (searchQuery.isNotEmpty)
                  Text(
                    'for "$searchQuery"',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Activities List or No Results
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: filteredBatches.isEmpty
                ? Container(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No activities found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try searching with different keywords',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: filteredBatches
                        .map(
                          (batch) => Column(
                            children: [
                              BatchCard(
                                ageGroup: batch['ageGroup']!,
                                categoryName: batch['categoryName']!,
                                activityName: batch['activityName']!,
                                price: batch['price']!,
                                location: batch['location']!,
                                organiser: batch['organiser']!,
                              ),
                              SizedBox(height: 16),
                            ],
                          ),
                        )
                        .toList(),
                  ),
          ),

          SizedBox(height: 100), // Extra space for bottom navigation
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'klayons',
          style: TextStyle(
            color: Color(0xFFFF6B35),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.black54),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationsPage()),
              );
            },
          ),
        ],
      ),
      body: _getCurrentPage(),
      bottomNavigationBar: Container(
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
            // Animated Orange Line - Always visible, slides between tabs
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                double screenWidth = MediaQuery.of(context).size.width;
                double tabWidth = screenWidth / 4;
                double lineWidth = 40;
                double currentPosition = _slideAnimation.value;

                return Positioned(
                  bottom: 0,
                  left:
                      (tabWidth * currentPosition) + (tabWidth - lineWidth) / 2,
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

// Home page content widget
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // This will be handled by the main widget when selectedIndex is 0
    return Container();
  }
}

// Keep your existing BatchCard class unchanged
class BatchCard extends StatelessWidget {
  final String ageGroup;
  final String categoryName;
  final String activityName;
  final String price;
  final String location;
  final String organiser;

  const BatchCard({
    Key? key,
    required this.ageGroup,
    required this.categoryName,
    required this.activityName,
    required this.price,
    required this.location,
    required this.organiser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: [
          // Image Header with Age Tag
          Container(
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
                // Activity illustration (placeholder)
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Icon(
                      _getActivityIcon(categoryName),
                      size: 60,
                      color: Colors.blue[600],
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
                      'Age: $ageGroup',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Category Name only
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: Offset(1, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content Section
          Padding(
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
                      child: Text(
                        activityName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.grey[600], size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Organiser
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey, size: 18),
                    SizedBox(width: 8),
                    Text(
                      organiser,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Save a Spot Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFFFF6B35), width: 1.5),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'Save a spot',
                      style: TextStyle(
                        color: Color(0xFFFF6B35),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'robotics workshop':
        return Icons.smart_toy;
      case 'chess masters':
        return Icons.grid_on;
      case 'art & craft':
        return Icons.palette;
      case 'programming':
        return Icons.code;
      default:
        return Icons.school;
    }
  }
}
