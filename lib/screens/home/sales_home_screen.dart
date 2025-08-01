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
  String _selectedFilter = 'All';
  String _sortBy = 'date';
  bool _sortAscending = false;
  final Map<String, TextEditingController> _rateControllers = {};
  final Map<String, double> _totalAmounts = {}; // Store calculated totals
  final TextEditingController _remarkController = TextEditingController();
  bool _isLoading = true;
  Set<String> _selectedLeads = {};
  bool _selectAll = false;
  bool _showAdvancedFilters = false;
  String? _currentUserId;
  String? _currentUsername;

  final Map<String, dynamic> _advancedFilters = {
    'dateRange': null,
    'location': 'All',
    'minAmount': '',
    'maxAmount': '',
  };

  final List<String> _filterOptions = [
    'All',
    'New/Progress',
    'Proposal Progress',
    'Waiting for Approval',
    'Approved',
  ];

  final List<String> _sortOptions = [
    'date',
    'lead_id',
    'project_name',
    'client_name',
    'project_location',
    'aluminium_area',
    'ms_weight',
    'rate_sqm',
    'total_amount',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _fetchLeads();
  }

  Future<void> _getCurrentUser() async {
    try {
      // Import SharedPreferences for cache access
      final prefs = await SharedPreferences.getInstance();

      // Get cached user_id from memory
      final cachedUserId = prefs.getString('user_id');
      final cachedSessionId = prefs.getString('session_id');
      final cachedSessionActive = prefs.getBool('session_active');
      final cachedUserType = prefs.getString('user_type');

      debugPrint('[CACHE] Cached user_id: $cachedUserId');
      debugPrint('[CACHE] Cached session_id: $cachedSessionId');
      debugPrint('[CACHE] Cached session_active: $cachedSessionActive');
      debugPrint('[CACHE] Cached user_type: $cachedUserType');

      // Validate cache data
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
        }
      } else {
        // Use cached user_id
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

      // Fallback to auth session if cache fails
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
      // Check if current user is available
      if (_currentUserId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      debugPrint('Fetching leads for user_id: $_currentUserId');

      // Use the cache-based utility function to fetch leads
      List<Map<String, dynamic>> joinedLeads;
      try {
        // Try to fetch leads using cache memory first
        joinedLeads = await LeadUtils.fetchLeadsForActiveUser();
        debugPrint('Successfully fetched leads using cache memory');
      } catch (cacheError) {
        debugPrint('Cache-based fetch failed: $cacheError');
        // Fallback to user_id-based fetch
        joinedLeads = await LeadUtils.fetchLeadsByUserId(_currentUserId!);
        debugPrint('Fallback to user_id-based fetch successful');
      }

      debugPrint('Found ${joinedLeads.length} leads for user');

      // Add sales person name to each lead
      final leadsWithSalesPerson = joinedLeads.map((lead) {
        return {...lead, 'sales_person_name': _currentUsername ?? ''};
      }).toList();

      // Initialize total amounts for each lead
      for (final lead in leadsWithSalesPerson) {
        final leadId = lead['lead_id'].toString();
        _totalAmounts[leadId] = lead['total_amount'] ?? 0.0;
      }

      setState(() {
        _leads = leadsWithSalesPerson;
        _filteredLeads = leadsWithSalesPerson;
        _isLoading = false;
      });

      debugPrint(
        'Successfully loaded ${leadsWithSalesPerson.length} leads for user $_currentUsername',
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

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilters();
    });
  }

  void _onSortChanged(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = sortBy;
        _sortAscending = true;
      }
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filteredLeads = _leads.where((lead) {
      final matchesSearch =
          lead['lead_id'].toString().toLowerCase().contains(_searchText) ||
          (lead['client_name'] ?? '').toLowerCase().contains(_searchText) ||
          (lead['project_name'] ?? '').toLowerCase().contains(_searchText);

      if (!matchesSearch) return false;

      if (_selectedFilter == 'All') return true;

      final status = _getLeadStatus(lead);
      return status == _selectedFilter;
    }).toList();

    // Apply sorting
    _filteredLeads.sort((a, b) {
      final aValue = a[_sortBy];
      final bValue = b[_sortBy];

      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return _sortAscending ? 1 : -1;
      if (bValue == null) return _sortAscending ? -1 : 1;

      if (aValue is Comparable && bValue is Comparable) {
        return _sortAscending
            ? Comparable.compare(aValue, bValue)
            : Comparable.compare(bValue, aValue);
      }
      return 0;
    });
  }

  String _getLeadStatus(Map<String, dynamic> lead) {
    return LeadUtils.getLeadStatus(lead);
  }

  void _toggleLeadSelection(String leadId) {
    setState(() {
      if (_selectedLeads.contains(leadId)) {
        _selectedLeads.remove(leadId);
      } else {
        _selectedLeads.add(leadId);
      }
      _updateSelectAll();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        _selectedLeads = _filteredLeads
            .map((lead) => lead['lead_id'].toString())
            .toSet();
      } else {
        _selectedLeads.clear();
      }
    });
  }

  void _updateSelectAll() {
    setState(() {
      _selectAll = _selectedLeads.length == _filteredLeads.length;
    });
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

                // Search, Filter, and Actions Section
                _buildSearchAndActions(isWide),
                SizedBox(height: isWide ? 24 : 8),

                // Advanced Filters
                if (_showAdvancedFilters) _buildAdvancedFilters(),
                if (_showAdvancedFilters) SizedBox(height: isWide ? 16 : 8),

                // Bulk Actions
                if (_selectedLeads.isNotEmpty) _buildBulkActions(),
                if (_selectedLeads.isNotEmpty)
                  SizedBox(height: isWide ? 16 : 8),

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
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.leaderboard, color: Colors.blue, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Lead Management',
                    style: TextStyle(
                      fontSize: isWide ? 28 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                'Manage and track all leads in your system',
                style: TextStyle(
                  fontSize: isWide ? 16 : 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.person, color: Colors.blue[700]),
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.download, color: Colors.grey[600]),
              onPressed: () {
                // TODO: Implement export functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Export functionality coming soon')),
                );
              },
              tooltip: 'Export',
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.grey[600]),
              onPressed: _fetchLeads,
              tooltip: 'Refresh',
            ),
          ],
        ),
      ],
    );
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
      child: Row(
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
    );
  }

  Widget _buildSearchAndActions(bool isWide) {
    return Container(
      padding: EdgeInsets.all(16),
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
          Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search leads by ID, client, or project...',
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
                  borderSide: BorderSide(color: Colors.blue),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _onSearch,
            ),
          ),
          SizedBox(width: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _selectedFilter,
              items: _filterOptions.map((filter) {
                return DropdownMenuItem(value: filter, child: Text(filter));
              }).toList(),
              onChanged: (value) {
                if (value != null) _onFilterChanged(value);
              },
              underline: SizedBox(),
              icon: Icon(Icons.arrow_drop_down),
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _sortBy,
              items: _sortOptions.map((sort) {
                return DropdownMenuItem(
                  value: sort,
                  child: Text(sort.replaceAll('_', ' ').toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) _onSortChanged(value);
              },
              underline: SizedBox(),
              icon: Icon(Icons.arrow_drop_down),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
            ),
            onPressed: () => _onSortChanged(_sortBy),
            tooltip: 'Toggle sort order',
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                _showAdvancedFilters = !_showAdvancedFilters;
              });
            },
            tooltip: 'Advanced filters',
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      padding: EdgeInsets.all(16),
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
          Text(
            'Advanced Filters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Min Amount',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _advancedFilters['minAmount'] = value;
                    _applyFilters();
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Max Amount',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _advancedFilters['maxAmount'] = value;
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActions() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.blue[700]),
          SizedBox(width: 8),
          Text(
            '${_selectedLeads.length} leads selected',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          Spacer(),
          TextButton.icon(
            icon: Icon(Icons.delete),
            label: Text('Delete Selected'),
            onPressed: () {
              // TODO: Implement bulk delete
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Bulk delete functionality coming soon'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
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
          // Table Header
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
                Checkbox(
                  value: _selectAll,
                  onChanged: (value) => _toggleSelectAll(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Lead ID',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                      'Client',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                      'Aluminium Area',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                      'MS Weight',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                      'Rate sq/m',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                      'Total + GST',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
    final isSelected = _selectedLeads.contains(leadId);

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.blue[50]
            : (index % 2 == 0 ? Colors.white : Colors.grey[50]),
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (value) => _toggleLeadSelection(leadId),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Text(
                leadId,
                style: TextStyle(fontWeight: FontWeight.w500),
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Text(
                lead['project_name'] ?? 'N/A',
                style: TextStyle(fontWeight: FontWeight.w500),
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Text(
                lead['client_name'] ?? 'N/A',
                style: TextStyle(fontWeight: FontWeight.w500),
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Text(
                lead['project_location'] ?? 'N/A',
                style: TextStyle(fontWeight: FontWeight.w500),
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${lead['aluminium_area']?.toStringAsFixed(2) ?? '0.00'} sq/m',
                    style: TextStyle(fontWeight: FontWeight.w500),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    'R1(₹${lead['aluminium_area']?.toStringAsFixed(2) ?? '0.00'})',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                      decoration: TextDecoration.underline,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Text(
                '${lead['ms_weight']?.toStringAsFixed(2) ?? '0.00'} kg',
                style: TextStyle(fontWeight: FontWeight.w500),
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: TextField(
                controller: _rateControllers.putIfAbsent(
                  leadId,
                  () => TextEditingController(
                    text: lead['rate_sqm']?.toString() ?? '0',
                  ),
                ),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 14),
                onChanged: (value) {
                  final rate = double.tryParse(value) ?? 0;
                  final aluminiumArea =
                      double.tryParse(
                        lead['aluminium_area']?.toString() ?? '0',
                      ) ??
                      0;
                  final totalAmount = aluminiumArea * rate * 1.18;
                  setState(() {
                    _totalAmounts[leadId] = totalAmount;
                  });
                },
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Text(
                '₹${totalAmount.toStringAsFixed(2)}',
                style: TextStyle(fontWeight: FontWeight.w500),
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(_getLeadStatus(lead)),
                  borderRadius: BorderRadius.circular(12),
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
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.person, color: Colors.blue),
                    onPressed: () => _assignLead(lead),
                    tooltip: 'Assign',
                  ),
                  IconButton(
                    icon: Icon(Icons.visibility, color: Colors.green),
                    onPressed: () => _viewLead(lead),
                    tooltip: 'View',
                  ),
                  IconButton(
                    icon: Icon(Icons.help, color: Colors.orange),
                    onPressed: () => _helpLead(lead),
                    tooltip: 'Help',
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.purple),
                    onPressed: () => _editLead(lead),
                    tooltip: 'Edit',
                  ),
                ],
              ),
            ),
          ),
        ],
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
    final isSelected = _selectedLeads.contains(leadId);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) => _toggleLeadSelection(leadId),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lead ID: $leadId',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Project: ${lead['project_name'] ?? 'N/A'}',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Client: ${lead['client_name'] ?? 'N/A'}',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Location: ${lead['project_location'] ?? 'N/A'}',
                          style: TextStyle(fontSize: 14),
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
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_getLeadStatus(lead)),
                      borderRadius: BorderRadius.circular(12),
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
                      IconButton(
                        icon: Icon(Icons.visibility, size: 20),
                        onPressed: () => _viewLead(lead),
                        tooltip: 'View',
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, size: 20),
                        onPressed: () => _editLead(lead),
                        tooltip: 'Edit',
                      ),
                    ],
                  ),
                ],
              ),
            ],
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
}

class _NavItem {
  final String label;
  final IconData icon;

  const _NavItem(this.label, this.icon);
}
