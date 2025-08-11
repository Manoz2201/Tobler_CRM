import 'package:flutter/material.dart';
import 'package:crm_app/widgets/profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/lead_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../../utils/navigation_utils.dart';
import '../../utils/timezone_utils.dart';
import '../auth/login_screen.dart';
import '../../services/query_notification_service.dart';
import '../../main.dart'
    show
        updateUserSessionActiveMCP,
        updateUserOnlineStatusMCP,
        updateUserOnlineStatusByEmailMCP,
        setUserOnlineStatus;

// ChartData class for Syncfusion charts
class ChartData {
  ChartData(this.x, this.y, this.color);
  final String x;
  final double y;
  final Color color;
}

class SalesHomeScreen extends StatefulWidget {
  final String currentUserType;
  final String currentUserEmail;
  final String currentUserId;

  const SalesHomeScreen({
    super.key,
    required this.currentUserType,
    required this.currentUserEmail,
    required this.currentUserId,
  });

  @override
  State<SalesHomeScreen> createState() => _SalesHomeScreenState();
}

class _SalesHomeScreenState extends State<SalesHomeScreen> {
  int _selectedIndex = 0;
  final Map<int, bool> _hoveredItems = {};
  bool _isCollapsed = false;

  List<NavItem> get _navItems {
    // Sales users get Leads Management navigation item
    return NavigationUtils.getNavigationItemsForRole('sales');
  }

