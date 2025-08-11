import 'package:flutter/material.dart';
import '../../user_management_service.dart';

// Admin User Management Page with Dashboard-style UI/UX
class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() =>
      _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  String searchQuery = '';
  final ScrollController _scrollbarController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchExpanded = false;

  // User statistics data
  Map<String, dynamic> _userStats = {
    'totalUsers': {'value': '0', 'percentage': '+0.0%', 'isPositive': true},
    'activeUsers': {'value': '0', 'percentage': '+0.0%', 'isPositive': true},
    'verifiedUsers': {'value': '0', 'percentage': '+0.0%', 'isPositive': true},
    'onlineUsers': {'value': '0', 'percentage': '+0.0%', 'isPositive': true},
  };

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final data = await UserManagementService.fetchUsers();
      setState(() {
        users = data;
        isLoading = false;
      });
      _calculateUserStats();
    } catch (e) {
      debugPrint('Error fetching users: $e');
      setState(() {
        users = [];
        isLoading = false;
      });
    }
  }

  void _calculateUserStats() {
    int totalUsers = users.length;
    int activeUsers = users
        .where((user) => user['session_active'] == true)
        .length;
    int verifiedUsers = users.where((user) => user['verified'] == true).length;
    int onlineUsers = users
        .where((user) => user['is_user_online'] == true)
        .length;

    setState(() {
      _userStats = {
        'totalUsers': {
          'value': totalUsers.toString(),
          'percentage': '+0.0%',
          'isPositive': true,
        },
        'activeUsers': {
          'value': activeUsers.toString(),
          'percentage': '+0.0%',
          'isPositive': true,
        },
        'verifiedUsers': {
          'value': verifiedUsers.toString(),
          'percentage': '+0.0%',
          'isPositive': true,
        },
        'onlineUsers': {
          'value': onlineUsers.toString(),
          'percentage': '+0.0%',
          'isPositive': true,
        },
      };
    });
  }

  List<Map<String, dynamic>> get filteredUsers {
    final lowerQuery = searchQuery.toLowerCase();
    return users.where((user) {
      return (user['username'] ?? '').toString().toLowerCase().contains(
            lowerQuery,
          ) ||
          (user['email'] ?? '').toString().toLowerCase().contains(lowerQuery) ||
          (user['user_type'] ?? '').toString().toLowerCase().contains(
            lowerQuery,
          );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header with User Management heading, search bar, and menu
              _buildHeader(),
              SizedBox(height: 24),

              // User Management content
              Expanded(child: _buildUserManagementContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 600;

        if (isMobile) {
          // Mobile layout
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Management heading with icon
              Row(
                children: [
                  Icon(Icons.people, color: Colors.grey[800], size: 20),
                  SizedBox(width: 6),
                  Text(
                    'User Management',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Spacer(),
                  // Search and menu buttons
                  Row(
                    children: [
                      // Collapsible search bar
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        width: _isSearchExpanded ? 200 : 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            if (_isSearchExpanded) ...[
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (val) {
                                      setState(() {
                                        searchQuery = val;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Search users...',
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isSearchExpanded = false;
                                    _searchController.clear();
                                    searchQuery = '';
                                  });
                                },
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.grey[600],
                                ),
                                iconSize: 14,
                                padding: EdgeInsets.zero,
                              ),
                            ] else ...[
                              Expanded(
                                child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _isSearchExpanded = true;
                                    });
                                  },
                                  icon: Icon(
                                    Icons.search,
                                    color: Colors.grey[600],
                                  ),
                                  iconSize: 16,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      // Add user button
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => _showAddUserDialog(context),
                          icon: Icon(Icons.add, color: Colors.white),
                          iconSize: 16,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        } else {
          // Desktop layout
          return Row(
            children: [
              // User Management heading with icon
              Row(
                children: [
                  Icon(Icons.people, color: Colors.grey[800], size: 20),
                  SizedBox(width: 6),
                  Text(
                    'User Management',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              Spacer(),
              // Search bar
              Container(
                width: 350,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search Username / Email / User Type',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              // Add user button
              Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _showAddUserDialog(context),
                  icon: Icon(Icons.add, color: Colors.white, size: 16),
                  label: Text(
                    'Add User',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildUserManagementContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 600;

        if (isMobile) {
          // Mobile layout
          return Column(
            children: [
              // User statistics cards
              _buildMobileUserStatsCards(),
              SizedBox(height: 24),
              // Users list
              Expanded(child: _buildUsersList()),
            ],
          );
        } else {
          // Desktop layout
          return Column(
            children: [
              // User statistics cards
              _buildDesktopUserStatsCards(),
              SizedBox(height: 24),
              // Users list
              Expanded(child: _buildUsersList()),
            ],
          );
        }
      },
    );
  }

  Widget _buildDesktopUserStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildUserStatCard(
            'Total Users',
            _userStats['totalUsers']['value'],
            _userStats['totalUsers']['percentage'],
            Icons.people,
            Colors.blue,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildUserStatCard(
            'Active Users',
            _userStats['activeUsers']['value'],
            _userStats['activeUsers']['percentage'],
            Icons.person,
            Colors.green,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildUserStatCard(
            'Verified Users',
            _userStats['verifiedUsers']['value'],
            _userStats['verifiedUsers']['percentage'],
            Icons.verified,
            Colors.orange,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildUserStatCard(
            'Online Users',
            _userStats['onlineUsers']['value'],
            _userStats['onlineUsers']['percentage'],
            Icons.online_prediction,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileUserStatsCards() {
    return Column(
      children: [
        // First row
        Row(
          children: [
            Expanded(
              child: _buildUserStatCard(
                'Total Users',
                _userStats['totalUsers']['value'],
                _userStats['totalUsers']['percentage'],
                Icons.people,
                Colors.blue,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildUserStatCard(
                'Active Users',
                _userStats['activeUsers']['value'],
                _userStats['activeUsers']['percentage'],
                Icons.person,
                Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        // Second row
        Row(
          children: [
            Expanded(
              child: _buildUserStatCard(
                'Verified Users',
                _userStats['verifiedUsers']['value'],
                _userStats['verifiedUsers']['percentage'],
                Icons.verified,
                Colors.orange,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildUserStatCard(
                'Online Users',
                _userStats['onlineUsers']['value'],
                _userStats['onlineUsers']['percentage'],
                Icons.online_prediction,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserStatCard(
    String title,
    String value,
    String percentage,
    IconData icon,
    Color color,
  ) {
    final isPositive = percentage.startsWith('+');
    final percentageColor = isPositive ? Colors.green : Colors.red;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: Icon + Title
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Main value - centered
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6),
          // Percentage with arrow - centered below value
          SizedBox(
            height: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: percentageColor,
                  size: 12,
                ),
                SizedBox(width: 4),
                Text(
                  percentage,
                  style: TextStyle(
                    fontSize: 11,
                    color: percentageColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 6),
          // Footer: "From previous period" centered
          Text(
            'From previous period',
            style: TextStyle(fontSize: 9, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              searchQuery.isNotEmpty
                  ? 'Try adjusting your search'
                  : 'No users available',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
        final isDesktop = constraints.maxWidth >= 1200;
        final orientation = MediaQuery.of(context).orientation;

        // Use grid for desktop/web, tablet, and mobile landscape; stack for mobile portrait
        bool useGrid =
            isDesktop ||
            isTablet ||
            (!isDesktop && !isTablet && orientation == Orientation.landscape);

        if (useGrid) {
          return GridView.builder(
            controller: _scrollbarController,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 4 : (isTablet ? 3 : 2),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.8,
            ),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              return _buildUserCard(user);
            },
          );
        } else {
          return ListView.builder(
            controller: _scrollbarController,
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: _buildUserCard(user),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with username and user type
            Row(
              children: [
                Expanded(
                  child: Text(
                    user['username'] ?? '',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (user['user_type'] != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user['user_type'].toString(),
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8),
            // Email
            Text(
              user['email'] ?? '',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 8),
            // Status indicators
            Row(
              children: [
                if (user['verified'] == true)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: Colors.green, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (user['is_user_online'] == true) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.blue, size: 8),
                        SizedBox(width: 4),
                        Text(
                          'Online',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 12),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () => _showEditUserDialog(context, user),
                  tooltip: 'Edit User',
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _showDeleteUserDialog(context, user),
                  tooltip: 'Delete User',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    // Implementation for adding user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Add User functionality will be implemented'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, Map<String, dynamic> user) {
    // Implementation for editing user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit User functionality will be implemented'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showDeleteUserDialog(BuildContext context, Map<String, dynamic> user) {
    // Implementation for deleting user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Delete User functionality will be implemented'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
