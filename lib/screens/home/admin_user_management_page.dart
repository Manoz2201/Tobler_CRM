import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
              childAspectRatio: isDesktop ? 3.5 : (isTablet ? 3.0 : 2.2),
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
    return InkWell(
      onTap: () => _showUserDetailDialog(context, user),
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with username and user type
              Row(
                children: [
                  Expanded(
                    child: Text(
                      user['username'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (user['user_type'] != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user['user_type'].toString(),
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 4),
              // Email
              Text(
                user['email'] ?? '',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              SizedBox(height: 4),
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
                          Icon(Icons.verified, color: Colors.green, size: 10),
                          SizedBox(width: 3),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (user['is_user_online'] == true) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.blue, size: 6),
                          SizedBox(width: 3),
                          Text(
                            'Online',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Show freeze status
                  if (user['is_frozen'] == true) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, color: Colors.red, size: 6),
                          SizedBox(width: 3),
                          Text(
                            'Frozen',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 4),
            ],
          ),
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
    final TextEditingController usernameController = TextEditingController(
      text: user['username'] ?? '',
    );
    final TextEditingController emailController = TextEditingController(
      text: user['email'] ?? '',
    );
    final TextEditingController userTypeController = TextEditingController(
      text: user['user_type'] ?? '',
    );
    final TextEditingController statusController = TextEditingController(
      text: user['status'] ?? '',
    );
    final TextEditingController screenNameController = TextEditingController(
      text: user['screen_name'] ?? '',
    );
    final TextEditingController screenTypeController = TextEditingController(
      text: user['screen_type'] ?? '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: user['description'] ?? '',
    );
    final TextEditingController userTargetController = TextEditingController(
      text: user['user_target']?.toString() ?? '0',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxWidth: 600,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Edit User - ${user['username'] ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.close, color: Colors.blue[600]),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Basic Information
                            _buildEditSection('Basic Information', [
                              _buildEditField(
                                'Username',
                                usernameController,
                                Icons.person,
                              ),
                              _buildEditField(
                                'Email',
                                emailController,
                                Icons.email,
                              ),
                              _buildEditField(
                                'User Type',
                                userTypeController,
                                Icons.category,
                              ),
                              _buildEditField(
                                'Status',
                                statusController,
                                Icons.info,
                              ),
                            ]),
                            SizedBox(height: 24),
                            // Additional Information
                            _buildEditSection('Additional Information', [
                              _buildEditField(
                                'Screen Name',
                                screenNameController,
                                Icons.screen_share,
                              ),
                              _buildEditField(
                                'Screen Type',
                                screenTypeController,
                                Icons.display_settings,
                              ),
                              _buildEditField(
                                'Description',
                                descriptionController,
                                Icons.description,
                              ),
                              _buildEditField(
                                'User Target',
                                userTargetController,
                                Icons.attach_money,
                              ),
                            ]),
                            SizedBox(height: 24),
                            // Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: Icon(Icons.cancel, color: Colors.white),
                                  label: Text('Cancel'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[600],
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    try {
                                      // Update user data
                                      final updatedData = {
                                        'user_name': usernameController.text,
                                        'email': emailController.text,
                                        'user_type': userTypeController.text,
                                        'status': statusController.text,
                                        'screen_name':
                                            screenNameController.text,
                                        'screen_type':
                                            screenTypeController.text,
                                        'description':
                                            descriptionController.text,
                                        'user_target':
                                            double.tryParse(
                                              userTargetController.text,
                                            ) ??
                                            0.0,
                                      };

                                      await UserManagementService.updateUserRaw(
                                        user['id'],
                                        updatedData,
                                      );

                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'User updated successfully!',
                                            ),
                                            backgroundColor: Colors.green,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }

                                      // Refresh the user list
                                      setState(() {
                                        fetchUsers();
                                      });
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to update user: $e',
                                            ),
                                            backgroundColor: Colors.red,
                                            duration: Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: Icon(Icons.save, color: Colors.white),
                                  label: Text('Save Changes'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFreezeUserDialog(BuildContext context, Map<String, dynamic> user) {
    final bool isCurrentlyFrozen = user['is_frozen'] == true;
    final String actionText = isCurrentlyFrozen ? 'Unfreeze' : 'Freeze';
    final String messageText = isCurrentlyFrozen
        ? 'Are you sure you want to unfreeze user "${user['username'] ?? 'N/A'}"? They will be able to login again.'
        : 'Are you sure you want to freeze user "${user['username'] ?? 'N/A'}"? They will not be able to login.';
    final IconData actionIcon = isCurrentlyFrozen
        ? Icons.lock_open
        : Icons.lock;
    final MaterialColor actionColor = isCurrentlyFrozen
        ? Colors.orange
        : Colors.grey;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(actionIcon, color: actionColor[600], size: 24),
              SizedBox(width: 12),
              Text('$actionText User'),
            ],
          ),
          content: Text(messageText, style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Update user freeze status
                  final updatedData = {'is_frozen': !isCurrentlyFrozen};

                  await UserManagementService.updateUserRaw(
                    user['id'],
                    updatedData,
                  );

                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close freeze dialog

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'User ${isCurrentlyFrozen ? 'unfrozen' : 'frozen'} successfully!',
                        ),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }

                  // Refresh the user list and close user details dialog
                  fetchUsers();
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close user details dialog
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close freeze dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to ${isCurrentlyFrozen ? 'unfreeze' : 'freeze'} user: $e',
                        ),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(actionText, style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteUserDialog(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red[600], size: 24),
              SizedBox(width: 12),
              Text('Delete User'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete user "${user['username'] ?? 'N/A'}"? This action cannot be undone.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Delete user from database
                  await UserManagementService.deleteUser(user['id']);

                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close delete dialog
                    Navigator.of(context).pop(); // Close user details dialog

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('User deleted successfully!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }

                  // Refresh the user list
                  fetchUsers();
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close delete dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete user: $e'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showUserDetailDialog(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            Text(
                              user['username'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Action icon buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              _showFreezeUserDialog(context, user);
                            },
                            icon: Icon(
                              user['is_frozen'] == true
                                  ? Icons.lock_open
                                  : Icons.lock,
                              color: user['is_frozen'] == true
                                  ? Colors.orange[600]
                                  : Colors.grey[600],
                              size: 20,
                            ),
                            tooltip: user['is_frozen'] == true
                                ? 'Unfreeze User'
                                : 'Freeze User',
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showEditUserDialog(context, user);
                            },
                            icon: Icon(
                              Icons.edit,
                              color: Colors.blue[600],
                              size: 20,
                            ),
                            tooltip: 'Edit User',
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showDeleteUserDialog(context, user);
                            },
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red[600],
                              size: 20,
                            ),
                            tooltip: 'Delete User',
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.close, color: Colors.blue[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Information Section
                        _buildDetailSection('Basic Information', Icons.info, [
                          _buildDetailRow(
                            'Username',
                            user['username'] ?? 'N/A',
                          ),
                          _buildDetailRow('Email', user['email'] ?? 'N/A'),
                          _buildDetailRow(
                            'User Type',
                            user['user_type'] ?? 'N/A',
                          ),
                          _buildDetailRow('Status', user['status'] ?? 'N/A'),
                        ]),
                        SizedBox(height: 24),
                        // Additional Information Section
                        _buildDetailSection(
                          'Additional Information',
                          Icons.description,
                          [
                            _buildDetailRow(
                              'Screen Name',
                              user['screen_name'] ?? 'N/A',
                            ),
                            _buildDetailRow(
                              'Screen Type',
                              user['screen_type'] ?? 'N/A',
                            ),
                            _buildDetailRow(
                              'Description',
                              user['description'] ?? 'N/A',
                            ),
                            _buildDetailRow(
                              'User Target',
                              _formatUserTarget(user['user_target']),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        // System Information Section
                        _buildDetailSection(
                          'System Information',
                          Icons.settings,
                          [
                            _buildDetailRow('User ID', user['id'] ?? 'N/A'),
                            _buildDetailRow(
                              'Created At',
                              _formatDate(user['created_at']),
                            ),
                            _buildDetailRow(
                              'Last Updated',
                              _formatDate(user['updated_at']),
                            ),
                            _buildDetailRow(
                              'Session Active',
                              user['session_active'] == true ? 'Yes' : 'No',
                            ),
                            _buildDetailRow(
                              'User Online',
                              user['is_user_online'] == true ? 'Yes' : 'No',
                            ),
                            _buildDetailRow(
                              'Verified',
                              user['verified'] == true ? 'Yes' : 'No',
                            ),
                            _buildDetailRow(
                              'Account Status',
                              user['is_frozen'] == true ? 'Frozen' : 'Active',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey[700], size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey[600], size: 18),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
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
                borderSide: BorderSide(color: Colors.blue[600]!),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ],
      ),
    );
  }

  String _formatUserTarget(dynamic userTarget) {
    if (userTarget == null) return 'Not Set';
    if (userTarget is num) {
      return '₹${NumberFormat('#,##0.00').format(userTarget)}';
    }
    return userTarget.toString();
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is String) {
        final parsed = DateTime.parse(date);
        return DateFormat('MMM dd, yyyy HH:mm').format(parsed);
      } else if (date is DateTime) {
        return DateFormat('MMM dd, yyyy HH:mm').format(date);
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }
}
