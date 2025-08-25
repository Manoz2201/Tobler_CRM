// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'dart:ui';
import 'admin_home_screen.dart';
import 'package:crm_app/user_management_service.dart';
import 'sales_home_screen.dart';
import 'proposal_engineer_home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crm_app/widgets/profile_page.dart';
import 'package:flutter/services.dart';
import '../../utils/navigation_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import '../../main.dart'
    show
        updateUserSessionActiveMCP,
        updateUserOnlineStatusMCP,
        updateUserOnlineStatusByEmailMCP,
        setUserOnlineStatus;

class DeveloperHomeScreen extends StatefulWidget {
  const DeveloperHomeScreen({super.key});

  @override
  State<DeveloperHomeScreen> createState() => _DeveloperHomeScreenState();
}

class _DeveloperHomeScreenState extends State<DeveloperHomeScreen> {
  int _selectedIndex = 0;
  // Restore fields for dockable nav and mobile nav
  bool _isCollapsed = false;
  int _drawerExpansion = 0;
  static const int _rowSize = 5;
  final Map<int, bool> _hoveredItems = {};
  
  // User information state variables
  String _username = '';
  String _userType = '';
  String _employeeCode = '';
  bool _isLoadingUserInfo = true;

  double get _drawerHeight =>
      _drawerExpansion == 0 ? 48 : (_drawerExpansion * 52.0 + 20.0);

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      
      if (user != null) {
        final response = await client
            .from('users')
            .select('username, user_type, employee_code')
            .eq('id', user.id)
            .single();
        
        setState(() {
          _username = response['username'] ?? '';
          _userType = response['user_type'] ?? '';
          _employeeCode = response['employee_code'] ?? '';
          _isLoadingUserInfo = false;
        });
        
        debugPrint('User info loaded: $_username $_userType($_employeeCode)');
      }
    } catch (e) {
      debugPrint('Error loading user info: $e');
      setState(() {
        _isLoadingUserInfo = false;
      });
    }
  }

  void _onItemTapped(int index) {
    // Check if logout button was tapped
    if (index == _navItems.length - 1 && _navItems[index].label == 'Logout') {
      _logout();
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    await setUserOnlineStatus(false);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    debugPrint('[LOGOUT] Logging out userId: $userId');

    if (userId != null) {
      await updateUserSessionActiveMCP(userId, false);
      await updateUserOnlineStatusMCP(userId, false);
    } else {
      debugPrint('[LOGOUT] userId is null, cannot update Supabase by id.');
    }

    // Update is_user_online by email
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    debugPrint('[LOGOUT] Logging out user_email: $email');
    if (email != null) {
      await updateUserOnlineStatusByEmailMCP(email, false);
    }

    await clearLoginSession();
    await Supabase.instance.client.auth.signOut();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // Helper to build the nav bar widget for wide screens
  Widget _buildNavBar(double screenHeight, double screenWidth) {
    return Container(
      width: _isCollapsed ? 80 : 280,
      height: screenHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Logo Section - Only show when expanded
                if (!_isCollapsed)
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: Image.asset(
                        'assets/Tobler_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                // Collapse/Expand Button
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isCollapsed = !_isCollapsed;
                    });
                  },
                  icon: Icon(
                    _isCollapsed ? Icons.arrow_forward : Icons.arrow_back,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // User Context Section
          if (!_isCollapsed)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // User Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _username.isNotEmpty
                            ? _username[0].toUpperCase()
                            : 'D',
                        style: const TextStyle(
                          color: Color(0xFF7B1FA2),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoadingUserInfo)
                          const Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          )
                        else ...[
                          Text(
                            'Hi, $_username',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$_userType($_employeeCode)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Navigation Items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: _navItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = _selectedIndex == index;
                  final isHovered = _hoveredItems[index] ?? false;

                  return MouseRegion(
                    onEnter: (_) {
                      setState(() {
                        _hoveredItems[index] = true;
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        _hoveredItems[index] = false;
                      });
                    },
                    child: GestureDetector(
                      onTap: () => _onItemTapped(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: EdgeInsets.symmetric(
                          horizontal: _isCollapsed ? 8 : 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFF3E5F5)
                              : isHovered
                              ? const Color(0xFFFAFAFA)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _isCollapsed
                            ? Icon(
                                item.icon,
                                color: isSelected
                                    ? const Color(0xFF7B1FA2)
                                    : const Color(0xFF757575),
                                size: 24,
                              )
                            : Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    color: isSelected
                                        ? const Color(0xFF7B1FA2)
                                        : const Color(0xFF757575),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? const Color(0xFF7B1FA2)
                                            : const Color(0xFF757575),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Restore _pages and _navItems fields
  late final List<Widget> _pages = <Widget>[
    Center(child: Text('Developer Dashboard')), // 0
    UserManagementPage(), // 1
    ScreenManagementPage(), // 2
    RoleManagementPage(), // 3
    Center(child: Text('Feature Configuration')),
    Center(child: Text('Search')),
    Center(child: Text('Settings')),
    Center(child: Text('Analytics')),
    ProfilePage(),
  ];

  List<NavItem> get _navItems {
    return NavigationUtils.getNavigationItemsForRole('developer');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWide = screenWidth > screenHeight;

    return Scaffold(
      // backgroundColor removed to prevent extra sidebar effect
      body: isWide
          ? Row(
              children: [
                _buildNavBar(screenHeight, screenWidth),
                Expanded(child: _pages[_selectedIndex]),
              ],
            )
          : Stack(
              children: [
                _pages[_selectedIndex],
                // Mobile bottom nav bar with expansion/collapse
                Stack(
                  children: [
                    if (_drawerExpansion < 2)
                      Positioned(
                        left: 16,
                        bottom: _drawerExpansion == 0
                            ? 10
                            : (_drawerHeight + 4),
                        child: Material(
                          color: Colors.transparent,
                          child: GestureDetector(
                            onVerticalDragUpdate: (details) {
                              setState(() {
                                _drawerExpansion += details.delta.dy < 0
                                    ? 1
                                    : 0;
                                _drawerExpansion = _drawerExpansion.clamp(0, 2);
                              });
                            },
                            onVerticalDragEnd: (_) {
                              setState(() {});
                            },
                            child: IconButton(
                              icon: const Icon(
                                Icons.keyboard_arrow_up,
                                size: 28,
                              ),
                              onPressed: () {
                                setState(() {
                                  _drawerExpansion++;
                                  _drawerExpansion = _drawerExpansion.clamp(
                                    0,
                                    2,
                                  );
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    if (_drawerExpansion > 0)
                      Positioned(
                        right: 16,
                        bottom: _drawerHeight + 4,
                        child: Material(
                          color: Colors.transparent,
                          child: GestureDetector(
                            onVerticalDragUpdate: (details) {
                              setState(() {
                                _drawerExpansion -= details.delta.dy > 0
                                    ? 1
                                    : 0;
                                _drawerExpansion = _drawerExpansion.clamp(0, 2);
                              });
                            },
                            onVerticalDragEnd: (_) {
                              setState(() {});
                            },
                            child: IconButton(
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                size: 28,
                              ),
                              onPressed: () {
                                setState(() {
                                  _drawerExpansion = 0;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    if (_drawerExpansion > 0)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: SafeArea(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            child: IntrinsicHeight(
                              key: ValueKey(_drawerExpansion),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                                child: Stack(
                                  children: [
                                    BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 16,
                                        sigmaY: 16,
                                      ),
                                      child: Container(
                                        color: Colors.white.withAlpha(
                                          (0.15 * 255).round(),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(24),
                                          topRight: Radius.circular(24),
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withAlpha(
                                            (0.3 * 255).round(),
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: AnimatedSwitcher(
                                              duration: const Duration(
                                                milliseconds: 350,
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: List.generate(_drawerExpansion, (
                                                  row,
                                                ) {
                                                  final start = row * _rowSize;
                                                  final end = (start + _rowSize)
                                                      .clamp(
                                                        0,
                                                        _navItems.length,
                                                      );
                                                  final items = _navItems
                                                      .sublist(start, end);
                                                  return AnimatedOpacity(
                                                    opacity:
                                                        _drawerExpansion > row
                                                        ? 1.0
                                                        : 0.0,
                                                    duration: const Duration(
                                                      milliseconds: 350,
                                                    ),
                                                    curve:
                                                        Curves.easeInOutCubic,
                                                    child: AnimatedSlide(
                                                      offset:
                                                          _drawerExpansion > row
                                                          ? Offset.zero
                                                          : const Offset(
                                                              0,
                                                              0.2,
                                                            ),
                                                      duration: const Duration(
                                                        milliseconds: 350,
                                                      ),
                                                      curve:
                                                          Curves.easeInOutCubic,
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceEvenly,
                                                        children: List.generate(items.length, (
                                                          i,
                                                        ) {
                                                          final index =
                                                              start + i;
                                                          final selected =
                                                              _selectedIndex ==
                                                              index;
                                                          double baseSize =
                                                              screenWidth > 1200
                                                              ? 32
                                                              : screenWidth >
                                                                    900
                                                              ? 30
                                                              : 28;
                                                          double scale =
                                                              selected
                                                              ? 1.2
                                                              : 1.0;
                                                          Color iconColor =
                                                              selected
                                                              ? const Color(
                                                                  0xFF1976D2,
                                                                )
                                                              : Colors
                                                                    .grey[400]!;
                                                          return SizedBox(
                                                            width: 48,
                                                            height: 48,
                                                            child: AnimatedScale(
                                                              scale: scale,
                                                              duration:
                                                                  const Duration(
                                                                    milliseconds:
                                                                        300,
                                                                  ),
                                                              curve: Curves
                                                                  .easeOutCubic,
                                                              child: IconButton(
                                                                icon: Icon(
                                                                  items[i].icon,
                                                                  color:
                                                                      iconColor,
                                                                  size:
                                                                      baseSize,
                                                                ),
                                                                tooltip:
                                                                    items[i]
                                                                        .label,
                                                                onPressed: () =>
                                                                    _onItemTapped(
                                                                      index,
                                                                    ),
                                                                padding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                visualDensity:
                                                                    VisualDensity
                                                                        .compact,
                                                              ),
                                                            ),
                                                          );
                                                        }),
                                                      ),
                                                    ),
                                                  );
                                                }),
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
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Top-level ScreenManagementPage widget
class ScreenManagementPage extends StatefulWidget {
  const ScreenManagementPage({super.key});
  @override
  State<ScreenManagementPage> createState() => _ScreenManagementPageState();
}

class _ScreenManagementPageState extends State<ScreenManagementPage> {
  final List<Map<String, dynamic>> demoUsers = [
    {'type': 'Admin', 'icon': Icons.admin_panel_settings},
    {'type': 'Sales', 'icon': Icons.trending_up},
    {'type': 'Proposal', 'icon': Icons.description},
    {'type': 'Human Resource', 'icon': Icons.people},
    {'type': 'User', 'icon': Icons.person},
  ];

  void _showFullScreenPreview(String type) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Preview',
      pageBuilder: (context, anim1, anim2) {
        final ValueNotifier<String> mode = ValueNotifier<String>('mobile');
        return SafeArea(
          child: Scaffold(
            backgroundColor: Colors.black.withAlpha((0.7 * 255).round()),
            body: Center(
              child: ValueListenableBuilder<String>(
                valueListenable: mode,
                builder: (context, previewMode, _) {
                  final double width = previewMode == 'web' ? 1280 : 390;
                  final double height = previewMode == 'web' ? 800 : 844;
                  return Container(
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(blurRadius: 24, color: Colors.black26),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        children: [
                          FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: width,
                              height: height,
                              child: _buildPreviewForType(type, previewMode),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 32,
                                color: Colors.black54,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              tooltip: 'Close',
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: ToggleButtons(
                              isSelected: [
                                previewMode == 'web',
                                previewMode == 'mobile',
                              ],
                              onPressed: (index) {
                                mode.value = index == 0 ? 'web' : 'mobile';
                              },
                              borderRadius: BorderRadius.circular(8),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Icon(Icons.desktop_windows),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Icon(Icons.smartphone),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(opacity: anim1, child: child);
      },
      transitionDuration: Duration(milliseconds: 200),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 600,
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  children: demoUsers
                      .map(
                        (user) => GestureDetector(
                          onTap: () =>
                              _showFullScreenPreview(user['type'] as String),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    user['icon'] as IconData,
                                    size: 48,
                                    color: Colors.deepPurple,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    user['type'] as String,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewForType(String type, String mode) {
    switch (type) {
      case 'Admin':
        return _PreviewNoScaffold(
          child: const AdminHomeScreen(),
        );
      case 'User':
        return _PreviewNoScaffold(child: UserManagementPage());
      case 'Sales':
        return _PreviewNoScaffold(
          child: SalesHomeScreen(
            currentUserType: 'PreviewType',
            currentUserEmail: 'preview@example.com',
            currentUserId: 'preview-user-id',
          ),
        );
      case 'Proposal':
        return _PreviewNoScaffold(
          child: ProposalHomeScreen(
            currentUserType: 'PreviewType',
            currentUserEmail: 'preview@example.com',
            currentUserId: 'preview-user-id',
          ),
        );
      case 'Human Resource':
        return _largePlaceholder(
          'Human Resource Screen Layout Preview',
          Colors.blue[50]!,
        );
      default:
        return Container();
    }
  }

  Widget _largePlaceholder(String label, Color color) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: color,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _PreviewNoScaffold extends StatelessWidget {
  final Widget child;
  const _PreviewNoScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    // Remove the outer Scaffold if present
    if (child is Scaffold) {
      final scaffold = child as Scaffold;
      return Column(
        children: [
          if (scaffold.appBar != null) scaffold.appBar!,
          Expanded(child: scaffold.body ?? SizedBox()),
        ],
      );
    }
    return child;
  }
}

// Top-level UserManagementPage widget (moved from ScreenManagementPage)
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});
  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  String searchQuery = '';
  final ScrollController _scrollbarController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

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
    } catch (e) {
      debugPrint('Error fetching users: $e');
      setState(() {
        users = [];
        isLoading = false;
      });
    }
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 600;
                return Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: isWide
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 350, // Fixed width for desktop/web
                              child: TextField(
                                controller: _searchController,
                                style: TextStyle(fontSize: 16),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  labelText:
                                      'Search Username / Email / User Type',
                                  prefixIcon: Icon(Icons.search),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    searchQuery = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: TextStyle(fontSize: 16),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  labelText:
                                      'Search Username / Email / User Type',
                                  prefixIcon: Icon(Icons.search),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    searchQuery = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                );
              },
            ),
            SizedBox(height: 24),
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else if (filteredUsers.isEmpty)
              Center(child: Text('No users found.'))
            else
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isTablet =
                        constraints.maxWidth >= 600 &&
                        constraints.maxWidth < 1200;
                    final isDesktop = constraints.maxWidth >= 1200;
                    final orientation = MediaQuery.of(context).orientation;
                    // Use grid for desktop/web, tablet, and mobile landscape; stack for mobile portrait
                    bool useGrid =
                        isDesktop ||
                        isTablet ||
                        (!isDesktop &&
                            !isTablet &&
                            orientation == Orientation.landscape);
                    if (useGrid) {
                      return GridView.builder(
                        controller: _scrollbarController,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4, // Max 4 cards per column
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.8, // Make cards even less tall
                        ),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 10.0,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          user['username'] ?? '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      if (user['user_type'] != null)
                                        Flexible(
                                          child: Chip(
                                            label: Text(
                                              user['user_type'].toString(),
                                            ),
                                            backgroundColor:
                                                Colors.deepPurple[50],
                                            labelStyle: TextStyle(
                                              color: Colors.deepPurple,
                                            ),
                                          ),
                                        ),
                                      if (user['device_type'] != null &&
                                          user['device_type']
                                              .toString()
                                              .isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 6.0,
                                          ),
                                          child: Flexible(
                                            child: Chip(
                                              label: Text(
                                                user['device_type'].toString(),
                                              ),
                                              backgroundColor: Colors.blue[50],
                                              labelStyle: TextStyle(
                                                color: Colors.blue[900],
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  Flexible(
                                    child: Text(
                                      user['email'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  if (user['created_at'] != null)
                                    Flexible(
                                      child: Text(
                                        'Created: ${user['created_at']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        tooltip: 'Edit',
                                        onPressed: () async {
                                          // Show edit dialog with all available fields
                                          final nameController =
                                              TextEditingController(
                                                text: user['username'] ?? '',
                                              );
                                          final emailController =
                                              TextEditingController(
                                                text: user['email'] ?? '',
                                              );
                                          final userTypeController =
                                              TextEditingController(
                                                text: user['user_type'] ?? '',
                                              );
                                          final verificationCodeController =
                                              TextEditingController(
                                                text:
                                                    user['verification_code'] ??
                                                    '',
                                              );
                                          final employeeCodeController =
                                              TextEditingController(
                                                text:
                                                    user['employee_code'] ?? '',
                                              );
                                          final sessionIdController =
                                              TextEditingController(
                                                text: user['session_id'] ?? '',
                                              );
                                          final deviceTypeController =
                                              TextEditingController(
                                                text: user['device_type'] ?? '',
                                              );
                                          final machineIdController =
                                              TextEditingController(
                                                text: user['machine_id'] ?? '',
                                              );
                                          bool sessionActive =
                                              user['session_active'] ?? false;
                                          bool verified =
                                              user['verified'] ?? false;
                                          bool isUserOnline =
                                              user['is_user_online'] ?? false;

                                          await showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (BuildContext context) {
                                              return StatefulBuilder(
                                                builder: (context, setState) {
                                                  return AlertDialog(
                                                    title: Text('Edit User'),
                                                    content: SingleChildScrollView(
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          // Username
                                                          TextField(
                                                            controller:
                                                                nameController,
                                                            decoration: InputDecoration(
                                                              labelText:
                                                                  'Username',
                                                              border:
                                                                  OutlineInputBorder(),
                                                              floatingLabelBehavior:
                                                                  FloatingLabelBehavior
                                                                      .always, // Always show label
                                                            ),
                                                          ),
                                                          SizedBox(height: 16),

                                                          // User Type Dropdown
                                                          Builder(
                                                            builder: (context) {
                                                              // Default user types
                                                              final defaultUserTypes = [
                                                                'Admin',
                                                                'Proposal Engineer',
                                                                'Salesperson',
                                                                'HR',
                                                                'Developer',
                                                              ];
                                                              // Current value (case-insensitive match)
                                                              String
                                                              currentType =
                                                                  userTypeController
                                                                      .text
                                                                      .trim();
                                                              List<String>
                                                              userTypes =
                                                                  List<
                                                                    String
                                                                  >.from(
                                                                    defaultUserTypes,
                                                                  );
                                                              if (currentType
                                                                      .isNotEmpty &&
                                                                  !userTypes
                                                                      .map(
                                                                        (e) => e
                                                                            .toLowerCase(),
                                                                      )
                                                                      .contains(
                                                                        currentType
                                                                            .toLowerCase(),
                                                                      )) {
                                                                userTypes.insert(
                                                                  0,
                                                                  currentType,
                                                                ); // Show current value if not in list
                                                              }
                                                              userTypes.add(
                                                                'Add new user type',
                                                              );
                                                              String
                                                              dropdownValue = userTypes.firstWhere(
                                                                (type) =>
                                                                    type
                                                                        .toLowerCase() ==
                                                                    currentType
                                                                        .toLowerCase(),
                                                                orElse: () =>
                                                                    userTypes
                                                                        .first,
                                                              );
                                                              return DropdownButtonFormField<
                                                                String
                                                              >(
                                                                initialValue:
                                                                    dropdownValue,
                                                                decoration: InputDecoration(
                                                                  labelText:
                                                                      'User Type',
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                ),
                                                                items: userTypes
                                                                    .map(
                                                                      (
                                                                        type,
                                                                      ) => DropdownMenuItem(
                                                                        value:
                                                                            type,
                                                                        child: Text(
                                                                          type,
                                                                        ),
                                                                      ),
                                                                    )
                                                                    .toList(),
                                                                onChanged: (value) async {
                                                                  if (value ==
                                                                      'Add new user type') {
                                                                    final newType = await showDialog<String>(
                                                                      context:
                                                                          context,
                                                                      builder: (context) {
                                                                        final controller =
                                                                            TextEditingController();
                                                                        return AlertDialog(
                                                                          title: Text(
                                                                            'Add New User Type',
                                                                          ),
                                                                          content: TextField(
                                                                            controller:
                                                                                controller,
                                                                            decoration: InputDecoration(
                                                                              labelText: 'User Type',
                                                                            ),
                                                                            autofocus:
                                                                                true,
                                                                          ),
                                                                          actions: [
                                                                            TextButton(
                                                                              onPressed: () => Navigator.pop(
                                                                                context,
                                                                              ),
                                                                              child: Text(
                                                                                'Cancel',
                                                                              ),
                                                                            ),
                                                                            ElevatedButton(
                                                                              onPressed: () => Navigator.pop(
                                                                                context,
                                                                                controller.text.trim(),
                                                                              ),
                                                                              child: Text(
                                                                                'Add',
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        );
                                                                      },
                                                                    );
                                                                    if (newType !=
                                                                            null &&
                                                                        newType
                                                                            .isNotEmpty) {
                                                                      setState(() {
                                                                        userTypeController.text =
                                                                            newType;
                                                                      });
                                                                    }
                                                                  } else {
                                                                    setState(() {
                                                                      userTypeController
                                                                              .text =
                                                                          value ??
                                                                          '';
                                                                    });
                                                                  }
                                                                },
                                                              );
                                                            },
                                                          ),
                                                          SizedBox(height: 16),

                                                          // User ID
                                                          TextField(
                                                            controller: TextEditingController(
                                                              text:
                                                                  user['user_id']
                                                                      ?.toString() ??
                                                                  '',
                                                            ),
                                                            enabled: false,
                                                            decoration:
                                                                InputDecoration(
                                                                  labelText:
                                                                      'User ID',
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                ),
                                                          ),
                                                          SizedBox(height: 16),

                                                          // ID
                                                          TextField(
                                                            controller:
                                                                TextEditingController(
                                                                  text:
                                                                      user['id']
                                                                          ?.toString() ??
                                                                      '',
                                                                ),
                                                            enabled: false,
                                                            decoration:
                                                                InputDecoration(
                                                                  labelText:
                                                                      'ID',
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                ),
                                                          ),
                                                          SizedBox(height: 16),

                                                          // Email
                                                          TextField(
                                                            controller:
                                                                emailController,
                                                            decoration:
                                                                InputDecoration(
                                                                  labelText:
                                                                      'Email',
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                ),
                                                          ),
                                                          SizedBox(height: 16),

                                                          // Password Hash
                                                          TextField(
                                                            controller: TextEditingController(
                                                              text:
                                                                  user['password_hash']
                                                                      ?.toString() ??
                                                                  '',
                                                            ),
                                                            enabled: false,
                                                            decoration: InputDecoration(
                                                              labelText:
                                                                  'Password Hash',
                                                              border:
                                                                  OutlineInputBorder(),
                                                            ),
                                                          ),
                                                          SizedBox(height: 16),

                                                          // Created At
                                                          TextField(
                                                            controller: TextEditingController(
                                                              text:
                                                                  user['created_at']
                                                                      ?.toString() ??
                                                                  '',
                                                            ),
                                                            enabled: false,
                                                            decoration:
                                                                InputDecoration(
                                                                  labelText:
                                                                      'Created At',
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                ),
                                                          ),
                                                          SizedBox(height: 16),

                                                          // Employee Code
                                                          TextField(
                                                            controller:
                                                                employeeCodeController,
                                                            decoration: InputDecoration(
                                                              labelText:
                                                                  'Employee Code',
                                                              border:
                                                                  OutlineInputBorder(),
                                                            ),
                                                          ),
                                                          SizedBox(height: 16),

                                                          // Session Active Checkbox
                                                          CheckboxListTile(
                                                            title: Text(
                                                              'Session Active',
                                                            ),
                                                            value:
                                                                sessionActive,
                                                            onChanged: (value) {
                                                              setState(() {
                                                                sessionActive =
                                                                    value ??
                                                                    false;
                                                              });
                                                            },
                                                          ),

                                                          // Session ID
                                                          TextField(
                                                            controller:
                                                                sessionIdController,
                                                            decoration:
                                                                InputDecoration(
                                                                  labelText:
                                                                      'Session ID',
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                ),
                                                          ),
                                                          SizedBox(height: 16),

                                                          // Device Type Dropdown
                                                          Builder(
                                                            builder: (context) {
                                                              final defaultDeviceTypes =
                                                                  [
                                                                    'Mobile',
                                                                    'Desktop',
                                                                    'Tablet',
                                                                    'Web',
                                                                  ];
                                                              String
                                                              currentDeviceType =
                                                                  deviceTypeController
                                                                      .text
                                                                      .trim();
                                                              List<String>
                                                              deviceTypes =
                                                                  List<
                                                                    String
                                                                  >.from(
                                                                    defaultDeviceTypes,
                                                                  );
                                                              if (currentDeviceType
                                                                      .isNotEmpty &&
                                                                  !deviceTypes
                                                                      .map(
                                                                        (e) => e
                                                                            .toLowerCase(),
                                                                      )
                                                                      .contains(
                                                                        currentDeviceType
                                                                            .toLowerCase(),
                                                                      )) {
                                                                deviceTypes.insert(
                                                                  0,
                                                                  currentDeviceType,
                                                                ); // Show current value if not in list
                                                              }
                                                              String
                                                              dropdownValue = deviceTypes.firstWhere(
                                                                (type) =>
                                                                    type
                                                                        .toLowerCase() ==
                                                                    currentDeviceType
                                                                        .toLowerCase(),
                                                                orElse: () =>
                                                                    deviceTypes
                                                                        .first,
                                                              );
                                                              return DropdownButtonFormField<
                                                                String
                                                              >(
                                                                initialValue:
                                                                    dropdownValue,
                                                                decoration: InputDecoration(
                                                                  labelText:
                                                                      'Device Type',
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                ),
                                                                items: deviceTypes
                                                                    .map(
                                                                      (
                                                                        type,
                                                                      ) => DropdownMenuItem(
                                                                        value:
                                                                            type,
                                                                        child: Text(
                                                                          type,
                                                                        ),
                                                                      ),
                                                                    )
                                                                    .toList(),
                                                                onChanged: (value) {
                                                                  setState(() {
                                                                    deviceTypeController
                                                                            .text =
                                                                        value ??
                                                                        '';
                                                                  });
                                                                },
                                                              );
                                                            },
                                                          ),
                                                          SizedBox(height: 16),

                                                          // Machine ID
                                                          TextField(
                                                            controller:
                                                                machineIdController,
                                                            decoration:
                                                                InputDecoration(
                                                                  labelText:
                                                                      'Machine ID',
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                ),
                                                          ),
                                                          SizedBox(height: 16),

                                                          // Verification Code
                                                          TextField(
                                                            controller:
                                                                verificationCodeController,
                                                            decoration: InputDecoration(
                                                              labelText:
                                                                  'Verification Code',
                                                              border:
                                                                  OutlineInputBorder(),
                                                            ),
                                                          ),
                                                          SizedBox(height: 16),

                                                          // Verified Checkbox
                                                          CheckboxListTile(
                                                            title: Text(
                                                              'Verified',
                                                            ),
                                                            value: verified,
                                                            onChanged: (value) {
                                                              setState(() {
                                                                verified =
                                                                    value ??
                                                                    false;
                                                              });
                                                            },
                                                          ),

                                                          // Is User Online Checkbox
                                                          CheckboxListTile(
                                                            title: Text(
                                                              'Is User Online',
                                                            ),
                                                            value: isUserOnline,
                                                            onChanged: (value) {
                                                              setState(() {
                                                                isUserOnline =
                                                                    value ??
                                                                    false;
                                                              });
                                                            },
                                                          ),

                                                          // Updated At
                                                          TextField(
                                                            controller: TextEditingController(
                                                              text:
                                                                  user['updated_at']
                                                                      ?.toString() ??
                                                                  '',
                                                            ),
                                                            enabled: false,
                                                            decoration:
                                                                InputDecoration(
                                                                  labelText:
                                                                      'Updated At',
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                ),
                                                          ),
                                                          SizedBox(height: 16),
                                                        ],
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                              context,
                                                            ).pop(),
                                                        child: Text('Cancel'),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () async {
                                                          try {
                                                            await UserManagementService.updateUserRaw(
                                                              user['id']
                                                                  .toString(),
                                                              {
                                                                'username':
                                                                    nameController
                                                                        .text,
                                                                'email':
                                                                    emailController
                                                                        .text,
                                                                'user_type':
                                                                    userTypeController
                                                                        .text,
                                                                'employee_code':
                                                                    employeeCodeController
                                                                        .text,
                                                                'session_id':
                                                                    sessionIdController
                                                                        .text,
                                                                'device_type':
                                                                    deviceTypeController
                                                                        .text,
                                                                'machine_id':
                                                                    machineIdController
                                                                        .text,
                                                                'verification_code':
                                                                    verificationCodeController
                                                                        .text,
                                                                'session_active':
                                                                    sessionActive,
                                                                'verified':
                                                                    verified,
                                                                'is_user_online':
                                                                    isUserOnline,
                                                                'updated_at':
                                                                    DateTime.now()
                                                                        .toIso8601String(),
                                                              },
                                                            );

                                                            Navigator.of(
                                                              context,
                                                            ).pop();
                                                            fetchUsers(); // Refresh the list
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'User updated successfully!',
                                                                ),
                                                              ),
                                                            );
                                                          } catch (e) {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Failed to update user: $e',
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        child: Text('Save'),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.copy,
                                          color: Colors.orange,
                                        ),
                                        tooltip: 'Copy',
                                        onPressed: () async {
                                          // Duplicate user details, appending ' (copy)' to username and email
                                          final newUser =
                                              Map<String, dynamic>.from(user);
                                          newUser['username'] =
                                              (user['username'] ?? '') +
                                              ' (copy)';
                                          if (user['email'] != null &&
                                              user['email'].toString().contains(
                                                '@',
                                              )) {
                                            final parts = user['email']
                                                .toString()
                                                .split('@');
                                            newUser['email'] =
                                                '${parts[0]}.copy@${parts[1]}';
                                          } else {
                                            newUser['email'] =
                                                (user['email'] ?? '') + '.copy';
                                          }
                                          // Remove id and created_at so Supabase can generate new ones
                                          newUser.remove('id');
                                          newUser.remove('created_at');
                                          // Insert the duplicated user
                                          await UserManagementService.addUserRaw(
                                            newUser,
                                          );
                                          if (!mounted) return;
                                          await fetchUsers();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('User duplicated.'),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        tooltip: 'Delete',
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text('Delete User'),
                                              content: Text(
                                                'Are you sure you want to delete this user?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await UserManagementService.deleteUser(
                                              user['id'],
                                            );
                                            if (!mounted) return;
                                            setState(() {
                                              users.removeWhere(
                                                (u) => u['id'] == user['id'],
                                              );
                                            });
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text('User deleted.'),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      // Use ListView for mobile portrait
                      return ListView.builder(
                        controller: _scrollbarController,
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 10.0,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          user['username'] ?? '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      if (user['user_type'] != null)
                                        Flexible(
                                          child: Chip(
                                            label: Text(
                                              user['user_type'].toString(),
                                            ),
                                            backgroundColor:
                                                Colors.deepPurple[50],
                                            labelStyle: TextStyle(
                                              color: Colors.deepPurple,
                                            ),
                                          ),
                                        ),
                                      if (user['device_type'] != null &&
                                          user['device_type']
                                              .toString()
                                              .isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 6.0,
                                          ),
                                          child: Flexible(
                                            child: Chip(
                                              label: Text(
                                                user['device_type'].toString(),
                                              ),
                                              backgroundColor: Colors.blue[50],
                                              labelStyle: TextStyle(
                                                color: Colors.blue[900],
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  Flexible(
                                    child: Text(
                                      user['email'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  if (user['created_at'] != null)
                                    Flexible(
                                      child: Text(
                                        'Created: ${user['created_at']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        tooltip: 'Edit',
                                        onPressed: () async {
                                          // Show edit dialog with all available fields
                                          final nameController =
                                              TextEditingController(
                                                text: user['username'] ?? '',
                                              );
                                          final emailController =
                                              TextEditingController(
                                                text: user['email'] ?? '',
                                              );
                                          final userTypeController =
                                              TextEditingController(
                                                text: user['user_type'] ?? '',
                                              );
                                          final verificationCodeController =
                                              TextEditingController(
                                                text:
                                                    user['verification_code'] ??
                                                    '',
                                              );
                                          final employeeCodeController =
                                              TextEditingController(
                                                text:
                                                    user['employee_code'] ?? '',
                                              );
                                          final sessionIdController =
                                              TextEditingController(
                                                text: user['session_id'] ?? '',
                                              );
                                          final deviceTypeController =
                                              TextEditingController(
                                                text: user['device_type'] ?? '',
                                              );
                                          final machineIdController =
                                              TextEditingController(
                                                text: user['machine_id'] ?? '',
                                              );
                                          bool sessionActive =
                                              user['session_active'] ?? false;
                                          bool verified =
                                              user['verified'] ?? false;
                                          bool isUserOnline =
                                              user['is_user_online'] ?? false;

                                          await showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (BuildContext context) {
                                              return StatefulBuilder(
                                                builder: (context, setState) {
                                                  return AlertDialog(
                                                    title: Text('Edit User'),
                                                    content: SingleChildScrollView(
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          // Username
                                                          TextField(
                                                            controller:
                                                                nameController,
                                                            decoration: InputDecoration(
                                                              labelText:
                                                                  'Username',
                                                              border:
                                                                  OutlineInputBorder(),
                                                              floatingLabelBehavior:
                                                                  FloatingLabelBehavior
                                                                      .always, // Always show label
                                                            ),
                                                          ),
                                                          SizedBox(height: 16),

                                                          // User Type Dropdown
                                                          Builder(
                                                            builder: (context) {
                                                              // Default user types
                                                              final defaultUserTypes = [
                                                                'Admin',
                                                                'Proposal Engineer',
                                                                'Salesperson',
                                                                'HR',
                                                                'Developer',
                                                              ];
                                                              // Current value (case-insensitive match)
                                                              String
                                                              currentType =
                                                                  userTypeController
                                                                      .text
                                                                      .trim();
                                                              List<String>
                                                              userTypes =
                                                                  List<
                                                                    String
                                                                  >.from(
                                                                    defaultUserTypes,
                                                                  );
                                                              if (currentType
                                                                      .isNotEmpty &&
                                                                  !userTypes
                                                                      .map(
                                                                        (e) => e
                                                                            .toLowerCase(),
                                                                      )
                                                                      .contains(
                                                                        currentType
                                                                            .toLowerCase(),
                                                                      )) {
                                                                userTypes.insert(
                                                                  0,
                                                                  currentType,
                                                                ); // Show current value if not in list
                                                              }
                                                              userTypes.add(
                                                                'Add new user type',
                                                              );
                                                              String
                                                              dropdownValue = userTypes.firstWhere(
                                                                (type) =>
                                                                    type
                                                                        .toLowerCase() ==
                                                                    currentType
                                                                        .toLowerCase(),
                                                                orElse: () =>
                                                                    userTypes
                                                                        .first,
                                                              );
                                                              return DropdownButtonFormField<
                                                                String
                                                              >(
                                                                initialValue:
                                                                    dropdownValue,
                                                                decoration: InputDecoration(
                                                                  labelText:
                                                                      'User Type',
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                ),
                                                                items: userTypes
                                                                    .map(
                                                                      (
                                                                        type,
                                                                      ) => DropdownMenuItem(
                                                                        value:
                                                                            type,
                                                                        child: Text(
                                                                          type,
                                                                        ),
                                                                      ),
                                                                    )
                                                                    .toList(),
                                                                onChanged: (value) async {
                                                                  if (value ==
                                                                      'Add new user type') {
                                                                    final newType = await showDialog<String>(
                                                                      context:
                                                                          context,
                                                                      builder: (context) {
                                                                        final controller =
                                                                            TextEditingController();
                                                                        return AlertDialog(
                                                                          title: Text(
                                                                            'Add New User Type',
                                                                          ),
                                                                          content: TextField(
                                                                            controller:
                                                                                controller,
                                                                            decoration: InputDecoration(
                                                                              labelText: 'User Type',
                                                                            ),
                                                                            autofocus:
                                                                                true,
                                                                          ),
                                                                          actions: [
                                                                            TextButton(
                                                                              onPressed: () => Navigator.pop(
                                                                                context,
                                                                              ),
                                                                              child: Text(
                                                                                'Cancel',
                                                                              ),
                                                                            ),
                                                                            ElevatedButton(
                                                                              onPressed: () => Navigator.pop(
                                                                                context,
                                                                                controller.text.trim(),
                                                                              ),
                                                                              child: Text(
                                                                                'Add',
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        );
                                                                      },
                                                                    );
                                                                    if (newType !=
                                                                            null &&
                                                                        newType
                                                                            .isNotEmpty) {
                                                                      setState(() {
                                                                        userTypeController.text =
                                                                            newType;
                                                                      });
                                                                    }
                                                                  } else {
                                                                    setState(() {
                                                                      userTypeController
                                                                              .text =
                                                                          value ??
                                                                          '';
                                                                    });
                                                                  }
                                                                },
                                                              );
                                                            },
                                                          ),
                                                          SizedBox(height: 16),

                                                          // User ID
                                                          TextField(
                                                            controller: TextEditingController(
                                                              text:
                                                                  user['user_id']
                                                                      ?.toString() ??
                                                                  '',
                                                            ),
                                                            enabled: false,
                                                            decoration:
                                                                InputDecoration(
                                                                  labelText:
                                                                      'User ID',
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                ),
                                                          ),
                                                          SizedBox(height: 16),

                                                          // ID
                                                          TextField(
                                                            controller:
                                                                TextEditingController(
                                                                  text:
                                                                      user['id']
                                                                          ?.toString() ??
                                                                      '',
                                                                ),
                                                            enabled: false,
                                                            decoration:
                                                                InputDecoration(
                                                                  labelText:
                                                                      'ID',
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                ),
                                                          ),
                                                          SizedBox(height: 16),

                                                          // Email
                                                          TextField(
                                                            controller:
                                                                emailController,
                                                            decoration:
                                                                InputDecoration(
                                                                  labelText:
                                                                      'Email',
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                ),
                                                          ),
                                                          SizedBox(height: 16),

                                                          // Password Hash
                                                          TextField(
                                                            controller: TextEditingController(
                                                              text:
                                                                  user['password_hash']
                                                                      ?.toString() ??
                                                                  '',
                                                            ),
                                                            enabled: false,
                                                            decoration: InputDecoration(
                                                              labelText:
                                                                  'Password Hash',
                                                              border:
                                                                  OutlineInputBorder(),
                                                            ),
                                                          ),
                                                          SizedBox(height: 16),

                                                          // Created At
                                                          TextField(
                                                            controller: TextEditingController(
                                                              text:
                                                                  user['created_at']
                                                                      ?.toString() ??
                                                                  '',
                                                            ),
                                                            enabled: false,
                                                            decoration:
                                                                InputDecoration(
                                                                  labelText:
                                                                      'Created At',
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                ),
                                                          ),
                                                          SizedBox(height: 16),

                                                          // Employee Code
                                                          TextField(
                                                            controller:
                                                                employeeCodeController,
                                                            decoration: InputDecoration(
                                                              labelText:
                                                                  'Employee Code',
                                                              border:
                                                                  OutlineInputBorder(),
                                                            ),
                                                          ),
                                                          SizedBox(height: 16),

                                                          // Session Active Checkbox
                                                          CheckboxListTile(
                                                            title: Text(
                                                              'Session Active',
                                                            ),
                                                            value:
                                                                sessionActive,
                                                            onChanged: (value) {
                                                              setState(() {
                                                                sessionActive =
                                                                    value ??
                                                                    false;
                                                              });
                                                            },
                                                          ),

                                                          // Session ID
                                                          TextField(
                                                            controller:
                                                                sessionIdController,
                                                            decoration:
                                                                InputDecoration(
                                                                  labelText:
                                                                      'Session ID',
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                ),
                                                          ),
                                                          SizedBox(height: 16),

                                                          // Device Type Dropdown
                                                          Builder(
                                                            builder: (context) {
                                                              final defaultDeviceTypes =
                                                                  [
                                                                    'Mobile',
                                                                    'Desktop',
                                                                    'Tablet',
                                                                    'Web',
                                                                  ];
                                                              String
                                                              currentDeviceType =
                                                                  deviceTypeController
                                                                      .text
                                                                      .trim();
                                                              List<String>
                                                              deviceTypes =
                                                                  List<
                                                                    String
                                                                  >.from(
                                                                    defaultDeviceTypes,
                                                                  );
                                                              if (currentDeviceType
                                                                      .isNotEmpty &&
                                                                  !deviceTypes
                                                                      .map(
                                                                        (e) => e
                                                                            .toLowerCase(),
                                                                      )
                                                                      .contains(
                                                                        currentDeviceType
                                                                            .toLowerCase(),
                                                                      )) {
                                                                deviceTypes.insert(
                                                                  0,
                                                                  currentDeviceType,
                                                                ); // Show current value if not in list
                                                              }
                                                              String
                                                              dropdownValue = deviceTypes.firstWhere(
                                                                (type) =>
                                                                    type
                                                                        .toLowerCase() ==
                                                                    currentDeviceType
                                                                        .toLowerCase(),
                                                                orElse: () =>
                                                                    deviceTypes
                                                                        .first,
                                                              );
                                                              return DropdownButtonFormField<
                                                                String
                                                              >(
                                                                initialValue:
                                                                    dropdownValue,
                                                                decoration: InputDecoration(
                                                                  labelText:
                                                                      'Device Type',
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                ),
                                                                items: deviceTypes
                                                                    .map(
                                                                      (
                                                                        type,
                                                                      ) => DropdownMenuItem(
                                                                        value:
                                                                            type,
                                                                        child: Text(
                                                                          type,
                                                                        ),
                                                                      ),
                                                                    )
                                                                    .toList(),
                                                                onChanged: (value) {
                                                                  setState(() {
                                                                    deviceTypeController
                                                                            .text =
                                                                        value ??
                                                                        '';
                                                                  });
                                                                },
                                                              );
                                                            },
                                                          ),
                                                          SizedBox(height: 16),

                                                          // Machine ID
                                                          TextField(
                                                            controller:
                                                                machineIdController,
                                                            decoration:
                                                                InputDecoration(
                                                                  labelText:
                                                                      'Machine ID',
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                ),
                                                          ),
                                                          SizedBox(height: 16),

                                                          // Verification Code
                                                          TextField(
                                                            controller:
                                                                verificationCodeController,
                                                            decoration: InputDecoration(
                                                              labelText:
                                                                  'Verification Code',
                                                              border:
                                                                  OutlineInputBorder(),
                                                            ),
                                                          ),
                                                          SizedBox(height: 16),

                                                          // Verified Checkbox
                                                          CheckboxListTile(
                                                            title: Text(
                                                              'Verified',
                                                            ),
                                                            value: verified,
                                                            onChanged: (value) {
                                                              setState(() {
                                                                verified =
                                                                    value ??
                                                                    false;
                                                              });
                                                            },
                                                          ),

                                                          // Is User Online Checkbox
                                                          CheckboxListTile(
                                                            title: Text(
                                                              'Is User Online',
                                                            ),
                                                            value: isUserOnline,
                                                            onChanged: (value) {
                                                              setState(() {
                                                                isUserOnline =
                                                                    value ??
                                                                    false;
                                                              });
                                                            },
                                                          ),

                                                          // Updated At
                                                          TextField(
                                                            controller: TextEditingController(
                                                              text:
                                                                  user['updated_at']
                                                                      ?.toString() ??
                                                                  '',
                                                            ),
                                                            enabled: false,
                                                            decoration:
                                                                InputDecoration(
                                                                  labelText:
                                                                      'Updated At',
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                ),
                                                          ),
                                                          SizedBox(height: 16),
                                                        ],
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                              context,
                                                            ).pop(),
                                                        child: Text('Cancel'),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () async {
                                                          try {
                                                            await UserManagementService.updateUserRaw(
                                                              user['id']
                                                                  .toString(),
                                                              {
                                                                'username':
                                                                    nameController
                                                                        .text,
                                                                'email':
                                                                    emailController
                                                                        .text,
                                                                'user_type':
                                                                    userTypeController
                                                                        .text,
                                                                'employee_code':
                                                                    employeeCodeController
                                                                        .text,
                                                                'session_id':
                                                                    sessionIdController
                                                                        .text,
                                                                'device_type':
                                                                    deviceTypeController
                                                                        .text,
                                                                'machine_id':
                                                                    machineIdController
                                                                        .text,
                                                                'verification_code':
                                                                    verificationCodeController
                                                                        .text,
                                                                'session_active':
                                                                    sessionActive,
                                                                'verified':
                                                                    verified,
                                                                'is_user_online':
                                                                    isUserOnline,
                                                                'updated_at':
                                                                    DateTime.now()
                                                                        .toIso8601String(),
                                                              },
                                                            );

                                                            Navigator.of(
                                                              context,
                                                            ).pop();
                                                            fetchUsers(); // Refresh the list
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'User updated successfully!',
                                                                ),
                                                              ),
                                                            );
                                                          } catch (e) {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Failed to update user: $e',
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        child: Text('Save'),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.copy,
                                          color: Colors.orange,
                                        ),
                                        tooltip: 'Copy',
                                        onPressed: () async {
                                          // Duplicate user details, appending ' (copy)' to username and email
                                          final newUser =
                                              Map<String, dynamic>.from(user);
                                          newUser['username'] =
                                              (user['username'] ?? '') +
                                              ' (copy)';
                                          if (user['email'] != null &&
                                              user['email'].toString().contains(
                                                '@',
                                              )) {
                                            final parts = user['email']
                                                .toString()
                                                .split('@');
                                            newUser['email'] =
                                                '${parts[0]}.copy@${parts[1]}';
                                          } else {
                                            newUser['email'] =
                                                (user['email'] ?? '') + '.copy';
                                          }
                                          // Remove id and created_at so Supabase can generate new ones
                                          newUser.remove('id');
                                          newUser.remove('created_at');
                                          // Insert the duplicated user
                                          await UserManagementService.addUserRaw(
                                            newUser,
                                          );
                                          if (!mounted) return;
                                          await fetchUsers();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('User duplicated.'),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        tooltip: 'Delete',
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text('Delete User'),
                                              content: Text(
                                                'Are you sure you want to delete this user?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await UserManagementService.deleteUser(
                                              user['id'],
                                            );
                                            if (!mounted) return;
                                            setState(() {
                                              users.removeWhere(
                                                (u) => u['id'] == user['id'],
                                              );
                                            });
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text('User deleted.'),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollbarController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

// Top-level ScreenTemplateDetailPage widget
class ScreenTemplateDetailPage extends StatelessWidget {
  final String screenName;
  final String userType;
  const ScreenTemplateDetailPage({
    super.key,
    required this.screenName,
    required this.userType,
  });

  @override
  Widget build(BuildContext context) {
    // Mock sub-templates
    final subTemplates = [
      {
        'name': 'Sub-Task 1',
        'description': 'Sub-template details',
        'status': 'Active',
        'userType': userType,
      },
      {
        'name': 'Sub-Task 2',
        'description': 'Another sub-template',
        'status': 'Inactive',
        'userType': userType,
      },
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('Templates for $screenName'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 900
                ? 3
                : MediaQuery.of(context).size.width > 600
                ? 2
                : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: subTemplates.length,
          itemBuilder: (context, i) {
            final sub = subTemplates[i];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Chip(
                      label: Text(
                        sub['userType']?.toString() ?? '',
                        style: TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.deepPurple[50],
                      labelStyle: TextStyle(color: Colors.deepPurple),
                    ),
                    SizedBox(height: 8),
                    Text(
                      sub['name']?.toString() ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      sub['description']?.toString() ?? '',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    Spacer(),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: sub['status'] == 'Active'
                              ? Colors.green[100]
                              : Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          sub['status']?.toString() ?? '',
                          style: TextStyle(
                            color: sub['status'] == 'Active'
                                ? Colors.green[800]
                                : Colors.red[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Add a new page to show all templates for a user type
class UserTypeTemplatesPage extends StatelessWidget {
  final String userType;
  final List<Map<String, dynamic>> templates;
  const UserTypeTemplatesPage({
    super.key,
    required this.userType,
    required this.templates,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$userType Templates'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 900
                ? 3
                : MediaQuery.of(context).size.width > 600
                ? 2
                : 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.1,
          ),
          itemCount: templates.length,
          itemBuilder: (context, i) {
            final screen = templates[i];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            screen['userName'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (screen['userType'] != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: Chip(
                              label: Text(
                                screen['userType'].toString(),
                                style: TextStyle(fontSize: 10),
                              ),
                              backgroundColor: Colors.deepPurple[50],
                              labelStyle: TextStyle(color: Colors.deepPurple),
                            ),
                          ),
                        if (screen['status'] != null)
                          Chip(
                            label: Text(
                              screen['status'].toString(),
                              style: TextStyle(fontSize: 10),
                            ),
                            backgroundColor: screen['status'] == 'Active'
                                ? Colors.green[100]
                                : Colors.red[100],
                            labelStyle: TextStyle(
                              color: screen['status'] == 'Active'
                                  ? Colors.green[800]
                                  : Colors.red[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      screen['screenName'] ?? screen['screenType'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      screen['description'] ?? '',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Role Management Page with Invited and Active tabs
class RoleManagementPage extends StatefulWidget {
  const RoleManagementPage({super.key});
  @override
  State<RoleManagementPage> createState() => _RoleManagementPageState();
}

class _RoleManagementPageState extends State<RoleManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Invite'),
            Tab(text: 'Invited'),
            Tab(text: 'Active'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _InviteUserTab(),
              _InvitedUsersTab(),
              const Center(child: Text('Active Users Placeholder')),
            ],
          ),
        ),
      ],
    );
  }
}

// Invite User Tab Content
class _InviteUserTab extends StatefulWidget {
  @override
  State<_InviteUserTab> createState() => _InviteUserTabState();
}

class _InviteUserTabState extends State<_InviteUserTab> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  String? _selectedRole;
  final List<String> _roles = [
    'Admin',
    'Sales',
    'Proposal Engineer',
    'Developer',
    'User',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Stack(
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite User',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'User Name'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mobileController,
                  decoration: const InputDecoration(labelText: 'Mobile No.'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  items: _roles
                      .map(
                        (role) =>
                            DropdownMenuItem(value: role, child: Text(role)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedRole = val),
                  decoration: const InputDecoration(
                    labelText: 'Role (User Type)',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 80), // Space for button
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  try {
                    await Supabase.instance.client.from('invitation').insert({
                      'user_name': _nameController.text.trim(),
                      'email': _emailController.text.trim(),
                      'mobile_no': _mobileController.text.trim(),
                      'user_type': _selectedRole,
                      'active': false,
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invitation sent and stored!'),
                      ),
                    );
                    _formKey.currentState?.reset();
                    setState(() {
                      _selectedRole = null;
                    });
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error sending invitation: ${e.toString()}',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Send'),
            ),
          ),
        ],
      ),
    );
  }
}

// Invited Users Tab Content
class _InvitedUsersTab extends StatefulWidget {
  @override
  State<_InvitedUsersTab> createState() => _InvitedUsersTabState();
}

class _InvitedUsersTabState extends State<_InvitedUsersTab> {
  late Future<List<Map<String, dynamic>>> _futureInvited;

  @override
  void initState() {
    super.initState();
    _futureInvited = _fetchInvited();
  }

  Future<List<Map<String, dynamic>>> _fetchInvited() async {
    final invitationData = await Supabase.instance.client
        .from('invitation')
        .select(
          'user_name, mobile_no, email, user_type, created_at, is_registered',
        )
        .eq('active', false)
        .order('created_at', ascending: false);
    // Fetch verification_code for each invited user's email from users table
    final emails = invitationData
        .map((e) => e['email'] as String?)
        .whereType<String>()
        .toList();
    Map<String, String> emailToCode = {};
    if (emails.isNotEmpty) {
      final usersData = await Supabase.instance.client
          .from('users')
          .select('email, verification_code')
          .inFilter('email', emails);
      for (final user in usersData) {
        if (user['email'] != null && user['verification_code'] != null) {
          emailToCode[user['email']] = user['verification_code'].toString();
        }
      }
    }
    // Add code to each invited row
    for (final row in invitationData) {
      row['verification_code'] = emailToCode[row['email']] ?? '-';
    }
    return List<Map<String, dynamic>>.from(invitationData);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _futureInvited,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final invited = snapshot.data ?? [];
            if (invited.isEmpty) {
              return const Center(child: Text('No invited users.'));
            }
            // Responsive DataTable with vertical dividers
            final columns = [
              {'label': 'User Name', 'key': 'user_name'},
              {'label': 'Mobile No.', 'key': 'mobile_no'},
              {'label': 'Email', 'key': 'email'},
              {'label': 'User Type', 'key': 'user_type'},
              {'label': 'Date', 'key': 'created_at'},
              {'label': 'Status', 'key': 'is_registered'},
              {'label': 'Code', 'key': 'verification_code'},
            ];
            return Column(
              children: [
                // Header row
                Container(
                  color: Colors.grey[100],
                  child: Row(
                    children: [
                      for (int i = 0; i < columns.length; i++)
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                            decoration: i < columns.length - 1
                                ? BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                  )
                                : null,
                            child: Center(
                              child: Text(
                                columns[i]['label'].toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1),
                // Data rows
                Expanded(
                  child: ListView.builder(
                    itemCount: invited.length,
                    itemBuilder: (context, rowIdx) {
                      final row = invited[rowIdx];
                      final date = row['created_at'] != null
                          ? row['created_at'].toString().split('T').first
                          : '-';
                      final status =
                          (row['is_registered'] == false ||
                              row['is_registered'] == null)
                          ? 'Not Yet'
                          : 'Registered';
                      final cells = [
                        (row['user_name'] ?? '-').toString(),
                        (row['mobile_no'] ?? '-').toString(),
                        (row['email'] ?? '-').toString(),
                        (row['user_type'] ?? '-').toString(),
                        date.toString(),
                        status.toString(),
                        (row['verification_code'] ?? '-').toString(),
                      ];
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            for (int i = 0; i < cells.length; i++)
                              Expanded(
                                flex: 1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 8,
                                  ),
                                  decoration: i < cells.length - 1
                                      ? BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              color: Colors.grey[300]!,
                                              width: 1,
                                            ),
                                          ),
                                        )
                                      : null,
                                  child: Center(
                                    child: i == cells.length - 1
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  cells[i],
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (cells[i] != '-')
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.copy,
                                                    size: 18,
                                                  ),
                                                  tooltip: 'Copy Code',
                                                  onPressed: () {
                                                    Clipboard.setData(
                                                      ClipboardData(
                                                        text: cells[i],
                                                      ),
                                                    );
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Code copied to clipboard',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                            ],
                                          )
                                        : Text(
                                            cells[i],
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
