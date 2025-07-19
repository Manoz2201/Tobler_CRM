// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'dart:ui';
import 'admin_home_screen.dart';
import 'package:crm_app/user_management_service.dart';
import 'sales_home_screen.dart';
import 'proposal_engineer_home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeveloperHomeScreen extends StatefulWidget {
  const DeveloperHomeScreen({super.key});

  @override
  State<DeveloperHomeScreen> createState() => _DeveloperHomeScreenState();
}

class _DeveloperHomeScreenState extends State<DeveloperHomeScreen> {
  int _selectedIndex = 0;
  // Restore fields for dockable nav and mobile nav
  bool _isDockedLeft = true;
  double _dragOffsetX = 0.0;
  int _drawerExpansion = 0;
  static const int _rowSize = 5;

  double get _drawerHeight =>
      _drawerExpansion == 0 ? 48 : (_drawerExpansion * 52.0 + 20.0);

  void _onHorizontalDragUpdate(DragUpdateDetails details, double screenWidth) {
    setState(() {
      _dragOffsetX += details.delta.dx;
      _dragOffsetX = _dragOffsetX.clamp(-screenWidth / 2, screenWidth / 2);
    });
  }

  void _onHorizontalDragEnd(double screenWidth) {
    setState(() {
      if (_dragOffsetX > 0) {
        _isDockedLeft = false;
      } else {
        _isDockedLeft = true;
      }
      _dragOffsetX = 0.0;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Helper to build the nav bar widget for wide screens
  Widget _buildNavBar(double screenHeight, double screenWidth) {
    return SizedBox(
      width: 72,
      height: screenHeight * 0.8,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                width: 72,
                height: screenHeight * 0.8,
                color: Colors.white.withAlpha((0.15 * 255).round()),
              ),
            ),
            Container(
              width: 72,
              height: screenHeight * 0.8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withAlpha((0.3 * 255).round()),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.05 * 255).toInt()),
                    blurRadius: 16,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_navItems.length, (index) {
                  final selected = _selectedIndex == index;
                  double baseSize = screenWidth > 1200
                      ? 32
                      : screenWidth > 900
                      ? 30
                      : 28;
                  double scale = selected ? 1.2 : 1.0;
                  Color iconColor = selected
                      ? const Color(0xFF1976D2)
                      : Colors.grey[400]!;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          color: Colors.white.withAlpha((0.18 * 255).round()),
                          child: AnimatedScale(
                            scale: scale,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            child: IconButton(
                              icon: Icon(
                                _navItems[index].icon,
                                color: iconColor,
                                size: baseSize,
                              ),
                              tooltip: _navItems[index].label,
                              onPressed: () => _onItemTapped(index),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Restore _pages and _navItems fields
  static final List<Widget> _pages = <Widget>[
    Center(child: Text('Developer Dashboard')), // 0
    UserManagementPage(), // 1
    ScreenManagementPage(), // 2
    RoleManagementPage(), // 3
    Center(child: Text('Feature Configuration')),
    Center(child: Text('Search')),
    Center(child: Text('Settings')),
    Center(child: Text('Analytics')),
    Center(child: Text('Profile')),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem('Dashboard', Icons.dashboard),
    _NavItem('User Management', Icons.group),
    _NavItem('Screen Management', Icons.desktop_windows),
    _NavItem('Role Management', Icons.security),
    _NavItem('Feature Configuration', Icons.tune),
    _NavItem('AI', Icons.auto_awesome),
    _NavItem('Settings', Icons.settings),
    _NavItem('Analytics', Icons.bar_chart),
    _NavItem('Profile', Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWide = screenWidth > screenHeight;

    return Scaffold(
      // backgroundColor removed to prevent extra sidebar effect
      body: isWide
          ? Stack(
              children: [
                // Main content with padding to avoid nav bar overlap
                AnimatedPadding(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.only(
                    left: _isDockedLeft ? 72 : 0,
                    right: !_isDockedLeft ? 72 : 0,
                  ),
                  child: _pages[_selectedIndex],
                ),
                // Dockable nav bar, centered vertically
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: _isDockedLeft ? 0.0 : 1.0,
                    end: _isDockedLeft ? 0.0 : 1.0,
                  ),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    final barX = value * (screenWidth - 72);
                    return Positioned(
                      left: barX + _dragOffsetX,
                      top: (screenHeight - (screenHeight * 0.8)) / 2,
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) =>
                            _onHorizontalDragUpdate(details, screenWidth),
                        onHorizontalDragEnd: (_) =>
                            _onHorizontalDragEnd(screenWidth),
                        onDoubleTap: () {
                          setState(() {
                            _isDockedLeft = !_isDockedLeft;
                            _dragOffsetX = 0.0;
                          });
                        },
                        child: _buildNavBar(screenHeight, screenWidth),
                      ),
                    );
                  },
                ),
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

// Top-level helper class for navigation items
class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 600,
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
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
    );
  }

  Widget _buildPreviewForType(String type, String mode) {
    switch (type) {
      case 'Admin':
        return _PreviewNoScaffold(child: AdminHomeScreen());
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
        return _PreviewNoScaffold(child: ProposalHomeScreen());
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
  String selectedUserType = 'All';
  String selectedStatus = 'All';
  String searchQuery = '';
  List<String> userTypes = ['All'];
  List<String> statuses = ['All', 'Active', 'Inactive'];

  final ScrollController _scrollbarController = ScrollController();
  String? expandedGroup;
  final Map<String, int> groupPageIndex = {};
  static const int pageSize = 8;
  int mainPageIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    final data = await UserManagementService.fetchUsers();
    setState(() {
      users = data;
      userTypes = [
        'All',
        ...{
          ...data
              .map((e) => e['user_type'] as String? ?? '')
              .where((e) => e.isNotEmpty),
        },
      ];
      isLoading = false;
    });
  }

  Future<void> addUser(Map<String, dynamic> user) async {
    await UserManagementService.addUser(
      userName: user['user_name'],
      userType: user['user_type'],
      status: user['status'],
      screenName: user['screen_name'],
      screenType: user['screen_type'],
      description: user['description'],
    );
    if (!mounted) return;
    await fetchUsers();
  }

  Future<void> updateUser(Map<String, dynamic> user) async {
    await UserManagementService.updateUser(
      id: user['id'],
      userName: user['user_name'],
      userType: user['user_type'],
      status: user['status'],
      screenName: user['screen_name'],
      screenType: user['screen_type'],
      description: user['description'],
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    await _refreshUsers();
  }

  Future<void> deleteUser(String id) async {
    await UserManagementService.deleteUser(id);
    if (!mounted) return;
    await fetchUsers();
  }

  List<Map<String, dynamic>> get filteredUsers {
    return users.where((user) {
      final matchesUserType =
          selectedUserType == 'All' ||
          (user['user_type'] ?? '') == selectedUserType;
      final matchesStatus =
          selectedStatus == 'All' ||
          ((user['status'] ?? '').toString().toLowerCase() ==
              selectedStatus.toLowerCase());
      final matchesQuery =
          searchQuery.isEmpty ||
          ((user['user_name'] ?? '').toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          )) ||
          ((user['screen_name'] ?? '').toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          )) ||
          ((user['user_type'] ?? '').toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          ));
      return matchesUserType && matchesStatus && matchesQuery;
    }).toList();
  }

  // For editing
  String editingUserType = '';
  String editingStatus = 'Active';

  // Modal form controllers
  String newUserStatus = 'Active';

  // Search bar controller
  final TextEditingController _searchController = TextEditingController();

  // Add a field to track frozen state per screen (by index)
  Set<int> frozenScreens = {};

  Future<void> _refreshUsers() async {
    await fetchUsers();
  }

  void _showEditDialog(Map<String, dynamic> user) async {
    final nameController = TextEditingController(text: user['user_name'] ?? '');
    final descController = TextEditingController(
      text: user['description'] ?? '',
    );
    final screenNameController = TextEditingController(
      text: user['screen_name'] ?? '',
    );
    final status = user['status'] ?? 'Active';
    final userType = user['user_type'] ?? '';
    String newStatus = status;
    String newUserType = userType;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'User Name'),
              ),
              TextField(
                controller: screenNameController,
                decoration: InputDecoration(labelText: 'Screen Name'),
              ),
              TextField(
                controller: descController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              DropdownButtonFormField<String>(
                value: newStatus,
                items: ['Active', 'Inactive']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => newStatus = val ?? 'Active',
                decoration: InputDecoration(labelText: 'Status'),
              ),
              DropdownButtonFormField<String>(
                value: newUserType,
                items: userTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (val) => newUserType = val ?? userType,
                decoration: InputDecoration(labelText: 'User Type'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedUser = {
                'id': user['id'],
                'user_name': nameController.text.trim(),
                'user_type': newUserType,
                'status': newStatus,
                'screen_name': screenNameController.text.trim(),
                'screen_type': user['screen_type'] ?? '',
                'description': descController.text.trim(),
              };
              await updateUser(updatedUser);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showViewDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Name: ${user['user_name'] ?? ''}'),
              Text('User Type: ${user['user_type'] ?? ''}'),
              Text('Status: ${user['status'] ?? ''}'),
              Text('Screen Name: ${user['screen_name'] ?? ''}'),
              Text('Description: ${user['description'] ?? ''}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _copyUser(Map<String, dynamic> user) async {
    await UserManagementService.addUser(
      userName: user['user_name'] ?? '',
      userType: user['user_type'] ?? '',
      status: user['status'] ?? 'Active',
      screenName: user['screen_name'] ?? '',
      screenType: user['screen_type'] ?? '',
      description: user['description'] ?? '',
    );
    if (!mounted) return;
    await _refreshUsers();
  }

  void _deleteUser(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User'),
        content: Text('Are you sure you want to delete ${user['user_name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirm == true) {
      await UserManagementService.deleteUser(user['id']);
      if (!mounted) return;
      await _refreshUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter and search screens by selected user type and search query
    final lowerQuery = searchQuery.toLowerCase();
    final filteredUsers = users.where((s) {
      final matchesUserType =
          (s['userType'] ?? '') == selectedUserType ||
          lowerQuery.contains((s['userType'] ?? '').toString().toLowerCase());
      final matchesName = (s['name'] ?? '').toString().toLowerCase().contains(
        lowerQuery,
      );
      final matchesDesc = (s['description'] ?? '')
          .toString()
          .toLowerCase()
          .contains(lowerQuery);
      final matchesStatus = (s['status'] ?? '')
          .toString()
          .toLowerCase()
          .contains(lowerQuery);
      return matchesUserType && (matchesName || matchesDesc || matchesStatus);
    }).toList();

    // Group filtered users by user_type
    final Map<String, List<Map<String, dynamic>>> groupedUsers = {};
    for (final user in filteredUsers) {
      final type = user['user_type'] ?? 'Unknown';
      groupedUsers.putIfAbsent(type, () => []).add(user);
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Scrollbar(
          controller: _scrollbarController,
          thumbVisibility: true,
          child: ListView(
            controller: _scrollbarController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DropdownButton<String>(
                    value: selectedUserType,
                    items: [
                      ...userTypes.map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      ),
                      DropdownMenuItem(
                        value: '__add_new__',
                        child: Row(
                          children: [
                            Icon(Icons.add, color: Colors.deepPurple),
                            SizedBox(width: 6),
                            Text(
                              'Add User Type',
                              style: TextStyle(color: Colors.deepPurple),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (val) async {
                      if (val == '__add_new__') {
                        final newTypeController = TextEditingController();
                        final result = await showDialog<String>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Add New User Type'),
                            content: TextField(
                              controller: newTypeController,
                              decoration: InputDecoration(
                                hintText: 'User type name',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (newTypeController.text
                                      .trim()
                                      .isNotEmpty) {
                                    Navigator.pop(
                                      context,
                                      newTypeController.text.trim(),
                                    );
                                  }
                                },
                                child: Text('Add'),
                              ),
                            ],
                          ),
                        );
                        if (result != null && result.isNotEmpty) {
                          setState(() {
                            userTypes.add(result);
                            selectedUserType = result;
                          });
                        }
                      } else {
                        setState(() {
                          selectedUserType = val ?? userTypes.first;
                        });
                      }
                    },
                  ),
                  SizedBox(width: 16),
                  SizedBox(
                    width: 240,
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelText: 'Search Screens/ user Type / Status',
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
              SizedBox(height: 24),
              if (isLoading)
                Center(child: CircularProgressIndicator())
              else if (expandedGroup != null &&
                  groupedUsers[expandedGroup!] != null &&
                  groupedUsers[expandedGroup!]!.length > pageSize)
                ...(() {
                  final userType = expandedGroup!;
                  final users = groupedUsers[userType]!;
                  final int totalPages = (users.length / pageSize).ceil();
                  int lastPage = totalPages - 1;
                  final int currentPage = mainPageIndex;
                  final List<Map<String, dynamic>> pagedUsers = users
                      .skip(currentPage * pageSize)
                      .take(pageSize)
                      .toList();
                  bool isLastPage = currentPage == lastPage;
                  bool showRestGroupsOnSamePage =
                      isLastPage && pagedUsers.length < pageSize;
                  List<Widget> widgets = [];
                  // Expanded group header
                  widgets.add(
                    InkWell(
                      onTap: () {
                        setState(() {
                          expandedGroup = null;
                          mainPageIndex = 0;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                userType,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_up,
                              color: Colors.deepPurple,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                  // Expanded group users
                  widgets.addAll(
                    pagedUsers.map(
                      (user) => Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          user['user_name'] ?? '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      if (user['user_type'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 4.0,
                                          ),
                                          child: Chip(
                                            label: Text(
                                              user['user_type'].toString(),
                                              style: TextStyle(fontSize: 10),
                                            ),
                                            backgroundColor:
                                                Colors.deepPurple[50],
                                            labelStyle: TextStyle(
                                              color: Colors.deepPurple,
                                            ),
                                          ),
                                        ),
                                      if (user['status'] != null)
                                        Chip(
                                          label: Text(
                                            user['status'].toString(),
                                            style: TextStyle(fontSize: 10),
                                          ),
                                          backgroundColor:
                                              user['status'] == 'Active'
                                              ? Colors.green[100]
                                              : Colors.red[100],
                                          labelStyle: TextStyle(
                                            color: user['status'] == 'Active'
                                                ? Colors.green[800]
                                                : Colors.red[800],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    user['screen_name'] ??
                                        user['screen_type'] ??
                                        '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    user['description'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.remove_red_eye,
                                      color: Colors.deepPurple,
                                    ),
                                    tooltip: 'View',
                                    onPressed: () => _showViewDialog(user),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    tooltip: 'Edit',
                                    onPressed: () => _showEditDialog(user),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.copy,
                                      color: Colors.orange,
                                    ),
                                    tooltip: 'Copy',
                                    onPressed: () => _copyUser(user),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Delete',
                                    onPressed: () => _deleteUser(user),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                  // If last page and there is space, show rest groups below
                  if (showRestGroupsOnSamePage) {
                    widgets.addAll(
                      groupedUsers.entries
                          .where((e) => e.key != userType)
                          .expand((entry) {
                            final otherType = entry.key;
                            final otherUsers = entry.value;
                            final isExpandable = otherUsers.length > 2;
                            final isExpanded = expandedGroup == otherType;
                            final int currentPage =
                                groupPageIndex[otherType] ?? 0;
                            final int totalPages =
                                (otherUsers.length / pageSize).ceil();
                            final List<Map<String, dynamic>> pagedOtherUsers =
                                (isExpandable &&
                                    isExpanded &&
                                    otherUsers.length > pageSize)
                                ? otherUsers
                                      .skip(currentPage * pageSize)
                                      .take(pageSize)
                                      .toList()
                                : otherUsers;
                            return [
                              InkWell(
                                onTap: isExpandable
                                    ? () {
                                        setState(() {
                                          if (isExpanded) {
                                            expandedGroup = null;
                                            mainPageIndex = 0;
                                          } else {
                                            expandedGroup = otherType;
                                            groupPageIndex[otherType] = 0;
                                            mainPageIndex = 0;
                                          }
                                        });
                                      }
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          otherType,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                      ),
                                      if (isExpandable)
                                        Icon(
                                          isExpanded
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          color: Colors.deepPurple,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              if (!isExpandable || isExpanded)
                                ...pagedOtherUsers.map(
                                  (user) => Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Stack(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      user['user_name'] ?? '',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  if (user['user_type'] != null)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            right: 4.0,
                                                          ),
                                                      child: Chip(
                                                        label: Text(
                                                          user['user_type']
                                                              .toString(),
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                        backgroundColor: Colors
                                                            .deepPurple[50],
                                                        labelStyle: TextStyle(
                                                          color:
                                                              Colors.deepPurple,
                                                        ),
                                                      ),
                                                    ),
                                                  if (user['status'] != null)
                                                    Chip(
                                                      label: Text(
                                                        user['status']
                                                            .toString(),
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                      backgroundColor:
                                                          user['status'] ==
                                                              'Active'
                                                          ? Colors.green[100]
                                                          : Colors.red[100],
                                                      labelStyle: TextStyle(
                                                        color:
                                                            user['status'] ==
                                                                'Active'
                                                            ? Colors.green[800]
                                                            : Colors.red[800],
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              SizedBox(height: 6),
                                              Text(
                                                user['screen_name'] ??
                                                    user['screen_type'] ??
                                                    '',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                user['description'] ?? '',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Positioned(
                                          right: 8,
                                          bottom: 8,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  Icons.remove_red_eye,
                                                  color: Colors.deepPurple,
                                                ),
                                                tooltip: 'View',
                                                onPressed: () =>
                                                    _showViewDialog(user),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.edit,
                                                  color: Colors.blue,
                                                ),
                                                tooltip: 'Edit',
                                                onPressed: () =>
                                                    _showEditDialog(user),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.copy,
                                                  color: Colors.orange,
                                                ),
                                                tooltip: 'Copy',
                                                onPressed: () =>
                                                    _copyUser(user),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                tooltip: 'Delete',
                                                onPressed: () =>
                                                    _deleteUser(user),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (isExpandable &&
                                  isExpanded &&
                                  otherUsers.length > pageSize)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.chevron_left),
                                        onPressed: currentPage > 0
                                            ? () {
                                                setState(() {
                                                  groupPageIndex[otherType] =
                                                      currentPage - 1;
                                                });
                                              }
                                            : null,
                                      ),
                                      Text(
                                        'Page ${currentPage + 1} of $totalPages',
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.chevron_right),
                                        onPressed: currentPage < totalPages - 1
                                            ? () {
                                                setState(() {
                                                  groupPageIndex[otherType] =
                                                      currentPage + 1;
                                                });
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                            ];
                          }),
                    );
                  }
                  // Page controls
                  widgets.add(
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.chevron_left),
                            onPressed: mainPageIndex > 0
                                ? () {
                                    setState(() {
                                      mainPageIndex--;
                                    });
                                  }
                                : null,
                          ),
                          Text(
                            'Page ${currentPage + 1} of ${totalPages + (showRestGroupsOnSamePage ? 0 : 1)}',
                          ),
                          IconButton(
                            icon: Icon(Icons.chevron_right),
                            onPressed:
                                (!isLastPage ||
                                        (isLastPage &&
                                            !showRestGroupsOnSamePage)) &&
                                    mainPageIndex <
                                        (totalPages +
                                            (showRestGroupsOnSamePage ? 0 : 1) -
                                            1)
                                ? () {
                                    setState(() {
                                      mainPageIndex++;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                  return widgets;
                })()
              else
                ...groupedUsers.entries.expand((entry) {
                  final userType = entry.key;
                  final users = entry.value;
                  final isExpandable = users.length > 2;
                  final isExpanded = expandedGroup == userType;
                  final int currentPage = groupPageIndex[userType] ?? 0;
                  final int totalPages = (users.length / pageSize).ceil();
                  final List<Map<String, dynamic>> pagedUsers =
                      (isExpandable && isExpanded && users.length > pageSize)
                      ? users
                            .skip(currentPage * pageSize)
                            .take(pageSize)
                            .toList()
                      : users;
                  return [
                    InkWell(
                      onTap: isExpandable
                          ? () {
                              setState(() {
                                if (isExpanded) {
                                  expandedGroup = null;
                                  mainPageIndex = 0;
                                } else {
                                  expandedGroup = userType;
                                  groupPageIndex[userType] = 0;
                                  mainPageIndex = 0;
                                }
                              });
                            }
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                userType,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                            if (isExpandable)
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Colors.deepPurple,
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (!isExpandable || isExpanded)
                      ...pagedUsers.map(
                        (user) => Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            user['user_name'] ?? '',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        if (user['user_type'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 4.0,
                                            ),
                                            child: Chip(
                                              label: Text(
                                                user['user_type'].toString(),
                                                style: TextStyle(fontSize: 10),
                                              ),
                                              backgroundColor:
                                                  Colors.deepPurple[50],
                                              labelStyle: TextStyle(
                                                color: Colors.deepPurple,
                                              ),
                                            ),
                                          ),
                                        if (user['status'] != null)
                                          Chip(
                                            label: Text(
                                              user['status'].toString(),
                                              style: TextStyle(fontSize: 10),
                                            ),
                                            backgroundColor:
                                                user['status'] == 'Active'
                                                ? Colors.green[100]
                                                : Colors.red[100],
                                            labelStyle: TextStyle(
                                              color: user['status'] == 'Active'
                                                  ? Colors.green[800]
                                                  : Colors.red[800],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      user['screen_name'] ??
                                          user['screen_type'] ??
                                          '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      user['description'] ?? '',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.remove_red_eye,
                                        color: Colors.deepPurple,
                                      ),
                                      tooltip: 'View',
                                      onPressed: () => _showViewDialog(user),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      tooltip: 'Edit',
                                      onPressed: () => _showEditDialog(user),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.copy,
                                        color: Colors.orange,
                                      ),
                                      tooltip: 'Copy',
                                      onPressed: () => _copyUser(user),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Delete',
                                      onPressed: () => _deleteUser(user),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (isExpandable && isExpanded && users.length > pageSize)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.chevron_left),
                              onPressed: currentPage > 0
                                  ? () {
                                      setState(() {
                                        groupPageIndex[userType] =
                                            currentPage - 1;
                                      });
                                    }
                                  : null,
                            ),
                            Text('Page ${currentPage + 1} of $totalPages'),
                            IconButton(
                              icon: Icon(Icons.chevron_right),
                              onPressed: currentPage < totalPages - 1
                                  ? () {
                                      setState(() {
                                        groupPageIndex[userType] =
                                            currentPage + 1;
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                  ];
                }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollbarController.dispose();
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
            childAspectRatio: 1.6,
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
                  value: _selectedRole,
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
    final data = await Supabase.instance.client
        .from('invitation')
        .select(
          'user_name, mobile_no, email, user_type, created_at, is_registered',
        )
        .eq('active', false)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
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
                                    child: Text(
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
