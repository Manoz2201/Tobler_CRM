// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; // Added for jsonEncode
import 'package:crm_app/widgets/profile_page.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/navigation_utils.dart';
import '../auth/login_screen.dart';
import '../../main.dart'
    show
        updateUserSessionActiveMCP,
        updateUserOnlineStatusMCP,
        updateUserOnlineStatusByEmailMCP,
        setUserOnlineStatus;

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

class ProposalHomeScreen extends StatefulWidget {
  final String? currentUserId;
  const ProposalHomeScreen({super.key, this.currentUserId});

  @override
  State<ProposalHomeScreen> createState() => _ProposalHomeScreenState();
}

class _ProposalHomeScreenState extends State<ProposalHomeScreen> {
  int _selectedIndex = 0;
  bool _isCollapsed = false;
  final Map<int, bool> _hoveredItems = {};

  List<NavItem> get _navItems {
    return NavigationUtils.getNavigationItemsForRole('proposal engineer');
  }

  late final List<Widget> _pages = <Widget>[
    ProposalDashboardScreen(currentUserId: widget.currentUserId),
    ProposalScreen(currentUserId: widget.currentUserId),
    const Center(child: Text('Clients List')),
    const Center(child: Text('Reports')),
    const Center(child: Text('Chat')),
    ProfilePage(currentUserId: widget.currentUserId ?? ''),
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

  Widget _buildMobileNavigationBar() {
    return Container(
      height: 55,
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 55,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / _navItems.length;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _navItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isSelected = _selectedIndex == index;
                    return _buildMobileNavItem(
                      item,
                      index,
                      isSelected,
                      itemWidth,
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMobileNavItem(
    NavItem item,
    int index,
    bool isSelected,
    double width,
  ) {
    final isHovered = _hoveredItems[index] ?? false;

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 1, vertical: 1),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredItems[index] = true),
        onExit: (_) => setState(() => _hoveredItems[index] = false),
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[50] : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: isSelected
                  ? Border.all(color: Colors.blue[300]!, width: 1)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? Colors.blue[600] : Colors.grey[600],
                  size: 18,
                ),
                if (isHovered || isSelected) ...[
                  Flexible(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 7,
                        color: isSelected ? Colors.blue[600] : Colors.grey[600],
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavBar(double screenHeight, double screenWidth) {
    return Container(
      width: _isCollapsed ? 80 : 280,
      height: screenHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
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
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        if (isWide) {
          // Web/tablet/desktop layout with sidebar
          return Scaffold(
            body: Row(
              children: [
                _buildNavBar(screenHeight, screenWidth),
                Expanded(
                  child: _pages[_selectedIndex],
                ),
              ],
            ),
          );
        } else {
          // Mobile layout with bottom nav
          return Scaffold(
            body: _pages[_selectedIndex],
            bottomNavigationBar: _buildMobileNavigationBar(),
          );
        }
      },
    );
  }
}

class ProposalScreen extends StatefulWidget {
  final String? currentUserId;
  const ProposalScreen({super.key, this.currentUserId});

  @override
  State<ProposalScreen> createState() => _ProposalScreenState();
}

class _ProposalScreenState extends State<ProposalScreen> {
  final List<Map<String, String>> proposals = [
    {'title': 'Proposal A', 'client': 'Client X', 'status': 'Draft'},
    {'title': 'Proposal B', 'client': 'Client Y', 'status': 'Submitted'},
    {'title': 'Proposal C', 'client': 'Client Z', 'status': 'Approved'},
  ];

  List<Map<String, dynamic>> _inquiries = [];
  List<Map<String, dynamic>> _submittedInquiries = [];
  String? _selectedStatusFilter;
  final Map<String, bool> _hoveredRows = {};
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final inquiries = await _fetchLeadsWithoutProposals();
      final submittedInquiries = await _fetchLeadsWithProposals();
      
      setState(() {
        _inquiries = inquiries;
        _submittedInquiries = submittedInquiries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading data: $e');
    }
  }





  Future<List<Map<String, dynamic>>> _fetchLeadsWithoutProposals() async {
    final client = Supabase.instance.client;

    // Get all monolithic leads
    final allLeads = await client
        .from('leads')
        .select(
          'id, client_name, project_name, project_location, created_at, remark, main_contact_name, main_contact_email, main_contact_mobile, lead_generated_by',
        )
        .eq('lead_type', 'Monolithic Formwork')
        .order('created_at', ascending: false);

    // Get leads that have proposals
    final leadsWithProposals = await client
        .from('proposal_file')
        .select('lead_id')
        .not('lead_id', 'is', null);

    final submittedLeadIds = leadsWithProposals
        .map((p) => p['lead_id'])
        .toSet();

    // Filter out leads that have proposals
    final leadsWithoutProposals = allLeads
        .where((lead) => !submittedLeadIds.contains(lead['id']))
        .toList();

    // Fetch usernames for each lead
    final leadsWithUsernames = await Future.wait(
      leadsWithoutProposals.map((lead) async {
        final username = await fetchUsernameByUserId(
          lead['lead_generated_by'] ?? '',
        );
        return {...lead, 'username': username ?? 'Unknown User'};
      }),
    );

    return List<Map<String, dynamic>>.from(leadsWithUsernames);
  }

  Future<List<Map<String, dynamic>>> _fetchLeadsWithProposals() async {
    final client = Supabase.instance.client;

    // Get leads that have proposals
    final leadsWithProposals = await client
        .from('proposal_file')
        .select('lead_id')
        .not('lead_id', 'is', null);

    final submittedLeadIds = leadsWithProposals
        .map((p) => p['lead_id'])
        .toSet();

    if (submittedLeadIds.isEmpty) {
      return [];
    }

    // Get the full lead details for leads with proposals
    final leadsData = await client
        .from('leads')
        .select(
          'id, client_name, project_name, project_location, created_at, remark, main_contact_name, main_contact_email, main_contact_mobile, lead_generated_by',
        )
        .inFilter('id', submittedLeadIds.toList())
        .order('created_at', ascending: false);

    // Fetch usernames for each lead
    final leadsWithUsernames = await Future.wait(
      leadsData.map((lead) async {
        final username = await fetchUsernameByUserId(
          lead['lead_generated_by'] ?? '',
        );
        return {...lead, 'username': username ?? 'Unknown User'};
      }),
    );

    return List<Map<String, dynamic>>.from(leadsWithUsernames);
  }



  Future<List<Map<String, dynamic>>> _fetchSubmittedProposals(
    String leadId,
  ) async {
    final client = Supabase.instance.client;

    // Fetch proposal files
    final files = await client
        .from('proposal_file')
        .select('*')
        .eq('lead_id', leadId);

    // Fetch proposal inputs
    final inputs = await client
        .from('proposal_input')
        .select('*')
        .eq('lead_id', leadId);

    // Fetch proposal remarks
    final remarks = await client
        .from('proposal_remark')
        .select('*')
        .eq('lead_id', leadId);

    return [
      ...files.map((f) => {...f, 'type': 'file'}),
      ...inputs.map((i) => {...i, 'type': 'input'}),
      ...remarks.map((r) => {...r, 'type': 'remark'}),
    ];
  }

  void _showAlertsDialog(BuildContext context, Map<String, dynamic> lead) {
    showDialog(
      context: context,
      builder: (context) => AlertsDialog(lead: lead),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildInquiriesContent(context),
    );
  }

  Widget _buildInquiriesContent(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }



    if (isWide) {
      // Desktop/Tablet layout
      return Column(
        children: [
          // Header with stats and refresh
          _buildHeader(context, 'Inquiries', _filteredData.length),
          // Stats cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildStatsCards(),
          ),
          // Table
          Expanded(
            child: _buildTable(context, _filteredData),
          ),
        ],
      );
    } else {
      // Mobile layout
      return Column(
        children: [
          // Mobile header
          _buildMobileHeader(context, 'Inquiries', _filteredData.length),
          // Mobile stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildMobileStatsCards(),
          ),
          // Mobile list
          Expanded(
            child: _buildMobileList(context, _filteredData),
          ),
        ],
      );
    }
  }

