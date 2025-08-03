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
    const Center(child: Text('Proposal Engineer Dashboard')),
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

  Future<void> _logScreenManagementEvent(String event) async {
    debugPrint('Screen Management Event: $event');
    // Log to Supabase for developer monitoring
    await Supabase.instance.client.from('screen_management_events').insert({
      'user_type': 'Proposal Engineer',
      'event': event,
      'timestamp': DateTime.now().toIso8601String(),
    });
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Proposals'),
          actions: [
            IconButton(
              icon: const Icon(Icons.analytics),
              tooltip: 'Log screen management event',
              onPressed: () => _logScreenManagementEvent('Viewed proposals'),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.18 * 255).round()),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: const Color(
                    0xFF1976D2,
                  ).withAlpha((0.6 * 255).round()), // 40% translucent
                  borderRadius: BorderRadius.circular(16),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.blueGrey[700],
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                overlayColor: WidgetStateProperty.all(
                  Colors.transparent,
                ), // remove hover effect
                tabs: const [
                  Tab(text: 'Inquiries'),
                  Tab(text: 'Submitted Inquiries'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // Inquiries Tab
            _buildInquiriesTab(context),
            // Submitted Inquiries Tab
            _buildSubmittedInquiriesTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInquiriesTab(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchLeadsWithoutProposals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text(
            'Error loading inquiries',
            style: TextStyle(color: Colors.red),
          );
        }
        final inquiries = snapshot.data ?? [];
        if (inquiries.isEmpty) {
          return Text(
            'No pending inquiries.',
            style: TextStyle(color: Colors.grey),
          );
        }
        if (isWide) {
          // Grid for web/tablet
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.2,
              ),
              itemCount: inquiries.length,
              itemBuilder: (context, idx) {
                final lead = inquiries[idx];
                final date = lead['created_at'] != null
                    ? DateFormat(
                        'dd-MM-yyyy',
                      ).format(DateTime.parse(lead['created_at']))
                    : '-';
                return glassCard(
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          // Left column
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _labelValue(
                                            'Client Name',
                                            lead['client_name'],
                                          ),
                                          _labelValue(
                                            'Project name',
                                            lead['project_name'],
                                          ),
                                          _labelValue(
                                            'Project Location',
                                            lead['project_location'],
                                          ),
                                          Row(
                                            children: [
                                              const Text(
                                                'Date',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                date,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                'Added by: ${lead['username'] ?? 'Unknown User'}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 4),
                                const Text(
                                  'REMARK',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lead['remark'] ??
                                      'Take your project from prototype to production with these essential integrations and features.',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                // Add space for buttons to prevent overlap
                                const SizedBox(height: 60),
                              ],
                            ),
                          ),
                          // Remove the vertical divider and right column (Main Contact only)
                          // The contact information section has been removed
                        ],
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: IconButton(
                                onPressed: () {
                                  _showAlertsDialog(context, lead);
                                },
                                icon: const Icon(
                                  Icons.notifications,
                                  color: Colors.red,
                                ),
                                tooltip: 'Alert',
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        QueryDialog(lead: lead),
                                  );
                                },
                                icon: const Icon(
                                  Icons.chat,
                                  color: Colors.orange,
                                ),
                                tooltip: 'Query',
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => ProposalResponseDialog(
                                    lead: lead,
                                    currentUserId: widget.currentUserId,
                                  ),
                                );
                              },
                              child: const Text('Propose'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        } else {
          // Stack/list for mobile
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            children: inquiries.map((lead) {
              final date = lead['created_at'] != null
                  ? DateFormat(
                      'dd-MM-yyyy',
                    ).format(DateTime.parse(lead['created_at']))
                  : '-';
              return SizedBox(
                width: double.infinity,
                child: glassCard(
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _labelValue(
                                      'Client Name',
                                      lead['client_name'],
                                    ),
                                    _labelValue(
                                      'Project name',
                                      lead['project_name'],
                                    ),
                                    _labelValue(
                                      'Project Location',
                                      lead['project_location'],
                                    ),
                                    Row(
                                      children: [
                                        const Text(
                                          'Date',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          date,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          'Added by: ${lead['username'] ?? 'Unknown User'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 4),
                          const Text(
                            'REMARK',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lead['remark'] ??
                                'Take your project from prototype to production with these essential integrations and features.',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Add space for buttons to prevent overlap
                          const SizedBox(height: 60),
                        ],
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: IconButton(
                                onPressed: () {
                                  _showAlertsDialog(context, lead);
                                },
                                icon: const Icon(
                                  Icons.notifications,
                                  color: Colors.red,
                                ),
                                tooltip: 'Alert',
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        QueryDialog(lead: lead),
                                  );
                                },
                                icon: const Icon(
                                  Icons.chat,
                                  color: Colors.orange,
                                ),
                                tooltip: 'Query',
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => ProposalResponseDialog(
                                    lead: lead,
                                    currentUserId: widget.currentUserId,
                                  ),
                                );
                              },
                              child: const Text('Propose'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }
      },
    );
  }

  Widget _buildSubmittedInquiriesTab(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchLeadsWithProposals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text(
            'Error loading submitted inquiries',
            style: TextStyle(color: Colors.red),
          );
        }
        final submittedInquiries = snapshot.data ?? [];
        if (submittedInquiries.isEmpty) {
          return Text(
            'No submitted inquiries.',
            style: TextStyle(color: Colors.grey),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          shrinkWrap: true,
          itemCount: submittedInquiries.length,
          itemBuilder: (context, idx) {
            final lead = submittedInquiries[idx];
            final date = lead['created_at'] != null
                ? DateFormat(
                    'dd-MM-yyyy',
                  ).format(DateTime.parse(lead['created_at']))
                : '-';
            return glassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labelValue('Client Name', lead['client_name']),
                            _labelValue('Project name', lead['project_name']),
                            _labelValue(
                              'Project Location',
                              lead['project_location'],
                            ),
                            Row(
                              children: [
                                const Text(
                                  'Date',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  date,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Contact info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CONTACT',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lead['main_contact_name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if ((lead['main_contact_email'] ?? '').isNotEmpty)
                            Text(
                              lead['main_contact_email'] ?? '',
                              style: const TextStyle(fontSize: 13),
                            ),
                          if ((lead['main_contact_mobile'] ?? '').isNotEmpty)
                            Text(
                              lead['main_contact_mobile'] ?? '',
                              style: const TextStyle(fontSize: 13),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Submitted Proposal Responses',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _fetchSubmittedProposals(lead['id']),
                        builder: (context, proposalsSnapshot) {
                          if (proposalsSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              width: 80,
                              height: 16,
                            ); // placeholder
                          }
                          final proposals = proposalsSnapshot.data ?? [];
                          if (proposals.isEmpty ||
                              proposals.first['user_id'] == null) {
                            return const SizedBox();
                          }
                          return FutureBuilder<Map<String, dynamic>?>(
                            future: _fetchUserInfo(
                              proposals.first['user_id']?.toString(),
                            ),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  width: 80,
                                  height: 16,
                                ); // placeholder
                              }
                              final user = userSnapshot.data;
                              if (user == null) return const SizedBox();
                              return Text(
                                '${user['username'] ?? ''} (${user['employee_code'] ?? ''})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blueGrey,
                                  fontSize: 14,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchSubmittedProposals(lead['id']),
                    builder: (context, proposalsSnapshot) {
                      if (proposalsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final proposals = proposalsSnapshot.data ?? [];
                      if (proposals.isEmpty) {
                        return const Text('No proposal responses.');
                      }
                      // Group by type
                      final files = proposals
                          .where((p) => p['type'] == 'file')
                          .toList();
                      final inputs = proposals
                          .where((p) => p['type'] == 'input')
                          .toList();
                      final remarks = proposals
                          .where((p) => p['type'] == 'remark')
                          .toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (files.isNotEmpty) ...[
                            const Text(
                              'Files:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...files.map(
                              (file) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2.0,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Name: ${file['file_name']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if ((file['file_link'] ?? '').isNotEmpty)
                                      Expanded(
                                        child: Text(
                                          'Link: ${file['file_link']}',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (inputs.isNotEmpty) ...[
                            const Text(
                              'Inputs:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...inputs.map(
                              (input) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2.0,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Input: ${input['input']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Value: ${input['value']} ${input['unit']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (remarks.isNotEmpty) ...[
                            const Text(
                              'Remarks:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...remarks.map(
                              (remark) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2.0,
                                ),
                                child: Text(
                                  '${remark['remark']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text(
                    'Activity Log',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: fetchLeadActivity(lead['id']),
                    builder: (context, activitySnapshot) {
                      if (activitySnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final activities = activitySnapshot.data ?? [];
                      if (activities.isEmpty) {
                        return const Text(
                          'No activity yet.',
                          style: TextStyle(color: Colors.grey),
                        );
                      }
                      return Column(
                        children: activities.map((activity) {
                          return FutureBuilder<Map<String, dynamic>?>(
                            future: _fetchUserInfo(
                              activity['user_id']?.toString(),
                            ),
                            builder: (context, userSnapshot) {
                              final user = userSnapshot.data;
                              final userStr = user != null
                                  ? '${user['username'] ?? 'Unknown'} (${user['employee_code'] ?? 'N/A'})'
                                  : 'Unknown User';
                              final activityType =
                                  activity['activity_type'] ?? '';
                              final timestamp = activity['created_at'] != null
                                  ? DateFormat('yyyy-MM-dd HH:mm').format(
                                      DateTime.parse(activity['created_at']),
                                    )
                                  : '';
                              final changes = activity['changes_made'];
                              String changesSummary = '';
                              if (changes is Map ||
                                  changes is List ||
                                  (changes is String &&
                                      changes.startsWith('{'))) {
                                final parsed = changes is String
                                    ? jsonDecode(changes)
                                    : changes;
                                if (parsed is Map) {
                                  if (parsed['files'] != null &&
                                      (parsed['files'] as List).isNotEmpty) {
                                    changesSummary +=
                                        'Files: ${(parsed['files'] as List).map((f) => f['file_name']).join(', ')}\n';
                                  }
                                  if (parsed['inputs'] != null &&
                                      (parsed['inputs'] as List).isNotEmpty) {
                                    changesSummary +=
                                        'Inputs: ${(parsed['inputs'] as List).map((i) => i['input']).join(', ')}\n';
                                  }
                                  if (parsed['remark'] != null &&
                                      (parsed['remark'] as String).isNotEmpty) {
                                    changesSummary +=
                                        'Remark: ${parsed['remark']}';
                                  }
                                }
                              } else if (changes is String) {
                                changesSummary = changes;
                              }
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  '$userStr • $activityType',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      timestamp,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    if (changesSummary.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 2.0,
                                        ),
                                        child: Text(
                                          changesSummary.trim(),
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}



// Helper for label-value pairs
Widget _labelValue(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 2.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            value ?? '-',
            style: const TextStyle(fontWeight: FontWeight.w400),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    ),
  );
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
      insetPadding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return Container(
            width: isWide ? 900 : double.infinity,
            height: MediaQuery.of(context).size.height * 0.9,
            padding: const EdgeInsets.all(16),
            child: isWide
                ? Row(
                    children: [
                      // Left: Lead info
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
                          child: _ProposalLeadInfoSection(
                            lead: lead,
                            otherContacts: otherContacts,
                            attachments: attachments,
                          ),
                        ),
                      ),
                      VerticalDivider(),
                      // Right: Proposal Response
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 24.0),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProposalLeadInfoSection(
                          lead: lead,
                          otherContacts: otherContacts,
                          attachments: attachments,
                        ),
                        const Divider(height: 32),
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
                  ),
          );
        },
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelValue('Client Name', lead['client_name']),
          _labelValue('Project name', lead['project_name']),
          _labelValue('Project Location', lead['project_location']),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lead['created_at'] != null
                      ? DateFormat(
                          'dd-MM-yyyy',
                        ).format(DateTime.parse(lead['created_at']))
                      : '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 16,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const Text('REMARK', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            lead['remark'] ?? '-',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: 12),
          const Divider(),
          const Text(
            'Lead Attachments',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ...attachments.map(
            (a) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a['file_name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                  if ((a['file_link'] ?? '').isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final url = a['file_link'] ?? '';
                              if (url.isNotEmpty) {
                                try {
                                  await launchUrl(Uri.parse(url));
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Could not open link: $url',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text(
                              a['file_link'] ?? '',
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.copy, size: 16),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: a['file_link'] ?? ''),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Link copied to clipboard'),
                              ),
                            );
                          },
                          tooltip: 'Copy link',
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
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
        const Text(
          'Proposal Response',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  const Text('File Name'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: List.generate(
                        widget.files.length,
                        (i) => Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: widget.files[i]['fileName'],
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  hintText: 'Enter file name',
                                  helperText: 'e.g., Proposal.pdf, Quote.docx',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: widget.files[i]['fileLink'],
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  hintText: 'Enter file link/URL',
                                  helperText:
                                      'e.g., https://drive.google.com/...',
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.add_box,
                                  color: Colors.orange,
                                ),
                                onPressed: widget.onAddFile,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            if (widget.files.length > 1)
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => widget.onRemoveFile(i),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Remark'),
              TextField(
                controller: widget.remarkController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your proposal remarks or additional notes',
                  helperText:
                      'Provide any additional information about the proposal',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: List.generate(
                        widget.inputs.length,
                        (i) => Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value:
                                    widget
                                            .inputs[i]['input']
                                            ?.text
                                            .isNotEmpty ==
                                        true
                                    ? widget.inputs[i]['input']?.text
                                    : null,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                hint: const Text('Select Input'),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Area',
                                    child: Text('Area'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'MS Wt.',
                                    child: Text('MS Wt.'),
                                  ),
                                ],
                                onChanged: (String? newValue) {
                                  if (newValue != null &&
                                      widget.inputs[i]['input'] != null) {
                                    widget.inputs[i]['input']!.text = newValue;
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: widget.inputs[i]['remark'],
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  hintText: 'Enter remark or note',
                                  helperText: 'Optional additional information',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: widget.inputs[i]['value'],
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  hintText: 'Enter value (e.g., 100, 50.5)',
                                  helperText: 'Numeric value required',
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    // Trigger rebuild to update totals
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.add_box,
                                  color: Colors.orange,
                                ),
                                onPressed: widget.onAddInput,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            if (widget.inputs.length > 1)
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => widget.onRemoveInput(i),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Summary totals row
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Area total
              Text(
                'Area = ${_calculateAreaTotal()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
              // MS Wt. total
              Text(
                'MS Wt. Avg = ${_calculateMSWeightAverage()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.bottomRight,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : widget.onSave,
              child: widget.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Submit Proposal'),
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

// Add this helper method to fetch user info by user_id
Future<Map<String, dynamic>?> _fetchUserInfo(String? userId) async {
  if (userId == null || userId.isEmpty) {
    return null;
  }

  final client = Supabase.instance.client;
  try {
    var user = await client
        .from('users')
        .select('username, employee_code')
        .eq('id', userId)
        .maybeSingle();
    user ??= await client
        .from('dev_user')
        .select('username, employee_code')
        .eq('id', userId)
        .maybeSingle();
    return user;
  } catch (e) {
    debugPrint('Error fetching user info: $e');
    return null;
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
