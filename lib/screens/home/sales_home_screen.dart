import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:crm_app/widgets/profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/lead_utils.dart';

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

  final List<_NavItem> _navItems = const [
    _NavItem('Dashboard', Icons.dashboard),
    _NavItem('Leads', Icons.leaderboard),
    _NavItem('Customers', Icons.people),
    _NavItem('Tasks', Icons.task),
    _NavItem('Reports', Icons.analytics),
    _NavItem('Settings', Icons.settings),
    _NavItem('Profile', Icons.person),
  ];

  late final List<Widget> _pages = <Widget>[
    const Center(child: Text('Sales Dashboard')),
    LeadManagementScreen(),
    const Center(child: Text('Customers Management')),
    const Center(child: Text('Tasks Management')),
    const Center(child: Text('Reports')),
    const Center(child: Text('Sales Settings')),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
                mainAxisAlignment: MainAxisAlignment.center,
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
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.withAlpha((0.2 * 255).round())
                              : isHovered
                              ? Colors.white.withAlpha((0.1 * 255).round())
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.icon,
                          color: isSelected ? Colors.blue : Colors.grey[600],
                          size: 24,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = _selectedIndex == index;

              return GestureDetector(
                onTap: () => _onItemTapped(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      color: isSelected ? Colors.blue : Colors.grey[600],
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected ? Colors.blue : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class LeadManagementScreen extends StatefulWidget {
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

  String? _currentUserId;
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _fetchLeads();
    // Add sample data to match the image exactly
    _addSampleData();
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

      // Fetch leads data for current sales user only
      final leadsResult = await client
          .from('leads')
          .select(
            'id, created_at, project_name, client_name, project_location, lead_generated_by',
          )
          .eq('lead_generated_by', _currentUserId!) // Filter by active user
          .order('created_at', ascending: false);

      debugPrint('Found ${leadsResult.length} leads from Supabase');

      // Step 4: Fetch related data for calculations
      final proposalInputResult = await client
          .from('proposal_input')
          .select('lead_id, input, value');

      final adminResponseResult = await client
          .from('admin_response')
          .select('lead_id, rate_sqm, status, remark');

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
          'approved': adminResponseData?['status'] == 'Approved',
          'status': adminResponseData?['status'] ?? 'New/Progress',
        });
      }

      // Step 7: Initialize total amounts for UI display
      for (final lead in joinedLeads) {
        final leadId = lead['lead_id'].toString();
        _totalAmounts[leadId] = lead['total_amount'] ?? 0.0;
      }

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

  void _onSearch(String value) {
    setState(() {
      _searchText = value.toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filteredLeads = _leads.where((lead) {
      final matchesSearch =
          lead['lead_id'].toString().toLowerCase().contains(_searchText) ||
          (lead['client_name'] ?? '').toLowerCase().contains(_searchText) ||
          (lead['project_name'] ?? '').toLowerCase().contains(_searchText);

      return matchesSearch;
    }).toList();
  }

  String _getLeadStatus(Map<String, dynamic> lead) {
    return LeadUtils.getLeadStatus(lead);
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
              // TODO: Implement export functionality for sales
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Export functionality coming soon')),
              );
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
                  'Lead Management',
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
          const SizedBox(height: 8),
          // Centered search box for mobile
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.95,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search leads...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  suffixIcon: IconButton(
                    onPressed: _fetchLeads,
                    icon: Icon(Icons.refresh, size: 18),
                    tooltip: 'Refresh',
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                  ),
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
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                onChanged: _onSearch,
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildStatsCards() {
    final totalLeads = _leads.length;
    final newLeads = _leads
        .where((lead) => _getLeadStatus(lead) == 'New/Progress')
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
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'New',
            newLeads.toString(),
            Icons.new_releases,
            Colors.green,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Proposal Progress',
            proposalProgress.toString(),
            Icons.pending,
            Colors.orange,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Waiting Approval',
            waitingApproval.toString(),
            Icons.schedule,
            Colors.purple,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Approved',
            approved.toString(),
            Icons.check_circle,
            Colors.green,
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
  ) {
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
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStatsCards() {
    final totalLeads = _leads.length;
    final newLeads = _leads
        .where((lead) => _getLeadStatus(lead) == 'New/Progress')
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
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildMobileStatCard(
            'New',
            newLeads.toString(),
            Icons.new_releases,
            Colors.green,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildMobileStatCard(
            'Progress',
            proposalProgress.toString(),
            Icons.pending,
            Colors.orange,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildMobileStatCard(
            'Waiting',
            waitingApproval.toString(),
            Icons.schedule,
            Colors.purple,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildMobileStatCard(
            'Approved',
            approved.toString(),
            Icons.check_circle,
            Colors.green,
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
  ) {
    return Container(
      padding: EdgeInsets.all(8),
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
              color: Colors.grey[800],
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
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
                // TODO: Implement add new lead functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Add New Lead functionality coming soon'),
                  ),
                );
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
                  // TODO: Implement add new lead functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Add New Lead functionality coming soon'),
                    ),
                  );
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
                  flex: 2,
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
                         crossAxisAlignment: CrossAxisAlignment.center,
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
                             textAlign: TextAlign.center,
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
                             textAlign: TextAlign.center,
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
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildInteractiveIconButton(
                            icon: Icons.visibility,
                            onPressed: () => _viewLead(lead),
                            tooltip: 'View Details',
                            leadId: leadId,
                          ),
                          SizedBox(width: 4),
                          _buildInteractiveIconButton(
                            icon: Icons.help,
                            onPressed: () => _helpLead(lead),
                            tooltip: 'Get Help',
                            leadId: leadId,
                          ),
                          SizedBox(width: 4),
                          _buildInteractiveIconButton(
                            icon: Icons.edit,
                            onPressed: () => _editLead(lead),
                            tooltip: 'Edit Lead',
                            leadId: leadId,
                          ),
                          SizedBox(width: 4),
                          _buildInteractiveIconButton(
                            icon: Icons.refresh,
                            onPressed: () => _refreshLead(lead),
                            tooltip: 'Refresh Data',
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
                              'Lead ID: $leadId',
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
                              'Client: ${lead['client_name'] ?? 'N/A'}',
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
                            icon: Icons.visibility,
                            onPressed: () => _viewLead(lead),
                            tooltip: 'View',
                            leadId: leadId,
                          ),
                          SizedBox(width: 8),
                          _buildMobileInteractiveButton(
                            icon: Icons.edit,
                            onPressed: () => _editLead(lead),
                            tooltip: 'Edit',
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

  void _assignLead(Map<String, dynamic> lead) {
    // TODO: Implement assign lead functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Assigning lead: ${lead['project_name']}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _viewLead(Map<String, dynamic> lead) {
    // TODO: Implement view lead details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing lead: ${lead['project_name']}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _helpLead(Map<String, dynamic> lead) {
    // TODO: Implement help functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Help for lead: ${lead['project_name']}'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _editLead(Map<String, dynamic> lead) {
    // TODO: Implement edit lead
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editing lead: ${lead['project_name']}'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _refreshLead(Map<String, dynamic> lead) {
    // TODO: Implement refresh lead
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Refreshing lead: ${lead['project_name']}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _deleteLead(Map<String, dynamic> lead) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Lead'),
          content: Text(
            'Are you sure you want to delete lead: ${lead['project_name']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Implement delete lead
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted lead: ${lead['project_name']}'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _viewLeadDetails(Map<String, dynamic> lead) {
    // TODO: Implement detailed view with modal or navigation
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Lead Details: ${lead['project_name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Client: ${lead['client_name']}'),
              Text('Project: ${lead['project_name']}'),
              Text('Location: ${lead['project_location']}'),
              Text(
                'Area: ${lead['aluminium_area']?.toStringAsFixed(1) ?? '0.0'} sqm',
              ),
              Text(
                'Weight: ${lead['ms_weight']?.toStringAsFixed(1) ?? '0.0'} kg',
              ),
              Text('Rate: ₹${lead['rate_sqm']?.toStringAsFixed(0) ?? '0'}'),
              Text(
                'Total: ₹${_totalAmounts[lead['lead_id'].toString()]?.toStringAsFixed(0) ?? '0'}',
              ),
              Text('Status: ${_getLeadStatus(lead)}'),
              Text('Date: ${_formatDate(lead['date'])}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _editLead(lead);
              },
              child: const Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInteractiveIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required String leadId,
    bool isDestructive = false,
  }) {
    // Determine color based on action type
    Color getActionColor() {
      if (isDestructive) return Colors.red;

      switch (tooltip.toLowerCase()) {
        case 'view details':
          return Colors.blue;
        case 'get help':
          return Colors.orange;
        case 'edit lead':
          return Colors.green;
        case 'refresh data':
          return Colors.purple;
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
        child: IconButton(
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
      ),
    );
  }

  Widget _buildMobileInteractiveButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required String leadId,
    bool isDestructive = false,
  }) {
    // Determine color based on action type
    Color getActionColor() {
      if (isDestructive) return Colors.red;

      switch (tooltip.toLowerCase()) {
        case 'view':
          return Colors.blue;
        case 'edit':
          return Colors.green;
        case 'delete':
          return Colors.red;
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
      child: IconButton(
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
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;

  const _NavItem(this.label, this.icon);
}