  Widget _buildHeader(BuildContext context, String title, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment, size: 24, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                  fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  '$count inquiries',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                ],
              ),
            ),
          // Search Bar
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search inquiries...',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context, String title, int count) {
    return Container(
            padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
              Icon(Icons.assignment, size: 24, color: Colors.blue[700]),
              const SizedBox(width: 8),
                          Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Mobile Search Bar
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search inquiries...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count inquiries',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          // Mobile stats cards
          _buildMobileStatsCards(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalInquiries = _inquiries.length + _submittedInquiries.length;
    final pendingInquiries = _inquiries.length;
    final submittedInquiries = _getSubmittedCount();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Inquiries',
            totalInquiries.toString(),
            Icons.assignment,
            Colors.blue,
            null,
            onTap: () => _onStatusFilterChanged(null), // Show all
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Pending',
            pendingInquiries.toString(),
            Icons.pending,
            Colors.orange,
            'Pending',
            onTap: () => _onStatusFilterChanged('Pending'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Submitted',
            submittedInquiries.toString(),
            Icons.check_circle,
            Colors.green,
            'Submitted',
            onTap: () => _onStatusFilterChanged('Submitted'),
          ),
        ),
      ],
    );
  }

  int _getSubmittedCount() {
    // Return the count of submitted inquiries
    return _submittedInquiries.length;
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String? statusFilter,
    {VoidCallback? onTap}
  ) {
    final isSelected = _selectedStatusFilter == statusFilter;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: color, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
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
                      const SizedBox(height: 4),
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
    final totalInquiries = _inquiries.length;
    final pendingInquiries = _inquiries.length;
    final submittedInquiries = _getSubmittedCount();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMobileStatCard(
                'Total',
                totalInquiries.toString(),
                Icons.assignment,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMobileStatCard(
                'Pending',
                pendingInquiries.toString(),
                Icons.pending,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMobileStatCard(
                'Submitted',
                submittedInquiries.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
                                const SizedBox(height: 4),
                                Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
                                Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<Map<String, dynamic>> data) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Results count
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
                        child: Row(
                          children: [
                Expanded(
                  child: Text(
                    '${data.length} inquiries',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
          // Table Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: const Text(
                      'Client/Date',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: const Text(
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
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: const Text(
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
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: const Text(
                      'Added By',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: const Text(
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
              itemCount: data.length,
              itemBuilder: (context, index) {
                final inquiry = data[index];
                return _buildTableRow(inquiry, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> inquiry, int index) {
    final inquiryId = inquiry['id'].toString();
    final date = inquiry['created_at'] != null
        ? DateFormat('dd-MM-yyyy').format(DateTime.parse(inquiry['created_at']))
                  : '-';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: (index % 2 == 0 ? Colors.white : Colors.grey[50]),
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _viewInquiryDetails(inquiry),
            onHover: (isHovered) {
              setState(() {
                _hoveredRows[inquiryId] = isHovered;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                    children: [
                  // Client/Date
                              Expanded(
                    flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                        Text(
                          inquiry['client_name'] ?? 'N/A',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                                          ),
                          overflow: TextOverflow.ellipsis,
                                        ),
                        const SizedBox(height: 4),
                                        Text(
                          date,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                  ),
                  // Project
                  Expanded(
                    flex: 2,
                    child: Text(
                      inquiry['project_name'] ?? 'N/A',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Location
                  Expanded(
                    flex: 1,
                    child: Text(
                      inquiry['project_location'] ?? 'N/A',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Added By
                  Expanded(
                    flex: 1,
                    child: Text(
                      inquiry['username'] ?? 'Unknown',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Actions
                  Expanded(
                    flex: 2,
                        child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        IconButton(
                          onPressed: () => _showAlertsDialog(context, inquiry),
                          icon: const Icon(Icons.notifications, color: Colors.red),
                                tooltip: 'Alert',
                        ),
                        IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                              builder: (context) => QueryDialog(lead: inquiry),
                                  );
                                },
                          icon: const Icon(Icons.chat, color: Colors.orange),
                                tooltip: 'Query',
                        ),
                        // Show different action based on whether inquiry is submitted or pending
                        if (_isSubmittedInquiry(inquiry))
                          ElevatedButton(
                            onPressed: () => _viewSubmittedProposal(context, inquiry),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: const Text('View'),
                          )
                        else
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => ProposalResponseDialog(
                                  lead: inquiry,
                                    currentUserId: widget.currentUserId,
                                  ),
                                );
                              },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                              child: const Text('Propose'),
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
    );
  }

  Widget _buildMobileList(BuildContext context, List<Map<String, dynamic>> data) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final inquiry = data[index];
        return _buildMobileCard(inquiry, index);
      },
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> inquiry, int index) {
    final date = inquiry['created_at'] != null
        ? DateFormat('dd-MM-yyyy').format(DateTime.parse(inquiry['created_at']))
                : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        padding: const EdgeInsets.all(16),
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
                        inquiry['client_name'] ?? 'N/A',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                      const SizedBox(height: 4),
                      Text(
                        inquiry['project_name'] ?? 'N/A',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                    Text(
                      date,
                            style: TextStyle(
                        color: Colors.blue[600],
                              fontWeight: FontWeight.bold,
                        fontSize: 12,
                            ),
                          ),
                    const SizedBox(height: 4),
                          Text(
                      inquiry['username'] ?? 'Unknown',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
            Text(
              inquiry['project_location'] ?? 'N/A',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                IconButton(
                  onPressed: () => _showAlertsDialog(context, inquiry),
                  icon: const Icon(Icons.notifications, color: Colors.red),
                  tooltip: 'Alert',
                ),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => QueryDialog(lead: inquiry),
                    );
                  },
                  icon: const Icon(Icons.chat, color: Colors.orange),
                  tooltip: 'Query',
                ),
                                    Expanded(
                  child: ElevatedButton(
                    onPressed: () => _viewSubmittedProposal(context, inquiry),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('View'),
                                        ),
                                      ),
                                  ],
                                ),
          ],
        ),
      ),
    );
  }

  void _viewInquiryDetails(Map<String, dynamic> inquiry) {
    // Implement inquiry details view
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Inquiry Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
            Text('Client: ${inquiry['client_name']}'),
            Text('Project: ${inquiry['project_name']}'),
            Text('Location: ${inquiry['project_location']}'),
            Text('Added by: ${inquiry['username']}'),
            if (inquiry['remark'] != null) Text('Remark: ${inquiry['remark']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }



  // Helper function to fetch lead activity
  Future<List<Map<String, dynamic>>> fetchLeadActivity(String leadId) async {
    final client = Supabase.instance.client;
    try {
      final activities = await client
          .from('lead_activity')
          .select('*')
          .eq('lead_id', leadId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(activities);
    } catch (e) {
      debugPrint('Error fetching lead activity: $e');
      return [];
    }
  }

  // Helper function to log lead activity
  Future<void> logLeadActivity({
    required String leadId,
    required String userId,
    required String activityType,
    required Map<String, dynamic> changesMade,
  }) async {
    final client = Supabase.instance.client;
    try {
      await client.from('lead_activity').insert({
        'lead_id': leadId,
        'user_id': userId,
        'activity_type': activityType,
        'changes_made': jsonEncode(changesMade),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging lead activity: $e');
    }
  }

  void _onStatusFilterChanged(String? status) {
    setState(() {
      _selectedStatusFilter = status;
    });
  }

  List<Map<String, dynamic>> get _filteredData {
    List<Map<String, dynamic>> baseData;
    
    if (_selectedStatusFilter == null) {
      // Show all data (pending + submitted)
      baseData = [..._inquiries, ..._submittedInquiries];
    } else if (_selectedStatusFilter == 'Pending') {
      // Show only pending inquiries
      baseData = _inquiries;
    } else if (_selectedStatusFilter == 'Submitted') {
      // Show only submitted inquiries
      baseData = _submittedInquiries;
    } else {
      baseData = [];
    }

    // Apply search filter if query is not empty
    if (_searchQuery.isNotEmpty) {
      baseData = baseData.where((inquiry) {
        // Search in all relevant fields
        final clientName = inquiry['client_name']?.toString().toLowerCase() ?? '';
        final projectName = inquiry['project_name']?.toString().toLowerCase() ?? '';
        final projectLocation = inquiry['project_location']?.toString().toLowerCase() ?? '';
        final username = inquiry['username']?.toString().toLowerCase() ?? '';
        final remark = inquiry['remark']?.toString().toLowerCase() ?? '';
        final mainContactName = inquiry['main_contact_name']?.toString().toLowerCase() ?? '';
        final mainContactEmail = inquiry['main_contact_email']?.toString().toLowerCase() ?? '';
        final mainContactMobile = inquiry['main_contact_mobile']?.toString().toLowerCase() ?? '';
        
        return clientName.contains(_searchQuery) ||
               projectName.contains(_searchQuery) ||
               projectLocation.contains(_searchQuery) ||
               username.contains(_searchQuery) ||
               remark.contains(_searchQuery) ||
               mainContactName.contains(_searchQuery) ||
               mainContactEmail.contains(_searchQuery) ||
               mainContactMobile.contains(_searchQuery);
      }).toList();
    }

    return baseData;
  }

  bool _isSubmittedInquiry(Map<String, dynamic> inquiry) {
    // Check if this inquiry is in the submitted list
    return _submittedInquiries.any((submitted) => submitted['id'] == inquiry['id']);
  }

  Future<void> _viewSubmittedProposal(BuildContext context, Map<String, dynamic> inquiry) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Fetch submitted proposal data as per PROPOSAL_FUNCTION_FLOW.md
      final proposalData = await _fetchSubmittedProposals(inquiry['id'].toString());
      
      // Close loading dialog
      Navigator.of(context).pop();

      // Show proposal details dialog
      showDialog(
        context: context,
        builder: (context) => SubmittedProposalDialog(
          inquiry: inquiry,
          proposalData: proposalData,
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading proposal: $e')),
      );
    }
  }
}

class ProposalResponseDialog extends StatefulWidget {
  final Map<String, dynamic> lead;
  final String? currentUserId;
  const ProposalResponseDialog({
    super.key,
    required this.lead,
    this.currentUserId,
  });

  @override
  State<ProposalResponseDialog> createState() => _ProposalResponseDialogState();
}

class _ProposalResponseDialogState extends State<ProposalResponseDialog> {
  List<Map<String, TextEditingController>> files = [];
  List<Map<String, TextEditingController>> inputs = [];
  final TextEditingController remarkController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> otherContacts = [];
  List<Map<String, dynamic>> attachments = [];

  @override
  void initState() {
    super.initState();
    _addFile();
    _addInput();
    _fetchOtherContacts();
    _fetchAttachments();
  }

  void _addFile() {
    files.add({
      'fileName': TextEditingController(),
      'fileLink': TextEditingController(),
    });
    setState(() {});
  }

  void _removeFile(int i) {
    if (files.length > 1) {
      files.removeAt(i);
      setState(() {});
    }
  }

  void _addInput() {
    inputs.add({
      'input': TextEditingController(),
      'value': TextEditingController(),
      'remark': TextEditingController(),
    });
    setState(() {});
  }

  void _removeInput(int i) {
    if (inputs.length > 1) {
      inputs.removeAt(i);
      setState(() {});
    }
  }

  Future<void> _fetchOtherContacts() async {
    final client = Supabase.instance.client;
    final data = await client
        .from('lead_contacts')
        .select('*')
        .eq('lead_id', widget.lead['id']);
    setState(() {
      otherContacts = List<Map<String, dynamic>>.from(data);
    });
  }

  Future<void> _fetchAttachments() async {
    final client = Supabase.instance.client;
    final data = await client
        .from('lead_attachments')
        .select('*')
        .eq('lead_id', widget.lead['id']);
    setState(() {
      attachments = List<Map<String, dynamic>>.from(data);
    });
  }

  Future<void> _saveProposal() async {
    setState(() {
      _isLoading = true;
    });

    final client = Supabase.instance.client;

    // Step 1: Check cache memory for active user and user_id
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
      debugPrint('[CACHE] Invalid or missing cache data');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please log in again.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Step 3: Verify user exists and is active in database
    var userData = await client
        .from('users')
        .select('id, session_id, session_active, user_type')
        .eq('id', cachedUserId)
        .maybeSingle();

    debugPrint('[SUPABASE] Users table lookup result: $userData');

    if (userData == null) {
      // Try dev_user table
      userData = await client
          .from('dev_user')
          .select('id, session_id, session_active, user_type')
          .eq('id', cachedUserId)
          .maybeSingle();

      debugPrint('[SUPABASE] Dev_user table lookup result: $userData');
    }

    // Step 4: Validate user is active and session matches
    if (userData == null) {
      debugPrint('[VALIDATION] User not found in database');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found. Please log in again.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final isActive = userData['session_active'] == true;
    final sessionMatches = userData['session_id'] == cachedSessionId;

    debugPrint(
      '[VALIDATION] User active: $isActive, Session matches: $sessionMatches',
    );

    if (!isActive || !sessionMatches) {
      debugPrint('[VALIDATION] User not active or session mismatch');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session invalid. Please log in again.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Step 5: Use cached user ID for operations
    final currentUserId = cachedUserId;
    debugPrint('[VALIDATION] Using cached user_id: $currentUserId');
    final leadId = widget.lead['id'];

    try {
      // Save files
      for (final file in files) {
        final fileName = file['fileName']!.text.trim();
        final fileLink = file['fileLink']!.text.trim();

        if (fileName.isNotEmpty || fileLink.isNotEmpty) {
          await client.from('proposal_file').insert({
            'lead_id': leadId,
            'file_name': fileName,
            'file_link': fileLink,
            'user_id': currentUserId,
          });
        }
      }
      // Save inputs
      for (final input in inputs) {
        if (input['input']!.text.trim().isNotEmpty) {
          await client.from('proposal_input').insert({
            'lead_id': leadId,
            'input': input['input']!.text.trim(),
            'value': input['value']!.text.trim(),
            'remark': input['remark']!.text.trim(),
            'user_id': currentUserId,
          });
        }
      }
      // Save remark
      if (remarkController.text.trim().isNotEmpty) {
        await client.from('proposal_remark').insert({
          'lead_id': leadId,
          'remark': remarkController.text.trim(),
          'user_id': currentUserId,
        });
      }

      // Calculate sum of Area values and average of MS Wt. values
      double aluminiumArea = 0.0;
      double msWeightTotal = 0.0;
      int msWeightCount = 0;

      for (final input in inputs) {
        if (input['input']!.text.trim().isNotEmpty) {
          final inputType = input['input']!.text.trim();
          final value = double.tryParse(input['value']!.text.trim()) ?? 0.0;

          if (inputType == 'Area') {
            aluminiumArea += value;
          } else if (inputType == 'MS Wt.') {
            msWeightTotal += value;
            msWeightCount++;
          }
        }
      }

      double msWeight = msWeightCount > 0 ? msWeightTotal / msWeightCount : 0.0;

      // Insert into admin_response table
      await client.from('admin_response').insert({
        'lead_id': leadId,
        'aluminium_area': aluminiumArea,
        'ms_weight': msWeight,
        'created_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        _isLoading = false;
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Proposal submitted!')));
      await logLeadActivity(
        leadId: leadId,
        userId: currentUserId,
        activityType: 'proposal_submitted',
        changesMade: {
          'files': files
              .where(
                (file) =>
                    file['fileName']!.text.trim().isNotEmpty ||
                    file['fileLink']!.text.trim().isNotEmpty,
              )
              .map(
                (file) => {
                  'file_name': file['fileName']!.text.trim(),
                  'file_link': file['fileLink']!.text.trim(),
                },
              )
              .toList(),
          'inputs': inputs
              .where((input) => input['input']!.text.trim().isNotEmpty)
              .map(
                (input) => {
                  'input': input['input']!.text.trim(),
                  'value': input['value']!.text.trim(),
                  'unit': input['unit']!.text.trim(),
                },
              )
              .toList(),
          'remark': remarkController.text.trim(),
        },
      );
    } catch (e) {
      debugPrint('Error saving proposal: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving proposal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width > 1200 ? 1000 : 
               MediaQuery.of(context).size.width > 800 ? 800 : 
               MediaQuery.of(context).size.width - 32,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.description, color: Colors.blue[700], size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Submit Proposal',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          '${lead['client_name']} - ${lead['project_name']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
                  return isWide
                ? Row(
                    children: [
                      // Left: Lead info
                      Expanded(
                        flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: Colors.grey[200]!),
                                  ),
                                ),
                        child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(24),
                          child: _ProposalLeadInfoSection(
                            lead: lead,
                            otherContacts: otherContacts,
                            attachments: attachments,
                          ),
                        ),
                      ),
                            ),
                      // Right: Proposal Response
                      Expanded(
                        flex: 3,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                          child: _ProposalResponseForm(
                            files: files,
                            inputs: inputs,
                            remarkController: remarkController,
                            isLoading: _isLoading,
                            onAddFile: _addFile,
                            onRemoveFile: _removeFile,
                            onAddInput: _addInput,
                            onRemoveInput: _removeInput,
                            onSave: _saveProposal,
                          ),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProposalLeadInfoSection(
                          lead: lead,
                          otherContacts: otherContacts,
                          attachments: attachments,
                        ),
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 24),
                        _ProposalResponseForm(
                          files: files,
                          inputs: inputs,
                          remarkController: remarkController,
                          isLoading: _isLoading,
                          onAddFile: _addFile,
                          onRemoveFile: _removeFile,
                          onAddInput: _addInput,
                          onRemoveInput: _removeInput,
                          onSave: _saveProposal,
                        ),
                      ],
                  ),
          );
        },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add this helper function to ProposalResponseDialog (or a shared utils file)
Future<void> logLeadActivity({
  required String leadId,
  required String userId,
  required String activityType,
  required dynamic changesMade, // can be String or Map
}) async {
  final client = Supabase.instance.client;
  await client.from('lead_activity').insert({
    'lead_id': leadId,
    'user_id': userId,
    'activity_type': activityType,
    'changes_made': changesMade is String
        ? changesMade
        : jsonEncode(changesMade),
    'created_at': DateTime.now().toIso8601String(),
  });
}

// Add this method to fetch activity logs for a lead
Future<List<Map<String, dynamic>>> fetchLeadActivity(String leadId) async {
  final client = Supabase.instance.client;
  final data = await client
      .from('lead_activity')
      .select('*')
      .eq('lead_id', leadId)
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(data);
}

// Responsive Lead Info Section
class _ProposalLeadInfoSection extends StatelessWidget {
  final Map<String, dynamic> lead;
  final List<Map<String, dynamic>> otherContacts;
  final List<Map<String, dynamic>> attachments;
  const _ProposalLeadInfoSection({
    required this.lead,
    required this.otherContacts,
    required this.attachments,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.info, color: Colors.green[700], size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Lead Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Lead Details Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Client Name', lead['client_name'] ?? 'N/A'),
              const SizedBox(height: 12),
              _buildInfoRow('Project Name', lead['project_name'] ?? 'N/A'),
              const SizedBox(height: 12),
              _buildInfoRow('Project Location', lead['project_location'] ?? 'N/A'),
              const SizedBox(height: 12),
              _buildInfoRow('Date', lead['created_at'] != null
                  ? DateFormat('dd-MM-yyyy').format(DateTime.parse(lead['created_at']))
                  : 'N/A'),
              const SizedBox(height: 12),
              _buildInfoRow('Added By', lead['username'] ?? 'Unknown User'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Remarks Section
        if (lead['remark'] != null && lead['remark'].toString().isNotEmpty) ...[
          _buildSectionHeader('Remarks', Icons.comment),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Text(
              lead['remark'],
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        
        // Attachments Section
        if (attachments.isNotEmpty) ...[
          _buildSectionHeader('Lead Attachments', Icons.attach_file),
          const SizedBox(height: 12),
          ...attachments.map((attachment) => _buildAttachmentCard(attachment)),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
            value,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
            ),
                ),
              ),
            ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[600], size: 18),
        const SizedBox(width: 8),
          Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentCard(Map<String, dynamic> attachment) {
    return Builder(
      builder: (context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.blue[600], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    attachment['file_name'] ?? 'Unnamed File',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            if ((attachment['file_link'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                        final url = attachment['file_link'] ?? '';
                              if (url.isNotEmpty) {
                                try {
                                  await launchUrl(Uri.parse(url));
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                content: Text('Could not open link: $url'),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text(
                        attachment['file_link'] ?? '',
                        style: TextStyle(
                          color: Colors.blue[600],
                                decoration: TextDecoration.underline,
                          fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                    icon: Icon(Icons.copy, size: 16, color: Colors.grey[600]),
                          onPressed: () {
                            Clipboard.setData(
                        ClipboardData(text: attachment['file_link'] ?? ''),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied to clipboard')),
                            );
                          },
                          tooltip: 'Copy link',
                        ),
                      ],
                    ),
                ],
        ],
        ),
      ),
    );
  }
}

// Responsive Proposal Response Form Section
class _ProposalResponseForm extends StatefulWidget {
  final List<Map<String, TextEditingController>> files;
  final List<Map<String, TextEditingController>> inputs;
  final TextEditingController remarkController;
  final bool isLoading;
  final VoidCallback onAddFile;
  final void Function(int) onRemoveFile;
  final VoidCallback onAddInput;
  final void Function(int) onRemoveInput;
  final VoidCallback onSave;

  const _ProposalResponseForm({
    required this.files,
    required this.inputs,
    required this.remarkController,
    required this.isLoading,
    required this.onAddFile,
    required this.onRemoveFile,
    required this.onAddInput,
    required this.onRemoveInput,
    required this.onSave,
  });

  @override
  State<_ProposalResponseForm> createState() => _ProposalResponseFormState();
}

class _ProposalResponseFormState extends State<_ProposalResponseForm> {
  // Calculate total Area values
  String _calculateAreaTotal() {
    double total = 0.0;
    for (final input in widget.inputs) {
      if (input['input']?.text == 'Area' &&
          input['value']?.text.isNotEmpty == true) {
        final value = double.tryParse(input['value']!.text) ?? 0.0;
        total += value;
      }
    }
    return total.toStringAsFixed(2);
  }

  // Calculate average MS Wt. values
  String _calculateMSWeightAverage() {
    double total = 0.0;
    int count = 0;
    for (final input in widget.inputs) {
      if (input['input']?.text == 'MS Wt.' &&
          input['value']?.text.isNotEmpty == true) {
        final value = double.tryParse(input['value']!.text) ?? 0.0;
        total += value;
        count++;
      }
    }
    return count > 0 ? (total / count).toStringAsFixed(2) : '0.00';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.edit_note, color: Colors.blue[700], size: 20),
            ),
            const SizedBox(width: 12),
            Text(
          'Proposal Response',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Files Section
        _buildSectionHeader('Files & Documents', Icons.attach_file),
        const SizedBox(height: 16),
        _buildFilesSection(),
        const SizedBox(height: 24),
        
        // Inputs Section
        _buildSectionHeader('Technical Specifications', Icons.settings),
        const SizedBox(height: 16),
        _buildInputsSection(),
        const SizedBox(height: 24),
        
        // Calculations Section
        _buildCalculationsSection(),
        const SizedBox(height: 24),
        
        // Remarks Section
        _buildSectionHeader('General Remarks', Icons.comment),
        const SizedBox(height: 16),
        _buildRemarksSection(),
        const SizedBox(height: 32),
        
        // Action Buttons
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[600], size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildFilesSection() {
    return Column(
      children: [
        ...List.generate(
          widget.files.length,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
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
                    Text(
                      'File ${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Spacer(),
                    if (widget.files.length > 1)
                      IconButton(
                        onPressed: () => widget.onRemoveFile(i),
                        icon: Icon(Icons.remove_circle, color: Colors.red[400], size: 20),
                        tooltip: 'Remove file',
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                          children: [
                    Expanded(
                              child: TextField(
                                controller: widget.files[i]['fileName'],
                        decoration: InputDecoration(
                          labelText: 'File Name',
                          hintText: 'e.g., Proposal.pdf, Quote.docx',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                              child: TextField(
                                controller: widget.files[i]['fileLink'],
                        decoration: InputDecoration(
                          labelText: 'File Link/URL',
                          hintText: 'https://drive.google.com/...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.onAddFile,
            icon: Icon(Icons.add, color: Colors.blue[600]),
            label: Text(
              'Add Another File',
              style: TextStyle(color: Colors.blue[600]),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
                          ],
    );
  }

  Widget _buildInputsSection() {
    return Column(
      children: [
        ...List.generate(
          widget.inputs.length,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
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
                    Text(
                      'Input ${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Spacer(),
                    if (widget.inputs.length > 1)
                      IconButton(
                        onPressed: () => widget.onRemoveInput(i),
                        icon: Icon(Icons.remove_circle, color: Colors.red[400], size: 20),
                        tooltip: 'Remove input',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: TextField(
                        controller: widget.inputs[i]['input'],
                        decoration: InputDecoration(
                          labelText: 'Input Type',
                          hintText: 'e.g., Area, MS Wt., Length',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                            Expanded(
                      child: TextField(
                        controller: widget.inputs[i]['value'],
                        decoration: InputDecoration(
                          labelText: 'Value',
                          hintText: 'Enter numeric value',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                                controller: widget.inputs[i]['remark'],
                  decoration: InputDecoration(
                    labelText: 'Remark (Optional)',
                    hintText: 'Additional notes for this input',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.onAddInput,
            icon: Icon(Icons.add, color: Colors.blue[600]),
            label: Text(
              'Add Another Input',
              style: TextStyle(color: Colors.blue[600]),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
                          ],
    );
  }

  Widget _buildCalculationsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Calculations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCalculationCard(
                  'Total Area',
                  _calculateAreaTotal(),
                  'sq.m',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCalculationCard(
                  'Avg MS Weight',
                  _calculateMSWeightAverage(),
                  'kg',
                  Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }

  Widget _buildCalculationCard(String title, String value, String unit, Color color) {
    return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
        color: Colors.white,
            borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksSection() {
    return TextField(
      controller: widget.remarkController,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: 'General Remarks',
        hintText: 'Enter any additional remarks or notes for this proposal...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.isLoading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : widget.onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
              child: widget.isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Submitting...'),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, size: 18),
                      const SizedBox(width: 8),
                      const Text('Submit Proposal'),
                    ],
            ),
          ),
        ),
      ],
    );
  }
}

Widget glassCard({
  required Widget child,
  EdgeInsetsGeometry? margin,
  EdgeInsetsGeometry? padding,
}) {
  return Container(
    margin: margin ?? const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
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
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((0.15 * 255).round()),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: padding ?? const EdgeInsets.all(20.0),
          child: child,
        ),
      ),
    ),
  );
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

      // Get current user's username
      String? currentUsername;
      try {
        final currentUser = await client.auth.getUser();
        if (currentUser.user != null) {
          currentUsername = await fetchUsernameByUserId(currentUser.user!.id);
        }
      } catch (e) {
        currentUsername = 'Unknown User';
      }

      // Insert query into database with all required fields
      await client.from('queries').insert({
        'lead_id': widget.lead['id'],
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
          .eq('lead_id', widget.lead['id'])
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



class SubmittedProposalDialog extends StatelessWidget {
  final Map<String, dynamic> inquiry;
  final List<Map<String, dynamic>> proposalData;

  const SubmittedProposalDialog({
    super.key,
    required this.inquiry,
    required this.proposalData,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Submitted Proposal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        Text(
                          '${inquiry['client_name']} - ${inquiry['project_name']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Lead Information
                    _buildSection('Lead Information', Icons.info),
                    _buildInfoRow('Client', inquiry['client_name'] ?? 'N/A'),
                    _buildInfoRow('Project', inquiry['project_name'] ?? 'N/A'),
                    _buildInfoRow('Location', inquiry['project_location'] ?? 'N/A'),
                    _buildInfoRow('Added By', inquiry['username'] ?? 'N/A'),
                    
                    const SizedBox(height: 24),
                    
                    // Proposal Files
                    _buildSection('Proposal Files', Icons.attach_file),
                    ...proposalData
                        .where((item) => item['type'] == 'file')
                        .map((file) => _buildFileItem(file)),
                    
                    const SizedBox(height: 24),
                    
                    // Proposal Inputs
                    _buildSection('Proposal Inputs', Icons.input),
                    ...proposalData
                        .where((item) => item['type'] == 'input')
                        .map((input) => _buildInputItem(input)),
                    
                    const SizedBox(height: 24),
                    
                    // Proposal Remarks
                    _buildSection('Proposal Remarks', Icons.comment),
                    ...proposalData
                        .where((item) => item['type'] == 'remark')
                        .map((remark) => _buildRemarkItem(remark)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[600], size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(Map<String, dynamic> file) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'File: ${file['file_name'] ?? 'N/A'}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (file['file_link'] != null && file['file_link'].toString().isNotEmpty)
            Text(
              'Link: ${file['file_link']}',
              style: TextStyle(
                color: Colors.blue[600],
                decoration: TextDecoration.underline,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputItem(Map<String, dynamic> input) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Input: ${input['input'] ?? 'N/A'}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text('Value: ${input['value'] ?? 'N/A'}'),
          if (input['remark'] != null && input['remark'].toString().isNotEmpty)
            Text('Remark: ${input['remark']}'),
        ],
      ),
    );
  }

  Widget _buildRemarkItem(Map<String, dynamic> remark) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        remark['remark'] ?? 'No remark',
        style: const TextStyle(fontStyle: FontStyle.italic),
      ),
    );
  }
}











class ProposalDashboardScreen extends StatefulWidget {
  final String? currentUserId;
  const ProposalDashboardScreen({super.key, this.currentUserId});

  @override
  State<ProposalDashboardScreen> createState() => _ProposalDashboardScreenState();
}

class _ProposalDashboardScreenState extends State<ProposalDashboardScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load dashboard data
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchDashboardAnalytics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red[600], size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading dashboard',
                  style: TextStyle(color: Colors.red[600]),
                ),
              ],
            ),
          );
        }

        final analytics = snapshot.data ?? {};
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard Header
              _buildDashboardHeader(),
              const SizedBox(height: 24),
              
              // Key Metrics Cards
              _buildKeyMetricsCards(analytics),
              const SizedBox(height: 24),
              
              // Charts Row
              Row(
                children: [
                  // Monthly Trends Chart
                  Expanded(
                    flex: 2,
                    child: _buildMonthlyTrendsChart(analytics),
                  ),
                  const SizedBox(width: 16),
                  // Top Clients Chart
                  Expanded(
                    flex: 1,
                    child: _buildTopClientsChart(analytics),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Recent Activity
              _buildRecentActivity(analytics),
            ],
          ),
        );
      },
    );
  }

  // Dashboard Analytics Methods
  Future<Map<String, dynamic>> _fetchDashboardAnalytics() async {
    final client = Supabase.instance.client;
    
    try {
      // 1. Fetch all leads for the current user
      final allLeads = await client
          .from('leads')
          .select('id, created_at, client_name, project_name, project_location')
          .eq('lead_type', 'Monolithic Formwork')
          .order('created_at', ascending: false);

      // 2. Fetch proposal data
      final proposalFiles = await client
          .from('proposal_file')
          .select('lead_id, created_at');



      final adminResponses = await client
          .from('admin_response')
          .select('lead_id, aluminium_area, ms_weight, rate_sqm, status, created_at');

      // 3. Calculate analytics
      final totalLeads = allLeads.length;
      final leadsWithProposals = proposalFiles.map((f) => f['lead_id']).toSet().length;
      final conversionRate = totalLeads > 0 ? (leadsWithProposals / totalLeads * 100) : 0.0;

      // 4. Calculate financial metrics
      double totalAluminiumArea = 0.0;
      double totalRevenue = 0.0;
      int approvedProposals = 0;

      for (final response in adminResponses) {
        final area = response['aluminium_area'] ?? 0.0;
        final rate = response['rate_sqm'] ?? 0.0;
        final status = response['status']?.toString().toLowerCase() ?? '';

        totalAluminiumArea += area;
        totalRevenue += area * rate * 1.18; // Including GST
        
        if (status == 'approved') {
          approvedProposals++;
        }
      }

      // 5. Calculate monthly trends
      final monthlyData = <String, int>{};
      
      for (final lead in allLeads) {
        final createdAt = DateTime.tryParse(lead['created_at'] ?? '');
        if (createdAt != null) {
          final monthKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
          monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + 1;
        }
      }

      // 6. Calculate top clients
      final clientCounts = <String, int>{};
      for (final lead in allLeads) {
        final clientName = lead['client_name'] ?? 'Unknown';
        clientCounts[clientName] = (clientCounts[clientName] ?? 0) + 1;
      }

      final topClients = clientCounts.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

      return {
        'totalLeads': totalLeads,
        'leadsWithProposals': leadsWithProposals,
        'conversionRate': conversionRate,
        'totalAluminiumArea': totalAluminiumArea,
        'totalRevenue': totalRevenue,
        'approvedProposals': approvedProposals,
        'monthlyData': monthlyData,
        'topClients': topClients.take(5).toList(),
        'recentActivity': allLeads.take(10).toList(),
      };
    } catch (e) {
      debugPrint('Error fetching dashboard analytics: $e');
      return {
        'totalLeads': 0,
        'leadsWithProposals': 0,
        'conversionRate': 0.0,
        'totalAluminiumArea': 0.0,
        'totalRevenue': 0.0,
        'approvedProposals': 0,
        'monthlyData': {},
        'topClients': [],
        'recentActivity': [],
      };
    }
  }

  Widget _buildDashboardHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, color: Colors.blue[600], size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Proposal Engineer Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  'Comprehensive insights into your proposal performance',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsCards(Map<String, dynamic> analytics) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Total Leads',
            analytics['totalLeads'].toString(),
            Icons.assignment,
            Colors.blue,
            'All inquiries',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Proposals',
            analytics['leadsWithProposals'].toString(),
            Icons.description,
            Colors.green,
            'Submitted proposals',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Conversion Rate',
            '${analytics['conversionRate'].toStringAsFixed(1)}%',
            Icons.trending_up,
            Colors.orange,
            'Success rate',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Total Revenue',
            '₹${(analytics['totalRevenue'] ?? 0).toStringAsFixed(0)}',
            Icons.attach_money,
            Colors.purple,
            'Estimated value',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendsChart(Map<String, dynamic> analytics) {
    final monthlyData = analytics['monthlyData'] as Map<String, int>? ?? {};
    final sortedMonths = monthlyData.keys.toList()..sort();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Monthly Trends',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (sortedMonths.isNotEmpty)
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: sortedMonths.map((month) {
                  final count = monthlyData[month] ?? 0;
                  final maxCount = monthlyData.values.isNotEmpty 
                      ? monthlyData.values.reduce((a, b) => a > b ? a : b) 
                      : 1;
                  final height = maxCount > 0 ? (count / maxCount) : 0.0;
                  
                  return Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              heightFactor: height,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue[600],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          month.substring(5), // Show only month
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            )
          else
            Center(
              child: Text(
                'No data available',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopClientsChart(Map<String, dynamic> analytics) {
    final topClients = analytics['topClients'] as List<MapEntry<String, int>>? ?? [];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: Colors.green[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Top Clients',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (topClients.isNotEmpty)
            ...topClients.map((client) {
              final percentage = topClients.isNotEmpty 
                  ? (client.value / topClients.first.value * 100) 
                  : 0.0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            client.key,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${client.value}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                    ),
                  ],
                ),
              );
            })
          else
            Center(
              child: Text(
                'No client data',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(Map<String, dynamic> analytics) {
    final recentActivity = analytics['recentActivity'] as List<dynamic>? ?? [];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.purple[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (recentActivity.isNotEmpty)
            ...recentActivity.take(5).map((activity) {
              final date = DateTime.tryParse(activity['created_at'] ?? '');
              final formattedDate = date != null 
                  ? DateFormat('MMM dd, yyyy').format(date)
                  : 'Unknown date';
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.blue[600],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['client_name'] ?? 'Unknown Client',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            activity['project_name'] ?? 'Unknown Project',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            })
          else
            Center(
              child: Text(
                'No recent activity',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
        ],
      ),
    );
  }
}