  late final List<Widget> _pages = <Widget>[
    SalesDashboardPage(
      currentUserId: widget.currentUserId,
      currentUserEmail: widget.currentUserEmail,
    ),
    LeadManagementScreen(),
    const Center(child: Text('Customers Management')),
    const Center(child: Text('Tasks Management')),
    const Center(child: Text('Reports')),
    const Center(child: Text('Sales Settings')),
    ProfilePage(),
  ];

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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: _buildMobileNavBar(),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _buildNavBar(screenHeight, screenWidth),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildNavBar(double screenHeight, double screenWidth) {
    return Container(
      width: _isCollapsed ? 80 : 280,
      height: screenHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A000000),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Section with Logo and User Profile
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: const Color(0xFFE0E0E0), width: 1),
              ),
            ),
            child: Column(
              children: [
                // Logo Section - Only show when expanded
                if (!_isCollapsed)
                  SizedBox(
                    height: 40,
                    child: Image.asset(
                      'assets/Tobler_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                const SizedBox(height: 16),
                // User Profile Section (only show when expanded)
                if (!_isCollapsed)
                  Row(
                    children: [
                      // User Avatar
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'U',
                            style: TextStyle(
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
                            const Text(
                              'Hi,',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              'Sales User',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF757575),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
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
                // Collapse/Expand Button (when collapsed)
                if (_isCollapsed)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isCollapsed = !_isCollapsed;
                      });
                    },
                    icon: const Icon(Icons.arrow_forward, color: Colors.grey),
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
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
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

  Widget _buildMobileNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _navItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = _selectedIndex == index;

                return GestureDetector(
                  onTap: () => _onItemTapped(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        color: isSelected ? Colors.blue : Colors.grey[600],
                        size: 26,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class LeadManagementScreen extends StatefulWidget {
  const LeadManagementScreen({super.key});

  @override
  State<LeadManagementScreen> createState() => _LeadManagementScreenState();
}

class _LeadManagementScreenState extends State<LeadManagementScreen> {
  List<Map<String, dynamic>> _leads = [];
  List<Map<String, dynamic>> _filteredLeads = [];
  String _searchText = '';
  final Map<String, double> _totalAmounts = {}; // Store calculated totals
  bool _isLoading = true;
  final Map<String, bool> _hoveredRows = {}; // Track hover state for each row
  final Map<String, bool> _hoveredButtons = {}; // Track hover state for buttons
  String? _selectedStatusFilter; // Track selected status filter for sorting

  // Add query count tracking
  final Map<String, int> _queryCounts = {};

  String? _currentUserId;
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _fetchLeads();
    // Add sample data to match the image exactly
    _addSampleData();

    // Set up periodic query count refresh
    _startQueryCountRefresh();
  }

  void _startQueryCountRefresh() {
    // Refresh query counts every 30 seconds
    Future.delayed(Duration(seconds: 30), () {
      if (mounted) {
        _fetchQueryCounts();
        _startQueryCountRefresh(); // Schedule next refresh
      }
    });
  }

  void _addSampleData() {
    // Add sample data to match the admin interface image
    final sampleLeads = [
      {
        'lead_id': '1',
        'client_name': 'RK Construction',
        'project_name': 'Dahisar Project',
        'project_location': 'Mumbai',
        'aluminium_area': 0.0,
        'ms_weight': 0.0,
        'rate_sqm': 0,
        'total_amount': 0.0,
        'project_id': 'Tobler-A49B',
        'date': '2025-07-30 12:00',
        'status': 'Proposal Progress',
      },
      {
        'lead_id': '2',
        'client_name': 'test',
        'project_name': 'test',
        'project_location': 'test',
        'aluminium_area': 0.0,
        'ms_weight': 0.0,
        'rate_sqm': 0,
        'total_amount': 0.0,
        'project_id': 'Tobler-B72C',
        'date': '2025-07-30 12:00',
        'status': 'Proposal Progress',
      },
      {
        'lead_id': '3',
        'client_name': 'JP Infra',
        'project_name': 'Thane Project',
        'project_location': 'Mumbai',
        'aluminium_area': 0.0,
        'ms_weight': 0.0,
        'rate_sqm': 0,
        'total_amount': 0.0,
        'project_id': 'Tobler-C91D',
        'date': '2025-07-30 12:00',
        'status': 'Proposal Progress',
      },
      {
        'lead_id': '4',
        'client_name': 'IBCLLP',
        'project_name': 'IBCLLP',
        'project_location': 'Mumbai',
        'aluminium_area': 0.0,
        'ms_weight': 0.0,
        'rate_sqm': 0,
        'total_amount': 0.0,
        'project_id': 'Tobler-D34E',
        'date': '2025-07-30 12:00',
        'status': 'Proposal Progress',
      },
      {
        'lead_id': '5',
        'client_name': 'West Best Buildcon',
        'project_name': 'Spenta Housing',
        'project_location': 'Mumbai',
        'aluminium_area': 0.0,
        'ms_weight': 0.0,
        'rate_sqm': 0,
        'total_amount': 0.0,
        'project_id': 'Tobler-E56F',
        'date': '2025-07-30 12:00',
        'status': 'Proposal Progress',
      },
      {
        'lead_id': '6',
        'client_name': 'Mehta Group',
        'project_name': 'Jogeshwari Project',
        'project_location': 'Mumbai',
        'aluminium_area': 0.0,
        'ms_weight': 0.0,
        'rate_sqm': 0,
        'total_amount': 0.0,
        'project_id': 'Tobler-F78G',
        'date': '2025-07-30 12:00',
        'status': 'Proposal Progress',
      },
    ];

    // Initialize total amounts for sample data
    for (final lead in sampleLeads) {
      final leadId = lead['lead_id'].toString();
      _totalAmounts[leadId] = (lead['total_amount'] as double?) ?? 0.0;
    }

    setState(() {
      _leads = sampleLeads;
      _filteredLeads = sampleLeads;
      _isLoading = false;
    });
  }

  Future<void> _getCurrentUser() async {
    try {
      debugPrint('Getting current user from cache memory...');

      // Step 1: Get cached user data
      final prefs = await SharedPreferences.getInstance();
      final cachedUserId = prefs.getString('user_id');
      final cachedSessionId = prefs.getString('session_id');
      final cachedSessionActive = prefs.getBool('session_active');
      final cachedUserType = prefs.getString('user_type');

      debugPrint('[CACHE] Cached user_id: $cachedUserId');
      debugPrint('[CACHE] Cached session_id: $cachedSessionId');
      debugPrint('[CACHE] Cached session_active: $cachedSessionActive');
      debugPrint('[CACHE] Cached user_type: $cachedUserType');

      // Step 2: Validate cache data
      if (cachedUserId == null ||
          cachedSessionId == null ||
          cachedSessionActive != true) {
        debugPrint('[CACHE] Invalid cache data, falling back to auth session');

        // Fallback to current auth session
        final client = Supabase.instance.client;
        final user = client.auth.currentUser;
        if (user != null) {
          setState(() {
            _currentUserId = user.id;
          });

          // Get username from users table
          final userData = await client
              .from('users')
              .select('username')
              .eq('id', user.id)
              .single();

          setState(() {
            _currentUsername = userData['username'];
          });

          debugPrint(
            '[AUTH] Loaded user from auth session: ${userData['username']} (ID: ${user.id})',
          );
        } else {
          debugPrint('[AUTH] No active user found in auth session');
        }
      } else {
        // Step 3: Use cached user_id
        setState(() {
          _currentUserId = cachedUserId;
        });

        // Get username from users table using cached user_id
        final client = Supabase.instance.client;
        final userData = await client
            .from('users')
            .select('username')
            .eq('id', cachedUserId)
            .single();

        setState(() {
          _currentUsername = userData['username'];
        });

        debugPrint(
          '[CACHE] Successfully loaded user from cache: $_currentUsername (ID: $_currentUserId)',
        );
      }
    } catch (e) {
      debugPrint('Error getting current user: $e');

      // Final fallback to auth session if cache fails
      try {
        final client = Supabase.instance.client;
        final user = client.auth.currentUser;
        if (user != null) {
          setState(() {
            _currentUserId = user.id;
          });

          // Get username from users table
          final userData = await client
              .from('users')
              .select('username')
              .eq('id', user.id)
              .single();

          setState(() {
            _currentUsername = userData['username'];
          });

          debugPrint(
            '[FALLBACK] Loaded user from fallback: ${userData['username']} (ID: ${user.id})',
          );
        } else {
          debugPrint('[FALLBACK] No user found in fallback');
        }
      } catch (fallbackError) {
        debugPrint('Fallback auth also failed: $fallbackError');
      }
    }
  }

  Future<void> _fetchLeads() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Starting lead fetch process...');

      // Step 1: Get active user from cache memory
      final prefs = await SharedPreferences.getInstance();
      final cachedUserId = prefs.getString('user_id');
      final cachedSessionActive = prefs.getBool('session_active');

      debugPrint('[CACHE] Active user_id: $cachedUserId');
      debugPrint('[CACHE] Session active: $cachedSessionActive');

      // Step 2: Validate cache data
      if (cachedUserId == null || cachedSessionActive != true) {
        debugPrint('[CACHE] Invalid cache data, using fallback');

        // Fallback to current auth session
        final client = Supabase.instance.client;
        final user = client.auth.currentUser;
        if (user == null) {
          throw Exception('No active user found');
        }

        setState(() {
          _currentUserId = user.id;
        });
      } else {
        setState(() {
          _currentUserId = cachedUserId;
        });
      }

      debugPrint('Fetching leads for user_id: $_currentUserId');

      // Step 3: Fetch leads from Supabase using the active user_id
      final client = Supabase.instance.client;

      // Fetch leads data for current sales user only with timeout
      final leadsResult = await client
          .from('leads')
          .select(
            'id, created_at, project_name, client_name, project_location, lead_generated_by',
          )
          .eq('lead_generated_by', _currentUserId!) // Filter by active user
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));

      debugPrint('Found ${leadsResult.length} leads from Supabase');

      // Step 4: Fetch related data for calculations with timeout protection
      List<dynamic> proposalInputResult = [];
      List<dynamic> adminResponseResult = [];

      try {
        proposalInputResult = await client
            .from('proposal_input')
            .select('lead_id, input, value')
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('⚠️ Error fetching proposal_input: $e');
        // Continue with empty data
      }

      try {
        adminResponseResult = await client
            .from('admin_response')
            .select('lead_id, rate_sqm, status, remark, project_id')
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('⚠️ Error fetching admin_response: $e');
        // Continue with empty data
      }

      // Step 5: Process data (same as admin but filtered by user)
      final Map<String, double> aluminiumAreaMap = {};
      final Map<String, List<double>> msWeightMap = {};

      for (final input in proposalInputResult) {
        final leadId = input['lead_id'];
        final inputName = input['input']?.toString().toLowerCase() ?? '';
        final value = double.tryParse(input['value']?.toString() ?? '0') ?? 0;

        if (leadId != null) {
          // Calculate Aluminium Area (sum of values containing "aluminium" or "alu")
          if (inputName.contains('aluminium') || inputName.contains('alu')) {
            aluminiumAreaMap[leadId] = (aluminiumAreaMap[leadId] ?? 0) + value;
          }

          // Calculate MS Weight (average of values containing "ms" or "ms wt.")
          if (inputName.contains('ms') || inputName.contains('ms wt.')) {
            if (!msWeightMap.containsKey(leadId)) {
              msWeightMap[leadId] = [];
            }
            msWeightMap[leadId]!.add(value);
          }
        }
      }

      final Map<String, Map<String, dynamic>> adminResponseMap = {};
      for (final response in adminResponseResult) {
        final leadId = response['lead_id'];
        if (leadId != null) {
          adminResponseMap[leadId] = response;
        }
      }

      // Step 6: Join the data (matching admin's Lead Management structure)
      final List<Map<String, dynamic>> joinedLeads = [];
      for (final lead in leadsResult) {
        final leadId = lead['id'];
        final adminResponseData = adminResponseMap[leadId];

        // Calculate MS Weight average
        final msWeights = msWeightMap[leadId] ?? [];
        final msWeightAverage = msWeights.isNotEmpty
            ? msWeights.reduce((a, b) => a + b) / msWeights.length
            : 0.0;

        // Calculate total amount (including GST)
        final aluminiumArea = aluminiumAreaMap[leadId] ?? 0;
        final rate = adminResponseData?['rate_sqm'] ?? 0;
        final totalAmount = aluminiumArea * rate * 1.18;

        // Determine dynamic status based on time and Supabase table checks
        String dynamicStatus = 'Proposal Progress'; // Default status

        // Check if lead is approved (found in admin_response table)
        if (adminResponseData?['status'] == 'Approved') {
          dynamicStatus = 'Approved';
        } else {
          // Check if lead is within 12 hours of creation
          final createdAt = lead['created_at'];
          if (createdAt != null) {
            final DateTime leadDate = createdAt is String
                ? DateTime.parse(createdAt)
                : createdAt as DateTime;
            final DateTime now = DateTime.now();
            final Duration difference = now.difference(leadDate);

            if (difference.inHours <= 12) {
              dynamicStatus = 'New';
            } else {
              // Check if lead has proposal input data (found in proposal_input table)
              if (aluminiumArea > 0) {
                dynamicStatus = 'Waiting for Approval';
              } else {
                dynamicStatus = 'Proposal Progress';
              }
            }
          }
        }

        joinedLeads.add({
          'lead_id': leadId,
          'date': lead['created_at'],
          'project_name': lead['project_name'] ?? '',
          'client_name': lead['client_name'] ?? '',
          'project_location': lead['project_location'] ?? '',
          'sales_person_name': _currentUsername ?? '',
          'aluminium_area': aluminiumArea,
          'ms_weight': msWeightAverage,
          'rate_sqm': rate,
          'total_amount': totalAmount,
          'project_id':
              adminResponseData?['project_id'] ??
              'N/A', // Add project_id from admin_response
          'approved': adminResponseData?['status'] == 'Approved',
          'status': dynamicStatus,
        });
      }

      // Step 7: Initialize total amounts for UI display
      for (final lead in joinedLeads) {
        final leadId = lead['lead_id'].toString();
        _totalAmounts[leadId] = lead['total_amount'] ?? 0.0;
      }

      // Step 8: Fetch query counts for all leads
      await _fetchQueryCounts();

      setState(() {
        _leads = joinedLeads;
        _filteredLeads = joinedLeads;
        _isLoading = false;
      });

      debugPrint(
        'Successfully loaded ${joinedLeads.length} leads for user $_currentUsername (ID: $_currentUserId)',
      );
    } catch (e) {
      debugPrint('Error fetching leads: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching leads: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method to fetch query counts for all leads
  Future<void> _fetchQueryCounts() async {
    try {
      final client = Supabase.instance.client;

      // Fetch query counts for each lead
      for (final lead in _leads) {
        final leadId = lead['lead_id'].toString();

        try {
          // The leadId should be the actual UUID from the leads table
          // If it's not a valid UUID, we can't proceed
          if (leadId.isEmpty || leadId == 'null') {
            debugPrint('Invalid leadId: $leadId');
            setState(() {
              _queryCounts[leadId] = 0;
            });
            continue;
          }

          // Get query count for this lead
          final queryCount = await client
              .from('queries')
              .select('id')
              .eq('lead_id', leadId);

          setState(() {
            _queryCounts[leadId] = queryCount.length;
          });
        } catch (e) {
          debugPrint('Error fetching query counts: $e');
          setState(() {
            _queryCounts[leadId] = 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching query counts: $e');
    }
  }

  void _onSearch(String value) {
    setState(() {
      _searchText = value.toLowerCase();
      _applyFilters();
    });
  }

  void _onStatusFilterChanged(String? statusFilter) {
    setState(() {
      _selectedStatusFilter = _selectedStatusFilter == statusFilter
          ? null
          : statusFilter;
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filteredLeads = _leads.where((lead) {
      // Apply search filter
      final matchesSearch =
          lead['lead_id'].toString().toLowerCase().contains(_searchText) ||
          (lead['client_name'] ?? '').toLowerCase().contains(_searchText) ||
          (lead['project_name'] ?? '').toLowerCase().contains(_searchText);

      // Apply status filter
      final matchesStatus =
          _selectedStatusFilter == null ||
          _getLeadStatus(lead) == _selectedStatusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  String _getLeadStatus(Map<String, dynamic> lead) {
    return LeadUtils.getLeadStatus(lead);
  }

  void _exportLeads() {
    try {
      // Implement export functionality for sales
      final filteredLeads = _filteredLeads;
      if (filteredLeads.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No leads to export'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Here you would typically generate and download a CSV/Excel file
      // For now, we'll show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exporting ${filteredLeads.length} leads...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is String) {
        final parsed = DateTime.parse(date);
        return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      } else if (date is DateTime) {
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  String _generateProjectId(String leadId) {
    // Generate project ID like "Tobler-A49B" from lead ID
    final hash = leadId.hashCode.abs();
    final hex = hash.toRadixString(16).toUpperCase();
    final shortHex = hex.length > 4 ? hex.substring(0, 4) : hex.padLeft(4, '0');
    return 'Tobler-$shortHex';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: Padding(
            padding: EdgeInsets.fromLTRB(
              isWide ? 24.0 : 16.0,
              isWide ? 24.0 : 12.0,
              isWide ? 24.0 : 16.0,
              isWide ? 24.0 : 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(isWide),
                SizedBox(height: isWide ? 24 : 8),

                // Stats Cards
                if (isWide) _buildStatsCards(),
                if (isWide) const SizedBox(height: 24),

                // Search and Actions Section
                _buildSearchAndActions(isWide),
                SizedBox(height: isWide ? 24 : 8),

                // Content
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _filteredLeads.isEmpty
                      ? _buildEmptyState()
                      : isWide
                      ? _buildWideTable()
                      : _buildMobileTable(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isWide) {
    if (isWide) {
      // Desktop layout - matching admin design exactly
      return Row(
        children: [
          Icon(Icons.leaderboard, size: 32, color: Colors.blue[700]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leads Management',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  'Manage and track your leads',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Implement export functionality for sales
              _exportLeads();
            },
            icon: Icon(Icons.download),
            tooltip: 'Export Leads',
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _fetchLeads,
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      );
    } else {
      // Mobile layout - compact design matching admin
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard, size: 24, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Leads Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Manage and track your leads',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          // Mobile stats cards
          _buildMobileStatsCards(),
        ],
      );
    }
  }

  Widget _buildStatsCards() {
    final totalLeads = _leads.length;
    final newLeads = _leads
        .where((lead) => _getLeadStatus(lead) == 'New')
        .length;
    final proposalProgress = _leads
        .where((lead) => _getLeadStatus(lead) == 'Proposal Progress')
        .length;
    final waitingApproval = _leads
        .where((lead) => _getLeadStatus(lead) == 'Waiting for Approval')
        .length;
    final approved = _leads
        .where((lead) => _getLeadStatus(lead) == 'Approved')
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Leads',
            totalLeads.toString(),
            Icons.leaderboard,
            Colors.blue,
            null, // No filter for total
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'New',
            newLeads.toString(),
            Icons.new_releases,
            Colors.green,
            'New',
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Proposal Progress',
            proposalProgress.toString(),
            Icons.pending,
            Colors.orange,
            'Proposal Progress',
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Waiting Approval',
            waitingApproval.toString(),
            Icons.schedule,
            Colors.purple,
            'Waiting for Approval',
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Approved',
            approved.toString(),
            Icons.check_circle,
            Colors.green,
            'Approved',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String? statusFilter,
  ) {
    final isSelected = _selectedStatusFilter == statusFilter;

    return GestureDetector(
      onTap: () => _onStatusFilterChanged(statusFilter),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: color, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? color : Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? color : Colors.grey[600],
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileStatsCards() {
    final totalLeads = _leads.length;
    final newLeads = _leads
        .where((lead) => _getLeadStatus(lead) == 'New')
        .length;
    final proposalProgress = _leads
        .where((lead) => _getLeadStatus(lead) == 'Proposal Progress')
        .length;
    final waitingApproval = _leads
        .where((lead) => _getLeadStatus(lead) == 'Waiting for Approval')
        .length;
    final approved = _leads
        .where((lead) => _getLeadStatus(lead) == 'Approved')
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildMobileStatCard(
            'Total',
            totalLeads.toString(),
            Icons.leaderboard,
            Colors.blue,
            null,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildMobileStatCard(
            'New',
            newLeads.toString(),
            Icons.new_releases,
            Colors.green,
            'New',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildMobileStatCard(
            'Progress',
            proposalProgress.toString(),
            Icons.pending,
            Colors.orange,
            'Proposal Progress',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildMobileStatCard(
            'Waiting',
            waitingApproval.toString(),
            Icons.schedule,
            Colors.purple,
            'Waiting for Approval',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildMobileStatCard(
            'Approved',
            approved.toString(),
            Icons.check_circle,
            Colors.green,
            'Approved',
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String? statusFilter,
  ) {
    final isSelected = _selectedStatusFilter == statusFilter;

    return GestureDetector(
      onTap: () => _onStatusFilterChanged(statusFilter),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: color, width: 1.5) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey[800],
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? color : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndActions(bool isWide) {
    if (isWide) {
      // Desktop layout - simplified with only search and Add New Lead button
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Search Input
            Expanded(
              flex: 3,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search leads...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
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
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: _onSearch,
              ),
            ),
            SizedBox(width: 16),
            // Add New Lead Button
            ElevatedButton.icon(
              onPressed: () {
                _showAddLeadDialog();
              },
              icon: Icon(Icons.add),
              label: Text('Add New Lead'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      );
    } else {
      // Mobile layout - simplified with only search and Add New Lead button
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Search Row
            TextField(
              decoration: InputDecoration(
                hintText: 'Search leads...',
                prefixIcon: Icon(Icons.search, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.blue[600]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: _onSearch,
            ),
            SizedBox(height: 8),
            // Add New Lead Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Implement add new lead functionality
                  _showAddLeadDialog();
                },
                icon: Icon(Icons.add, size: 16),
                label: Text('Add New Lead'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard_outlined, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No leads found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildWideTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Count Header (matching image)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_filteredLeads.length} leads',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
          // Table Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Client/Date',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.left,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Project',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Project ID',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Location',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Area',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Weight',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Rate',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Actions',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table Body
          Expanded(
            child: ListView.builder(
              itemCount: _filteredLeads.length,
              itemBuilder: (context, index) {
                final lead = _filteredLeads[index];
                return _buildTableRow(lead, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> lead, int index) {
    final leadId = lead['lead_id'].toString();
    final totalAmount = _totalAmounts[leadId] ?? 0.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: (index % 2 == 0 ? Colors.white : Colors.grey[50]),
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _viewLeadDetails(lead),
            onHover: (isHovered) {
              setState(() {
                // Update hover state for this row
                _hoveredRows[leadId] = isHovered;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: _hoveredRows[leadId] == true
                    ? Colors.blue.withValues(alpha: 0.05)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lead['client_name'] ?? 'N/A',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _hoveredRows[leadId] == true
                                  ? Colors.blue[700]
                                  : Colors.grey[800],
                            ),
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            textAlign: TextAlign.left,
                          ),
                          Text(
                            _formatDate(lead['date']),
                            style: TextStyle(
                              fontSize: 12,
                              color: _hoveredRows[leadId] == true
                                  ? Colors.blue[600]
                                  : Colors.grey[600],
                            ),
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      child: Text(
                        lead['project_name'] ?? 'N/A',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: _hoveredRows[leadId] == true
                              ? Colors.blue[700]
                              : Colors.grey[800],
                        ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      child: Text(
                        _generateProjectId(leadId),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: _hoveredRows[leadId] == true
                              ? Colors.blue[700]
                              : Colors.grey[800],
                        ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      child: Text(
                        lead['project_location'] ?? 'N/A',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: _hoveredRows[leadId] == true
                              ? Colors.blue[700]
                              : Colors.grey[800],
                        ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      child: Text(
                        '${lead['aluminium_area']?.toStringAsFixed(1) ?? '0.0'} sqm',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: _hoveredRows[leadId] == true
                              ? Colors.blue[700]
                              : Colors.grey[800],
                        ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      child: Text(
                        '${lead['ms_weight']?.toStringAsFixed(1) ?? '0.0'} kg',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: _hoveredRows[leadId] == true
                              ? Colors.blue[700]
                              : Colors.grey[800],
                        ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      child: Text(
                        '₹${lead['rate_sqm']?.toStringAsFixed(0) ?? '0'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: _hoveredRows[leadId] == true
                              ? Colors.blue[700]
                              : Colors.grey[800],
                        ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      child: Text(
                        '₹${totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: _hoveredRows[leadId] == true
                              ? Colors.blue[700]
                              : Colors.grey[800],
                        ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_getLeadStatus(lead)),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _hoveredRows[leadId] == true
                              ? [
                                  BoxShadow(
                                    color: _getStatusColor(
                                      _getLeadStatus(lead),
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          _getLeadStatus(lead),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildInteractiveIconButton(
                            icon: Icons.edit,
                            onPressed: () => _editLead(lead),
                            tooltip: 'Edit Lead',
                            leadId: leadId,
                          ),
                          SizedBox(width: 4),
                          _buildInteractiveIconButton(
                            icon: Icons.notifications,
                            onPressed: () => _showAlertsDialog(context, lead),
                            tooltip: 'Alert',
                            leadId: leadId,
                            isAlert: true,
                          ),
                          SizedBox(width: 4),
                          _buildInteractiveIconButton(
                            icon: Icons.chat,
                            onPressed: () => _showQueryDialog(context, lead),
                            tooltip: 'Query',
                            leadId: leadId,
                            isQuery: true,
                          ),
                          SizedBox(width: 4),
                          _buildInteractiveIconButton(
                            icon: Icons.flag,
                            onPressed: () => _initializeStatus(lead),
                            tooltip: 'Initialize Status',
                            leadId: leadId,
                          ),
                          SizedBox(width: 4),
                          _buildInteractiveIconButton(
                            icon: Icons.delete,
                            onPressed: () => _deleteLead(lead),
                            tooltip: 'Delete Lead',
                            leadId: leadId,
                            isDestructive: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileTable() {
    return ListView.builder(
      itemCount: _filteredLeads.length,
      itemBuilder: (context, index) {
        final lead = _filteredLeads[index];
        return _buildMobileCard(lead, index);
      },
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> lead, int index) {
    final leadId = lead['lead_id'].toString();
    final totalAmount = _totalAmounts[leadId] ?? 0.0;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: _hoveredRows[leadId] == true ? 8 : 2,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: _hoveredRows[leadId] == true
              ? Border.all(color: Colors.blue[300]!, width: 1)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _viewLeadDetails(lead),
            onHover: (isHovered) {
              setState(() {
                _hoveredRows[leadId] = isHovered;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Client: ${lead['client_name'] ?? 'N/A'}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _hoveredRows[leadId] == true
                                    ? Colors.blue[700]
                                    : Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Project: ${lead['project_name'] ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: _hoveredRows[leadId] == true
                                    ? Colors.blue[600]
                                    : Colors.grey[700],
                              ),
                            ),
                            Text(
                              'Lead ID: ${lead['project_id'] ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: _hoveredRows[leadId] == true
                                    ? Colors.blue[600]
                                    : Colors.grey[700],
                              ),
                            ),
                            Text(
                              'Location: ${lead['project_location'] ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: _hoveredRows[leadId] == true
                                    ? Colors.blue[600]
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aluminium Area: ${lead['aluminium_area']?.toStringAsFixed(2) ?? '0.00'} sq/m',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              'MS Weight: ${lead['ms_weight']?.toStringAsFixed(2) ?? '0.00'} kg',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Rate: ₹${lead['rate_sqm']?.toStringAsFixed(2) ?? '0.00'}',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Total: ₹${totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_getLeadStatus(lead)),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _hoveredRows[leadId] == true
                              ? [
                                  BoxShadow(
                                    color: _getStatusColor(
                                      _getLeadStatus(lead),
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          _getLeadStatus(lead),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Spacer(),
                      Row(
                        children: [
                          _buildMobileInteractiveButton(
                            icon: Icons.edit,
                            onPressed: () => _editLead(lead),
                            tooltip: 'Edit',
                            leadId: leadId,
                          ),
                          SizedBox(width: 8),
                          _buildMobileInteractiveButton(
                            icon: Icons.notifications,
                            onPressed: () => _showAlertsDialog(context, lead),
                            tooltip: 'Alert',
                            leadId: leadId,
                            isAlert: true,
                          ),
                          SizedBox(width: 8),
                          _buildMobileInteractiveButton(
                            icon: Icons.chat,
                            onPressed: () => _showQueryDialog(context, lead),
                            tooltip: 'Query',
                            leadId: leadId,
                            isQuery: true,
                          ),
                          SizedBox(width: 8),
                          _buildMobileInteractiveButton(
                            icon: Icons.flag,
                            onPressed: () => _initializeStatus(lead),
                            tooltip: 'Initialize Status',
                            leadId: leadId,
                          ),
                          SizedBox(width: 8),
                          _buildMobileInteractiveButton(
                            icon: Icons.delete,
                            onPressed: () => _deleteLead(lead),
                            tooltip: 'Delete',
                            leadId: leadId,
                            isDestructive: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    return Color(LeadUtils.getStatusColor(status));
  }

  void _editLead(Map<String, dynamic> lead) {
    // Open edit lead dialog with pre-filled data
    debugPrint('Edit lead called with data: $lead');
    debugPrint('Lead ID: ${lead['lead_id']}');
    debugPrint('Lead ID type: ${lead['lead_id'].runtimeType}');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return EditLeadDialog(
          currentUserId: _currentUserId,
          leadId: lead['lead_id'].toString(),
          onLeadUpdated: () {
            _fetchLeads(); // Refresh the leads list
          },
        );
      },
    );
  }

  void _initializeStatus(Map<String, dynamic> lead) {
    debugPrint('Initialize status called with data: $lead');
    debugPrint('Lead ID: ${lead['lead_id']}');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return InitializeStatusDialog(
          leadId: lead['lead_id'].toString(),
          projectName: lead['project_name'] ?? 'N/A',
          onStatusUpdated: () {
            _fetchLeads(); // Refresh the leads list
          },
        );
      },
    );
  }

  Future<void> _deleteLead(Map<String, dynamic> lead) async {
    final leadId = lead['lead_id'].toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Lead'),
          content: Text(
            'Are you sure you want to delete lead: ${lead['project_name']}?\n\nThis action cannot be undone and will delete all related data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  final client = Supabase.instance.client;
                  debugPrint('Starting delete operation for lead_id: $leadId');

                  // Add timeout protection
                  final timeoutDuration = const Duration(seconds: 30);

                  // Delete from all related tables in the correct order
                  // (child tables first, then parent table)

                  // 1. Delete from lead_activity
                  try {
                    await client
                        .from('lead_activity')
                        .delete()
                        .eq('lead_id', leadId)
                        .timeout(timeoutDuration);
                    debugPrint('✅ Deleted from lead_activity');
                  } catch (e) {
                    debugPrint('⚠️ Error deleting from lead_activity: $e');
                  }

                  // 2. Delete from proposal_remark
                  try {
                    await client
                        .from('proposal_remark')
                        .delete()
                        .eq('lead_id', leadId)
                        .timeout(timeoutDuration);
                    debugPrint('✅ Deleted from proposal_remark');
                  } catch (e) {
                    debugPrint('⚠️ Error deleting from proposal_remark: $e');
                  }

                  // 3. Delete from proposal_file
                  try {
                    await client
                        .from('proposal_file')
                        .delete()
                        .eq('lead_id', leadId)
                        .timeout(timeoutDuration);
                    debugPrint('✅ Deleted from proposal_file');
                  } catch (e) {
                    debugPrint('⚠️ Error deleting from proposal_file: $e');
                  }

                  // 4. Delete from proposal_input
                  try {
                    await client
                        .from('proposal_input')
                        .delete()
                        .eq('lead_id', leadId)
                        .timeout(timeoutDuration);
                    debugPrint('✅ Deleted from proposal_input');
                  } catch (e) {
                    debugPrint('⚠️ Error deleting from proposal_input: $e');
                  }

                  // 5. Delete from admin_response
                  try {
                    await client
                        .from('admin_response')
                        .delete()
                        .eq('lead_id', leadId)
                        .timeout(timeoutDuration);
                    debugPrint('✅ Deleted from admin_response');
                  } catch (e) {
                    debugPrint('⚠️ Error deleting from admin_response: $e');
                  }

                  // 6. Delete from initial_quote
                  try {
                    await client
                        .from('initial_quote')
                        .delete()
                        .eq('lead_id', leadId)
                        .timeout(timeoutDuration);
                    debugPrint('✅ Deleted from initial_quote');
                  } catch (e) {
                    debugPrint('⚠️ Error deleting from initial_quote: $e');
                  }

                  // 7. Delete from lead_attachment
                  try {
                    await client
                        .from('lead_attachment')
                        .delete()
                        .eq('lead_id', leadId)
                        .timeout(timeoutDuration);
                    debugPrint('✅ Deleted from lead_attachment');
                  } catch (e) {
                    debugPrint('⚠️ Error deleting from lead_attachment: $e');
                  }

                  // 8. Delete from lead_contacts
                  try {
                    await client
                        .from('lead_contacts')
                        .delete()
                        .eq('lead_id', leadId)
                        .timeout(timeoutDuration);
                    debugPrint('✅ Deleted from lead_contacts');
                  } catch (e) {
                    debugPrint('⚠️ Error deleting from lead_contacts: $e');
                  }

                  // 9. Delete from queries
                  try {
                    await client
                        .from('queries')
                        .delete()
                        .eq('lead_id', leadId)
                        .timeout(timeoutDuration);
                    debugPrint('✅ Deleted from queries');
                  } catch (e) {
                    debugPrint('⚠️ Error deleting from queries: $e');
                  }

                  // 10. Finally, delete from leads table
                  try {
                    final deleteResult = await client
                        .from('leads')
                        .delete()
                        .eq('id', leadId)
                        .timeout(timeoutDuration);

                    debugPrint('✅ Deleted from leads: $deleteResult');

                    // Verify the lead was actually deleted
                    final verifyResult = await client
                        .from('leads')
                        .select('id')
                        .eq('id', leadId)
                        .maybeSingle();

                    if (verifyResult != null) {
                      throw Exception(
                        'Lead still exists after deletion attempt',
                      );
                    }

                    debugPrint('✅ Lead deletion verified successfully');
                  } catch (e) {
                    debugPrint('❌ Error deleting from leads: $e');
                    throw Exception(
                      'Failed to delete lead from main table: $e',
                    );
                  }

                  // Show success alert
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Success'),
                          content: const Text('Successfully Deleted'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  }

                  // Refresh the leads list with timeout protection
                  try {
                    await _fetchLeads().timeout(const Duration(seconds: 15));
                  } catch (e) {
                    debugPrint('⚠️ Error refreshing leads after deletion: $e');
                  }
                } catch (e) {
                  debugPrint('❌ Error during delete operation: $e');

                  // Show error message
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Error'),
                          content: Text('Error deleting lead: ${e.toString()}'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showAlertsDialog(
    BuildContext context,
    Map<String, dynamic> lead,
  ) async {
    // Refresh query counts before showing dialog
    _fetchQueryCounts();

    // Mark queries as read when dialog is opened
    final leadId = lead['lead_id']?.toString() ?? lead['id']?.toString();
    if (leadId != null) {
      final userId = await _getCurrentUserId();
      if (userId != null) {
        await QueryNotificationService.markQueriesAsRead(leadId, userId);
        // Refresh the UI to update the green dot
        if (mounted) {
          setState(() {});
        }
      }
    }

    // Check if widget is still mounted before showing dialog
    if (mounted && context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertsDialog(lead: lead);
        },
      );
    }
  }

  void _showQueryDialog(BuildContext context, Map<String, dynamic> lead) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return QueryDialog(lead: lead);
      },
    );
  }

  /// Get current user's ID
  Future<String?> _getCurrentUserId() async {
    try {
      // First try to get from cache
      final prefs = await SharedPreferences.getInstance();
      final cachedUserId = prefs.getString('user_id');
      final cachedSessionId = prefs.getString('session_id');
      final cachedSessionActive = prefs.getBool('session_active');

      if (cachedUserId != null &&
          cachedSessionId != null &&
          cachedSessionActive == true) {
        return cachedUserId;
      } else {
        // Fallback to current auth session
        final currentUser = await Supabase.instance.client.auth.getUser();
        return currentUser.user?.id;
      }
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
    }
    return null;
  }

  /// Check if a lead has unread queries for the current user
  Future<bool> _hasUnreadQueries(String leadId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return false;

      return await QueryNotificationService.hasUnreadQueries(leadId, userId);
    } catch (e) {
      debugPrint('Error checking unread queries: $e');
      return false;
    }
  }

  Future<void> _viewLeadDetails(Map<String, dynamic> lead) async {
    // Check if we have 'id' or 'lead_id' field
    final leadId = lead['id']?.toString() ?? lead['lead_id']?.toString();

    if (leadId == null) {
      debugPrint('❌ No lead ID found in lead data');
      debugPrint('Available keys: ${lead.keys.toList()}');
      return;
    }

    debugPrint('Starting _viewLeadDetails for lead_id: $leadId');
    debugPrint('Full lead data: $lead');
    debugPrint('Available keys in lead: ${lead.keys.toList()}');

    setState(() {
      _isLoading = true;
    });

    try {
      final client = Supabase.instance.client;

      debugPrint('Fetching comprehensive data for lead_id: $leadId');

      // Initialize data containers for all relevant tables
      Map<String, dynamic> leadsData = {};
      List<dynamic> leadContactsData = [];
      List<dynamic> leadAttachmentsData = [];
      List<dynamic> leadActivityData = [];
      List<dynamic> proposalInputData = [];
      List<dynamic> proposalFileData = [];
      List<dynamic> proposalRemarkData = [];
      List<dynamic> queriesData = [];
      Map<String, dynamic> adminResponseData = {};

      // 1. Fetch leads table data
      try {
        leadsData = await client
            .from('leads')
            .select('*')
            .eq('id', leadId)
            .single();
        debugPrint(
          '✅ Successfully fetched leads data: ${leadsData['project_name']}',
        );
      } catch (e) {
        debugPrint('❌ Error fetching leads data: $e');
        // Use the lead data we already have
        leadsData = lead;
      }

      // 2. Fetch lead_contacts table data
      try {
        leadContactsData = await client
            .from('lead_contacts')
            .select('*')
            .eq('lead_id', leadId);
        debugPrint(
          '✅ Successfully fetched ${leadContactsData.length} contacts',
        );
      } catch (e) {
        debugPrint('❌ Error fetching contacts: $e');
        leadContactsData = [];
      }

      // 3. Fetch lead_attachments table data
      try {
        leadAttachmentsData = await client
            .from('lead_attachments')
            .select('*')
            .eq('lead_id', leadId);
        debugPrint(
          '✅ Successfully fetched ${leadAttachmentsData.length} attachments',
        );
      } catch (e) {
        debugPrint('❌ Error fetching attachments: $e');
        leadAttachmentsData = [];
      }

      // 4. Fetch lead_activity table data
      try {
        leadActivityData = await client
            .from('lead_activity')
            .select('*')
            .eq('lead_id', leadId)
            .order('created_at', ascending: false);
        debugPrint(
          '✅ Successfully fetched ${leadActivityData.length} activities',
        );
      } catch (e) {
        debugPrint('❌ Error fetching activities: $e');
        leadActivityData = [];
      }

      // 5. Fetch proposal_input table data with username
      try {
        proposalInputData = await client
            .from('proposal_input')
            .select('input, value, user_id')
            .eq('lead_id', leadId);

        // Fetch usernames for each proposal input
        for (int i = 0; i < proposalInputData.length; i++) {
          try {
            final userData = await client
                .from('users')
                .select('username')
                .eq('id', proposalInputData[i]['user_id'])
                .single();
            proposalInputData[i]['username'] =
                userData['username'] ?? 'Unknown';
          } catch (e) {
            proposalInputData[i]['username'] = 'Unknown';
          }
        }

        debugPrint(
          '✅ Successfully fetched ${proposalInputData.length} proposal inputs with usernames',
        );
      } catch (e) {
        debugPrint('❌ Error fetching proposal inputs: $e');
        proposalInputData = [];
      }

      // 6. Fetch proposal_file table data
      try {
        proposalFileData = await client
            .from('proposal_file')
            .select('file_name, file_link')
            .eq('lead_id', leadId);
        debugPrint(
          '✅ Successfully fetched ${proposalFileData.length} proposal files',
        );
      } catch (e) {
        debugPrint('❌ Error fetching proposal files: $e');
        proposalFileData = [];
      }

      // 7. Fetch proposal_remark table data
      try {
        proposalRemarkData = await client
            .from('proposal_remark')
            .select('remark')
            .eq('lead_id', leadId);
        debugPrint(
          '✅ Successfully fetched ${proposalRemarkData.length} proposal remarks',
        );
      } catch (e) {
        debugPrint('❌ Error fetching proposal remarks: $e');
        proposalRemarkData = [];
      }

      // 8. Fetch queries table data
      try {
        queriesData = await client
            .from('queries')
            .select('*')
            .eq('lead_id', leadId);
        debugPrint('✅ Successfully fetched ${queriesData.length} queries');
      } catch (e) {
        debugPrint('❌ Error fetching queries: $e');
        queriesData = [];
      }

      // 9. Fetch admin_response table data
      try {
        final adminResponseResult = await client
            .from('admin_response')
            .select(
              'aluminium_area, ms_weight, rate_sqm, total_amount_gst, status, remark, created_at, updated_at',
            )
            .eq('lead_id', leadId);

        if (adminResponseResult.isNotEmpty) {
          adminResponseData = adminResponseResult.first;
          debugPrint(
            '✅ Successfully fetched admin response with data: ${adminResponseData['aluminium_area']}, ${adminResponseData['ms_weight']}, ${adminResponseData['rate_sqm']}, ${adminResponseData['total_amount_gst']}',
          );
        } else {
          debugPrint('⚠️ No admin response found for lead_id: $leadId');
          // Create empty admin response data
          adminResponseData = {
            'aluminium_area': 0,
            'ms_weight': 0,
            'rate_sqm': 0,
            'total_amount_gst': 0,
            'status': 'Pending',
            'remark': 'No admin response yet',
            'created_at': null,
            'updated_at': null,
          };
        }
      } catch (e) {
        debugPrint('❌ Error fetching admin response: $e');
        // Create empty admin response data
        adminResponseData = {
          'aluminium_area': 0,
          'ms_weight': 0,
          'rate_sqm': 0,
          'total_amount_gst': 0,
          'status': 'Pending',
          'remark': 'No admin response yet',
          'created_at': null,
          'updated_at': null,
        };
      }

      setState(() {
        _isLoading = false;
      });

      debugPrint(
        '🎉 All data fetched successfully. Showing comprehensive details dialog',
      );
      debugPrint('📞 Contact data summary:');
      debugPrint('   - Main contact name: ${leadsData['main_contact_name']}');
      debugPrint('   - Main contact email: ${leadsData['main_contact_email']}');
      debugPrint(
        '   - Main contact mobile: ${leadsData['main_contact_mobile']}',
      );
      debugPrint(
        '   - Main contact designation: ${leadsData['main_contact_designation']}',
      );
      debugPrint('   - Additional contacts count: ${leadContactsData.length}');
      if (leadContactsData.isNotEmpty) {
        debugPrint(
          '   - Additional contacts: ${leadContactsData.map((c) => c['contact_name']).toList()}',
        );
      }

      // Show comprehensive details dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              insetPadding: EdgeInsets.all(16),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.8,
                child: _buildLeadDetailsDialog(
                  leadsData,
                  leadContactsData,
                  leadAttachmentsData,
                  leadActivityData,
                  proposalInputData,
                  proposalFileData,
                  proposalRemarkData,
                  queriesData,
                  adminResponseData,
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      debugPrint('❌ Error in _viewLeadDetails: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading lead details: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInteractiveIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required String leadId,
    bool isDestructive = false,
    bool isAlert = false,
    bool isQuery = false,
  }) {
    // Determine color based on action type
    Color getActionColor() {
      if (isDestructive) return Colors.red;
      if (isAlert) return Colors.red;
      if (isQuery) return Colors.orange;

      switch (tooltip.toLowerCase()) {
        case 'view details':
          return Colors.blue;
        case 'get help':
          return Colors.orange;
        case 'edit lead':
          return Colors.green;
        case 'refresh data':
          return Colors.purple;
        case 'alert':
          return Colors.red;
        case 'query':
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }

    final actionColor = getActionColor();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hoveredButtons['$leadId-$tooltip'] == true
              ? actionColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: _hoveredButtons['$leadId-$tooltip'] == true
              ? Border.all(color: actionColor.withValues(alpha: 0.3), width: 1)
              : null,
        ),
        child: Stack(
          children: [
            IconButton(
              icon: Icon(
                icon,
                color: _hoveredButtons['$leadId-$tooltip'] == true
                    ? actionColor
                    : actionColor.withValues(alpha: 0.7),
                size: 20,
              ),
              onPressed: onPressed,
              tooltip: tooltip,
              padding: EdgeInsets.all(8),
              constraints: BoxConstraints(minWidth: 36, minHeight: 36),
              onHover: (isHovered) {
                setState(() {
                  _hoveredButtons['$leadId-$tooltip'] = isHovered;
                });
              },
            ),
            // Green dot for unread alerts
            if (isAlert)
              FutureBuilder<bool>(
                future: _hasUnreadQueries(leadId),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data == true) {
                    return Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadDetailsDialog(
    Map<String, dynamic> leadsData,
    List<dynamic> leadContactsData,
    List<dynamic> leadAttachmentsData,
    List<dynamic> leadActivityData,
    List<dynamic> proposalInputData,
    List<dynamic> proposalFileData,
    List<dynamic> proposalRemarkData,
    List<dynamic> queriesData,
    Map<String, dynamic> adminResponseData,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: isMobile ? EdgeInsets.zero : EdgeInsets.all(16),
      child: Container(
        width: isMobile
            ? MediaQuery.of(context).size.width -
                  6 // 3px offset from each side
            : MediaQuery.of(context).size.width * 0.95,
        height: isMobile
            ? MediaQuery.of(context).size.height -
                  6 // 3px offset from each side
            : MediaQuery.of(context).size.height * 0.9,
        margin: isMobile ? EdgeInsets.all(3) : null, // 3px offset for mobile
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          color: Colors.grey[800], // Dark grey background as shown in image
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with DEBUG ribbon
            _buildCompleteLeadDetailsHeader(leadsData),

            // Content Area with multiple information sections
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800], // Dark grey background
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(isMobile ? 16 : 20),
                    bottomRight: Radius.circular(isMobile ? 16 : 20),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: _buildCompleteLeadDetailsContent(
                    leadsData,
                    leadContactsData,
                    leadAttachmentsData,
                    leadActivityData,
                    proposalInputData,
                    proposalFileData,
                    proposalRemarkData,
                    queriesData,
                    adminResponseData,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteLeadDetailsHeader(Map<String, dynamic> leadsData) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isMobile ? 16 : 20),
          topRight: Radius.circular(isMobile ? 16 : 20),
        ),
        color:
            Colors.grey[100], // Light grey header background as shown in image
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Blue bar chart icon
          Icon(
            Icons.bar_chart,
            color: Colors.blue[600],
            size: isMobile ? 24 : 32,
          ),
          SizedBox(width: isMobile ? 12 : 16),

          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete Lead Details - ${leadsData['project_name'] ?? '7 Mahalaskmi'}',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Lead ID: ${leadsData['id'] ?? '85d471f9-0a44-46bc-a223-8ac0af38fefa'} | Status: Active',
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: Colors.grey[600],
              size: isMobile ? 20 : 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteLeadDetailsContent(
    Map<String, dynamic> leadsData,
    List<dynamic> leadContactsData,
    List<dynamic> leadAttachmentsData,
    List<dynamic> leadActivityData,
    List<dynamic> proposalInputData,
    List<dynamic> proposalFileData,
    List<dynamic> proposalRemarkData,
    List<dynamic> queriesData,
    Map<String, dynamic> adminResponseData,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Basic Information Section
        _buildInfoSectionCard('Basic Information', [
          _buildInfoRow(
            'Project Name',
            leadsData['project_name'] ?? '7 Mahalaskmi',
          ),
          _buildInfoRow(
            'Client Name',
            leadsData['client_name'] ?? 'Runwal Enterprises',
          ),
          _buildInfoRow(
            'Project Location',
            leadsData['project_location'] ?? 'Mumbai',
          ),
          _buildInfoRow('Lead Type', 'Monolithic Formwork'),
          _buildInfoRow('Created Date', _formatDate(leadsData['created_at'])),
          _buildInfoRow(
            'Remark',
            leadsData['remark'] ??
                '1 Tower of Sales Building and 1 Tower of Rehab building to be considered',
          ),
        ]),
        SizedBox(height: 16),

        // Proposal Response Section
        if (proposalInputData.isNotEmpty ||
            proposalRemarkData.isNotEmpty ||
            proposalFileData.isNotEmpty)
          _buildInfoSectionCard('Proposal Response', [
            // Proposal Inputs
            if (proposalInputData.isNotEmpty) ...[
              ...proposalInputData.map(
                (input) => _buildInfoRow(
                  input['input'] ?? 'Input',
                  '${input['value']?.toString() ?? 'N/A'} (by ${input['username'] ?? 'Unknown'})',
                ),
              ),
              if (proposalRemarkData.isNotEmpty || proposalFileData.isNotEmpty)
                SizedBox(height: 8),
            ],

            // Proposal Remarks
            if (proposalRemarkData.isNotEmpty) ...[
              ...proposalRemarkData.map(
                (remark) =>
                    _buildInfoRow('Remark', remark['remark'] ?? 'No remark'),
              ),
              if (proposalFileData.isNotEmpty) SizedBox(height: 8),
            ],

            // Proposal Files
            if (proposalFileData.isNotEmpty) ...[
              ...proposalFileData.map(
                (file) => _buildInfoRow(
                  file['file_name'] ?? 'File',
                  file['file_link'] ?? 'No link available',
                ),
              ),
            ],
          ]),
        if (proposalInputData.isNotEmpty ||
            proposalRemarkData.isNotEmpty ||
            proposalFileData.isNotEmpty)
          SizedBox(height: 16),

        // Contact Information Section
        _buildInfoSectionCard('Contact Information', [
          // Main Contact (from leads table)
          _buildInfoRow(
            'Main Contact Name',
            leadsData['main_contact_name'] ?? 'N/A',
          ),
          _buildInfoRow(
            'Main Contact Email',
            leadsData['main_contact_email'] ?? 'N/A',
          ),
          _buildInfoRow(
            'Main Contact Mobile',
            leadsData['main_contact_mobile'] ?? 'N/A',
          ),
          _buildInfoRow(
            'Main Contact Designation',
            leadsData['main_contact_designation'] ?? 'N/A',
          ),
          if (leadContactsData.isNotEmpty) ...[
            SizedBox(height: 8),
            Divider(color: Colors.grey[400]),
            SizedBox(height: 8),
            Text(
              'Additional Contacts:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            ...leadContactsData.map(
              (contact) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    'Contact Name',
                    contact['contact_name'] ?? 'N/A',
                  ),
                  _buildInfoRow('Designation', contact['designation'] ?? 'N/A'),
                  _buildInfoRow('Email', contact['email'] ?? 'N/A'),
                  _buildInfoRow('Mobile', contact['mobile'] ?? 'N/A'),
                  if (contact != leadContactsData.last) ...[
                    SizedBox(height: 8),
                    Divider(color: Colors.grey[300]),
                    SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ]),
        SizedBox(height: 16),

        // Attachments Section
        if (leadAttachmentsData.isNotEmpty)
          _buildInfoSectionCard('Attachments', [
            ...leadAttachmentsData.map(
              (attachment) => _buildInfoRow(
                attachment['file_name'] ?? 'File',
                attachment['file_link'] ?? 'No link available',
              ),
            ),
          ]),
        if (leadAttachmentsData.isNotEmpty) SizedBox(height: 16),

        // Management Response Section
        _buildInfoSectionCard('Management Response', [
          _buildInfoRow(
            'Aluminium Area',
            '${adminResponseData['aluminium_area']?.toStringAsFixed(2) ?? '0.00'} sqm',
          ),
          _buildInfoRow(
            'MS Weight',
            '${adminResponseData['ms_weight']?.toStringAsFixed(2) ?? '0.00'} kg',
          ),
          _buildInfoRow(
            'Rate per sqm',
            '₹${adminResponseData['rate_sqm']?.toStringAsFixed(2) ?? '0.00'}',
          ),
          _buildInfoRow(
            'Total Amount (GST)',
            '₹${adminResponseData['total_amount_gst']?.toString() ?? '0'}',
          ),
          _buildInfoRow('Status', adminResponseData['status'] ?? 'Pending'),
          _buildInfoRow(
            'Remark',
            adminResponseData['remark'] ?? 'No admin response yet',
          ),
          _buildInfoRow(
            'Created Date',
            _formatDate(adminResponseData['created_at']),
          ),
          _buildInfoRow(
            'Updated Date',
            _formatDate(adminResponseData['updated_at']),
          ),
        ]),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoSectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50], // Light grey card background
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    // Check if this is a file link (contains http or https)
    final bool isFileLink =
        value.toLowerCase().contains('http://') ||
        value.toLowerCase().contains('https://');

    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value.isEmpty ? '(empty value)' : value,
                    style: TextStyle(
                      fontSize: 14,
                      color: isFileLink ? Colors.blue[600] : Colors.grey[800],
                      decoration: isFileLink ? TextDecoration.underline : null,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // Action buttons for file links
                if (isFileLink) ...[
                  // Open in browser button
                  GestureDetector(
                    onTap: () => _openFileLink(value),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.open_in_new,
                        size: 12,
                        color: Colors.blue[600],
                      ),
                    ),
                  ),
                  SizedBox(width: 4),
                ],
                // Copy icon
                GestureDetector(
                  onTap: () => _copyFileLink(value),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(Icons.copy, size: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFileLink(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening file in browser...'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open file link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyFileLink(String url) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File link copied to clipboard'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error copying link: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddLeadDialog() {
    showDialog(
      context: context,
      builder: (context) => AddLeadDialog(
        currentUserId: _currentUserId,
        onLeadAdded: () {
          _fetchLeads(); // Refresh the leads list
        },
      ),
    );
  }

  Widget _buildMobileInteractiveButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required String leadId,
    bool isDestructive = false,
    bool isAlert = false,
    bool isQuery = false,
  }) {
    // Determine color based on action type
    Color getActionColor() {
      if (isDestructive) return Colors.red;
      if (isAlert) return Colors.red;
      if (isQuery) return Colors.orange;

      switch (tooltip.toLowerCase()) {
        case 'view':
          return Colors.blue;
        case 'edit':
          return Colors.green;
        case 'delete':
          return Colors.red;
        case 'alert':
          return Colors.red;
        case 'query':
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }

    final actionColor = getActionColor();

    return AnimatedContainer(
      duration: Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: _hoveredButtons['$leadId-$tooltip'] == true
            ? actionColor.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: _hoveredButtons['$leadId-$tooltip'] == true
            ? Border.all(color: actionColor.withValues(alpha: 0.3), width: 1)
            : null,
      ),
      child: Stack(
        children: [
          IconButton(
            icon: Icon(
              icon,
              color: _hoveredButtons['$leadId-$tooltip'] == true
                  ? actionColor
                  : actionColor.withValues(alpha: 0.7),
              size: 18,
            ),
            onPressed: onPressed,
            tooltip: tooltip,
            padding: EdgeInsets.all(6),
            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            onHover: (isHovered) {
              setState(() {
                _hoveredButtons['$leadId-$tooltip'] = isHovered;
              });
            },
          ),
          // Green dot for unread alerts
          if (isAlert)
            FutureBuilder<bool>(
              future: _hasUnreadQueries(leadId),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == true) {
                  return Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
        ],
      ),
    );
  }
}

// Using NavItem from navigation_utils.dart instead of _NavItem

class AddLeadDialog extends StatefulWidget {
  final String? currentUserId;
  final VoidCallback onLeadAdded;

  const AddLeadDialog({
    super.key,
    required this.currentUserId,
    required this.onLeadAdded,
  });

  @override
  State<AddLeadDialog> createState() => _AddLeadDialogState();
}

class _AddLeadDialogState extends State<AddLeadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _projectLocationController = TextEditingController();
  final _remarkController = TextEditingController();
  final _mainContactNameController = TextEditingController();
  final _mainContactEmailController = TextEditingController();
  final _mainContactMobileController = TextEditingController();
  final _mainContactDesignationController = TextEditingController();

  // Additional contact fields
  final List<Map<String, TextEditingController>> _additionalContacts = [];

  // Attachment fields
  final List<Map<String, TextEditingController>> _attachments = [];

  // Initial quote fields (for scaffolding)
  final List<Map<String, TextEditingController>> _initialQuotes = [];

  bool _isLoading = false;
  String _selectedLeadType = 'Monolithic Formwork';

  final List<String> _leadTypes = ['Monolithic Formwork', 'Scaffolding'];

  @override
  void initState() {
    super.initState();
    // Initialize with one additional contact and one attachment
    _addAdditionalContact();
    _addAttachment();
    if (_selectedLeadType == 'Scaffolding') {
      _addInitialQuote();
    }
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _clientNameController.dispose();
    _projectLocationController.dispose();
    _remarkController.dispose();
    _mainContactNameController.dispose();
    _mainContactEmailController.dispose();
    _mainContactMobileController.dispose();
    _mainContactDesignationController.dispose();

    // Dispose additional contacts
    for (final contact in _additionalContacts) {
      contact['name']?.dispose();
      contact['designation']?.dispose();
      contact['email']?.dispose();
      contact['mobile']?.dispose();
    }

    // Dispose attachments
    for (final attachment in _attachments) {
      attachment['name']?.dispose();
      attachment['link']?.dispose();
    }

    // Dispose initial quotes
    for (final quote in _initialQuotes) {
      quote['item']?.dispose();
      quote['quantity']?.dispose();
      quote['rate']?.dispose();
      quote['amount']?.dispose();
    }

    super.dispose();
  }

  void _addAdditionalContact() {
    _additionalContacts.add({
      'name': TextEditingController(),
      'designation': TextEditingController(),
      'email': TextEditingController(),
      'mobile': TextEditingController(),
    });
    setState(() {});
  }

  void _removeAdditionalContact(int index) {
    if (_additionalContacts.length > 1) {
      _additionalContacts[index]['name']?.dispose();
      _additionalContacts[index]['designation']?.dispose();
      _additionalContacts[index]['email']?.dispose();
      _additionalContacts[index]['mobile']?.dispose();
      _additionalContacts.removeAt(index);
      setState(() {});
    }
  }

  void _addAttachment() {
    _attachments.add({
      'name': TextEditingController(),
      'link': TextEditingController(),
    });
    setState(() {});
  }

  void _removeAttachment(int index) {
    if (_attachments.length > 1) {
      _attachments[index]['name']?.dispose();
      _attachments[index]['link']?.dispose();
      _attachments.removeAt(index);
      setState(() {});
    }
  }

  void _addInitialQuote() {
    _initialQuotes.add({
      'item': TextEditingController(),
      'quantity': TextEditingController(),
      'rate': TextEditingController(),
      'amount': TextEditingController(),
    });
    setState(() {});
  }

  void _removeInitialQuote(int index) {
    if (_initialQuotes.length > 1) {
      _initialQuotes[index]['item']?.dispose();
      _initialQuotes[index]['quantity']?.dispose();
      _initialQuotes[index]['rate']?.dispose();
      _initialQuotes[index]['amount']?.dispose();
      _initialQuotes.removeAt(index);
      setState(() {});
    }
  }

  // Helper methods for responsive form design
  Widget _buildSectionHeader(String title, IconData icon, bool isWide) {
    return Container(
      padding: EdgeInsets.all(isWide ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[600]!.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: Colors.blue[600], size: isWide ? 20 : 16),
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: isWide ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
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
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
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
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _saveLead() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User session not found. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final client = Supabase.instance.client;

      // Get current active user data from cache memory
      final prefs = await SharedPreferences.getInstance();
      final cachedUserId = prefs.getString('user_id');
      final cachedUserEmail = prefs.getString('user_email');
      final cachedUserType = prefs.getString('user_type');
      final cachedSessionActive = prefs.getBool('session_active');

      debugPrint('[CACHE] Cached user_id: $cachedUserId');
      debugPrint('[CACHE] Cached user_email: $cachedUserEmail');
      debugPrint('[CACHE] Cached user_type: $cachedUserType');
      debugPrint('[CACHE] Cached session_active: $cachedSessionActive');

      // Validate cache data
      if (cachedUserId == null || cachedSessionActive != true) {
        debugPrint('[CACHE] Invalid cache data, using fallback');
        // Fallback to current auth session
        final currentUser = client.auth.currentUser;
        if (currentUser == null) {
          throw Exception('No active user found');
        }
      }

      // Insert new lead into the leads table with user information
      final result = await client.from('leads').insert({
        'project_name': _projectNameController.text.trim(),
        'client_name': _clientNameController.text.trim(),
        'project_location': _projectLocationController.text.trim(),
        'lead_type': _selectedLeadType,
        'remark': _remarkController.text.trim(),
        'main_contact_name': _mainContactNameController.text.trim(),
        'main_contact_email': _mainContactEmailController.text.trim(),
        'main_contact_mobile': _mainContactMobileController.text.trim(),
        'main_contact_designation': _mainContactDesignationController.text
            .trim(),
        'lead_generated_by': widget.currentUserId,
        'user_type': cachedUserType ?? 'sales', // Get from cache memory
        'user_id':
            cachedUserId ?? widget.currentUserId, // Get from cache memory
        'user_email': cachedUserEmail ?? '', // Get from cache memory
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      if (result.isNotEmpty) {
        final newLead = result.first;
        final leadId = newLead['id'];

        // Insert additional contacts into lead_contacts table
        for (final contact in _additionalContacts) {
          if (contact['name']?.text.trim().isNotEmpty == true) {
            await client.from('lead_contacts').insert({
              'lead_id': leadId,
              'contact_name': contact['name']?.text.trim(),
              'designation': contact['designation']?.text.trim(),
              'email': contact['email']?.text.trim(),
              'mobile': contact['mobile']?.text.trim(),
            });
          }
        }

        // Insert attachments into lead_attachments table
        for (final attachment in _attachments) {
          if (attachment['name']?.text.trim().isNotEmpty == true) {
            await client.from('lead_attachments').insert({
              'lead_id': leadId,
              'file_name': attachment['name']?.text.trim(),
              'file_link': attachment['link']?.text.trim(),
            });
          }
        }

        // Insert initial quotes for scaffolding leads
        if (_selectedLeadType == 'Scaffolding') {
          for (final quote in _initialQuotes) {
            if (quote['item']?.text.trim().isNotEmpty == true) {
              await client.from('initial_quote').insert({
                'lead_id': leadId,
                'item': quote['item']?.text.trim(),
                'quantity':
                    double.tryParse(quote['quantity']?.text.trim() ?? '0') ?? 0,
                'rate': double.tryParse(quote['rate']?.text.trim() ?? '0') ?? 0,
                'amount':
                    double.tryParse(quote['amount']?.text.trim() ?? '0') ?? 0,
              });
            }
          }
        }

        // Log the activity (commented out due to column structure issues)
        // await client.from('lead_activity').insert({
        //   'lead_id': leadId,
        //   'user_id': widget.currentUserId,
        //   'activity_type': 'Lead Created',
        //   'changes_made': 'New lead created by sales user',
        //   'created_at': DateTime.now().toIso8601String(),
        // });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lead added successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          widget.onLeadAdded();
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Error adding lead: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding lead: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        return Dialog(
          insetPadding: EdgeInsets.all(isWide ? 24 : 16),
          child: Container(
            width: isWide ? 800 : double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              children: [
                // Header - matching lead management style
                Container(
                  padding: EdgeInsets.all(isWide ? 24 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[600]!.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add_circle,
                          color: Colors.blue[600],
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Lead',
                              style: TextStyle(
                                fontSize: isWide ? 24 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              'Create a new lead for your client',
                              style: TextStyle(
                                fontSize: isWide ? 14 : 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),

                // Form Content
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.grey[50]),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isWide ? 24 : 16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Project Information Section
                            _buildSectionHeader(
                              'Project Information',
                              Icons.business,
                              isWide,
                            ),
                            SizedBox(height: isWide ? 20 : 16),

                            // Project Information Grid
                            if (isWide) ...[
                              // Desktop: 2-column layout
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildFormField(
                                      controller: _projectNameController,
                                      label: 'Project Name *',
                                      icon: Icons.business,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Project name is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: _buildFormField(
                                      controller: _clientNameController,
                                      label: 'Client Name *',
                                      icon: Icons.person,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Client name is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildFormField(
                                      controller: _projectLocationController,
                                      label: 'Project Location *',
                                      icon: Icons.location_on,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Project location is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: _buildDropdownField(
                                      value: _selectedLeadType,
                                      label: 'Lead Type *',
                                      icon: Icons.category,
                                      items: _leadTypes.map((type) {
                                        return DropdownMenuItem(
                                          value: type,
                                          child: Text(type),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedLeadType = value!;

                                          // Handle scaffolding initial quotes
                                          if (value == 'Scaffolding' &&
                                              _initialQuotes.isEmpty) {
                                            _addInitialQuote();
                                          } else if (value ==
                                              'Monolithic Formwork') {
                                            // Clear initial quotes for non-scaffolding leads
                                            for (final quote
                                                in _initialQuotes) {
                                              quote['item']?.dispose();
                                              quote['quantity']?.dispose();
                                              quote['rate']?.dispose();
                                              quote['amount']?.dispose();
                                            }
                                            _initialQuotes.clear();
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              // Mobile: Single column layout
                              _buildFormField(
                                controller: _projectNameController,
                                label: 'Project Name *',
                                icon: Icons.business,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Project name is required';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              _buildFormField(
                                controller: _clientNameController,
                                label: 'Client Name *',
                                icon: Icons.person,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Client name is required';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              _buildFormField(
                                controller: _projectLocationController,
                                label: 'Project Location *',
                                icon: Icons.location_on,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Project location is required';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              _buildDropdownField(
                                value: _selectedLeadType,
                                label: 'Lead Type *',
                                icon: Icons.category,
                                items: _leadTypes.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedLeadType = value!;

                                    // Handle scaffolding initial quotes
                                    if (value == 'Scaffolding' &&
                                        _initialQuotes.isEmpty) {
                                      _addInitialQuote();
                                    } else if (value == 'Monolithic Formwork') {
                                      // Clear initial quotes for non-scaffolding leads
                                      for (final quote in _initialQuotes) {
                                        quote['item']?.dispose();
                                        quote['quantity']?.dispose();
                                        quote['rate']?.dispose();
                                        quote['amount']?.dispose();
                                      }
                                      _initialQuotes.clear();
                                    }
                                  });
                                },
                              ),
                            ],
                            SizedBox(height: 16),

                            // Remark
                            _buildFormField(
                              controller: _remarkController,
                              label: 'Remark',
                              icon: Icons.note,
                              maxLines: 3,
                            ),
                            SizedBox(height: isWide ? 32 : 24),

                            // Main Contact Information Section
                            _buildSectionHeader(
                              'Main Contact Information',
                              Icons.person_outline,
                              isWide,
                            ),
                            SizedBox(height: isWide ? 20 : 16),

                            // Main Contact Information Grid
                            if (isWide) ...[
                              // Desktop: 2-column layout
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildFormField(
                                      controller: _mainContactNameController,
                                      label: 'Contact Name',
                                      icon: Icons.person_outline,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: _buildFormField(
                                      controller:
                                          _mainContactDesignationController,
                                      label: 'Designation',
                                      icon: Icons.work,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildFormField(
                                      controller: _mainContactEmailController,
                                      label: 'Email',
                                      icon: Icons.email,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: _buildFormField(
                                      controller: _mainContactMobileController,
                                      label: 'Mobile',
                                      icon: Icons.phone,
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              // Mobile: Single column layout
                              _buildFormField(
                                controller: _mainContactNameController,
                                label: 'Contact Name',
                                icon: Icons.person_outline,
                              ),
                              SizedBox(height: 16),
                              _buildFormField(
                                controller: _mainContactDesignationController,
                                label: 'Designation',
                                icon: Icons.work,
                              ),
                              SizedBox(height: 16),
                              _buildFormField(
                                controller: _mainContactEmailController,
                                label: 'Email',
                                icon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              SizedBox(height: 16),
                              _buildFormField(
                                controller: _mainContactMobileController,
                                label: 'Mobile',
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                              ),
                            ],
                            SizedBox(height: isWide ? 32 : 24),

                            // Additional Contacts Section
                            _buildSectionHeader(
                              'Additional Contacts',
                              Icons.people,
                              isWide,
                            ),
                            SizedBox(height: isWide ? 20 : 16),

                            // Additional Contacts List
                            ..._additionalContacts.asMap().entries.map((entry) {
                              final index = entry.key;
                              final contact = entry.value;
                              return Container(
                                margin: EdgeInsets.only(bottom: 16),
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[600]!.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.person,
                                            color: Colors.blue[600],
                                            size: 16,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Contact ${index + 1}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700],
                                              fontSize: isWide ? 14 : 12,
                                            ),
                                          ),
                                        ),
                                        if (_additionalContacts.length > 1)
                                          IconButton(
                                            onPressed: () =>
                                                _removeAdditionalContact(index),
                                            icon: Icon(
                                              Icons.remove_circle,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            tooltip: 'Remove Contact',
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    if (isWide) ...[
                                      // Desktop: 2-column layout
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildFormField(
                                              controller: contact['name']!,
                                              label: 'Name',
                                              icon: Icons.person_outline,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: _buildFormField(
                                              controller:
                                                  contact['designation']!,
                                              label: 'Designation',
                                              icon: Icons.work,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildFormField(
                                              controller: contact['email']!,
                                              label: 'Email',
                                              icon: Icons.email,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: _buildFormField(
                                              controller: contact['mobile']!,
                                              label: 'Mobile',
                                              icon: Icons.phone,
                                              keyboardType: TextInputType.phone,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      // Mobile: Single column layout
                                      _buildFormField(
                                        controller: contact['name']!,
                                        label: 'Name',
                                        icon: Icons.person_outline,
                                      ),
                                      SizedBox(height: 12),
                                      _buildFormField(
                                        controller: contact['designation']!,
                                        label: 'Designation',
                                        icon: Icons.work,
                                      ),
                                      SizedBox(height: 12),
                                      _buildFormField(
                                        controller: contact['email']!,
                                        label: 'Email',
                                        icon: Icons.email,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                      ),
                                      SizedBox(height: 12),
                                      _buildFormField(
                                        controller: contact['mobile']!,
                                        label: 'Mobile',
                                        icon: Icons.phone,
                                        keyboardType: TextInputType.phone,
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),

                            // Add Contact Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _addAdditionalContact,
                                icon: Icon(Icons.add, size: isWide ? 20 : 16),
                                label: Text(
                                  'Add Contact',
                                  style: TextStyle(fontSize: isWide ? 14 : 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue[600],
                                  side: BorderSide(color: Colors.blue[600]!),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isWide ? 20 : 16,
                                    vertical: isWide ? 12 : 8,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: isWide ? 32 : 24),

                            // Attachments Section
                            _buildSectionHeader(
                              'Attachments',
                              Icons.attach_file,
                              isWide,
                            ),
                            SizedBox(height: isWide ? 20 : 16),

                            // Attachments List
                            ..._attachments.asMap().entries.map((entry) {
                              final index = entry.key;
                              final attachment = entry.value;
                              return Container(
                                margin: EdgeInsets.only(bottom: 16),
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.green[600]!
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.attach_file,
                                            color: Colors.green[600],
                                            size: 16,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Attachment ${index + 1}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700],
                                              fontSize: isWide ? 14 : 12,
                                            ),
                                          ),
                                        ),
                                        if (_attachments.length > 1)
                                          IconButton(
                                            onPressed: () =>
                                                _removeAttachment(index),
                                            icon: Icon(
                                              Icons.remove_circle,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            tooltip: 'Remove Attachment',
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    if (isWide) ...[
                                      // Desktop: 2-column layout
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildFormField(
                                              controller: attachment['name']!,
                                              label: 'File Name',
                                              icon: Icons.attach_file,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: _buildFormField(
                                              controller: attachment['link']!,
                                              label: 'File Link',
                                              icon: Icons.link,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      // Mobile: Single column layout
                                      _buildFormField(
                                        controller: attachment['name']!,
                                        label: 'File Name',
                                        icon: Icons.attach_file,
                                      ),
                                      SizedBox(height: 12),
                                      _buildFormField(
                                        controller: attachment['link']!,
                                        label: 'File Link',
                                        icon: Icons.link,
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),

                            // Add Attachment Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _addAttachment,
                                icon: Icon(Icons.add, size: isWide ? 20 : 16),
                                label: Text(
                                  'Add Attachment',
                                  style: TextStyle(fontSize: isWide ? 14 : 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green[600],
                                  side: BorderSide(color: Colors.green[600]!),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isWide ? 20 : 16,
                                    vertical: isWide ? 12 : 8,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: isWide ? 32 : 24),

                            // Initial Quote Section (for Scaffolding)
                            if (_selectedLeadType == 'Scaffolding') ...[
                              _buildSectionHeader(
                                'Initial Quote',
                                Icons.receipt,
                                isWide,
                              ),
                              SizedBox(height: isWide ? 20 : 16),

                              // Quote Table Header
                              Container(
                                padding: EdgeInsets.all(isWide ? 16 : 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Item',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isWide ? 14 : 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Quantity',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isWide ? 14 : 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Rate',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isWide ? 14 : 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Amount',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isWide ? 14 : 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    SizedBox(
                                      width: isWide ? 48 : 40,
                                    ), // Space for remove button
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),

                              // Quote Items List
                              ..._initialQuotes.asMap().entries.map((entry) {
                                final index = entry.key;
                                final quote = entry.value;
                                return Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.all(isWide ? 16 : 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: _buildFormField(
                                          controller: quote['item']!,
                                          label: 'Item',
                                          icon: Icons.inventory,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: _buildFormField(
                                          controller: quote['quantity']!,
                                          label: 'Qty',
                                          icon: Icons.numbers,
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: _buildFormField(
                                          controller: quote['rate']!,
                                          label: 'Rate',
                                          icon: Icons.currency_rupee,
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: _buildFormField(
                                          controller: quote['amount']!,
                                          label: 'Amount',
                                          icon: Icons.calculate,
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      if (_initialQuotes.length > 1)
                                        IconButton(
                                          onPressed: () =>
                                              _removeInitialQuote(index),
                                          icon: Icon(
                                            Icons.remove_circle,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          tooltip: 'Remove Item',
                                        ),
                                    ],
                                  ),
                                );
                              }),

                              // Add Quote Item Button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _addInitialQuote,
                                  icon: Icon(Icons.add, size: isWide ? 20 : 16),
                                  label: Text(
                                    'Add Quote Item',
                                    style: TextStyle(
                                      fontSize: isWide ? 14 : 12,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.orange[600],
                                    side: BorderSide(
                                      color: Colors.orange[600]!,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isWide ? 20 : 16,
                                      vertical: isWide ? 12 : 8,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: isWide ? 32 : 24),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Action Buttons - matching lead management style
                Container(
                  padding: EdgeInsets.all(isWide ? 24 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Cancel Button
                      OutlinedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, size: isWide ? 20 : 16),
                        label: Text(
                          'Cancel',
                          style: TextStyle(fontSize: isWide ? 14 : 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[400]!),
                          padding: EdgeInsets.symmetric(
                            horizontal: isWide ? 24 : 16,
                            vertical: isWide ? 12 : 8,
                          ),
                        ),
                      ),

                      // Save Button
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveLead,
                        icon: _isLoading
                            ? SizedBox(
                                width: isWide ? 20 : 16,
                                height: isWide ? 20 : 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(Icons.save, size: isWide ? 20 : 16),
                        label: Text(
                          _isLoading ? 'Saving...' : 'Save Lead',
                          style: TextStyle(fontSize: isWide ? 14 : 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isWide ? 24 : 16,
                            vertical: isWide ? 12 : 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class EditLeadDialog extends StatefulWidget {
  final String? currentUserId;
  final String leadId;
  final VoidCallback onLeadUpdated;

  const EditLeadDialog({
    super.key,
    required this.currentUserId,
    required this.leadId,
    required this.onLeadUpdated,
  });

  @override
  State<EditLeadDialog> createState() => _EditLeadDialogState();
}

class _EditLeadDialogState extends State<EditLeadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _projectLocationController = TextEditingController();
  final _remarkController = TextEditingController();
  final _mainContactNameController = TextEditingController();
  final _mainContactEmailController = TextEditingController();
  final _mainContactMobileController = TextEditingController();
  final _mainContactDesignationController = TextEditingController();
  final _selectedDateController = TextEditingController();

  // Additional contact fields
  final List<Map<String, TextEditingController>> _additionalContacts = [];

  // Attachment fields
  final List<Map<String, TextEditingController>> _attachments = [];

  // Initial quote fields (for scaffolding)
  final List<Map<String, TextEditingController>> _initialQuotes = [];

  bool _isLoading = false;
  bool _isDataLoading = true;
  String _selectedLeadType = 'Monolithic Formwork';

  final List<String> _leadTypes = ['Monolithic Formwork', 'Scaffolding'];

  @override
  void initState() {
    super.initState();
    // Set default date to today
    _selectedDateController.text = DateFormat(
      'dd/MM/yyyy',
    ).format(DateTime.now());
    _fetchLeadData();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _fetchLeadData() async {
    try {
      final client = Supabase.instance.client;

      // Fetch main lead data
      final leadResult = await client
          .from('leads')
          .select()
          .eq('id', widget.leadId)
          .single();

      // Fetch additional contacts
      final contactsResult = await client
          .from('lead_contacts')
          .select()
          .eq('lead_id', widget.leadId);

      // Fetch attachments
      final attachmentsResult = await client
          .from('lead_attachments')
          .select()
          .eq('lead_id', widget.leadId);

      // Fetch initial quotes (for scaffolding leads)
      final quotesResult = await client
          .from('initial_quote')
          .select()
          .eq('lead_id', widget.leadId);

      if (mounted) {
        setState(() {
          // Populate main lead data
          _projectNameController.text = leadResult['project_name'] ?? '';
          _clientNameController.text = leadResult['client_name'] ?? '';
          _projectLocationController.text =
              leadResult['project_location'] ?? '';
          _remarkController.text = leadResult['remark'] ?? '';
          _mainContactNameController.text =
              leadResult['main_contact_name'] ?? '';
          _mainContactEmailController.text =
              leadResult['main_contact_email'] ?? '';
          _mainContactMobileController.text =
              leadResult['main_contact_mobile'] ?? '';
          _mainContactDesignationController.text =
              leadResult['main_contact_designation'] ?? '';
          _selectedLeadType = leadResult['lead_type'] ?? 'Monolithic Formwork';

          // Populate date field with created_at from database
          if (leadResult['created_at'] != null) {
            try {
              final createdAt = DateTime.parse(
                leadResult['created_at'].toString(),
              );
              _selectedDateController.text = DateFormat(
                'dd/MM/yyyy',
              ).format(createdAt);
            } catch (e) {
              // If parsing fails, use today's date
              _selectedDateController.text = DateFormat(
                'dd/MM/yyyy',
              ).format(DateTime.now());
            }
          } else {
            // If created_at is null, use today's date
            _selectedDateController.text = DateFormat(
              'dd/MM/yyyy',
            ).format(DateTime.now());
          }

          // Clear existing controllers
          for (final contact in _additionalContacts) {
            contact['name']?.dispose();
            contact['designation']?.dispose();
            contact['email']?.dispose();
            contact['mobile']?.dispose();
          }
          _additionalContacts.clear();

          for (final attachment in _attachments) {
            attachment['name']?.dispose();
            attachment['link']?.dispose();
          }
          _attachments.clear();

          for (final quote in _initialQuotes) {
            quote['item']?.dispose();
            quote['quantity']?.dispose();
            quote['rate']?.dispose();
            quote['amount']?.dispose();
          }
          _initialQuotes.clear();

          // Populate additional contacts
          for (final contact in contactsResult) {
            _additionalContacts.add({
              'name': TextEditingController(
                text: contact['contact_name'] ?? '',
              ),
              'designation': TextEditingController(
                text: contact['designation'] ?? '',
              ),
              'email': TextEditingController(text: contact['email'] ?? ''),
              'mobile': TextEditingController(text: contact['mobile'] ?? ''),
            });
          }

          // Populate attachments
          for (final attachment in attachmentsResult) {
            _attachments.add({
              'name': TextEditingController(
                text: attachment['file_name'] ?? '',
              ),
              'link': TextEditingController(
                text: attachment['file_link'] ?? '',
              ),
            });
          }

          // Populate initial quotes
          for (final quote in quotesResult) {
            _initialQuotes.add({
              'item': TextEditingController(text: quote['item'] ?? ''),
              'quantity': TextEditingController(
                text: quote['quantity']?.toString() ?? '',
              ),
              'rate': TextEditingController(
                text: quote['rate']?.toString() ?? '',
              ),
              'amount': TextEditingController(
                text: quote['amount']?.toString() ?? '',
              ),
            });
          }

          // Ensure at least one contact and attachment
          if (_additionalContacts.isEmpty) {
            _addAdditionalContact();
          }
          if (_attachments.isEmpty) {
            _addAttachment();
          }
          if (_selectedLeadType == 'Scaffolding' && _initialQuotes.isEmpty) {
            _addInitialQuote();
          }

          _isDataLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching lead data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading lead data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _clientNameController.dispose();
    _projectLocationController.dispose();
    _remarkController.dispose();
    _mainContactNameController.dispose();
    _mainContactEmailController.dispose();
    _mainContactMobileController.dispose();
    _mainContactDesignationController.dispose();
    _selectedDateController.dispose();

    // Dispose additional contacts
    for (final contact in _additionalContacts) {
      contact['name']?.dispose();
      contact['designation']?.dispose();
      contact['email']?.dispose();
      contact['mobile']?.dispose();
    }

    // Dispose attachments
    for (final attachment in _attachments) {
      attachment['name']?.dispose();
      attachment['link']?.dispose();
    }

    // Dispose initial quotes
    for (final quote in _initialQuotes) {
      quote['item']?.dispose();
      quote['quantity']?.dispose();
      quote['rate']?.dispose();
      quote['amount']?.dispose();
    }

    super.dispose();
  }

  void _addAdditionalContact() {
    _additionalContacts.add({
      'name': TextEditingController(),
      'designation': TextEditingController(),
      'email': TextEditingController(),
      'mobile': TextEditingController(),
    });
    setState(() {});
  }

  void _removeAdditionalContact(int index) {
    if (_additionalContacts.length > 1) {
      _additionalContacts[index]['name']?.dispose();
      _additionalContacts[index]['designation']?.dispose();
      _additionalContacts[index]['email']?.dispose();
      _additionalContacts[index]['mobile']?.dispose();
      _additionalContacts.removeAt(index);
      setState(() {});
    }
  }

  void _addAttachment() {
    _attachments.add({
      'name': TextEditingController(),
      'link': TextEditingController(),
    });
    setState(() {});
  }

  void _removeAttachment(int index) {
    if (_attachments.length > 1) {
      _attachments[index]['name']?.dispose();
      _attachments[index]['link']?.dispose();
      _attachments.removeAt(index);
      setState(() {});
    }
  }

  void _addInitialQuote() {
    _initialQuotes.add({
      'item': TextEditingController(),
      'quantity': TextEditingController(),
      'rate': TextEditingController(),
      'amount': TextEditingController(),
    });
    setState(() {});
  }

  void _removeInitialQuote(int index) {
    if (_initialQuotes.length > 1) {
      _initialQuotes[index]['item']?.dispose();
      _initialQuotes[index]['quantity']?.dispose();
      _initialQuotes[index]['rate']?.dispose();
      _initialQuotes[index]['amount']?.dispose();
      _initialQuotes.removeAt(index);
      setState(() {});
    }
  }

  // Helper methods for responsive form design (same as AddLeadDialog)
  Widget _buildSectionHeader(String title, IconData icon, bool isWide) {
    return Container(
      padding: EdgeInsets.all(isWide ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[600]!.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: Colors.blue[600], size: isWide ? 20 : 16),
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: isWide ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
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
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
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
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _updateLead() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User session not found. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final client = Supabase.instance.client;

      debugPrint('Starting lead update for lead ID: ${widget.leadId}');
      debugPrint('Project Name: ${_projectNameController.text.trim()}');
      debugPrint('Client Name: ${_clientNameController.text.trim()}');
      debugPrint('Project Location: ${_projectLocationController.text.trim()}');
      debugPrint('Lead Type: $_selectedLeadType');

      // First, verify the lead exists
      final existingLead = await client
          .from('leads')
          .select('id, project_name')
          .eq('id', widget.leadId)
          .maybeSingle();

      if (existingLead == null) {
        throw Exception('Lead with ID ${widget.leadId} not found');
      }

      debugPrint('Found existing lead: ${existingLead['project_name']}');

      // Parse the selected date from the date controller
      DateTime selectedDate;
      try {
        selectedDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(_selectedDateController.text);
      } catch (e) {
        // If parsing fails, use current date
        selectedDate = DateTime.now();
      }

      // Update main lead data
      final updateResult = await client
          .from('leads')
          .update({
            'project_name': _projectNameController.text.trim(),
            'client_name': _clientNameController.text.trim(),
            'project_location': _projectLocationController.text.trim(),
            'lead_type': _selectedLeadType,
            'remark': _remarkController.text.trim(),
            'main_contact_name': _mainContactNameController.text.trim(),
            'main_contact_email': _mainContactEmailController.text.trim(),
            'main_contact_mobile': _mainContactMobileController.text.trim(),
            'main_contact_designation': _mainContactDesignationController.text
                .trim(),
            'created_at': selectedDate.toIso8601String(),
          })
          .eq('id', widget.leadId);

      debugPrint('Lead update result: $updateResult');

      // Delete existing additional contacts and insert new ones
      debugPrint('Deleting existing contacts for lead ID: ${widget.leadId}');
      await client.from('lead_contacts').delete().eq('lead_id', widget.leadId);

      debugPrint('Inserting ${_additionalContacts.length} contacts');
      for (final contact in _additionalContacts) {
        if (contact['name']?.text.trim().isNotEmpty == true) {
          final contactData = {
            'lead_id': widget.leadId,
            'contact_name': contact['name']?.text.trim(),
            'designation': contact['designation']?.text.trim(),
            'email': contact['email']?.text.trim(),
            'mobile': contact['mobile']?.text.trim(),
          };
          debugPrint('Inserting contact: $contactData');
          await client.from('lead_contacts').insert(contactData);
        }
      }

      // Delete existing attachments and insert new ones
      debugPrint('Deleting existing attachments for lead ID: ${widget.leadId}');
      await client
          .from('lead_attachments')
          .delete()
          .eq('lead_id', widget.leadId);

      debugPrint('Inserting ${_attachments.length} attachments');
      for (final attachment in _attachments) {
        if (attachment['name']?.text.trim().isNotEmpty == true) {
          final attachmentData = {
            'lead_id': widget.leadId,
            'file_name': attachment['name']?.text.trim(),
            'file_link': attachment['link']?.text.trim(),
          };
          debugPrint('Inserting attachment: $attachmentData');
          await client.from('lead_attachments').insert(attachmentData);
        }
      }

      // Delete existing initial quotes and insert new ones for scaffolding leads
      debugPrint('Deleting existing quotes for lead ID: ${widget.leadId}');
      await client.from('initial_quote').delete().eq('lead_id', widget.leadId);

      if (_selectedLeadType == 'Scaffolding') {
        debugPrint(
          'Inserting ${_initialQuotes.length} quotes for scaffolding lead',
        );
        for (final quote in _initialQuotes) {
          if (quote['item']?.text.trim().isNotEmpty == true) {
            final quoteData = {
              'lead_id': widget.leadId,
              'item': quote['item']?.text.trim(),
              'quantity':
                  double.tryParse(quote['quantity']?.text.trim() ?? '0') ?? 0,
              'rate': double.tryParse(quote['rate']?.text.trim() ?? '0') ?? 0,
              'amount':
                  double.tryParse(quote['amount']?.text.trim() ?? '0') ?? 0,
            };
            debugPrint('Inserting quote: $quoteData');
            await client.from('initial_quote').insert(quoteData);
          }
        }
      }

      // Log the activity (commented out due to column structure issues)
      // await client.from('lead_activity').insert({
      //   'lead_id': widget.leadId,
      //   'user_id': widget.currentUserId,
      //   'activity_type': 'Lead Updated',
      //   'changes_made': 'Lead information updated by sales user',
      //   'created_at': DateTime.now().toIso8601String(),
      // });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lead "${_projectNameController.text.trim()}" updated successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        widget.onLeadUpdated();
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error updating lead: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating lead: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDataLoading) {
      return Dialog(
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading lead data...'),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        return Dialog(
          insetPadding: EdgeInsets.all(isWide ? 24 : 16),
          child: Container(
            width: isWide ? 800 : double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              children: [
                // Header - matching lead management style
                Container(
                  padding: EdgeInsets.all(isWide ? 24 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[600]!.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.edit,
                          color: Colors.orange[600],
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Lead',
                              style: TextStyle(
                                fontSize: isWide ? 24 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Update lead information and related data',
                              style: TextStyle(
                                fontSize: isWide ? 14 : 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Date input field
                      Container(
                        width: isWide ? 150 : 120,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _selectedDateController,
                                decoration: InputDecoration(
                                  hintText: 'Select Date',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  hintStyle: TextStyle(
                                    fontSize: isWide ? 12 : 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: isWide ? 12 : 11,
                                  color: Colors.grey[800],
                                ),
                                readOnly: true,
                                onTap: () => _selectDate(context),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _selectDate(context),
                              icon: Icon(
                                Icons.calendar_today,
                                color: Colors.grey[600],
                                size: 18,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),

                // Form Content - same structure as AddLeadDialog
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isWide ? 24 : 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Project Information Section
                          _buildSectionHeader(
                            'Project Information',
                            Icons.business,
                            isWide,
                          ),
                          SizedBox(height: isWide ? 16 : 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildFormField(
                                  controller: _projectNameController,
                                  label: 'Project Name',
                                  icon: Icons.business,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Project name is required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(width: isWide ? 16 : 12),
                              Expanded(
                                child: _buildFormField(
                                  controller: _clientNameController,
                                  label: 'Client Name',
                                  icon: Icons.person,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Client name is required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isWide ? 16 : 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildFormField(
                                  controller: _projectLocationController,
                                  label: 'Project Location',
                                  icon: Icons.location_on,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Project location is required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(width: isWide ? 16 : 12),
                              Expanded(
                                child: _buildDropdownField(
                                  value: _selectedLeadType,
                                  label: 'Lead Type',
                                  icon: Icons.category,
                                  items: _leadTypes.map((type) {
                                    return DropdownMenuItem<String>(
                                      value: type,
                                      child: Text(type),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedLeadType =
                                          value ?? 'Monolithic Formwork';
                                      // Add initial quote if switching to Scaffolding
                                      if (_selectedLeadType == 'Scaffolding' &&
                                          _initialQuotes.isEmpty) {
                                        _addInitialQuote();
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isWide ? 16 : 12),
                          _buildFormField(
                            controller: _remarkController,
                            label: 'Remarks',
                            icon: Icons.note,
                            maxLines: 3,
                          ),
                          SizedBox(height: isWide ? 32 : 24),

                          // Main Contact Section
                          _buildSectionHeader(
                            'Main Contact',
                            Icons.contact_phone,
                            isWide,
                          ),
                          SizedBox(height: isWide ? 16 : 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildFormField(
                                  controller: _mainContactNameController,
                                  label: 'Contact Name',
                                  icon: Icons.person,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Contact name is required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(width: isWide ? 16 : 12),
                              Expanded(
                                child: _buildFormField(
                                  controller: _mainContactDesignationController,
                                  label: 'Designation',
                                  icon: Icons.work,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isWide ? 16 : 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildFormField(
                                  controller: _mainContactEmailController,
                                  label: 'Email',
                                  icon: Icons.email,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Email is required';
                                    }
                                    if (!RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(width: isWide ? 16 : 12),
                              Expanded(
                                child: _buildFormField(
                                  controller: _mainContactMobileController,
                                  label: 'Mobile',
                                  icon: Icons.phone,
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Mobile number is required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isWide ? 32 : 24),

                          // Additional Contacts Section
                          _buildSectionHeader(
                            'Additional Contacts',
                            Icons.people,
                            isWide,
                          ),
                          SizedBox(height: isWide ? 16 : 12),
                          ..._additionalContacts.asMap().entries.map((entry) {
                            final index = entry.key;
                            final contact = entry.value;
                            return Container(
                              margin: EdgeInsets.only(bottom: isWide ? 16 : 12),
                              padding: EdgeInsets.all(isWide ? 16 : 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        color: Colors.grey[600],
                                        size: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Contact ${index + 1}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Spacer(),
                                      if (_additionalContacts.length > 1)
                                        IconButton(
                                          onPressed: () =>
                                              _removeAdditionalContact(index),
                                          icon: Icon(
                                            Icons.remove_circle,
                                            color: Colors.red[400],
                                          ),
                                          tooltip: 'Remove Contact',
                                          padding: EdgeInsets.all(4),
                                          constraints: BoxConstraints(
                                            minWidth: 24,
                                            minHeight: 24,
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildFormField(
                                          controller: contact['name']!,
                                          label: 'Name',
                                          icon: Icons.person,
                                        ),
                                      ),
                                      SizedBox(width: isWide ? 16 : 12),
                                      Expanded(
                                        child: _buildFormField(
                                          controller: contact['designation']!,
                                          label: 'Designation',
                                          icon: Icons.work,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isWide ? 16 : 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildFormField(
                                          controller: contact['email']!,
                                          label: 'Email',
                                          icon: Icons.email,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                        ),
                                      ),
                                      SizedBox(width: isWide ? 16 : 12),
                                      Expanded(
                                        child: _buildFormField(
                                          controller: contact['mobile']!,
                                          label: 'Mobile',
                                          icon: Icons.phone,
                                          keyboardType: TextInputType.phone,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                          SizedBox(height: isWide ? 16 : 12),
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: _addAdditionalContact,
                              icon: Icon(Icons.add, size: isWide ? 18 : 16),
                              label: Text(
                                'Add Another Contact',
                                style: TextStyle(fontSize: isWide ? 14 : 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue[600],
                                side: BorderSide(color: Colors.blue[600]!),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWide ? 20 : 16,
                                  vertical: isWide ? 12 : 8,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isWide ? 32 : 24),

                          // Attachments Section
                          _buildSectionHeader(
                            'Attachments',
                            Icons.attach_file,
                            isWide,
                          ),
                          SizedBox(height: isWide ? 16 : 12),
                          ..._attachments.asMap().entries.map((entry) {
                            final index = entry.key;
                            final attachment = entry.value;
                            return Container(
                              margin: EdgeInsets.only(bottom: isWide ? 16 : 12),
                              padding: EdgeInsets.all(isWide ? 16 : 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.attach_file,
                                        color: Colors.grey[600],
                                        size: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Attachment ${index + 1}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Spacer(),
                                      if (_attachments.length > 1)
                                        IconButton(
                                          onPressed: () =>
                                              _removeAttachment(index),
                                          icon: Icon(
                                            Icons.remove_circle,
                                            color: Colors.red[400],
                                          ),
                                          tooltip: 'Remove Attachment',
                                          padding: EdgeInsets.all(4),
                                          constraints: BoxConstraints(
                                            minWidth: 24,
                                            minHeight: 24,
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildFormField(
                                          controller: attachment['name']!,
                                          label: 'File Name',
                                          icon: Icons.description,
                                        ),
                                      ),
                                      SizedBox(width: isWide ? 16 : 12),
                                      Expanded(
                                        child: _buildFormField(
                                          controller: attachment['link']!,
                                          label: 'File Link',
                                          icon: Icons.link,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                          SizedBox(height: isWide ? 16 : 12),
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: _addAttachment,
                              icon: Icon(Icons.add, size: isWide ? 18 : 16),
                              label: Text(
                                'Add Another Attachment',
                                style: TextStyle(fontSize: isWide ? 14 : 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue[600],
                                side: BorderSide(color: Colors.blue[600]!),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWide ? 20 : 16,
                                  vertical: isWide ? 12 : 8,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isWide ? 32 : 24),

                          // Initial Quote Section (for Scaffolding leads)
                          if (_selectedLeadType == 'Scaffolding') ...[
                            _buildSectionHeader(
                              'Initial Quote',
                              Icons.receipt,
                              isWide,
                            ),
                            SizedBox(height: isWide ? 16 : 12),
                            ..._initialQuotes.asMap().entries.map((entry) {
                              final index = entry.key;
                              final quote = entry.value;
                              return Container(
                                margin: EdgeInsets.only(
                                  bottom: isWide ? 16 : 12,
                                ),
                                padding: EdgeInsets.all(isWide ? 16 : 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.receipt,
                                          color: Colors.grey[600],
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Quote Item ${index + 1}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Spacer(),
                                        if (_initialQuotes.length > 1)
                                          IconButton(
                                            onPressed: () =>
                                                _removeInitialQuote(index),
                                            icon: Icon(
                                              Icons.remove_circle,
                                              color: Colors.red[400],
                                            ),
                                            tooltip: 'Remove Quote Item',
                                            padding: EdgeInsets.all(4),
                                            constraints: BoxConstraints(
                                              minWidth: 24,
                                              minHeight: 24,
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildFormField(
                                            controller: quote['item']!,
                                            label: 'Item',
                                            icon: Icons.inventory,
                                          ),
                                        ),
                                        SizedBox(width: isWide ? 16 : 12),
                                        Expanded(
                                          child: _buildFormField(
                                            controller: quote['quantity']!,
                                            label: 'Quantity',
                                            icon: Icons.numbers,
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: isWide ? 16 : 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildFormField(
                                            controller: quote['rate']!,
                                            label: 'Rate',
                                            icon: Icons.attach_money,
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        SizedBox(width: isWide ? 16 : 12),
                                        Expanded(
                                          child: _buildFormField(
                                            controller: quote['amount']!,
                                            label: 'Amount',
                                            icon: Icons.calculate,
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                            SizedBox(height: isWide ? 16 : 12),
                            Center(
                              child: OutlinedButton.icon(
                                onPressed: _addInitialQuote,
                                icon: Icon(Icons.add, size: isWide ? 18 : 16),
                                label: Text(
                                  'Add Another Quote Item',
                                  style: TextStyle(fontSize: isWide ? 14 : 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange[600],
                                  side: BorderSide(color: Colors.orange[600]!),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isWide ? 20 : 16,
                                    vertical: isWide ? 12 : 8,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: isWide ? 32 : 24),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Action Buttons - matching lead management style
                Container(
                  padding: EdgeInsets.all(isWide ? 24 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Cancel Button
                      OutlinedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, size: isWide ? 20 : 16),
                        label: Text(
                          'Cancel',
                          style: TextStyle(fontSize: isWide ? 14 : 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[400]!),
                          padding: EdgeInsets.symmetric(
                            horizontal: isWide ? 24 : 16,
                            vertical: isWide ? 12 : 8,
                          ),
                        ),
                      ),

                      // Update Button
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _updateLead,
                        icon: _isLoading
                            ? SizedBox(
                                width: isWide ? 20 : 16,
                                height: isWide ? 20 : 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(Icons.save, size: isWide ? 20 : 16),
                        label: Text(
                          _isLoading ? 'Updating...' : 'Update Lead',
                          style: TextStyle(fontSize: isWide ? 14 : 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isWide ? 24 : 16,
                            vertical: isWide ? 12 : 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Sales Dashboard Page
class SalesDashboardPage extends StatefulWidget {
  final String currentUserId;
  final String currentUserEmail;

  const SalesDashboardPage({
    super.key,
    required this.currentUserId,
    required this.currentUserEmail,
  });

  @override
  State<SalesDashboardPage> createState() => _SalesDashboardPageState();
}

class _SalesDashboardPageState extends State<SalesDashboardPage> {
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedTimePeriod = 'Quarter';
  String _selectedCurrency = 'INR';
  String _currentUsername = '';
  bool _isLoading = false;

  // Dashboard data state
  Map<String, dynamic> _dashboardData = {
    'totalRevenue': {'value': '₹0', 'percentage': '+0.0%', 'isPositive': true},
    'aluminiumArea': {
      'value': '0 m²',
      'percentage': '+0.0%',
      'isPositive': true,
    },
    'qualifiedLeads': {'value': '0', 'percentage': '+0.0%', 'isPositive': true},
  };

  // Chart data state
  List<BarChartGroupData> _barChartData = [];
  bool _isLoadingChartData = false;

  // Lead status distribution data state
  Map<String, int> _leadStatusDistribution = {
    'Won': 0,
    'Lost': 0,
    'Follow Up': 0,
  };
  bool _isLoadingLeadStatusData = false;

  // Lead Performance state
  String _activeLeadTab = 'Won';
  List<Map<String, dynamic>> _leadPerformanceData = [];
  List<Map<String, dynamic>> _filteredLeadData = [];
  bool _isLoadingLeadData = false;
  final TextEditingController _leadSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCurrentUsername();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _leadSearchController.dispose();
    super.dispose();
  }

  // Fetch current user's username
  Future<void> _fetchCurrentUsername() async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('users')
          .select('username')
          .eq('id', widget.currentUserId)
          .single();

      setState(() {
        _currentUsername = response['username'] ?? '';
      });

      // Fetch dashboard data after getting username
      _fetchDashboardData();
      _fetchChartData();
      _fetchLeadStatusDistributionData();
      _fetchLeadPerformanceData();
    } catch (e) {
      debugPrint('Error fetching username: $e');
    }
  }

  // Helper method to get date range based on selected time period
  Map<String, DateTime> _getDateRange(String timePeriod) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (timePeriod.toLowerCase()) {
      case 'week':
        startDate = now.subtract(Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'quarter':
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case 'semester':
        startDate = DateTime(now.year, now.month - 6, now.day);
        break;
      case 'annual':
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case 'two years':
        startDate = DateTime(now.year - 2, now.month, now.day);
        break;
      case 'three years':
        startDate = DateTime(now.year - 3, now.month, now.day);
        break;
      case 'five years':
        startDate = DateTime(now.year - 5, now.month, now.day);
        break;
      default:
        startDate = DateTime(now.year, now.month - 3, now.day);
    }

    return {'start': startDate, 'end': endDate};
  }

  // Fetch dashboard data from Supabase
  Future<void> _fetchDashboardData() async {
    if (_currentUsername.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final client = Supabase.instance.client;
      final dateRange = _getDateRange(_selectedTimePeriod);

      // Fetch data from admin_response table filtered by sales_user and Won status
      final response = await client
          .from('admin_response')
          .select()
          .eq('sales_user', _currentUsername)
          .eq('update_lead_status', 'Won')
          .gte('updated_at', dateRange['start']!.toIso8601String())
          .lte('updated_at', dateRange['end']!.toIso8601String());

      await _calculateDashboardMetrics(response);
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Calculate dashboard metrics from fetched data
  Future<void> _calculateDashboardMetrics(List<dynamic> data) async {
    double totalRevenue = 0;
    double totalAluminiumArea = 0;
    int qualifiedLeadsCount = 0;

    for (var record in data) {
      if (record['total_amount_gst'] != null) {
        totalRevenue += (record['total_amount_gst'] is num)
            ? record['total_amount_gst'].toDouble()
            : 0;
      }

      if (record['aluminium_area'] != null) {
        totalAluminiumArea += (record['aluminium_area'] is num)
            ? record['aluminium_area'].toDouble()
            : 0;
      }

      qualifiedLeadsCount++;
    }

    final previousPeriodData = await _getPreviousPeriodData();

    final revenuePercentage = _calculatePercentage(
      totalRevenue,
      previousPeriodData['revenue'] ?? 0,
    );
    final aluminiumAreaPercentage = _calculatePercentage(
      totalAluminiumArea,
      previousPeriodData['aluminiumArea'] ?? 0,
    );
    final leadsPercentage = _calculatePercentage(
      qualifiedLeadsCount.toDouble(),
      previousPeriodData['leads'] ?? 0,
    );

    setState(() {
      _dashboardData = {
        'totalRevenue': {
          'value': _formatRevenueInCrore(totalRevenue),
          'percentage':
              '${revenuePercentage >= 0 ? '+' : ''}${revenuePercentage.toStringAsFixed(1)}%',
          'isPositive': revenuePercentage >= 0,
        },
        'aluminiumArea': {
          'value': '${totalAluminiumArea.toStringAsFixed(0)} m²',
          'percentage':
              '${aluminiumAreaPercentage >= 0 ? '+' : ''}${aluminiumAreaPercentage.toStringAsFixed(1)}%',
          'isPositive': aluminiumAreaPercentage >= 0,
        },
        'qualifiedLeads': {
          'value': qualifiedLeadsCount.toString(),
          'percentage':
              '${leadsPercentage >= 0 ? '+' : ''}${leadsPercentage.toStringAsFixed(1)}%',
          'isPositive': leadsPercentage >= 0,
        },
      };
    });
  }

  // Get previous period data for comparison
  Future<Map<String, double>> _getPreviousPeriodData() async {
    try {
      final client = Supabase.instance.client;
      final currentDateRange = _getDateRange(_selectedTimePeriod);

      final duration = currentDateRange['end']!.difference(
        currentDateRange['start']!,
      );
      final previousStartDate = currentDateRange['start']!.subtract(duration);
      final previousEndDate = currentDateRange['start']!;

      final previousResponse = await client
          .from('admin_response')
          .select()
          .eq('sales_user', _currentUsername)
          .eq('update_lead_status', 'Won')
          .gte('updated_at', previousStartDate.toIso8601String())
          .lte('updated_at', previousEndDate.toIso8601String());

      double previousRevenue = 0;
      double previousAluminiumArea = 0;
      int previousLeadsCount = 0;

      for (var record in previousResponse) {
        if (record['total_amount_gst'] != null) {
          previousRevenue += (record['total_amount_gst'] is num)
              ? record['total_amount_gst'].toDouble()
              : 0;
        }
        if (record['aluminium_area'] != null) {
          previousAluminiumArea += (record['aluminium_area'] is num)
              ? record['aluminium_area'].toDouble()
              : 0;
        }
        previousLeadsCount++;
      }

      return {
        'revenue': previousRevenue,
        'aluminiumArea': previousAluminiumArea,
        'leads': previousLeadsCount.toDouble(),
      };
    } catch (e) {
      debugPrint('Error fetching previous period data: $e');
      return {'revenue': 0, 'aluminiumArea': 0, 'leads': 0};
    }
  }

  // Fetch chart data from admin_response table
  Future<void> _fetchChartData() async {
    if (_currentUsername.isEmpty) return;

    setState(() {
      _isLoadingChartData = true;
    });

    try {
      final client = Supabase.instance.client;
      final dateRange = _getDateRange(_selectedTimePeriod);

      final response = await client
          .from('admin_response')
          .select('aluminium_area, total_amount_gst, updated_at')
          .eq('sales_user', _currentUsername)
          .eq('update_lead_status', 'Won')
          .gte('updated_at', dateRange['start']!.toIso8601String())
          .lte('updated_at', dateRange['end']!.toIso8601String())
          .order('updated_at', ascending: true)
          .timeout(const Duration(seconds: 10));

      await _processChartData(response);
    } catch (e) {
      debugPrint('Error fetching chart data: $e');
      setState(() {
        _barChartData = [];
        _isLoadingChartData = false;
      });
    }
  }

  // Process chart data and create bar chart data with cumulative approach
  Future<void> _processChartData(List<dynamic> data) async {
    if (data.isEmpty) {
      setState(() {
        _barChartData = [];
        _isLoadingChartData = false;
      });
      return;
    }

    // Get the date range for the selected time period
    final dateRange = _getDateRange(_selectedTimePeriod);
    final startDate = dateRange['start']!;
    final endDate = dateRange['end']!;

    // Group data based on time period with cumulative approach
    Map<String, List<Map<String, dynamic>>> groupedData = {};

    for (var record in data) {
      final updatedAt = DateTime.parse(record['updated_at']);

      // Convert UTC datetime to local timezone for proper comparison
      final localUpdatedAt = TimezoneUtils.convertToLocal(updatedAt);

      // Only include data within the selected time period range
      if (localUpdatedAt.isBefore(startDate) ||
          localUpdatedAt.isAfter(endDate)) {
        continue;
      }

      String groupKey;

      switch (_selectedTimePeriod.toLowerCase()) {
        case 'week':
          final dayOfWeek = updatedAt.weekday;
          groupKey = _getDayOfWeekName(dayOfWeek);
          break;
        case 'month':
          final weekOfMonth = ((updatedAt.day - 1) ~/ 7) + 1;
          groupKey = 'Week $weekOfMonth';
          break;
        case 'quarter':
          groupKey = _getMonthName(updatedAt.month);
          break;
        case 'semester':
          groupKey = _getMonthName(updatedAt.month);
          break;
        case 'annual':
          groupKey = _getMonthName(updatedAt.month);
          break;
        case 'two years':
          final quarter = ((updatedAt.month - 1) ~/ 3) + 1;
          groupKey = 'Q$quarter-${updatedAt.year}';
          break;
        case 'three years':
          final semester = updatedAt.month <= 6 ? 1 : 2;
          groupKey = 'S$semester-${updatedAt.year}';
          break;
        case 'five years':
          groupKey = updatedAt.year.toString();
          break;
        default:
          groupKey = _getMonthName(updatedAt.month);
      }

      if (!groupedData.containsKey(groupKey)) {
        groupedData[groupKey] = [];
      }
      groupedData[groupKey]!.add(record);
    }

    final labels = _getChartLabels();
    final barGroups = <BarChartGroupData>[];

    for (int i = 0; i < labels.length; i++) {
      final label = labels[i];
      final groupData = groupedData[label] ?? [];

      double totalRevenue = 0;

      for (var record in groupData) {
        totalRevenue += (record['total_amount_gst'] ?? 0).toDouble();
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            // Revenue bar (Pink color)
            BarChartRodData(
              toY: totalRevenue / 10000000, // Convert to Crore (Cr)
              color: Colors.pink,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    setState(() {
      _barChartData = barGroups;
      _isLoadingChartData = false;
    });
  }

  // Fetch lead status distribution data
  Future<void> _fetchLeadStatusDistributionData() async {
    if (_currentUsername.isEmpty) return;

    setState(() {
      _isLoadingLeadStatusData = true;
    });

    try {
      final client = Supabase.instance.client;
      final dateRange = _getDateRange(_selectedTimePeriod);

      final response = await client
          .from('admin_response')
          .select('update_lead_status')
          .eq('sales_user', _currentUsername)
          .gte('updated_at', dateRange['start']!.toIso8601String())
          .lte('updated_at', dateRange['end']!.toIso8601String())
          .timeout(const Duration(seconds: 10));

      await _processLeadStatusDistributionData(response);
    } catch (e) {
      debugPrint('Error fetching lead status distribution data: $e');
      setState(() {
        _leadStatusDistribution = {'Won': 0, 'Lost': 0, 'Follow Up': 0};
        _isLoadingLeadStatusData = false;
      });
    }
  }

  // Process lead status distribution data
  Future<void> _processLeadStatusDistributionData(List<dynamic> data) async {
    Map<String, int> statusCounts = {'Won': 0, 'Lost': 0, 'Follow Up': 0};

    for (var record in data) {
      final status = record['update_lead_status'];
      if (status != null && statusCounts.containsKey(status)) {
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }
    }

    setState(() {
      _leadStatusDistribution = statusCounts;
      _isLoadingLeadStatusData = false;
    });
  }

  // Helper methods
  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  String _getDayOfWeekName(int dayOfWeek) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dayOfWeek - 1];
  }

  List<String> _getChartLabels() {
    final now = DateTime.now();

    switch (_selectedTimePeriod.toLowerCase()) {
      case 'week':
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      case 'month':
        // Show only current month's weeks
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final totalWeeks = ((daysInMonth - 1) ~/ 7) + 1;

        final labels = <String>[];
        for (int week = 1; week <= totalWeeks; week++) {
          labels.add('Week $week');
        }
        return labels;
      case 'quarter':
        // Show only current quarter months
        final currentMonth = now.month;
        if (currentMonth >= 1 && currentMonth <= 3) {
          // Q1 (Jan-Mar)
          return ['Jan', 'Feb', 'Mar'];
        } else if (currentMonth >= 4 && currentMonth <= 6) {
          // Q2 (Apr-Jun)
          return ['Apr', 'May', 'Jun'];
        } else if (currentMonth >= 7 && currentMonth <= 9) {
          // Q3 (Jul-Sep)
          return ['Jul', 'Aug', 'Sep'];
        } else {
          // Q4 (Oct-Dec)
          return ['Oct', 'Nov', 'Dec'];
        }
      case 'semester':
        // Show only current semester months
        final currentMonth = now.month;
        if (currentMonth >= 1 && currentMonth <= 6) {
          // First semester (Jan-Jun)
          return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
        } else {
          // Second semester (Jul-Dec)
          return ['Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        }
      case 'annual':
        return [
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
      case 'two years':
        // Show quarters for current year and previous year
        final labels = <String>[];
        for (int year = now.year - 1; year <= now.year; year++) {
          labels.addAll(['Q1-$year', 'Q2-$year', 'Q3-$year', 'Q4-$year']);
        }
        return labels;
      case 'three years':
        // Show semesters for current year and previous 2 years
        final labels = <String>[];
        for (int year = now.year - 2; year <= now.year; year++) {
          labels.addAll(['S1-$year', 'S2-$year']);
        }
        return labels;
      case 'five years':
        // Show years for current year and previous 4 years
        final labels = <String>[];
        for (int year = now.year - 4; year <= now.year; year++) {
          labels.add(year.toString());
        }
        return labels.reversed.toList(); // Show most recent first
      default:
        return [
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
    }
  }

  double _calculatePercentage(double current, double previous) {
    if (previous == 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
  }

  // Format revenue in Crore (Cr) format
  String _formatRevenueInCrore(double amount) {
    if (amount >= 10000000) {
      // 1 Crore = 10,000,000
      final croreValue = amount / 10000000;
      if (croreValue >= 100) {
        return '₹${croreValue.toStringAsFixed(0)} Cr';
      } else if (croreValue >= 10) {
        return '₹${croreValue.toStringAsFixed(1)} Cr';
      } else {
        return '₹${croreValue.toStringAsFixed(2)} Cr';
      }
    } else if (amount >= 100000) {
      // 1 Lakh = 100,000
      final lakhValue = amount / 100000;
      if (lakhValue >= 100) {
        return '₹${lakhValue.toStringAsFixed(0)} L';
      } else if (lakhValue >= 10) {
        return '₹${lakhValue.toStringAsFixed(1)} L';
      } else {
        return '₹${lakhValue.toStringAsFixed(2)} L';
      }
    } else if (amount >= 1000) {
      // 1 Thousand = 1,000
      final thousandValue = amount / 1000;
      return '₹${thousandValue.toStringAsFixed(0)} K';
    } else {
      return '₹${amount.toStringAsFixed(0)}';
    }
  }

  // Build Syncfusion pie chart data
  List<ChartData> _buildSyncfusionPieChartData() {
    final totalLeads = _leadStatusDistribution.values.fold(
      0,
      (sum, count) => sum + count,
    );
    final chartData = <ChartData>[];

    if (totalLeads == 0) {
      return chartData;
    }

    final colors = {
      'Won': Colors.green,
      'Lost': Colors.red,
      'Follow Up': Colors.orange,
    };

    for (var entry in _leadStatusDistribution.entries) {
      if (entry.value > 0) {
        chartData.add(
          ChartData(entry.key, entry.value.toDouble(), colors[entry.key]!),
        );
      }
    }

    return chartData;
  }

  // Refresh data when time period changes
  void _onTimePeriodChanged(String newPeriod) {
    setState(() {
      _selectedTimePeriod = newPeriod;
    });
    _fetchDashboardData();
    _fetchChartData();
    _fetchLeadStatusDistributionData();
    _fetchLeadPerformanceData();
  }

  // Fetch lead performance data from admin_response table
  // This method fetches ONLY the data that matches the current user's username
  // in the admin_response table's sales_user column
  Future<void> _fetchLeadPerformanceData() async {
    if (_currentUsername.isEmpty) {
      debugPrint('[LEAD_PERFORMANCE] Username is empty, skipping fetch');
      return;
    }

    setState(() {
      _isLoadingLeadData = true;
    });

    try {
      final client = Supabase.instance.client;
      final dateRange = _getDateRange(_selectedTimePeriod);

      debugPrint(
        '[LEAD_PERFORMANCE] Fetching data for user: $_currentUsername',
      );
      debugPrint(
        '[LEAD_PERFORMANCE] Date range: ${dateRange['start']} to ${dateRange['end']}',
      );

      final response = await client
          .from('admin_response')
          .select('*')
          .eq(
            'sales_user',
            _currentUsername,
          ) // Only fetch rows where sales_user matches current username
          .gte('updated_at', dateRange['start']!.toIso8601String())
          .lte('updated_at', dateRange['end']!.toIso8601String())
          .order('updated_at', ascending: false)
          .timeout(const Duration(seconds: 10));

      debugPrint(
        '[LEAD_PERFORMANCE] Fetched ${response.length} records for user: $_currentUsername',
      );

      setState(() {
        _leadPerformanceData = List<Map<String, dynamic>>.from(response);
        _filteredLeadData = List<Map<String, dynamic>>.from(response);
        _isLoadingLeadData = false;
      });
    } catch (e) {
      debugPrint('Error fetching lead performance data: $e');
      setState(() {
        _isLoadingLeadData = false;
      });
    }
  }

  // Filter lead data based on search query
  void _filterLeadData(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredLeadData = List<Map<String, dynamic>>.from(
          _leadPerformanceData,
        );
      });
      return;
    }

    final filtered = _leadPerformanceData.where((lead) {
      final searchQuery = query.toLowerCase();
      return lead['project_id']?.toString().toLowerCase().contains(
                searchQuery,
              ) ==
              true ||
          lead['project_name']?.toString().toLowerCase().contains(
                searchQuery,
              ) ==
              true ||
          lead['client_name']?.toString().toLowerCase().contains(searchQuery) ==
              true ||
          lead['location']?.toString().toLowerCase().contains(searchQuery) ==
              true ||
          lead['aluminium_area']?.toString().toLowerCase().contains(
                searchQuery,
              ) ==
              true ||
          lead['ms_weight']?.toString().toLowerCase().contains(searchQuery) ==
              true ||
          lead['rate_sqm']?.toString().toLowerCase().contains(searchQuery) ==
              true ||
          lead['total_amount_gst']?.toString().toLowerCase().contains(
                searchQuery,
              ) ==
              true ||
          lead['sales_user']?.toString().toLowerCase().contains(searchQuery) ==
              true ||
          lead['update_lead_status']?.toString().toLowerCase().contains(
                searchQuery,
              ) ==
              true ||
          lead['lead_status_remark']?.toString().toLowerCase().contains(
                searchQuery,
              ) ==
              true ||
          lead['created_at']?.toString().toLowerCase().contains(searchQuery) ==
              true ||
          lead['updated_at']?.toString().toLowerCase().contains(searchQuery) ==
              true;
    }).toList();

    setState(() {
      _filteredLeadData = filtered;
    });
  }

  // Show currency dialog
  void _showCurrencyDialog() {
    final currencies = ['INR', 'USD', 'EUR', 'CHF', 'GBP'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Currency'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: currencies.map((currency) {
              return ListTile(
                title: Text(currency),
                trailing: _selectedCurrency == currency
                    ? Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedCurrency = currency;
                  });
                  _fetchDashboardData();
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Show time period dialog
  void _showTimePeriodDialog() {
    final timePeriods = [
      'Week',
      'Month',
      'Quarter',
      'Semester',
      'Annual',
      'Two Years',
      'Three Years',
      'Five Years',
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Time Period'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: timePeriods.map((period) {
              return ListTile(
                title: Text(period),
                trailing: _selectedTimePeriod == period
                    ? Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  _onTimePeriodChanged(period);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Helper method to safely get isPositive value
  bool _getIsPositive(String title) {
    final key = title.toLowerCase().replaceAll(' ', '');
    final data = _dashboardData[key];
    if (data != null && data['isPositive'] != null) {
      return data['isPositive'] as bool;
    }
    return true; // Default to positive if data is not available
  }

  // Build lead performance table
  Widget _buildLeadPerformanceTable() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with search
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                // Mobile layout - stacked vertically
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lead Performance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _leadSearchController,
                        onChanged: _filterLeadData,
                        decoration: InputDecoration(
                          hintText: 'Search leads...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[600],
                          ),
                          suffixIcon: _leadSearchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.grey[600],
                                  ),
                                  onPressed: () {
                                    _leadSearchController.clear();
                                    _filterLeadData('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Desktop layout - horizontal with search bar expanding left
                return Row(
                  children: [
                    // Search bar - expands toward left
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextField(
                          controller: _leadSearchController,
                          onChanged: _filterLeadData,
                          decoration: InputDecoration(
                            hintText: 'Search leads...',
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey[600],
                            ),
                            suffixIcon: _leadSearchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: () {
                                      _leadSearchController.clear();
                                      _filterLeadData('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    // Title - positioned on the right
                    Text(
                      'Lead Performance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          SizedBox(height: 16),

          // Tabs
          _buildLeadTabs(),
          SizedBox(height: 16),

          // Table
          _buildLeadTable(),

          // Pagination
          SizedBox(height: 16),
          _buildPagination(),
        ],
      ),
    );
  }

  // Build lead tabs
  Widget _buildLeadTabs() {
    final tabs = [
      {
        'key': 'Won',
        'label': 'Won Leads',
        'count': _getLeadCountByStatus('Won'),
      },
      {
        'key': 'Lost',
        'label': 'Lost Leads',
        'count': _getLeadCountByStatus('Lost'),
      },
      {
        'key': 'Follow Up',
        'label': 'Follow Up',
        'count': _getLeadCountByStatus('Follow Up'),
      },
    ];

    return Row(
      children: tabs.map((tab) {
        final isActive = _activeLeadTab == tab['key'];
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _activeLeadTab = tab['key'] as String;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? Colors.blue : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    tab['label'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.blue : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${tab['count']}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.blue : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Get lead count by status from lead status distribution data
  int _getLeadCountByStatus(String status) {
    return _leadStatusDistribution[status] ?? 0;
  }

  // Build lead table
  Widget _buildLeadTable() {
    final filteredData = _filteredLeadData
        .where((lead) => lead['update_lead_status'] == _activeLeadTab)
        .toList();

    if (_isLoadingLeadData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading lead data...',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (filteredData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No $_activeLeadTab leads found',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 900;

        if (isMobile) {
          // Mobile layout - interactive cards with dashboard style
          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: filteredData.length,
            itemBuilder: (context, index) {
              final lead = filteredData[index];
              return AnimatedContainer(
                duration: Duration(milliseconds: 300),
                margin: EdgeInsets.only(bottom: 16),
                child: Card(
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () => _showLeadDetailsDialog(lead),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Colors.grey[50]!],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with project name and status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lead['project_name']?.toString() ??
                                            'N/A',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.grey[800],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'ID: ${lead['project_id']?.toString() ?? 'N/A'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      lead['update_lead_status'],
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _getStatusColor(
                                        lead['update_lead_status'],
                                      ),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _getStatusColor(
                                          lead['update_lead_status'],
                                        ).withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    lead['update_lead_status']?.toString() ??
                                        'N/A',
                                    style: TextStyle(
                                      color: _getStatusColor(
                                        lead['update_lead_status'],
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),

                            // Key metrics in a grid layout
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricCard(
                                    'Area',
                                    '${lead['aluminium_area']?.toString() ?? '0'} m²',
                                    Icons.grid_on,
                                    Colors.blue,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _buildMetricCard(
                                    'Rate',
                                    '₹${lead['rate_sqm']?.toString() ?? '0'}',
                                    Icons.attach_money,
                                    Colors.green,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _buildMetricCard(
                                    'Total',
                                    '₹${lead['total_amount_gst']?.toString() ?? '0'}',
                                    Icons.account_balance_wallet,
                                    Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),

                            // Additional info in a clean layout
                            _buildMobileInfoRow(
                              'Client',
                              lead['client_name']?.toString() ?? 'N/A',
                              Icons.person,
                            ),
                            _buildMobileInfoRow(
                              'Location',
                              lead['location']?.toString() ?? 'N/A',
                              Icons.location_on,
                            ),
                            _buildMobileInfoRow(
                              'MS Weight',
                              lead['ms_weight']?.toString() ?? 'N/A',
                              Icons.fitness_center,
                            ),
                            _buildMobileInfoRow(
                              'Sales User',
                              lead['sales_user']?.toString() ?? 'N/A',
                              Icons.person_outline,
                            ),
                            _buildMobileInfoRow(
                              'Updated',
                              _formatDate(lead['updated_at']),
                              Icons.schedule,
                            ),

                            // Interactive action buttons
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionButton(
                                    'Query',
                                    Icons.chat_bubble_outline,
                                    Colors.blue,
                                    () => _showQueryDialogMobile(context, lead),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _buildActionButton(
                                    'Alerts',
                                    Icons.notifications_none,
                                    Colors.orange,
                                    () =>
                                        _showAlertsDialogMobile(context, lead),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _buildActionButton(
                                    'Details',
                                    Icons.info_outline,
                                    Colors.grey[600]!,
                                    () => _showLeadDetailsDialog(lead),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        } else if (isTablet) {
          // Tablet layout - compact table with horizontal scrolling
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 12,
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
                fontSize: 11,
              ),
              dataTextStyle: TextStyle(fontSize: 11, color: Colors.grey[700]),
              columns: [
                DataColumn(
                  label: SizedBox(width: 80, child: Text('PROJECT ID')),
                ),
                DataColumn(
                  label: SizedBox(width: 100, child: Text('PROJECT NAME')),
                ),
                DataColumn(
                  label: SizedBox(width: 90, child: Text('CLIENT NAME')),
                ),
                DataColumn(label: SizedBox(width: 70, child: Text('LOCATION'))),
                DataColumn(label: SizedBox(width: 80, child: Text('AREA'))),
                DataColumn(label: SizedBox(width: 70, child: Text('RATE'))),
                DataColumn(label: SizedBox(width: 90, child: Text('TOTAL'))),
                DataColumn(
                  label: SizedBox(width: 100, child: Text('SALES USER')),
                ),
                DataColumn(label: SizedBox(width: 60, child: Text('STATUS'))),
                DataColumn(
                  label: SizedBox(width: 100, child: Text('CLOSED DATE')),
                ),
              ],
              rows: filteredData
                  .map((lead) => _buildTabletLeadRow(lead))
                  .toList(),
            ),
          );
        } else {
          // Desktop layout - table with evenly distributed columns and vertical lines
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Header row
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildTableHeaderCell('PROJECT ID', 1),
                      _buildTableHeaderCell('PROJECT NAME', 2),
                      _buildTableHeaderCell('CLIENT NAME', 2),
                      _buildTableHeaderCell('LOCATION', 1),
                      _buildTableHeaderCell('ALUMINIUM AREA', 1),
                      _buildTableHeaderCell('MS WEIGHT', 1),
                      _buildTableHeaderCell('RATE/SQM', 1),
                      _buildTableHeaderCell('TOTAL AMOUNT', 1),
                      _buildTableHeaderCell('SALES USER', 1),
                      _buildTableHeaderCell('STATUS', 1),
                      _buildTableHeaderCell('REMARK', 1),
                      _buildTableHeaderCell('CLOSED DATE', 1),
                    ],
                  ),
                ),
                // Data rows
                ...filteredData.map((lead) => _buildTableDataRow(lead)),
              ],
            ),
          );
        }
      },
    );
  }

  // Build mobile info row
  Widget _buildMobileInfoRow(String label, String value, [IconData? icon]) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey[500]),
            SizedBox(width: 8),
          ],
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: Colors.grey[800]),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  // Build metric card for dashboard style
  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  // Build action button for dashboard style
  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              children: [
                Icon(icon, size: 20, color: color),
                SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build tablet lead row
  DataRow _buildTabletLeadRow(Map<String, dynamic> lead) {
    final projectId = lead['project_id'] ?? 'N/A';
    final projectName = lead['project_name'] ?? 'N/A';
    final clientName = lead['client_name'] ?? 'N/A';
    final location = lead['location'] ?? 'N/A';
    final aluminiumArea = lead['aluminium_area'] != null
        ? '${lead['aluminium_area'].toString()} m²'
        : 'N/A';
    final rateSqm = lead['rate_sqm'] != null
        ? '₹${lead['rate_sqm'].toString()}'
        : 'N/A';
    final totalAmount = lead['total_amount_gst'] != null
        ? '₹${lead['total_amount_gst'].toString()}'
        : 'N/A';
    final salesUser = lead['sales_user'] ?? 'N/A';
    final status = lead['update_lead_status'] ?? 'N/A';
    final closedDate = lead['updated_at'] != null
        ? DateTime.parse(lead['updated_at']).toLocal().toString().split('.')[0]
        : 'N/A';

    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 80,
            child: Text(
              projectId,
              style: TextStyle(fontSize: 9),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 100,
            child: Text(
              projectName,
              style: TextStyle(fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 90,
            child: Text(
              clientName,
              style: TextStyle(fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 70,
            child: Text(
              location,
              style: TextStyle(fontSize: 9),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 80,
            child: Text(
              aluminiumArea,
              style: TextStyle(fontSize: 9),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 70,
            child: Text(
              rateSqm,
              style: TextStyle(fontSize: 9),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 90,
            child: Text(
              totalAmount,
              style: TextStyle(fontSize: 9),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 100,
            child: Text(
              salesUser,
              style: TextStyle(fontSize: 9),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 60,
            child: Text(
              status,
              style: TextStyle(fontSize: 9),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 100,
            child: Text(
              closedDate,
              style: TextStyle(fontSize: 9),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  // Show lead details dialog
  void _showLeadDetailsDialog(Map<String, dynamic> lead) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Lead Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow(
                  'Project ID',
                  lead['project_id']?.toString() ?? 'N/A',
                ),
                _buildDetailRow(
                  'Project Name',
                  lead['project_name']?.toString() ?? 'N/A',
                ),
                _buildDetailRow(
                  'Client Name',
                  lead['client_name']?.toString() ?? 'N/A',
                ),
                _buildDetailRow(
                  'Location',
                  lead['location']?.toString() ?? 'N/A',
                ),
                _buildDetailRow(
                  'Aluminium Area',
                  '${lead['aluminium_area']?.toString() ?? '0'} m²',
                ),
                _buildDetailRow(
                  'MS Weight',
                  lead['ms_weight']?.toString() ?? 'N/A',
                ),
                _buildDetailRow(
                  'Rate/SQM',
                  '₹${lead['rate_per_sqm']?.toString() ?? '0'}',
                ),
                _buildDetailRow(
                  'Total Amount',
                  '₹${lead['total_amount_gst']?.toString() ?? '0'}',
                ),
                _buildDetailRow(
                  'Sales User',
                  lead['sales_user']?.toString() ?? 'N/A',
                ),
                _buildDetailRow(
                  'Status',
                  lead['update_lead_status']?.toString() ?? 'N/A',
                ),
                _buildDetailRow('Remark', lead['remark']?.toString() ?? 'N/A'),
                _buildDetailRow('Updated At', _formatDate(lead['updated_at'])),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Build detail row for dialog
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  // Show query dialog for mobile
  void _showQueryDialogMobile(BuildContext context, Map<String, dynamic> lead) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Query functionality - Coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Show alerts dialog for mobile
  void _showAlertsDialogMobile(
    BuildContext context,
    Map<String, dynamic> lead,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alerts functionality - Coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Get status color
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Won':
        return Colors.green;
      case 'Lost':
        return Colors.red;
      case 'Follow Up':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Format date
  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  // Build table header cell
  Widget _buildTableHeaderCell(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey[300]!)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            maxLines: 3, // Limit to 3 lines to prevent layout issues
          ),
        ),
      ),
    );
  }

  // Build table data row
  Widget _buildTableDataRow(Map<String, dynamic> lead) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          _buildTableDataCell(lead['project_id']?.toString() ?? 'N/A', 1),
          _buildTableDataCell(lead['project_name']?.toString() ?? 'N/A', 2),
          _buildTableDataCell(lead['client_name']?.toString() ?? 'N/A', 2),
          _buildTableDataCell(lead['location']?.toString() ?? 'N/A', 1),
          _buildTableDataCell(
            '${lead['aluminium_area']?.toString() ?? '0'} m²',
            1,
          ),
          _buildTableDataCell(lead['ms_weight']?.toString() ?? 'N/A', 1),
          _buildTableDataCell('₹${lead['rate_sqm']?.toString() ?? '0'}', 1),
          _buildTableDataCell(
            '₹${lead['total_amount_gst']?.toString() ?? '0'}',
            1,
          ),
          _buildTableDataCell(lead['sales_user']?.toString() ?? 'N/A', 1),
          _buildTableDataCell(
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(
                  lead['update_lead_status'],
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                lead['update_lead_status']?.toString() ?? 'N/A',
                style: TextStyle(
                  color: _getStatusColor(lead['update_lead_status']),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            1,
          ),
          _buildTableDataCell(lead['remark']?.toString() ?? 'N/A', 1),
          _buildTableDataCell(_formatDate(lead['updated_at']), 1),
        ],
      ),
    );
  }

  // Build table data cell
  Widget _buildTableDataCell(
    dynamic content,
    int flex, {
    bool isClientName = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey[300]!)),
        ),
        child: content is Widget
            ? content
            : SizedBox(
                width: double.infinity,
                child: Text(
                  content.toString(),
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                  textAlign: isClientName ? TextAlign.left : TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  maxLines: 3, // Limit to 3 lines to prevent layout issues
                ),
              ),
      ),
    );
  }

  // Build pagination widget
  Widget _buildPagination() {
    final totalResults = _filteredLeadData.length;
    final totalOriginalResults = _leadPerformanceData.length;
    final showingText = totalResults > 0
        ? 'Showing 1 to $totalResults of $totalOriginalResults results'
        : 'No results found';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          // Mobile layout - stacked vertically
          return Column(
            children: [
              Text(
                showingText,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: null, // Disabled for first page
                    child: Text(
                      'Previous',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ),
                  SizedBox(width: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(width: 4),
                  TextButton(
                    onPressed: () {},
                    child: Text('2', style: TextStyle(fontSize: 12)),
                  ),
                  SizedBox(width: 4),
                  TextButton(
                    onPressed: () {},
                    child: Text('3', style: TextStyle(fontSize: 12)),
                  ),
                  SizedBox(width: 4),
                  TextButton(
                    onPressed: () {},
                    child: Text('Next', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          );
        } else {
          // Desktop layout - horizontal
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  showingText,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: null, // Disabled for first page
                    child: Text(
                      'Previous',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  TextButton(
                    onPressed: () {},
                    child: Text('2', style: TextStyle(fontSize: 12)),
                  ),
                  SizedBox(width: 8),
                  TextButton(
                    onPressed: () {},
                    child: Text('3', style: TextStyle(fontSize: 12)),
                  ),
                  SizedBox(width: 8),
                  TextButton(
                    onPressed: () {},
                    child: Text('Next', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  // Build time period filter
  Widget _buildTimePeriodFilter() {
    final timePeriods = [
      'Week',
      'Month',
      'Quarter',
      'Semester',
      'Annual',
      'Two Years',
      'Three Years',
      'Five Years',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time Period Label
        Padding(
          padding: EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'Time Period:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        // Time Period Buttons - Horizontal Scroll
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: timePeriods.map((period) {
              final isSelected = _selectedTimePeriod == period;
              return Padding(
                padding: EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    _onTimePeriodChanged(period);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[100] : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      period,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.blue[700] : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
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
              // Header
              _buildHeader(),
              SizedBox(height: 24),

              // Time Period Filter
              _buildTimePeriodFilter(),
              SizedBox(height: 24),

              // Dashboard content
              Expanded(child: _buildDashboardContent()),
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
          // Mobile layout - only search and three dots
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard heading with icon
              Row(
                children: [
                  Icon(Icons.dashboard, color: Colors.grey[800], size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Sales Dashboard',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(width: 12),
                  // Collapsible search bar in same place
                  Expanded(
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
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
                                  decoration: InputDecoration(
                                    hintText: 'Search...',
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
                                });
                              },
                              icon: Icon(Icons.close, color: Colors.grey[600]),
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
                  ),
                  SizedBox(width: 8),
                  // Three dots menu button
                  Container(
                    width: 36,
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
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        // Handle menu selection
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Selected: $value'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'settings',
                          child: Row(
                            children: [
                              Icon(
                                Icons.settings,
                                color: Colors.grey[600],
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text('Settings', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'help',
                          child: Row(
                            children: [
                              Icon(
                                Icons.help,
                                color: Colors.grey[600],
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text('Help', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          // Desktop layout - full header with all controls
          return Row(
            children: [
              // Dashboard heading with icon
              Row(
                children: [
                  Icon(Icons.dashboard, color: Colors.grey[800], size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Sales Dashboard',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),

              Spacer(),

              // Search bar
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: _isSearchExpanded ? 300 : 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (_isSearchExpanded) ...[
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey[400]),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isSearchExpanded = false;
                            _searchController.clear();
                          });
                        },
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                        iconSize: 20,
                      ),
                    ] else ...[
                      Expanded(
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _isSearchExpanded = true;
                            });
                          },
                          icon: Icon(Icons.search, color: Colors.grey[600]),
                          iconSize: 20,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(width: 16),

              // Currency icon button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    // Show currency selection dialog
                    _showCurrencyDialog();
                  },
                  icon: Icon(Icons.attach_money, color: Colors.grey[600]),
                  iconSize: 20,
                ),
              ),

              SizedBox(width: 16),

              // Time period icon button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    // Show time period selection dialog
                    _showTimePeriodDialog();
                  },
                  icon: Icon(Icons.schedule, color: Colors.grey[600]),
                  iconSize: 20,
                ),
              ),

              SizedBox(width: 16),

              // Notification button icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        // Handle notification tap
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Notifications'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(Icons.notifications, color: Colors.grey[600]),
                      iconSize: 20,
                    ),
                    // Notification badge
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 16),

              // Chat button icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        // Handle chat tap
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Chat'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(Icons.chat, color: Colors.grey[600]),
                      iconSize: 20,
                    ),
                    // Chat badge
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildDashboardContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1200) {
          // Desktop layout
          return SingleChildScrollView(
            child: Column(
              children: [
                _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Loading dashboard data...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildDashboardCard(
                              'Total Revenue',
                              _dashboardData['totalRevenue']['value'],
                              _dashboardData['totalRevenue']['percentage'],
                              Icons.attach_money,
                              Colors.blue,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildDashboardCard(
                              'Aluminum Area',
                              _dashboardData['aluminiumArea']['value'],
                              _dashboardData['aluminiumArea']['percentage'],
                              Icons.grid_on,
                              Colors.purple,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildDashboardCard(
                              'Qualified Leads',
                              _dashboardData['qualifiedLeads']['value'],
                              _dashboardData['qualifiedLeads']['percentage'],
                              Icons.people,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildQualifiedAreaVsRevenueChart()),
                    SizedBox(width: 16),
                    Expanded(child: _buildLeadStatusDistributionChart()),
                  ],
                ),
                SizedBox(height: 24),
                _buildLeadPerformanceTable(),
              ],
            ),
          );
        } else {
          // Mobile layout
          return SingleChildScrollView(
            child: Column(
              children: [
                _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Loading dashboard data...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildDashboardCard(
                                  'Qualified Leads',
                                  _dashboardData['qualifiedLeads']['value'],
                                  _dashboardData['qualifiedLeads']['percentage'],
                                  Icons.people,
                                  Colors.orange,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _buildDashboardCard(
                                  'Aluminum Area',
                                  _dashboardData['aluminiumArea']['value'],
                                  _dashboardData['aluminiumArea']['percentage'],
                                  Icons.grid_on,
                                  Colors.purple,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          _buildDashboardCard(
                            'Total Revenue',
                            _dashboardData['totalRevenue']['value'],
                            _dashboardData['totalRevenue']['percentage'],
                            Icons.attach_money,
                            Colors.blue,
                          ),
                        ],
                      ),
                SizedBox(height: 24),
                _buildQualifiedAreaVsRevenueChart(),
                SizedBox(height: 16),
                _buildLeadStatusDistributionChart(),
                SizedBox(height: 24),
                _buildLeadPerformanceTable(),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildDashboardCard(
    String title,
    String value,
    String percentage,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getIsPositive(title)
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  percentage,
                  style: TextStyle(
                    color: _getIsPositive(title) ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildQualifiedAreaVsRevenueChart() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              Icon(Icons.bar_chart, color: Colors.grey[800], size: 20),
              SizedBox(width: 8),
              Text(
                'Revenue by Period',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: _isLoadingChartData
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading chart data...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : _barChartData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No chart data available',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No won leads found for the selected period',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxYValue(),
                      minY: 0,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final labels = _getChartLabels();
                            final label = group.x.toInt() < labels.length
                                ? labels[group.x.toInt()]
                                : '';
                            final value = rod.toY.toStringAsFixed(1);
                            final seriesName = 'Revenue (Cr)';

                            return BarTooltipItem(
                              '$label\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: '$seriesName: $value',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              const style = TextStyle(
                                color: Color(0xff7589a2),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              );
                              final labels = _getChartLabels();
                              if (value.toInt() < labels.length) {
                                final label = labels[value.toInt()];
                                // Truncate long labels to prevent overflow
                                final displayLabel = label.length > 8
                                    ? '${label.substring(0, 8)}...'
                                    : label;
                                return Text(displayLabel, style: style);
                              }
                              return const Text('', style: style);
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: _getYAxisInterval(),
                            getTitlesWidget: (double value, TitleMeta meta) {
                              const style = TextStyle(
                                color: Color(0xff67727d),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              );
                              return Text(
                                _formatYAxisLabel(value),
                                style: style,
                              );
                            },
                            reservedSize: 50,
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: _getGridInterval(),
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[300]!,
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          );
                        },
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      barGroups: _buildBarGroups(),
                    ),
                  ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.pink,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Revenue (Cr)',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to get max Y value for bar chart
  double _getMaxYValue() {
    if (_barChartData.isEmpty) return 10.0;

    double maxValue = 0.0;
    for (var group in _barChartData) {
      for (var bar in group.barRods) {
        if (bar.toY > maxValue) {
          maxValue = bar.toY;
        }
      }
    }
    return (maxValue * 1.4).clamp(10.0, double.infinity); // Add 40% padding
  }

  // Helper method to get grid interval based on max value
  double _getGridInterval() {
    final maxY = _getMaxYValue();
    // Divide maxY by 6 to get 6 grid lines
    return (maxY / 6).ceil().toDouble();
  }

  // Helper method to get Y-axis interval
  double _getYAxisInterval() {
    final maxY = _getMaxYValue();
    // Divide maxY by 6 to get 6 Y-axis labels
    return (maxY / 6).ceil().toDouble();
  }

  // Helper method to format Y-axis labels
  String _formatYAxisLabel(double value) {
    // Since values are now in Crore, format accordingly
    if (value >= 100) {
      return '${(value / 100).toStringAsFixed(1)}Cr';
    } else if (value >= 10) {
      return '${value.toStringAsFixed(1)}Cr';
    } else {
      return '${value.toStringAsFixed(2)}Cr';
    }
  }

  // Build bar groups for the chart
  List<BarChartGroupData> _buildBarGroups() {
    return _barChartData;
  }

  Widget _buildLeadStatusDistributionChart() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              Icon(Icons.pie_chart, color: Colors.grey[800], size: 20),
              SizedBox(width: 8),
              Text(
                'Lead Status Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: _isLoadingLeadStatusData
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading distribution data...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : _leadStatusDistribution.values.every((count) => count == 0)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pie_chart,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No data available',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No leads found for the selected period',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      // Left side legend with percentage and count
                      Expanded(flex: 1, child: _buildLegendWithPercentage()),
                      SizedBox(width: 16),
                      // Right side pie chart
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 200.0,
                          child: SfCircularChart(
                            legend: Legend(isVisible: false),
                            series: <CircularSeries>[
                              PieSeries<ChartData, String>(
                                dataSource: _buildSyncfusionPieChartData(),
                                pointColorMapper: (ChartData data, _) =>
                                    data.color,
                                xValueMapper: (ChartData data, _) => data.x,
                                yValueMapper: (ChartData data, _) => data.y,
                                dataLabelSettings: DataLabelSettings(
                                  isVisible: false,
                                ),
                              ),
                            ],
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

  Widget _buildLegendWithPercentage() {
    final totalLeads = _leadStatusDistribution.values.fold(
      0,
      (sum, count) => sum + count,
    );
    final colors = {
      'Won': Colors.green,
      'Lost': Colors.red,
      'Follow Up': Colors.orange,
    };

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._leadStatusDistribution.entries.map((entry) {
            if (entry.value == 0) return SizedBox.shrink();

            final percentage = totalLeads > 0
                ? (entry.value / totalLeads * 100).toStringAsFixed(1)
                : '0.0';
            final color = colors[entry.key] ?? Colors.grey;

            return Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        SizedBox(height: 2),
                        Text(
                          '$entry.value leads ($percentage%)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class InitializeStatusDialog extends StatefulWidget {
  final String leadId;
  final String projectName;
  final VoidCallback onStatusUpdated;

  const InitializeStatusDialog({
    super.key,
    required this.leadId,
    required this.projectName,
    required this.onStatusUpdated,
  });

  @override
  State<InitializeStatusDialog> createState() => _InitializeStatusDialogState();
}

class _InitializeStatusDialogState extends State<InitializeStatusDialog> {
  String? _selectedStatus;
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _listingDateController = TextEditingController();
  final TextEditingController _qualifiedDateController =
      TextEditingController();
  bool _isSubmitting = false;
  DateTime? _listingDate;
  DateTime? _qualifiedDate;

  @override
  void initState() {
    super.initState();
    _initializeDates();
  }

  Future<void> _initializeDates() async {
    try {
      // Set Qualified Date to current date
      _qualifiedDate = DateTime.now();
      _qualifiedDateController.text = DateFormat(
        'yyyy-MM-dd',
      ).format(_qualifiedDate!);

      // Fetch Listing Date from leads table
      final client = Supabase.instance.client;
      final leadResponse = await client
          .from('leads')
          .select('created_at')
          .eq('id', widget.leadId)
          .single();

      if (leadResponse['created_at'] != null) {
        _listingDate = DateTime.parse(leadResponse['created_at']);
        _listingDateController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(_listingDate!);
      } else {
        // Fallback to current date if created_at is null
        _listingDate = DateTime.now();
        _listingDateController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(_listingDate!);
      }
    } catch (e) {
      debugPrint('Error initializing dates: $e');
      // Set both dates to current date as fallback
      _listingDate = DateTime.now();
      _qualifiedDate = DateTime.now();
      _listingDateController.text = DateFormat(
        'yyyy-MM-dd',
      ).format(_listingDate!);
      _qualifiedDateController.text = DateFormat(
        'yyyy-MM-dd',
      ).format(_qualifiedDate!);
    }
  }

  @override
  void dispose() {
    _remarkController.dispose();
    _listingDateController.dispose();
    _qualifiedDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isListingDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isListingDate
          ? (_listingDate ?? DateTime.now())
          : (_qualifiedDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isListingDate) {
          _listingDate = picked;
          _listingDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _qualifiedDate = picked;
          _qualifiedDateController.text = DateFormat(
            'yyyy-MM-dd',
          ).format(picked);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.flag, color: Colors.blue),
          SizedBox(width: 8),
          Text('Initialize Status'),
          Spacer(),
          // Date input fields on the right side
          Row(
            children: [
              // Listing Date
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _listingDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Listing Date',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today, size: 16),
                      onPressed: () => _selectDate(context, true),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    labelStyle: TextStyle(fontSize: 12),
                  ),
                  style: TextStyle(fontSize: 12),
                ),
              ),
              SizedBox(width: 8),
              // Qualified Date
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _qualifiedDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Qualified Date',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today, size: 16),
                      onPressed: () => _selectDate(context, false),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    labelStyle: TextStyle(fontSize: 12),
                  ),
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project: ${widget.projectName}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select Status:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatusButton(
                    'Won',
                    Colors.green.shade600,
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusButton(
                    'Lost',
                    Colors.red.shade600,
                    Icons.cancel,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusButton(
                    'Follow Up',
                    Colors.orange.shade600,
                    Icons.refresh,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Remark:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _remarkController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter your remark here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          icon: Icon(Icons.cancel, color: Colors.red.shade600, size: 20),
          label: Text(
            'Cancel',
            style: TextStyle(
              color: Colors.red.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting || _selectedStatus == null
              ? null
              : _submitStatus,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(Icons.check_circle, color: Colors.white, size: 20),
          label: Text(
            'Submit',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
            shadowColor: Colors.green.shade600.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusButton(String status, Color color, IconData icon) {
    final isSelected = _selectedStatus == status;

    return _StatusButton(
      status: status,
      color: color,
      icon: icon,
      isSelected: isSelected,
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
    );
  }

  Future<void> _submitStatus() async {
    if (_selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a status'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final client = Supabase.instance.client;

      // Step 1: Get cached user data
      final prefs = await SharedPreferences.getInstance();
      final cachedUserId = prefs.getString('user_id');
      final cachedSessionId = prefs.getString('session_id');
      final cachedSessionActive = prefs.getBool('session_active');
      final cachedUserType = prefs.getString('user_type');

      debugPrint('[CACHE] Cached user_id: $cachedUserId');
      debugPrint('[CACHE] Cached session_id: $cachedSessionId');
      debugPrint('[CACHE] Cached session_active: $cachedSessionActive');
      debugPrint('[CACHE] Cached user_type: $cachedUserType');

      // Step 2: Validate cache data
      if (cachedUserId == null ||
          cachedSessionId == null ||
          cachedSessionActive != true) {
        throw Exception('User not authenticated - invalid cache data');
      }

      // Step 3: Get current username from users table using cached user_id
      final userResponse = await client
          .from('users')
          .select('username')
          .eq('id', cachedUserId)
          .single();

      final currentUsername = userResponse['username'] as String;
      debugPrint(
        '[AUTH] Current username: $currentUsername (ID: $cachedUserId)',
      );

      // Step 4: Get the existing admin_response data to verify authentication and check if record exists
      final leadResponse = await client
          .from('admin_response')
          .select('sales_user, id, lead_id')
          .eq('lead_id', widget.leadId)
          .maybeSingle();

      debugPrint(
        '[AUTH] Checking existing record for lead_id: ${widget.leadId}',
      );

      if (leadResponse != null) {
        final salesUser = leadResponse['sales_user'] as String?;
        final recordId = leadResponse['id'] as String?;
        debugPrint('[AUTH] Sales user from lead: $salesUser');
        debugPrint('[AUTH] Record ID: $recordId');

        // Step 5: Verify that the current user matches the sales user
        if (salesUser != null && salesUser == currentUsername) {
          debugPrint('[AUTH] ✅ User authenticated successfully');
        } else {
          throw Exception(
            'User not authorized to update this lead status. Expected: $salesUser, Current: $currentUsername',
          );
        }
      } else {
        throw Exception(
          'No existing admin_response record found for lead_id: ${widget.leadId}. Please ensure the lead has been processed first.',
        );
      }

      // Step 6: Map status values according to requirements
      String mappedStatus;
      switch (_selectedStatus) {
        case 'Follow Up':
          mappedStatus = 'Negotiation';
          break;
        case 'Lost':
          mappedStatus = 'Closed';
          break;
        case 'Won':
          mappedStatus = 'Completed';
          break;
        default:
          mappedStatus = _selectedStatus!;
      }

      // Step 7: Update the existing admin_response row using the record ID
      final recordId = leadResponse['id'] as String;
      debugPrint(
        '[UPDATE] Updating existing record with ID: $recordId for lead_id: ${widget.leadId}',
      );

      await client
          .from('admin_response')
          .update({
            'update_lead_status': _selectedStatus,
            'status': mappedStatus,
            'lead_status_remark': _remarkController.text.trim(),
            'created_at': _listingDate?.toIso8601String(),
            'updated_at': _qualifiedDate?.toIso8601String(),
          })
          .eq('id', recordId);

      debugPrint('[UPDATE] ✅ Successfully updated existing record');

      debugPrint('✅ Status updated successfully: $_selectedStatus');
      debugPrint('✅ Mapped status: $mappedStatus');
      debugPrint('✅ Remark: ${_remarkController.text.trim()}');
      debugPrint(
        '✅ Listing Date (created_at): ${_listingDate?.toIso8601String()}',
      );
      debugPrint(
        '✅ Qualified Date (updated_at): ${_qualifiedDate?.toIso8601String()}',
      );

      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        widget.onStatusUpdated();
      }
    } catch (e) {
      debugPrint('❌ Error updating status: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}

class _StatusButton extends StatefulWidget {
  final String status;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.status,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_StatusButton> createState() => _StatusButtonState();
}

class _StatusButtonState extends State<_StatusButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          isHovered = false;
        });
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.color.withValues(alpha: 0.2)
                : isHovered
                ? widget.color.withValues(alpha: 0.1)
                : Colors.white,
            border: Border.all(
              color: widget.isSelected
                  ? widget.color
                  : isHovered
                  ? widget.color.withValues(alpha: 0.7)
                  : Colors.grey[300]!,
              width: widget.isSelected
                  ? 2.5
                  : isHovered
                  ? 1.5
                  : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isHovered || widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Icon(
                widget.icon,
                color: widget.isSelected
                    ? widget.color
                    : isHovered
                    ? widget.color.withValues(alpha: 0.9)
                    : widget.color.withValues(alpha: 0.7),
                size: 28,
              ),
              SizedBox(height: 6),
              Text(
                widget.status,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.isSelected || isHovered
                      ? FontWeight.w700
                      : FontWeight.w600,
                  color: widget.isSelected
                      ? widget.color
                      : isHovered
                      ? widget.color.withValues(alpha: 0.9)
                      : widget.color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Alerts Dialog Widget
class AlertsDialog extends StatefulWidget {
  final Map<String, dynamic> lead;

  const AlertsDialog({super.key, required this.lead});

  @override
  State<AlertsDialog> createState() => _AlertsDialogState();
}

class _AlertsDialogState extends State<AlertsDialog> {
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final client = Supabase.instance.client;

      // Fetch alerts for this lead
      final alerts = await client
          .from('queries')
          .select('*')
          .eq('lead_id', widget.lead['lead_id'] ?? widget.lead['id'])
          .order('created_at', ascending: false);

      setState(() {
        _alerts = List<Map<String, dynamic>>.from(alerts);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final date = DateFormat('yyyy-MM-dd').format(dateTime);
      final time = DateFormat('HH:mm:ss').format(dateTime);
      return '$date at $time';
    } catch (e) {
      return dateTimeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Alerts & Queries'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lead: ${widget.lead['project_name'] ?? 'Unknown Project'}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_alerts.isEmpty)
              const Center(
                child: Text(
                  'No alerts or queries found for this lead.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _alerts.length,
                  itemBuilder: (context, index) {
                    final alert = _alerts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'From: ${alert['sender_name'] ?? 'Unknown'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Text(
                                  _formatDateTime(alert['created_at'] ?? ''),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'To: ${alert['receiver_name'] ?? alert['to_username'] ?? 'Unknown'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              alert['query_message'] ??
                                  alert['message'] ??
                                  'No message',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// Helper function to fetch username by user ID
Future<String?> fetchUsernameByUserId(String userId) async {
  final client = Supabase.instance.client;
  try {
    // First try to get from users table
    var user = await client
        .from('users')
        .select('username')
        .eq('id', userId)
        .maybeSingle();

    if (user != null) {
      return user['username'];
    }

    // If not found in users, try dev_user table
    user = await client
        .from('dev_user')
        .select('username')
        .eq('id', userId)
        .maybeSingle();

    return user?['username'];
  } catch (e) {
    return null;
  }
}

// Helper function to fetch all usernames
Future<List<String>> fetchAllUsernames() async {
  final client = Supabase.instance.client;
  try {
    // Fetch from users table
    final users = await client
        .from('users')
        .select('username')
        .not('username', 'is', null);

    // Fetch from dev_user table
    final devUsers = await client
        .from('dev_user')
        .select('username')
        .not('username', 'is', null);

    // Combine and remove duplicates
    final allUsernames = <String>{};
    allUsernames.addAll(users.map((u) => u['username'] as String));
    allUsernames.addAll(devUsers.map((u) => u['username'] as String));

    return allUsernames.toList()..sort();
  } catch (e) {
    return [];
  }
}

// Query Dialog Widget
class QueryDialog extends StatefulWidget {
  final Map<String, dynamic> lead;

  const QueryDialog({super.key, required this.lead});

  @override
  State<QueryDialog> createState() => _QueryDialogState();
}

class _QueryDialogState extends State<QueryDialog> {
  final TextEditingController _messageController = TextEditingController();
  String? _selectedUsername;
  List<String> _usernames = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsernames();
  }

  Future<void> _loadUsernames() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final usernames = await fetchAllUsernames();
      setState(() {
        _usernames = usernames;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitQuery() async {
    if (_selectedUsername == null || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a user and enter a message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final client = Supabase.instance.client;

      // Get current user's username from cache memory
      String? currentUsername;
      try {
        // Step 1: Get cached user data
        final prefs = await SharedPreferences.getInstance();
        final cachedUserId = prefs.getString('user_id');
        final cachedSessionId = prefs.getString('session_id');
        final cachedSessionActive = prefs.getBool('session_active');

        debugPrint('[CACHE] Cached user_id: $cachedUserId');
        debugPrint('[CACHE] Cached session_id: $cachedSessionId');
        debugPrint('[CACHE] Cached session_active: $cachedSessionActive');

        // Step 2: Validate cache data
        if (cachedUserId == null ||
            cachedSessionId == null ||
            cachedSessionActive != true) {
          debugPrint(
            '[CACHE] Invalid cache data, falling back to auth session',
          );

          // Fallback to current auth session
          final currentUser = await client.auth.getUser();
          if (currentUser.user != null) {
            currentUsername = await fetchUsernameByUserId(currentUser.user!.id);
          }
        } else {
          // Step 3: Get username from users table using cached user_id
          final userResponse = await client
              .from('users')
              .select('username')
              .eq('id', cachedUserId)
              .single();

          currentUsername = userResponse['username'] as String;
          debugPrint(
            '[CACHE] Successfully loaded username from cache: $currentUsername (ID: $cachedUserId)',
          );
        }
      } catch (e) {
        debugPrint('Error getting current username: $e');
        currentUsername = 'Unknown User';
      }

      // Insert query into database with all required fields
      await client.from('queries').insert({
        'lead_id': widget.lead['lead_id'] ?? widget.lead['id'],
        'sender_name': currentUsername ?? 'Unknown User',
        'receiver_name': _selectedUsername,
        'to_username': _selectedUsername,
        'query_message': _messageController.text.trim(),
        'message': _messageController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Query sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending query: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Send Query'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lead: ${widget.lead['project_name'] ?? 'Unknown Project'}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select User:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String>(
                value: _selectedUsername,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select a user',
                ),
                items: _usernames.map((username) {
                  return DropdownMenuItem<String>(
                    value: username,
                    child: Text(username),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUsername = value;
                  });
                },
              ),
            const SizedBox(height: 16),
            const Text(
              'Message:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your query message...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitQuery,
          child: const Text('Send Query'),
        ),
      ],
    );
  }
}
