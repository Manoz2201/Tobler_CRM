// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; // Added for jsonEncode
import 'package:crm_app/widgets/profile_page.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

// Add this helper method to fetch user info by user_id
Future<Map<String, dynamic>?> fetchUserInfo(String userId) async {
  final client = Supabase.instance.client;
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

// Helper function to fetch notification count for a user
Future<int> fetchNotificationCount(String username) async {
  final client = Supabase.instance.client;
  try {
    final result = await client
        .from('queries')
        .select('id')
        .eq('receiver_name', username);

    return result.length;
  } catch (e) {
    return 0;
  }
}

// Helper function to copy text to clipboard
Future<void> copyToClipboard(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Copied to clipboard'),
      duration: Duration(seconds: 2),
      backgroundColor: Colors.green,
    ),
  );
}

// Helper function to launch URL
Future<void> launchURL(String url) async {
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch $url';
  }
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
  bool _isDockedLeft = true;
  double _dragOffsetX = 0.0;

  final ScrollController _scrollbarController = ScrollController();

  final List<_NavItem> _navItems = const [
    _NavItem('Dashboard', Icons.dashboard),
    _NavItem('Lead', Icons.leaderboard),
    _NavItem('Opportunities', Icons.trending_up),
    _NavItem('RM', Icons.people),
    _NavItem('Chat', Icons.chat),
    _NavItem('Profile', Icons.person),
  ];

  late final List<Widget> _pages = <Widget>[
    Center(child: Text('Sales Dashboard')),
    SalesLeadTable(
      currentUserId: widget.currentUserId,
      currentUserEmail: widget.currentUserEmail,
      currentUserType: widget.currentUserType,
    ),
    Center(child: Text('Opportunities')),
    RelationshipManagementPage(
      currentUserId: widget.currentUserId,
      currentUserEmail: widget.currentUserEmail,
      currentUserType: widget.currentUserType,
    ),
    Center(child: Text('Chat')),
    ProfilePage(
      currentUserId: widget.currentUserId,
      currentUserEmail: widget.currentUserEmail,
      currentUserType: widget.currentUserType,
    ),
  ];

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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final iconCount = _navItems.length;
                  final iconHeight = 32.0;
                  final iconPadding = 12.0;
                  final totalIconHeight =
                      iconCount * (iconHeight + iconPadding);
                  final availableHeight = constraints.maxHeight;
                  if (totalIconHeight > availableHeight) {
                    return Scrollbar(
                      thumbVisibility: false,
                      trackVisibility: false,
                      controller: _scrollbarController,
                      child: SingleChildScrollView(
                        controller: _scrollbarController,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
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
                              padding: const EdgeInsets.symmetric(
                                vertical: 6.0,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 8,
                                    sigmaY: 8,
                                  ),
                                  child: Container(
                                    color: Colors.white.withAlpha(
                                      (0.18 * 255).round(),
                                    ),
                                    child: AnimatedScale(
                                      scale: scale,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
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
                    );
                  } else {
                    return Column(
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
                                color: Colors.white.withAlpha(
                                  (0.18 * 255).round(),
                                ),
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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        if (isWide) {
          // Web/tablet/desktop layout with sidebar
          return Scaffold(
            body: Stack(
              children: [
                AnimatedPadding(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.only(
                    left: _isDockedLeft ? 72 : 0,
                    right: !_isDockedLeft ? 72 : 0,
                  ),
                  child: _pages[_selectedIndex],
                ),
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
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() {
                              _isDockedLeft = !_isDockedLeft;
                              _dragOffsetX = 0.0;
                            });
                          });
                        },
                        child: _buildNavBar(screenHeight, screenWidth),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        } else {
          // Mobile layout with bottom navigation
          return Scaffold(
            body: _pages[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF1976D2),
              unselectedItemColor: Colors.grey[400],
              items: _navItems
                  .map(
                    (item) => BottomNavigationBarItem(
                      icon: Icon(item.icon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
          );
        }
      },
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}

class _LeadsPage extends StatefulWidget {
  final String currentUserType;
  final String currentUserEmail;
  final String currentUserId;
  const _LeadsPage({
    required this.currentUserType,
    required this.currentUserEmail,
    required this.currentUserId,
  });
  @override
  State<_LeadsPage> createState() => _LeadsPageState();
}

class _LeadsPageState extends State<_LeadsPage> {
  List<Map<String, dynamic>> _leads = [];
  List<Map<String, dynamic>> _filteredLeads = [];
  String _searchText = '';
  String _selectedFilter = 'All';
  String _sortBy = 'date';
  bool _sortAscending = false;
  final Map<String, TextEditingController> _rateControllers = {};
  bool _isLoading = true;
  Set<String> _selectedLeads = {};
  bool _selectAll = false;

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
    _fetchLeads();
  }

  Future<void> _fetchLeads() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final client = Supabase.instance.client;

      // Fetch leads data for current sales user
      final leadsResult = await client
          .from('leads')
          .select(
            'id, created_at, project_name, client_name, project_location, lead_generated_by, lead_type, status',
          )
          .eq('lead_generated_by', widget.currentUserId)
          .order('created_at', ascending: false);

      // Fetch proposal_input data for Area and MS Weight
      final proposalInputResult = await client
          .from('proposal_input')
          .select('lead_id, input, value');

      // Fetch admin_response data for Rate sq/m and approval status
      final adminResponseResult = await client
          .from('admin_response')
          .select('lead_id, rate_sqm, status, remark');

      // Process proposal_input data to calculate Aluminium Area and MS Weight
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

      // Join the data
      final List<Map<String, dynamic>> joinedLeads = [];
      for (final lead in leadsResult) {
        final leadId = lead['id'];
        final adminResponseData = adminResponseMap[leadId];

        // Calculate MS Weight average
        final msWeights = msWeightMap[leadId] ?? [];
        final msWeightAverage = msWeights.isNotEmpty
            ? msWeights.reduce((a, b) => a + b) / msWeights.length
            : 0.0;

        joinedLeads.add({
          'lead_id': leadId,
          'date': lead['created_at'],
          'project_name': lead['project_name'] ?? '',
          'client_name': lead['client_name'] ?? '',
          'project_location': lead['project_location'] ?? '',
          'lead_type': lead['lead_type'] ?? '',
          'aluminium_area': aluminiumAreaMap[leadId] ?? 0,
          'ms_weight': msWeightAverage,
          'rate_sqm': adminResponseData?['rate_sqm'] ?? 0,
          'approved': adminResponseData?['status'] == 'Approved',
          'status':
              lead['status'] ?? adminResponseData?['status'] ?? 'New/Progress',
        });
      }

      setState(() {
        _leads = joinedLeads;
        _filteredLeads = joinedLeads;
        _isLoading = false;
      });
    } catch (e) {
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
    // Check for status first (Won, Lost, Loop, etc.)
    if (lead['status'] != null && lead['status'].toString().isNotEmpty) {
      return lead['status'];
    }
    if (lead['approved'] == true) return 'Approved';
    if (lead['rate_sqm'] != null && lead['rate_sqm'] > 0) {
      return 'Waiting for Approval';
    }
    if (lead['aluminium_area'] > 0 || lead['ms_weight'] > 0) {
      return 'Proposal Progress';
    }
    return 'New/Progress';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'New/Progress':
        return Colors.blue;
      case 'Proposal Progress':
        return Colors.orange;
      case 'Waiting for Approval':
        return Colors.purple;
      case 'Approved':
        return Colors.green;
      case 'Won':
        return Colors.green[700]!;
      case 'Lost':
        return Colors.red[600]!;
      case 'Loop':
        return Colors.orange[600]!;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateLeadStatus(String leadId, String status) async {
    try {
      final client = Supabase.instance.client;

      await client.from('leads').update({'status': status}).eq('id', leadId);

      // Refresh the leads list
      _fetchLeads();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lead status updated to $status'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating lead status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showStatusUpdateDialog(String leadId, String currentStatus) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.update, color: Colors.blue[600]),
              SizedBox(width: 8),
              Text('Update Lead Status'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current Status: $currentStatus',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Select new status:',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _updateLeadStatus(leadId, 'Won');
                    },
                    icon: Icon(Icons.check_circle, color: Colors.white),
                    label: Text('Won'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _updateLeadStatus(leadId, 'Lost');
                    },
                    icon: Icon(Icons.cancel, color: Colors.white),
                    label: Text('Lost'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _updateLeadStatus(leadId, 'Loop');
                    },
                    icon: Icon(Icons.loop, color: Colors.white),
                    label: Text('Loop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _updateSelectAll() {
    _selectAll =
        _selectedLeads.length == _filteredLeads.length &&
        _filteredLeads.isNotEmpty;
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

  void _exportLeads() {
    _showCryptoKeyValidationDialog();
  }

  void _showCryptoKeyValidationDialog() {
    final TextEditingController cryptoKeyController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.security, color: Colors.blue),
              SizedBox(width: 8),
              Text('Enter Crypto Key'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please enter your crypto key to validate access for exporting leads.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              TextField(
                controller: cryptoKeyController,
                decoration: InputDecoration(
                  labelText: 'Crypto Key',
                  hintText: 'Enter your crypto key',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _validateCryptoKey(cryptoKeyController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
              child: Text('Validate Key'),
            ),
          ],
        );
      },
    );
  }

  void _validateCryptoKey(String cryptoKey) {
    // Simple validation - you can implement more complex validation
    if (cryptoKey == 'admin123') {
      _performExport();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid crypto key. Access denied.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _performExport() {
    // Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export functionality will be implemented here.'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  double calculateTotalAmount() {
    double total = 0;
    for (final lead in _filteredLeads) {
      final rate = lead['rate_sqm'] ?? 0;
      final area = lead['aluminium_area'] ?? 0;
      total += rate * area;
    }
    return total;
  }

  Future<void> _saveRateToDatabase(String leadId, String rate) async {
    try {
      final client = Supabase.instance.client;
      await client.from('admin_response').upsert({
        'lead_id': leadId,
        'rate_sqm': double.tryParse(rate) ?? 0,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving rate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewLeadDetails(Map<String, dynamic> lead) async {
    // Navigate to lead details view
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Lead Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Lead ID: ${lead['lead_id']}'),
              Text('Project: ${lead['project_name']}'),
              Text('Client: ${lead['client_name']}'),
              Text('Location: ${lead['project_location']}'),
              Text('Status: ${_getLeadStatus(lead)}'),
              Text('Rate: ₹${lead['rate_sqm'] ?? 0}/sqm'),
              Text(
                'Total Amount: ₹${(lead['rate_sqm'] ?? 0) * (lead['aluminium_area'] ?? 0)}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _queryLead(Map<String, dynamic> lead) {
    showDialog(
      context: context,
      builder: (context) => SalesQueryDialog(lead: lead),
    );
  }

  void _editLead(Map<String, dynamic> lead) {
    // Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit functionality will be implemented here.'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showAddLeadDialog() async {
    String? selectedType;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Lead Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Monolithic Formwork'),
              leading: Radio<String>(
                value: 'Monolithic Formwork',
                groupValue: selectedType,
                onChanged: (val) {
                  selectedType = val;
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                selectedType = 'Monolithic Formwork';
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Scaffolding'),
              leading: Radio<String>(
                value: 'Scaffolding',
                groupValue: selectedType,
                onChanged: (val) {
                  selectedType = val;
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                selectedType = 'Scaffolding';
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
    if (selectedType == null) return;
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => _AddLeadForm(
        leadType: selectedType!,
        onLeadCreated: () async {
          await _fetchLeads();
        },
        userType: widget.currentUserType,
        userEmail: widget.currentUserEmail,
        userId: widget.currentUserId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header with controls
                Container(
                  padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Leads',
                            style: TextStyle(
                              fontSize: isMobile ? 24 : 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _showAddLeadDialog,
                                icon: const Icon(Icons.add),
                                label: Text('Add Lead'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              if (_selectedLeads.isNotEmpty)
                                ElevatedButton.icon(
                                  onPressed: _exportLeads,
                                  icon: const Icon(Icons.download),
                                  label: Text('Export'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600],
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Search and Filter Controls
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: _onSearch,
                              decoration: InputDecoration(
                                hintText: 'Search leads...',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          DropdownButton<String>(
                            value: _selectedFilter,
                            items: _filterOptions.map((filter) {
                              return DropdownMenuItem<String>(
                                value: filter,
                                child: Text(filter),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) _onFilterChanged(value);
                            },
                          ),
                          SizedBox(width: 12),
                          DropdownButton<String>(
                            value: _sortBy,
                            items: _sortOptions.map((sort) {
                              return DropdownMenuItem<String>(
                                value: sort,
                                child: Text(
                                  'Sort by ${sort.replaceAll('_', ' ')}',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) _onSortChanged(value);
                            },
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _sortAscending = !_sortAscending;
                                _applyFilters();
                              });
                            },
                            icon: Icon(
                              _sortAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Leads Table
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: isMobile ? 8.0 : 16.0,
                        ),
                        child: Column(
                          children: [
                            // Table Header
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _selectAll,
                                    onChanged: (value) => _toggleSelectAll(),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Lead ID',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Project',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Client',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Location',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Type',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Area',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Weight',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Rate',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Total',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Status',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Actions',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Table Rows
                            ..._filteredLeads.map(
                              (lead) => _buildLeadRow(lead),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLeadRow(Map<String, dynamic> lead) {
    final leadId = lead['lead_id'].toString();
    final status = _getLeadStatus(lead);
    final statusColor = _getStatusColor(status);

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _selectedLeads.contains(leadId),
            onChanged: (value) => _toggleLeadSelection(leadId),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                leadId,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                lead['project_name'] ?? '',
                style: TextStyle(fontSize: 14),
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                lead['client_name'] ?? '',
                style: TextStyle(fontSize: 14),
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                lead['project_location'] ?? '',
                style: TextStyle(fontSize: 14),
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
                lead['lead_type'] ?? '',
                style: TextStyle(fontSize: 14),
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
                '${(lead['aluminium_area'] ?? 0).toStringAsFixed(2)}',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text('${(lead['ms_weight'] ?? 0).toStringAsFixed(2)}'),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: TextFormField(
                controller:
                    _rateControllers[leadId] ??
                    TextEditingController(
                      text: (lead['rate_sqm'] ?? 0).toString(),
                    ),
                style: TextStyle(fontSize: 12),
                onChanged: (val) {
                  setState(() {});
                  _saveRateToDatabase(leadId, val);
                },
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                '₹${((lead['rate_sqm'] ?? 0) * (lead['aluminium_area'] ?? 0)).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () => _viewLeadDetails(lead),
                    icon: Icon(Icons.visibility, size: 18),
                    tooltip: 'View Details',
                    color: Colors.blue[600],
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    onPressed: () => _queryLead(lead),
                    icon: Icon(Icons.question_mark, size: 18),
                    tooltip: 'Query',
                    color: Colors.orange[600],
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    onPressed: () => _editLead(lead),
                    icon: Icon(Icons.edit, size: 18),
                    tooltip: 'Edit',
                    color: Colors.grey[600],
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    onPressed: () => _showStatusUpdateDialog(
                      lead['id'],
                      _getLeadStatus(lead),
                    ),
                    icon: Icon(Icons.update, size: 18),
                    tooltip: 'Update Status',
                    color: Colors.purple[600],
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
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

class _AddLeadForm extends StatefulWidget {
  final String userType;
  final String userEmail;
  final String userId;
  final String leadType;
  final VoidCallback onLeadCreated;

  const _AddLeadForm({
    required this.userType,
    required this.userEmail,
    required this.userId,
    required this.leadType,
    required this.onLeadCreated,
  });

  @override
  State<_AddLeadForm> createState() => _AddLeadFormState();
}

class _AddLeadFormState extends State<_AddLeadForm> {
  final _formKey = GlobalKey<FormState>();

  // Basic Information Controllers
  final TextEditingController clientNameController = TextEditingController();
  final TextEditingController projectNameController = TextEditingController();
  final TextEditingController projectLocationController =
      TextEditingController();
  final TextEditingController remarkController = TextEditingController();

  // Contact Information Controllers
  final List<Map<String, TextEditingController>> contacts = [
    {
      'name': TextEditingController(),
      'designation': TextEditingController(),
      'email': TextEditingController(),
      'mobile': TextEditingController(),
    },
  ];

  // Attachment Controllers
  final List<Map<String, TextEditingController>> attachments = [
    {'fileName': TextEditingController(), 'fileLink': TextEditingController()},
  ];

  // Quote Table Controllers
  final List<List<TextEditingController>> quoteTable = [
    [
      TextEditingController(), // Item Name
      TextEditingController(), // Unit Weight
      TextEditingController(), // Quantity
      TextEditingController(), // Ex-Factory Price
      TextEditingController(), // Unit Price (Auto-calculated)
      TextEditingController(), // Profit %
      TextEditingController(), // Total (Auto-calculated)
      TextEditingController(), // Per/Kg Price (Auto-calculated)
    ],
  ];

  bool _isSubmitting = false;

  @override
  void dispose() {
    // Dispose all controllers
    clientNameController.dispose();
    projectNameController.dispose();
    projectLocationController.dispose();
    remarkController.dispose();

    for (var contact in contacts) {
      contact['name']!.dispose();
      contact['designation']!.dispose();
      contact['email']!.dispose();
      contact['mobile']!.dispose();
    }

    for (var attachment in attachments) {
      attachment['fileName']!.dispose();
      attachment['fileLink']!.dispose();
    }

    for (var row in quoteTable) {
      for (var controller in row) {
        controller.dispose();
      }
    }

    super.dispose();
  }

  void _addContact() {
    setState(() {
      contacts.add({
        'name': TextEditingController(),
        'designation': TextEditingController(),
        'email': TextEditingController(),
        'mobile': TextEditingController(),
      });
    });
  }

  void _removeContact(int index) {
    if (contacts.length > 1) {
      setState(() {
        contacts[index]['name']!.dispose();
        contacts[index]['designation']!.dispose();
        contacts[index]['email']!.dispose();
        contacts[index]['mobile']!.dispose();
        contacts.removeAt(index);
      });
    }
  }

  void _addAttachment() {
    setState(() {
      attachments.add({
        'fileName': TextEditingController(),
        'fileLink': TextEditingController(),
      });
    });
  }

  void _removeAttachment(int index) {
    if (attachments.length > 1) {
      setState(() {
        attachments[index]['fileName']!.dispose();
        attachments[index]['fileLink']!.dispose();
        attachments.removeAt(index);
      });
    }
  }

  void _addQuoteRow() {
    setState(() {
      quoteTable.add([
        TextEditingController(), // Item Name
        TextEditingController(), // Unit Weight
        TextEditingController(), // Quantity
        TextEditingController(), // Ex-Factory Price
        TextEditingController(), // Unit Price (Auto-calculated)
        TextEditingController(), // Profit %
        TextEditingController(), // Total (Auto-calculated)
        TextEditingController(), // Per/Kg Price (Auto-calculated)
      ]);
    });
  }

  void _removeQuoteRow(int index) {
    if (quoteTable.length > 1) {
      setState(() {
        for (var controller in quoteTable[index]) {
          controller.dispose();
        }
        quoteTable.removeAt(index);
      });
    }
  }

  void _calculateQuoteRow(int rowIndex) {
    if (rowIndex < quoteTable.length) {
      final row = quoteTable[rowIndex];
      final unitWeight = double.tryParse(row[1].text) ?? 0;
      final quantity = double.tryParse(row[2].text) ?? 0;
      final exFactoryPrice = double.tryParse(row[3].text) ?? 0;
      final profitPercent = double.tryParse(row[5].text) ?? 0;

      if (exFactoryPrice > 0 && profitPercent > 0) {
        final unitPrice = exFactoryPrice * (1 + profitPercent / 100);
        final total = unitPrice * quantity;
        final perKgPrice = unitWeight > 0 ? total / unitWeight : 0;

        row[4].text = unitPrice.toStringAsFixed(2);
        row[6].text = total.toStringAsFixed(2);
        row[7].text = perKgPrice.toStringAsFixed(2);
      }
    }
  }

  Map<String, dynamic> _calculateSummary() {
    double totalQuantity = 0;
    double totalAmount = 0;
    double totalProfit = 0;
    double totalWeight = 0;

    for (var row in quoteTable) {
      totalQuantity += double.tryParse(row[2].text) ?? 0;
      totalAmount += double.tryParse(row[6].text) ?? 0;
      totalProfit +=
          (double.tryParse(row[3].text) ?? 0) *
          (double.tryParse(row[5].text) ?? 0) /
          100;
      totalWeight += double.tryParse(row[1].text) ?? 0;
    }

    return {
      'quantity': totalQuantity,
      'amount': totalAmount,
      'profit': totalProfit,
      'weight': totalWeight,
    };
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final client = Supabase.instance.client;
      final now = DateTime.now();
      final activityDate = DateFormat('yyyy-MM-dd').format(now);
      final activityTime = DateFormat('HH:mm:ss').format(now);
      final isMonolithic =
          widget.leadType.toLowerCase() == 'monolithic formwork';

      // 1. Insert into leads table
      final response = await client
          .from('leads')
          .insert({
            'project_name': projectNameController.text.trim(),
            'client_name': clientNameController.text.trim(),
            'project_location': projectLocationController.text.trim(),
            'remark': remarkController.text.trim(),
            'main_contact_name': contacts[0]['name']!.text.trim(),
            'main_contact_designation': contacts[0]['designation']!.text.trim(),
            'main_contact_email': contacts[0]['email']!.text.trim(),
            'main_contact_mobile': contacts[0]['mobile']!.text.trim(),
            'user_type': widget.userType,
            'user_email': widget.userEmail,
            'lead_generated_by': widget.userId,
            'lead_type': widget.leadType,
            'status': 'New/Progress',
            'created_by': widget.userId,
            'custom_status': null,
          })
          .select('id');

      final leadId = response[0]['id'];

      // 2. Insert additional contacts into lead_contacts table (skip first contact as it's main contact)
      if (contacts.length > 1) {
        final List<Map<String, dynamic>> additionalContacts = [];
        for (int i = 1; i < contacts.length; i++) {
          final contact = contacts[i];
          if (contact['name']!.text.trim().isNotEmpty) {
            additionalContacts.add({
              'lead_id': leadId,
              'contact_name': contact['name']!.text.trim(),
              'designation': contact['designation']!.text.trim(),
              'email': contact['email']!.text.trim(),
              'mobile': contact['mobile']!.text.trim(),
            });
          }
        }

        if (additionalContacts.isNotEmpty) {
          await client.from('lead_contacts').insert(additionalContacts);
        }
      }

      // 3. Insert attachments into lead_attachments table
      final List<Map<String, dynamic>> attachmentData = [];
      for (var attachment in attachments) {
        if (attachment['fileName']!.text.trim().isNotEmpty) {
          attachmentData.add({
            'lead_id': leadId,
            'file_name': attachment['fileName']!.text.trim(),
            'file_link': attachment['fileLink']!.text.trim(),
          });
        }
      }

      if (attachmentData.isNotEmpty) {
        await client.from('lead_attachments').insert(attachmentData);
      }

      // 4. Insert quote data into proposal_input (only for Scaffolding)
      if (!isMonolithic) {
        final List<Map<String, dynamic>> quoteData = quoteTable.map((row) {
          return {
            'item_name': row[0].text,
            'unit_weight': double.tryParse(row[1].text) ?? 0,
            'quantity': double.tryParse(row[2].text) ?? 0,
            'ex_factory_price': double.tryParse(row[3].text) ?? 0,
            'unit_price': double.tryParse(row[4].text) ?? 0,
            'profit_percent': double.tryParse(row[5].text) ?? 0,
            'total': double.tryParse(row[6].text) ?? 0,
            'per_kg_price': double.tryParse(row[7].text) ?? 0,
          };
        }).toList();

        await client.from('proposal_input').insert({
          'lead_id': leadId,
          'input': 'Initial Quote Data',
          'value': jsonEncode(quoteData),
          'created_at': now.toIso8601String(),
        });
      }

      // 5. Record in lead_activity table
      await client.from('lead_activity').insert({
        'lead_id': leadId,
        'activity_date': activityDate,
        'activity_time': activityTime,
        'user_name': widget.userEmail,
        'activity': 'Lead Created',
        'changes_made': 'New lead created by ${widget.userEmail}',
      });

      widget.onLeadCreated();
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating lead: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;
    final isMonolithic = widget.leadType.toLowerCase() == 'monolithic formwork';

    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Lead - ${widget.leadType}'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
            child: _isSubmitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text('Submit'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? 1200 : double.infinity,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Information Section
                _buildSectionHeader('Basic Information', Icons.info),
                const SizedBox(height: 16),
                if (isWide)
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'Client Name',
                          clientNameController,
                          true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          'Project Name',
                          projectNameController,
                          true,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildTextField(
                        'Client Name',
                        clientNameController,
                        true,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Project Name',
                        projectNameController,
                        true,
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                if (isWide)
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'Project Location',
                          projectLocationController,
                          true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          'Remark',
                          remarkController,
                          false,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildTextField(
                        'Project Location',
                        projectLocationController,
                        true,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField('Remark', remarkController, false),
                    ],
                  ),

                const SizedBox(height: 32),

                // Contact Information Section
                _buildSectionHeader('Contact Information', Icons.contact_phone),
                const SizedBox(height: 16),
                ...contacts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final contact = entry.value;
                  return _buildContactRow(contact, index);
                }),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _addContact,
                  icon: Icon(Icons.add),
                  label: Text('Add Contact'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 32),

                // Attachments Section
                _buildSectionHeader('Attachments', Icons.attach_file),
                const SizedBox(height: 16),
                ...attachments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final attachment = entry.value;
                  return _buildAttachmentRow(attachment, index);
                }),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _addAttachment,
                  icon: Icon(Icons.add),
                  label: Text('Add Attachment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                  ),
                ),

                // Initial Quote Section - Only for Scaffolding
                if (!isMonolithic) ...[
                  const SizedBox(height: 32),
                  _buildSectionHeader('Initial Quote', Icons.calculate),
                  const SizedBox(height: 16),
                  _buildQuoteTable(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[600], size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool required,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: required
          ? (value) => value!.isEmpty ? 'Required' : null
          : null,
    );
  }

  Widget _buildContactRow(
    Map<String, TextEditingController> contact,
    int index,
  ) {
    final isMainContact = index == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isMainContact ? Colors.blue[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMainContact ? Colors.blue[200]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isMainContact
                    ? 'Main Contact'
                    : 'Additional Contact ${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isMainContact ? Colors.blue[700] : Colors.grey[700],
                ),
              ),
              if (!isMainContact)
                IconButton(
                  onPressed: () => _removeContact(index),
                  icon: Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Remove Contact',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField('Name', contact['name']!, true)),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'Designation',
                  contact['designation']!,
                  true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField('Email', contact['email']!, true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField('Mobile', contact['mobile']!, true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentRow(
    Map<String, TextEditingController> attachment,
    int index,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Attachment ${index + 1}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (attachments.length > 1)
                IconButton(
                  onPressed: () => _removeAttachment(index),
                  icon: Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Remove Attachment',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'File Name',
                  attachment['fileName']!,
                  false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'File Link',
                  attachment['fileLink']!,
                  false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteTable() {
    final summary = _calculateSummary();

    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Item Name',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  'Unit Weight (kg)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  'Quantity',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  'Ex-Factory Price',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  'Unit Price',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  'Profit (%)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  'Per/Kg Price',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  'Actions',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        // Table Body
        ...quoteTable.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          return _buildQuoteRow(row, index);
        }),
        // Summary Row
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'TOTAL',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text('${summary['weight'].toStringAsFixed(1)} kg'),
              ),
              Expanded(
                child: Text('${summary['quantity'].toStringAsFixed(1)}'),
              ),
              Expanded(child: Text('')),
              Expanded(child: Text('')),
              Expanded(child: Text('${summary['profit'].toStringAsFixed(2)}%')),
              Expanded(child: Text('₹${summary['amount'].toStringAsFixed(2)}')),
              Expanded(child: Text('')),
              Expanded(child: Text('')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _addQuoteRow,
          icon: Icon(Icons.add),
          label: Text('Add Quote Row'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteRow(List<TextEditingController> row, int index) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: row[0],
              decoration: InputDecoration(hintText: 'Item Name'),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: row[1],
              decoration: InputDecoration(hintText: 'Weight'),
              onChanged: (value) => _calculateQuoteRow(index),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: row[2],
              decoration: InputDecoration(hintText: 'Qty'),
              onChanged: (value) => _calculateQuoteRow(index),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: row[3],
              decoration: InputDecoration(hintText: 'Ex-Factory'),
              onChanged: (value) => _calculateQuoteRow(index),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: row[4],
              decoration: InputDecoration(hintText: 'Unit Price'),
              enabled: false,
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: row[5],
              decoration: InputDecoration(hintText: 'Profit %'),
              onChanged: (value) => _calculateQuoteRow(index),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: row[6],
              decoration: InputDecoration(hintText: 'Total'),
              enabled: false,
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: row[7],
              decoration: InputDecoration(hintText: 'Per/Kg'),
              enabled: false,
            ),
          ),
          Expanded(
            child: IconButton(
              onPressed: quoteTable.length > 1
                  ? () => _removeQuoteRow(index)
                  : null,
              icon: Icon(Icons.delete, color: Colors.red),
              tooltip: 'Remove Row',
            ),
          ),
        ],
      ),
    );
  }
}

// Query Dialog Widget for Sales
class SalesQueryDialog extends StatefulWidget {
  final Map<String, dynamic> lead;

  const SalesQueryDialog({super.key, required this.lead});

  @override
  State<SalesQueryDialog> createState() => _SalesQueryDialogState();
}

class _SalesQueryDialogState extends State<SalesQueryDialog> {
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

      // Get current user's username more reliably
      String? currentUsername;
      try {
        final currentUser = await client.auth.getUser();
        if (currentUser.user != null) {
          // First try to get username from users table
          var userData = await client
              .from('users')
              .select('username')
              .eq('id', currentUser.user!.id)
              .maybeSingle();

          if (userData != null) {
            currentUsername = userData['username'];
          } else {
            // If not found in users, try dev_user table
            userData = await client
                .from('dev_user')
                .select('username')
                .eq('id', currentUser.user!.id)
                .maybeSingle();

            if (userData != null) {
              currentUsername = userData['username'];
            }
          }

          // If still not found, use email as fallback
          if (currentUsername == null || currentUsername.isEmpty) {
            currentUsername =
                currentUser.user!.email?.split('@')[0] ?? 'Unknown User';
          }
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

// Alerts Dialog Widget for Sales
class SalesAlertsDialog extends StatefulWidget {
  final Map<String, dynamic> lead;

  const SalesAlertsDialog({super.key, required this.lead});

  @override
  State<SalesAlertsDialog> createState() => _SalesAlertsDialogState();
}

class _SalesAlertsDialogState extends State<SalesAlertsDialog> {
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

      // Get current user's username more reliably
      String? currentUsername;
      try {
        final currentUser = await client.auth.getUser();
        if (currentUser.user != null) {
          // First try to get username from users table
          var userData = await client
              .from('users')
              .select('username')
              .eq('id', currentUser.user!.id)
              .maybeSingle();

          if (userData != null) {
            currentUsername = userData['username'];
          } else {
            // If not found in users, try dev_user table
            userData = await client
                .from('dev_user')
                .select('username')
                .eq('id', currentUser.user!.id)
                .maybeSingle();

            if (userData != null) {
              currentUsername = userData['username'];
            }
          }

          // If still not found, use email as fallback
          if (currentUsername == null || currentUsername.isEmpty) {
            currentUsername =
                currentUser.user!.email?.split('@')[0] ?? 'Unknown User';
          }
        }
      } catch (e) {
        currentUsername = 'Unknown User';
      }

      // Fetch alerts for current user (as receiver)
      final alerts = await client
          .from('queries')
          .select('*')
          .eq('receiver_name', currentUsername ?? 'Unknown User')
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
      title: const Text('My Alerts & Queries'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All queries sent to you:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_alerts.isEmpty)
              const Center(
                child: Text(
                  'No alerts or queries found for you.',
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
                            const SizedBox(height: 4),
                            Text(
                              'Lead ID: ${alert['lead_id'] ?? 'Unknown'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.orange,
                                fontSize: 12,
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

// Sales-specific LeadTable for sales users
class SalesLeadTable extends StatefulWidget {
  final String currentUserId;
  final String currentUserEmail;
  final String currentUserType;

  const SalesLeadTable({
    super.key,
    required this.currentUserId,
    required this.currentUserEmail,
    required this.currentUserType,
  });

  @override
  State<SalesLeadTable> createState() => _SalesLeadTableState();
}

class _SalesLeadTableState extends State<SalesLeadTable> {
  List<Map<String, dynamic>> _leads = [];
  List<Map<String, dynamic>> _filteredLeads = [];
  String _searchText = '';
  String _selectedFilter = 'All';
  String _sortBy = 'date';
  bool _sortAscending = false;
  bool _isLoading = true;
  Set<String> _selectedLeads = {};
  bool _selectAll = false;

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
    _fetchLeads();
  }

  Future<void> _fetchLeads() async {
    debugPrint('Fetching leads for user: ${widget.currentUserId}');
    setState(() {
      _isLoading = true;
    });

    try {
      final client = Supabase.instance.client;

      // Fetch leads data - only leads generated by current sales user
      final leadsResult = await client
          .from('leads')
          .select(
            'id, created_at, project_name, client_name, project_location, lead_generated_by, status',
          )
          .eq('lead_generated_by', widget.currentUserId)
          .order('created_at', ascending: false);

      debugPrint('Fetched ${leadsResult.length} leads from database');

      // Fetch users data for sales person names
      final usersResult = await client.from('users').select('id, username');

      // Fetch proposal_input data for Area and MS Weight
      final proposalInputResult = await client
          .from('proposal_input')
          .select('lead_id, input, value');

      // Fetch admin_response data for Rate sq/m and approval status
      final adminResponseResult = await client
          .from('admin_response')
          .select('lead_id, rate_sqm, status, remark');

      // Create maps for quick lookup
      final Map<String, String> userMap = {};
      for (final user in usersResult) {
        userMap[user['id']] = user['username'] ?? '';
      }

      // Process proposal_input data to calculate Aluminium Area and MS Weight
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

      // Join the data
      final List<Map<String, dynamic>> joinedLeads = [];
      for (final lead in leadsResult) {
        final leadId = lead['id'];
        final salesPersonName = userMap[lead['lead_generated_by']] ?? '';
        final adminResponseData = adminResponseMap[leadId];

        // Calculate MS Weight average
        final msWeights = msWeightMap[leadId] ?? [];
        final msWeightAverage = msWeights.isNotEmpty
            ? msWeights.reduce((a, b) => a + b) / msWeights.length
            : 0.0;

        joinedLeads.add({
          'lead_id': leadId,
          'date': lead['created_at'],
          'project_name': lead['project_name'] ?? '',
          'client_name': lead['client_name'] ?? '',
          'project_location': lead['project_location'] ?? '',
          'sales_person_name': salesPersonName,
          'aluminium_area': aluminiumAreaMap[leadId] ?? 0,
          'ms_weight': msWeightAverage,
          'rate_sqm': adminResponseData?['rate_sqm'] ?? 0,
          'approved': adminResponseData?['status'] == 'Approved',
        });
      }

      debugPrint('Processed ${joinedLeads.length} leads for display');
      setState(() {
        _leads = joinedLeads;
        _filteredLeads = joinedLeads;
        _isLoading = false;
      });
      debugPrint('Leads state updated successfully');
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

  void _updateSelectAll() {
    final allSelected = _filteredLeads.every(
      (lead) => _selectedLeads.contains(lead['lead_id'].toString()),
    );
    if (_selectAll != allSelected) {
      setState(() {
        _selectAll = allSelected;
      });
    }
  }

  void _exportLeads() {
    if (_filteredLeads.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No leads to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _showCryptoKeyValidationDialog();
  }

  void _showCryptoKeyValidationDialog() {
    final cryptoKeyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Crypto Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please enter the crypto key to export leads:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cryptoKeyController,
              decoration: const InputDecoration(
                labelText: 'Crypto Key',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _validateCryptoKey(cryptoKeyController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Validate Key'),
          ),
        ],
      ),
    );
  }

  void _validateCryptoKey(String cryptoKey) {
    // Simple validation - you can implement your own logic
    if (cryptoKey == 'admin123') {
      _performExport();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid crypto key'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _performExport() {
    try {
      final csvData = _generateCSV();
      final fileName =
          'sales_leads_export_${DateTime.now().millisecondsSinceEpoch}.csv';

      _showExportPreviewDialog(csvData, fileName);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _generateCSV() {
    final csvBuffer = StringBuffer();

    // Add header
    csvBuffer.writeln(
      'Lead ID,Date,Project Name,Client Name,Location,Aluminium Area,MS Weight,Rate sq/m,Status,Total Amount',
    );

    // Add data rows
    for (final lead in _filteredLeads) {
      final status = _getLeadStatus(lead);
      final totalAmount = calculateTotalAmount(lead);

      csvBuffer.writeln(
        [
          lead['lead_id'],
          _formatDate(lead['date']),
          '"${lead['project_name']}"',
          '"${lead['client_name']}"',
          '"${lead['project_location']}"',
          lead['aluminium_area'],
          lead['ms_weight'],
          lead['rate_sqm'],
          status,
          totalAmount,
        ].join(','),
      );
    }

    return csvBuffer.toString();
  }

  double calculateTotalAmount(Map<String, dynamic> lead) {
    final aluminiumArea = lead['aluminium_area'] ?? 0.0;
    final rateSqm = lead['rate_sqm'] ?? 0.0;
    return aluminiumArea * rateSqm;
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = date is String ? DateTime.parse(date) : date as DateTime;
      return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }

  void _showExportPreviewDialog(String content, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.file_download, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Export Preview'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Text(
                'File: $fileName',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      content,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
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
          ElevatedButton.icon(
            onPressed: () {
              _downloadExport(content, fileName);
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.download),
            label: const Text('Download'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadExport(String content, String fileName) async {
    // For web, trigger download
    if (kIsWeb) {
      // For web, show success message (download handled by browser)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export ready for download: $fileName'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // For mobile/desktop, show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export saved as $fileName'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _viewLeadDetails(Map<String, dynamic> lead) async {
    final leadId = lead['lead_id'];

    // Record the view activity
    await _recordLeadActivity(
      leadId.toString(),
      'Lead Viewed',
      'Lead details viewed by sales user',
      widget.currentUserId,
      widget.currentUserEmail,
    );

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator());
      },
    );

    try {
      final client = Supabase.instance.client;

      // Fetch all lead details
      final leadDetails = await client
          .from('leads')
          .select('*')
          .eq('id', leadId)
          .maybeSingle();

      if (leadDetails == null) {
        throw Exception('Lead not found');
      }

      // Fetch user details for sales person
      final salesPersonDetails = await client
          .from('users')
          .select('username, email')
          .eq('id', leadDetails['lead_generated_by'])
          .maybeSingle();

      // Fetch all proposal inputs for this lead
      final proposalInputs = await client
          .from('proposal_input')
          .select('*')
          .eq('lead_id', leadId)
          .order('input');

      // Fetch admin response for this lead (latest only)
      final adminResponse = await client
          .from('admin_response')
          .select('*')
          .eq('lead_id', leadId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // Fetch lead activity timeline
      final activityTimeline = await client
          .from('lead_activity')
          .select('*')
          .eq('lead_id', leadId)
          .order('activity_date', ascending: false)
          .order('activity_time', ascending: false);

      // Fetch comprehensive activity data from all tables
      final allActivityData = await _fetchAllActivityData(leadId);

      // Fetch customer details if available (latest only)
      List<Map<String, dynamic>> customerDetails = [];
      if (leadDetails['client_name'] != null) {
        try {
          customerDetails = await client
              .from('customers')
              .select('*')
              .eq('name', leadDetails['client_name'])
              .order('created_at', ascending: false)
              .limit(1);
        } catch (e) {
          // Customer table might not exist or have different structure
          debugPrint('Customer details not available: $e');
        }
      }

      // Fetch any comments or notes
      List<Map<String, dynamic>> comments = [];
      try {
        comments = await client
            .from('lead_comments')
            .select('*')
            .eq('lead_id', leadId)
            .order('created_at', ascending: false);
      } catch (e) {
        // Comments table might not exist
        debugPrint('Comments not available: $e');
      }

      // Fetch any tasks related to this lead
      List<Map<String, dynamic>> tasks = [];
      try {
        tasks = await client
            .from('tasks')
            .select('*')
            .eq('lead_id', leadId)
            .order('due_date', ascending: true);
      } catch (e) {
        // Tasks table might not exist
        debugPrint('Tasks not available: $e');
      }

      // Fetch any follow-ups
      List<Map<String, dynamic>> followUps = [];
      try {
        followUps = await client
            .from('lead_followups')
            .select('*')
            .eq('lead_id', leadId)
            .order('followup_date', ascending: false);
      } catch (e) {
        // Follow-ups table might not exist
        debugPrint('Follow-ups not available: $e');
      }

      // Fetch any quotations
      List<Map<String, dynamic>> quotations = [];
      try {
        quotations = await client
            .from('quotations')
            .select('*')
            .eq('lead_id', leadId)
            .order('created_at', ascending: false);
      } catch (e) {
        // Quotations table might not exist
        debugPrint('Quotations not available: $e');
      }

      // Fetch any invoices
      List<Map<String, dynamic>> invoices = [];
      try {
        invoices = await client
            .from('invoices')
            .select('*')
            .eq('lead_id', leadId)
            .order('created_at', ascending: false);
      } catch (e) {
        // Invoices table might not exist
        debugPrint('Invoices not available: $e');
      }

      // Fetch main contact information from leads table
      List<Map<String, dynamic>> mainContacts = [];
      if (leadDetails['main_contact_name'] != null &&
          leadDetails['main_contact_name'].toString().isNotEmpty) {
        mainContacts = [
          {
            'name': leadDetails['main_contact_name'],
            'designation': leadDetails['main_contact_designation'] ?? 'N/A',
            'email': leadDetails['main_contact_email'] ?? 'N/A',
            'mobile': leadDetails['main_contact_mobile'] ?? 'N/A',
          },
        ];
      }

      // Fetch lead attachments
      List<Map<String, dynamic>> leadAttachments = [];
      try {
        leadAttachments = await client
            .from('lead_attachments')
            .select('file_name, file_link')
            .eq('lead_id', leadId)
            .order('created_at', ascending: false);
      } catch (e) {
        // Lead attachments table might not exist
        debugPrint('Lead attachments not available: $e');
      }

      // Fetch lead contacts
      List<Map<String, dynamic>> leadContacts = [];
      try {
        leadContacts = await client
            .from('lead_contacts')
            .select('contact_name, designation, email, mobile')
            .eq('lead_id', leadId)
            .order('created_at', ascending: false);
      } catch (e) {
        // Lead contacts table might not exist
        debugPrint('Lead contacts not available: $e');
      }

      // Fetch queries
      List<Map<String, dynamic>> queries = [];
      try {
        queries = await client
            .from('queries')
            .select('*')
            .eq('lead_id', leadId)
            .order('created_at', ascending: false);
      } catch (e) {
        // Queries table might not exist
        debugPrint('Queries not available: $e');
      }

      // Fetch proposal files
      List<Map<String, dynamic>> proposalFiles = [];
      try {
        final proposalFilesResult = await client
            .from('proposal_file')
            .select('file_name, file_link, user_id')
            .eq('lead_id', leadId)
            .order('created_at', ascending: false);

        // Fetch usernames for each user_id
        for (final file in proposalFilesResult) {
          final userId = file['user_id'];
          String username = 'N/A';

          if (userId != null) {
            try {
              final userResult = await client
                  .from('users')
                  .select('username')
                  .eq('id', userId)
                  .maybeSingle();
              username = userResult?['username'] ?? 'N/A';
            } catch (e) {
              // Try dev_user table if users table fails
              try {
                final devUserResult = await client
                    .from('dev_user')
                    .select('username')
                    .eq('id', userId)
                    .maybeSingle();
                username = devUserResult?['username'] ?? 'N/A';
              } catch (e) {
                username = 'N/A';
              }
            }
          }

          proposalFiles.add({...file, 'username': username});
        }
      } catch (e) {
        // Proposal file table might not exist
        debugPrint('Proposal files not available: $e');
      }

      // Fetch proposal remarks with user details
      List<Map<String, dynamic>> proposalRemarks = [];
      try {
        final proposalRemarksResult = await client
            .from('proposal_remark')
            .select('*, users!proposal_remark_user_id_fkey(username)')
            .eq('lead_id', leadId)
            .order('created_at', ascending: false);

        proposalRemarks = proposalRemarksResult.map((remark) {
          final user = remark['users'] as Map<String, dynamic>?;
          return {...remark, 'username': user?['username'] ?? 'N/A'};
        }).toList();
      } catch (e) {
        // Proposal remark table might not exist
        debugPrint('Proposal remarks not available: $e');
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Show comprehensive details dialog
        _showComprehensiveLeadDetailsDialog(
          leadDetails,
          salesPersonDetails ?? {'username': 'N/A', 'email': 'N/A'},
          proposalInputs,
          adminResponse,
          activityTimeline,
          customerDetails.isNotEmpty ? customerDetails.first : null,
          comments,
          tasks,
          followUps,
          quotations,
          invoices,
          mainContacts,
          leadAttachments,
          leadContacts,
          queries,
          proposalFiles,
          proposalRemarks,
          allActivityData,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching lead details: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAllActivityData(
    String leadId,
  ) async {
    final client = Supabase.instance.client;
    final List<Map<String, dynamic>> allActivities = [];

    try {
      // First, get all activities from lead_activity table (primary activity log)
      try {
        final leadActivities = await client
            .from('lead_activity')
            .select('*')
            .eq('lead_id', leadId)
            .order('activity_date', ascending: false)
            .order('activity_time', ascending: false);

        if (leadActivities.isNotEmpty) {
          for (final item in leadActivities) {
            final activityItem = {
              ...item,
              'table_source': 'lead_activity',
              'activity_type': item['activity_type'] ?? 'Lead Activity',
              'activity_description':
                  item['description'] ?? 'Activity recorded',
              'activity_date': item['activity_date'],
              'activity_time': item['activity_time'],
              'is_primary_activity': true,
            };
            allActivities.add(activityItem);
          }
        }
      } catch (e) {
        debugPrint('Error fetching from lead_activity: $e');
      }

      // Then, search for lead_id in all other tables to find related activities
      final tables = [
        'activity_logs',
        'lead_comments',
        'tasks',
        'lead_followups',
        'queries',
        'proposal_remark',
        'admin_response',
        'quotations',
        'invoices',
        'lead_attachments',
        'lead_contacts',
        'proposal_input',
        'proposal_file',
        'leads', // Include leads table for lead creation/updates
        'users', // Include users table for user-related activities
      ];

      for (final table in tables) {
        try {
          // Search for lead_id in the table
          final data = await client
              .from(table)
              .select('*')
              .eq('lead_id', leadId);

          if (data.isNotEmpty) {
            for (final item in data) {
              // Add table source and format activity data
              final activityItem = {
                ...item,
                'table_source': table,
                'activity_type': _getActivityType(table, item),
                'activity_description': _getActivityDescription(table, item),
                'activity_date':
                    item['created_at'] ??
                    item['activity_date'] ??
                    item['date'] ??
                    item['updated_at'],
                'activity_time':
                    item['created_at'] ?? item['activity_time'] ?? item['time'],
                'is_primary_activity': false,
              };
              allActivities.add(activityItem);
            }
          }
        } catch (e) {
          // Skip tables that don't exist or have different structure
          debugPrint('Error fetching from $table: $e');
        }
      }

      // Also search for activities where lead_id might be in different column names
      final alternativeColumnSearches = [
        {'table': 'activity_logs', 'column': 'related_lead_id'},
        {'table': 'tasks', 'column': 'related_lead'},
        {'table': 'comments', 'column': 'lead_reference'},
        {'table': 'notifications', 'column': 'lead_id'},
      ];

      for (final search in alternativeColumnSearches) {
        try {
          final data = await client
              .from(search['table']!)
              .select('*')
              .eq(search['column']!, leadId);

          if (data.isNotEmpty) {
            for (final item in data) {
              final activityItem = {
                ...item,
                'table_source': search['table']!,
                'activity_type': _getActivityType(search['table']!, item),
                'activity_description': _getActivityDescription(
                  search['table']!,
                  item,
                ),
                'activity_date':
                    item['created_at'] ??
                    item['activity_date'] ??
                    item['date'] ??
                    item['updated_at'],
                'activity_time':
                    item['created_at'] ?? item['activity_time'] ?? item['time'],
                'is_primary_activity': false,
              };
              allActivities.add(activityItem);
            }
          }
        } catch (e) {
          // Skip if table or column doesn't exist
          debugPrint(
            'Error searching ${search['table']}.${search['column']}: $e',
          );
        }
      }

      // Sort by date and time (most recent first)
      allActivities.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['activity_date']?.toString() ?? '') ??
            DateTime.now();
        final dateB =
            DateTime.tryParse(b['activity_date']?.toString() ?? '') ??
            DateTime.now();
        return dateB.compareTo(dateA);
      });

      return allActivities;
    } catch (e) {
      debugPrint('Error fetching all activity data: $e');
      return [];
    }
  }

  String _getActivityType(String table, Map<String, dynamic> item) {
    switch (table) {
      case 'activity_logs':
        return item['activity_type'] ?? 'Activity';
      case 'lead_activity':
        return item['activity_type'] ?? 'Lead Activity';
      case 'lead_comments':
        return 'Comment';
      case 'tasks':
        return 'Task';
      case 'lead_followups':
        return 'Follow-up';
      case 'queries':
        return 'Query';
      case 'proposal_remark':
        return 'Proposal Remark';
      case 'admin_response':
        return 'Admin Response';
      case 'quotations':
        return 'Quotation';
      case 'invoices':
        return 'Invoice';
      case 'lead_attachments':
        return 'Attachment';
      case 'lead_contacts':
        return 'Contact';
      case 'proposal_input':
        return 'Proposal Input';
      case 'proposal_file':
        return 'Proposal File';
      default:
        return 'Activity';
    }
  }

  String _getActivityDescription(String table, Map<String, dynamic> item) {
    switch (table) {
      case 'activity_logs':
        return item['description'] ?? 'Activity logged';
      case 'lead_activity':
        return item['description'] ?? 'Lead activity';
      case 'lead_comments':
        return item['comment'] ?? 'Comment added';
      case 'tasks':
        return '${item['task_title'] ?? 'Task'}: ${item['task_description'] ?? ''}';
      case 'lead_followups':
        return item['followup_notes'] ?? 'Follow-up added';
      case 'queries':
        return item['query_text'] ?? 'Query submitted';
      case 'proposal_remark':
        return item['remark'] ?? 'Proposal remark';
      case 'admin_response':
        return item['response_text'] ?? 'Admin response';
      case 'quotations':
        return 'Quotation: ${item['quotation_number'] ?? ''}';
      case 'invoices':
        return 'Invoice: ${item['invoice_number'] ?? ''}';
      case 'lead_attachments':
        return 'Attachment: ${item['file_name'] ?? ''}';
      case 'lead_contacts':
        return 'Contact: ${item['contact_name'] ?? ''}';
      case 'proposal_input':
        return 'Proposal input updated';
      case 'proposal_file':
        return 'Proposal file: ${item['file_name'] ?? ''}';
      default:
        return 'Activity recorded';
    }
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
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
    );
  }

  Widget _buildDetailRowForDialog(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[800])),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithCopy(
    String label,
    String value, {
    bool isUrl = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: isUrl ? Colors.blue[600] : Colors.grey[800],
                      decoration: isUrl ? TextDecoration.underline : null,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: () => copyToClipboard(context, value),
                  icon: Icon(Icons.copy, size: 16, color: Colors.grey[600]),
                  tooltip: 'Copy to clipboard',
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                ),
                if (isUrl) ...[
                  SizedBox(width: 4),
                  IconButton(
                    onPressed: () => launchURL(value),
                    icon: Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: Colors.blue[600],
                    ),
                    tooltip: 'Open in browser',
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimelineItem(Map<String, dynamic> activity) {
    final activityType = activity['activity_type'] ?? 'Activity';
    final activityDescription =
        activity['activity_description'] ??
        activity['description'] ??
        'No description';
    final activityDate =
        activity['activity_date'] ?? activity['created_at'] ?? activity['date'];
    final activityTime =
        activity['activity_time'] ?? activity['created_at'] ?? activity['time'];
    final tableSource = activity['table_source'] ?? 'Unknown';
    final isPrimaryActivity = activity['is_primary_activity'] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPrimaryActivity ? Colors.blue[50] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPrimaryActivity ? Colors.blue[200]! : Colors.grey[200]!,
          width: isPrimaryActivity ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPrimaryActivity ? Icons.star : Icons.access_time,
                size: 16,
                color: isPrimaryActivity ? Colors.blue[600] : Colors.grey[600],
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_formatDate(activityDate)} ${activityTime != null ? _formatTime(activityTime) : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPrimaryActivity
                        ? Colors.blue[700]
                        : Colors.grey[700],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPrimaryActivity ? Colors.blue[100] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isPrimaryActivity
                      ? 'PRIMARY'
                      : tableSource.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isPrimaryActivity
                        ? Colors.blue[800]
                        : Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            activityType,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isPrimaryActivity ? Colors.blue[800] : Colors.grey[800],
            ),
          ),
          if (activityDescription.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              activityDescription,
              style: TextStyle(
                fontSize: 12,
                color: isPrimaryActivity ? Colors.blue[700] : Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(dynamic timeValue) {
    if (timeValue == null) return '';

    try {
      if (timeValue is String) {
        // If it's a full datetime string, extract time part
        if (timeValue.contains('T') || timeValue.contains(' ')) {
          final dateTime = DateTime.tryParse(timeValue);
          if (dateTime != null) {
            return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
          }
        }
        // If it's just a time string
        return timeValue;
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  Widget _buildFloatingAddButton() {
    return FloatingActionButton(
      onPressed: _showAddLeadDialog,
      backgroundColor: Colors.green[600],
      elevation: 8,
      tooltip: 'Add New Lead',
      child: Icon(Icons.add, color: Colors.white),
    );
  }

  // Record activity in lead_activity table
  Future<void> _recordLeadActivity(
    String leadId,
    String activityType,
    String description,
    String userId,
    String userEmail,
  ) async {
    try {
      final client = Supabase.instance.client;
      final now = DateTime.now();
      final activityDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final activityTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      await client.from('lead_activity').insert({
        'lead_id': leadId,
        'activity_type': activityType,
        'description': description,
        'user_id': userId,
        'user_email': userEmail,
        'activity_date': activityDate,
        'activity_time': activityTime,
        'created_at': now.toIso8601String(),
      });

      debugPrint(
        'Activity recorded: $activityType - $description for lead $leadId',
      );
    } catch (e) {
      debugPrint('Error recording activity: $e');
    }
  }

  void _showComprehensiveLeadDetailsDialog(
    Map<String, dynamic> leadDetails,
    Map<String, dynamic> salesPersonDetails,
    List<Map<String, dynamic>> proposalInputs,
    Map<String, dynamic>? adminResponse,
    List<Map<String, dynamic>> activityTimeline,
    Map<String, dynamic>? customerDetails,
    List<Map<String, dynamic>> comments,
    List<Map<String, dynamic>> tasks,
    List<Map<String, dynamic>> followUps,
    List<Map<String, dynamic>> quotations,
    List<Map<String, dynamic>> invoices,
    List<Map<String, dynamic>> mainContacts,
    List<Map<String, dynamic>> leadAttachments,
    List<Map<String, dynamic>> leadContacts,
    List<Map<String, dynamic>> queries,
    List<Map<String, dynamic>> proposalFiles,
    List<Map<String, dynamic>> proposalRemarks,
    List<Map<String, dynamic>> allActivityData,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
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
                      Icon(Icons.leaderboard, color: Colors.blue[700]),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complete Lead Details - ${leadDetails['project_name'] ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              'Lead ID: ${leadDetails['id']} | Status: ${_getLeadStatus(leadDetails)}',
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
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Information
                        _buildDetailSection('Basic Information', [
                          _buildDetailRowForDialog(
                            'Project Name',
                            leadDetails['project_name'] ?? 'N/A',
                          ),
                          _buildDetailRowForDialog(
                            'Client Name',
                            leadDetails['client_name'] ?? 'N/A',
                          ),
                          _buildDetailRowForDialog(
                            'Project Location',
                            leadDetails['project_location'] ?? 'N/A',
                          ),
                          _buildDetailRowForDialog(
                            'Lead Type',
                            leadDetails['lead_type'] ?? 'N/A',
                          ),
                          _buildDetailRowForDialog(
                            'Created Date',
                            _formatDate(leadDetails['created_at']),
                          ),
                          _buildDetailRowForDialog(
                            'Remark',
                            leadDetails['remark'] ?? 'N/A',
                          ),
                        ]),
                        SizedBox(height: 20),

                        // Sales Person Information
                        _buildDetailSection('Sales Person Information', [
                          _buildDetailRowForDialog(
                            'Name',
                            salesPersonDetails['username'] ?? 'N/A',
                          ),
                          _buildDetailRowForDialog(
                            'Email',
                            salesPersonDetails['email'] ?? 'N/A',
                          ),
                        ]),
                        SizedBox(height: 20),

                        // Customer Details (if available)
                        if (customerDetails != null)
                          _buildDetailSection('Customer Details', [
                            _buildDetailRowForDialog(
                              'Name',
                              customerDetails['name'] ?? 'N/A',
                            ),
                            _buildDetailRowForDialog(
                              'Email',
                              customerDetails['email'] ?? 'N/A',
                            ),
                            _buildDetailRowForDialog(
                              'Phone',
                              customerDetails['phone'] ?? 'N/A',
                            ),
                            _buildDetailRowForDialog(
                              'Address',
                              customerDetails['address'] ?? 'N/A',
                            ),
                            _buildDetailRowForDialog(
                              'Company',
                              customerDetails['company'] ?? 'N/A',
                            ),
                          ]),
                        if (customerDetails != null) SizedBox(height: 20),

                        // Proposal Inputs
                        if (proposalInputs.isNotEmpty)
                          _buildDetailSection(
                            'Proposal Inputs',
                            proposalInputs
                                .map(
                                  (input) => _buildDetailRowForDialog(
                                    input['input'] ?? 'N/A',
                                    input['value']?.toString() ?? 'N/A',
                                  ),
                                )
                                .toList(),
                          ),
                        if (proposalInputs.isNotEmpty) SizedBox(height: 20),

                        // Admin Response
                        if (adminResponse != null)
                          _buildDetailSection('Admin Response', [
                            _buildDetailRowForDialog(
                              'Status',
                              adminResponse['status'] ?? 'N/A',
                            ),
                            _buildDetailRowForDialog(
                              'Rate sq/m',
                              '₹${adminResponse['rate_sqm']?.toString() ?? '0'}',
                            ),
                            _buildDetailRowForDialog(
                              'Total Amount + GST',
                              '₹${adminResponse['total_amount_gst']?.toString() ?? '0'}',
                            ),
                            _buildDetailRowForDialog(
                              'Remark',
                              adminResponse['remark'] ?? 'N/A',
                            ),
                            _buildDetailRowForDialog(
                              'Response Date',
                              _formatDate(adminResponse['created_at']),
                            ),
                          ]),
                        if (adminResponse != null) SizedBox(height: 20),

                        // Tasks
                        if (tasks.isNotEmpty)
                          _buildDetailSection(
                            'Related Tasks',
                            tasks
                                .map(
                                  (task) => _buildDetailRowForDialog(
                                    '${task['title'] ?? 'N/A'} (${_formatDate(task['due_date'])})',
                                    '${task['description'] ?? 'N/A'} - Status: ${task['status'] ?? 'Pending'}',
                                  ),
                                )
                                .toList(),
                          ),
                        if (tasks.isNotEmpty) SizedBox(height: 20),

                        // Follow-ups
                        if (followUps.isNotEmpty)
                          _buildDetailSection(
                            'Follow-ups',
                            followUps
                                .map(
                                  (followup) => _buildDetailRowForDialog(
                                    '${_formatDate(followup['followup_date'])} ${followup['followup_time']}',
                                    '${followup['notes'] ?? 'N/A'} - Status: ${followup['status'] ?? 'Pending'}',
                                  ),
                                )
                                .toList(),
                          ),
                        if (followUps.isNotEmpty) SizedBox(height: 20),

                        // Quotations
                        if (quotations.isNotEmpty)
                          _buildDetailSection(
                            'Quotations',
                            quotations
                                .map(
                                  (quote) => _buildDetailRowForDialog(
                                    'Quote #${quote['id']} (${_formatDate(quote['created_at'])})',
                                    'Amount: ₹${quote['total_amount']?.toString() ?? '0'} - Status: ${quote['status'] ?? 'Draft'}',
                                  ),
                                )
                                .toList(),
                          ),
                        if (quotations.isNotEmpty) SizedBox(height: 20),

                        // Invoices
                        if (invoices.isNotEmpty)
                          _buildDetailSection(
                            'Invoices',
                            invoices
                                .map(
                                  (invoice) => _buildDetailRowForDialog(
                                    'Invoice #${invoice['id']} (${_formatDate(invoice['created_at'])})',
                                    'Amount: ₹${invoice['total_amount']?.toString() ?? '0'} - Status: ${invoice['status'] ?? 'Draft'}',
                                  ),
                                )
                                .toList(),
                          ),
                        if (invoices.isNotEmpty) SizedBox(height: 20),

                        // Lead Attachments
                        if (leadAttachments.isNotEmpty)
                          _buildDetailSection(
                            'Lead Attachments',
                            leadAttachments
                                .map(
                                  (attachment) => _buildDetailRowWithCopy(
                                    attachment['file_name'] ?? 'N/A',
                                    attachment['file_link'] ?? 'N/A',
                                    isUrl: true,
                                  ),
                                )
                                .toList(),
                          ),
                        if (leadAttachments.isNotEmpty) SizedBox(height: 20),

                        // Comments
                        if (comments.isNotEmpty)
                          _buildDetailSection(
                            'Comments & Notes',
                            comments
                                .map(
                                  (comment) => _buildDetailRowForDialog(
                                    '${comment['created_by'] ?? 'N/A'} (${_formatDate(comment['created_at'])})',
                                    comment['comment'] ?? 'N/A',
                                  ),
                                )
                                .toList(),
                          ),
                        if (comments.isNotEmpty) SizedBox(height: 20),

                        // Main Contacts
                        if (mainContacts.isNotEmpty)
                          _buildDetailSection(
                            'Main Contact',
                            mainContacts
                                .map(
                                  (contact) => [
                                    _buildDetailRowWithCopy(
                                      'Name',
                                      contact['name'] ?? 'N/A',
                                    ),
                                    _buildDetailRowWithCopy(
                                      'Designation',
                                      contact['designation'] ?? 'N/A',
                                    ),
                                    _buildDetailRowWithCopy(
                                      'Email',
                                      contact['email'] ?? 'N/A',
                                    ),
                                    _buildDetailRowWithCopy(
                                      'Mobile',
                                      contact['mobile'] ?? 'N/A',
                                    ),
                                  ],
                                )
                                .expand((x) => x)
                                .toList(),
                          ),
                        if (mainContacts.isNotEmpty) SizedBox(height: 20),

                        // Lead Contacts
                        if (leadContacts.isNotEmpty)
                          _buildDetailSection(
                            'Additional Contacts',
                            leadContacts
                                .map(
                                  (contact) => [
                                    _buildDetailRowWithCopy(
                                      'Name',
                                      contact['contact_name'] ?? 'N/A',
                                    ),
                                    _buildDetailRowWithCopy(
                                      'Designation',
                                      contact['designation'] ?? 'N/A',
                                    ),
                                    _buildDetailRowWithCopy(
                                      'Email',
                                      contact['email'] ?? 'N/A',
                                    ),
                                    _buildDetailRowWithCopy(
                                      'Mobile',
                                      contact['mobile'] ?? 'N/A',
                                    ),
                                    SizedBox(
                                      height: 8,
                                    ), // Add spacing between contacts
                                  ],
                                )
                                .expand((x) => x)
                                .toList(),
                          ),
                        if (leadContacts.isNotEmpty) SizedBox(height: 20),

                        // Queries
                        if (queries.isNotEmpty)
                          _buildDetailSection(
                            'Queries',
                            queries
                                .map(
                                  (query) => _buildDetailRowForDialog(
                                    '${query['subject'] ?? 'N/A'} (${_formatDate(query['created_at'])})',
                                    '${query['query_text'] ?? 'N/A'} | Status: ${query['status'] ?? 'N/A'}',
                                  ),
                                )
                                .toList(),
                          ),
                        if (queries.isNotEmpty) SizedBox(height: 20),

                        // Proposal Files
                        if (proposalFiles.isNotEmpty)
                          _buildDetailSection(
                            'Proposal Files',
                            proposalFiles
                                .map(
                                  (file) => _buildDetailRowWithCopy(
                                    '${file['file_name'] ?? 'N/A'} (${file['username'] ?? 'N/A'})',
                                    file['file_link'] ?? 'N/A',
                                    isUrl: true,
                                  ),
                                )
                                .toList(),
                          ),
                        if (proposalFiles.isNotEmpty) SizedBox(height: 20),

                        // Proposal Remarks
                        if (proposalRemarks.isNotEmpty)
                          _buildDetailSection(
                            'Proposal Remarks',
                            proposalRemarks
                                .map(
                                  (remark) => _buildDetailRowForDialog(
                                    '${remark['remark'] ?? 'N/A'} (${remark['username'] ?? 'N/A'})',
                                    remark['created_at'] != null
                                        ? _formatDate(remark['created_at'])
                                        : 'N/A',
                                  ),
                                )
                                .toList(),
                          ),
                        if (proposalRemarks.isNotEmpty) SizedBox(height: 20),

                        // Enhanced Activity Timeline
                        if (allActivityData.isNotEmpty)
                          _buildDetailSection(
                            'Activity Timeline',
                            allActivityData
                                .map(
                                  (activity) =>
                                      _buildActivityTimelineItem(activity),
                                )
                                .toList(),
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

  void _queryLead(Map<String, dynamic> lead) {
    // Show query dialog for sales users
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Query Lead - ${lead['lead_id']}'),
        content: const Text('Query functionality for sales users'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Record the query activity
              await _recordLeadActivity(
                lead['lead_id'].toString(),
                'Query Submitted',
                'Query submitted by sales user',
                widget.currentUserId,
                widget.currentUserEmail,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Query submitted for Lead ${lead['lead_id']}'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Submit Query'),
          ),
        ],
      ),
    );
  }

  void _editLead(Map<String, dynamic> lead) {
    // Show edit dialog for sales users
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Lead - ${lead['lead_id']}'),
        content: const Text('Edit functionality for sales users'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Record the edit activity
              await _recordLeadActivity(
                lead['lead_id'].toString(),
                'Lead Edited',
                'Lead details edited by sales user',
                widget.currentUserId,
                widget.currentUserEmail,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Lead ${lead['lead_id']} updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showRelatedFilesDialog(Map<String, dynamic> lead) async {
    try {
      final client = Supabase.instance.client;

      // Fetch related files
      final proposalFiles = await client
          .from('proposal_file')
          .select('*')
          .eq('lead_id', lead['lead_id']);

      if (proposalFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No related files found for this lead.'),
            backgroundColor: Colors.blue,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.file_copy, color: Colors.blue[600]),
              SizedBox(width: 8),
              Text('Related Files'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lead ID: ${lead['lead_id']}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'This lead has ${proposalFiles.length} associated file(s):',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              ...proposalFiles
                  .map(
                    (file) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.file_present,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              file['file_name'] ?? 'Unknown file',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              SizedBox(height: 16),
              Text(
                'To delete this lead, you must first remove these files.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading related files: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _forceDeleteLead(Map<String, dynamic> lead) async {
    // Show confirmation dialog for force delete
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[600]),
            SizedBox(width: 8),
            Text('Force Delete Lead'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚠️ WARNING: This will permanently delete the lead and ALL associated files!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Lead ID: ${lead['lead_id']}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              'Project: ${lead['project_name'] ?? 'N/A'}',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              'This action will:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Delete all associated proposal files'),
            Text('• Delete all proposal input data'),
            Text('• Delete all admin responses'),
            Text('• Permanently remove the lead'),
            Text('• This action CANNOT be undone!'),
            SizedBox(height: 16),
            Text(
              'Are you absolutely sure you want to proceed?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performForceDelete(lead);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Force Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _performForceDelete(Map<String, dynamic> lead) async {
    try {
      final client = Supabase.instance.client;
      final leadId = lead['lead_id'];

      debugPrint('Force deleting lead: $leadId');

      // First, delete all associated proposal files
      try {
        final proposalFiles = await client
            .from('proposal_file')
            .select('id')
            .eq('lead_id', leadId);

        if (proposalFiles.isNotEmpty) {
          debugPrint('Deleting ${proposalFiles.length} proposal files');
          await client.from('proposal_file').delete().eq('lead_id', leadId);
        }
      } catch (e) {
        debugPrint('Error deleting proposal files: $e');
        // Continue with deletion even if this fails
      }

      // Delete all admin responses
      try {
        final adminResponses = await client
            .from('admin_response')
            .select('id')
            .eq('lead_id', leadId);

        if (adminResponses.isNotEmpty) {
          debugPrint('Deleting ${adminResponses.length} admin responses');
          await client.from('admin_response').delete().eq('lead_id', leadId);
        }
      } catch (e) {
        debugPrint('Error deleting admin responses: $e');
        // Continue with deletion even if this fails
      }

      // Delete all proposal input data
      try {
        final proposalInputs = await client
            .from('proposal_input')
            .select('id')
            .eq('lead_id', leadId);

        if (proposalInputs.isNotEmpty) {
          debugPrint('Deleting ${proposalInputs.length} proposal inputs');
          await client.from('proposal_input').delete().eq('lead_id', leadId);
        }
      } catch (e) {
        debugPrint('Error deleting proposal inputs: $e');
        // Continue with deletion even if this fails
      }

      // Note: Removed contacts, activity_logs, and notifications tables as they don't exist in the database

      // Now delete the lead
      debugPrint('Deleting lead from database');
      final deleteResult = await client.from('leads').delete().eq('id', leadId);
      debugPrint('Delete result: $deleteResult');

      // Record the force delete activity
      try {
        await _recordLeadActivity(
          leadId.toString(),
          'Lead Force Deleted',
          'Lead and all associated files deleted by sales user',
          widget.currentUserId,
          widget.currentUserEmail,
        );
        debugPrint('Activity recorded successfully');
      } catch (activityError) {
        debugPrint('Error recording activity: $activityError');
      }

      // Refresh the leads list
      debugPrint('Refreshing leads list...');
      await _fetchLeads();
      debugPrint('Leads list refreshed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lead $leadId and all associated files deleted successfully',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error during force delete: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error force deleting lead: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showAdminResponsesDialog(Map<String, dynamic> lead) async {
    try {
      final client = Supabase.instance.client;

      // Fetch related admin responses
      final adminResponses = await client
          .from('admin_response')
          .select('*')
          .eq('lead_id', lead['lead_id']);

      if (adminResponses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No admin responses found for this lead.'),
            backgroundColor: Colors.blue,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.blue[600]),
              SizedBox(width: 8),
              Text('Admin Responses'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lead ID: ${lead['lead_id']}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'This lead has ${adminResponses.length} admin response(s):',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              ...adminResponses
                  .map(
                    (response) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status: ${response['status'] ?? 'Unknown'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (response['remark'] != null &&
                                    response['remark'].toString().isNotEmpty)
                                  Text(
                                    'Remark: ${response['remark']}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              SizedBox(height: 16),
              Text(
                'To delete this lead, you must first remove these admin responses.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading admin responses: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteLead(Map<String, dynamic> lead) {
    // Show delete confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete, color: Colors.red[600]),
            SizedBox(width: 8),
            Text('Delete Lead'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this lead?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'Lead ID: ${lead['lead_id']}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              'Project: ${lead['project_name'] ?? 'N/A'}',
              style: TextStyle(fontSize: 14),
            ),
            Text(
              'Client: ${lead['client_name'] ?? 'N/A'}',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '⚠️ This action cannot be undone!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                final client = Supabase.instance.client;

                // First, check if there are any related records that would prevent deletion
                final proposalFiles = await client
                    .from('proposal_file')
                    .select('id')
                    .eq('lead_id', lead['lead_id']);

                if (proposalFiles.isNotEmpty) {
                  // Show warning about related files
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[600]),
                          SizedBox(width: 8),
                          Text('Cannot Delete Lead'),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This lead cannot be deleted because it has associated proposal files.',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Lead ID: ${lead['lead_id']}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Project: ${lead['project_name'] ?? 'N/A'}',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'To delete this lead, you must first:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• Remove all associated proposal files\n• Or contact an administrator',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showRelatedFilesDialog(lead);
                          },
                          child: const Text('View Files'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _forceDeleteLead(lead);
                          },
                          child: Text(
                            'Force Delete',
                            style: TextStyle(
                              color: Colors.red[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                // Check for other potential foreign key constraints
                final adminResponses = await client
                    .from('admin_response')
                    .select('id')
                    .eq('lead_id', lead['lead_id']);

                final proposalInputs = await client
                    .from('proposal_input')
                    .select('id')
                    .eq('lead_id', lead['lead_id']);

                if (adminResponses.isNotEmpty || proposalInputs.isNotEmpty) {
                  // Show warning about admin responses
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[600]),
                          SizedBox(width: 8),
                          Text('Cannot Delete Lead'),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This lead cannot be deleted because it has associated data in other tables.',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Lead ID: ${lead['lead_id']}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Project: ${lead['project_name'] ?? 'N/A'}',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'To delete this lead, you must first:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• Remove all associated data from other tables\n• Or use Force Delete to remove everything',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showAdminResponsesDialog(lead);
                          },
                          child: const Text('View Responses'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _forceDeleteLead(lead);
                          },
                          child: Text(
                            'Force Delete',
                            style: TextStyle(
                              color: Colors.red[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                // If no constraints found, proceed with deletion
                debugPrint('Attempting to delete lead: ${lead['lead_id']}');

                final deleteResult = await client
                    .from('leads')
                    .delete()
                    .eq('id', lead['lead_id']);
                debugPrint('Delete result: $deleteResult');

                // Record the delete activity
                try {
                  await _recordLeadActivity(
                    lead['lead_id'].toString(),
                    'Lead Deleted',
                    'Lead deleted by sales user',
                    widget.currentUserId,
                    widget.currentUserEmail,
                  );
                  debugPrint('Activity recorded successfully');
                } catch (activityError) {
                  debugPrint('Error recording activity: $activityError');
                  // Don't fail the deletion if activity recording fails
                }

                // Refresh the leads list
                debugPrint('Refreshing leads list...');
                await _fetchLeads();
                debugPrint('Leads list refreshed');

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Lead ${lead['lead_id']} deleted successfully',
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Error during lead deletion: $e');
                String errorMessage = 'Error deleting lead';

                // Provide more specific error messages
                if (e.toString().contains('foreign key constraint')) {
                  errorMessage =
                      'Cannot delete lead: It has associated files or responses. Please remove them first or contact an administrator.';
                } else if (e.toString().contains(
                  'proposal_file_lead_id_fkey',
                )) {
                  errorMessage =
                      'Cannot delete lead: It has associated proposal files. Please remove them first.';
                } else if (e.toString().contains('not found')) {
                  errorMessage = 'Lead not found or already deleted.';
                } else if (e.toString().contains('permission')) {
                  errorMessage =
                      'Permission denied. You may not have rights to delete this lead.';
                } else {
                  errorMessage = 'Error deleting lead: ${e.toString()}';
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddLeadDialog() async {
    String? selectedType;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Lead Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Monolithic Formwork'),
              leading: Radio<String>(
                value: 'Monolithic Formwork',
                groupValue: selectedType,
                onChanged: (val) {
                  selectedType = val;
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: Text('Scaffolding'),
              leading: Radio<String>(
                value: 'Scaffolding',
                groupValue: selectedType,
                onChanged: (val) {
                  selectedType = val;
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (selectedType != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          child: SizedBox(
            width: MediaQuery.of(context).size.width > 700
                ? 700
                : MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.9,
            child: _AddLeadForm(
              userType: widget.currentUserType,
              userEmail: widget.currentUserEmail,
              userId: widget.currentUserId,
              leadType: selectedType!,
              onLeadCreated: () {
                Navigator.of(context).pop();
                _fetchLeads(); // Refresh the leads list
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lead created successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ),
        ),
      );
    }
  }

  String _getLeadStatus(Map<String, dynamic> lead) {
    // Check for status first (Won, Lost, Loop, etc.)
    if (lead['status'] != null && lead['status'].toString().isNotEmpty) {
      return lead['status'];
    }

    // Check if lead is approved first
    if (lead['approved'] == true) {
      return 'Approved';
    }

    final createdAt = lead['date'];
    if (createdAt == null) return 'Unknown';

    try {
      final createdDateTime = createdAt is String
          ? DateTime.parse(createdAt)
          : createdAt as DateTime;
      final now = DateTime.now();
      final difference = now.difference(createdDateTime);

      // Check if lead is within last 6 hours
      if (difference.inHours <= 6) {
        return 'New/Progress';
      }

      // Check if lead has proposal_input data
      final aluminiumArea =
          double.tryParse(lead['aluminium_area']?.toString() ?? '0') ?? 0;
      final msWeight =
          double.tryParse(lead['ms_weight']?.toString() ?? '0') ?? 0;

      if (aluminiumArea == 0 && msWeight == 0) {
        return 'Proposal Progress';
      } else {
        return 'Waiting for Approval';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'New/Progress':
        return Colors.blue;
      case 'Proposal Progress':
        return Colors.orange;
      case 'Waiting for Approval':
        return Colors.purple;
      case 'Approved':
        return Colors.green;
      case 'Won':
        return Colors.green[700]!;
      case 'Lost':
        return Colors.red[600]!;
      case 'Loop':
        return Colors.orange[600]!;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateLeadStatus(String leadId, String status) async {
    try {
      final client = Supabase.instance.client;

      await client.from('leads').update({'status': status}).eq('id', leadId);

      // Refresh the leads list
      _fetchLeads();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lead status updated to $status'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating lead status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showStatusUpdateDialog(String leadId, String currentStatus) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.update, color: Colors.blue[600]),
              SizedBox(width: 8),
              Text('Update Lead Status'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current Status: $currentStatus',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Select new status:',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _updateLeadStatus(leadId, 'Won');
                    },
                    icon: Icon(Icons.check_circle, color: Colors.white),
                    label: Text('Won'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _updateLeadStatus(leadId, 'Lost');
                    },
                    icon: Icon(Icons.cancel, color: Colors.white),
                    label: Text('Lost'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _updateLeadStatus(leadId, 'Loop');
                    },
                    icon: Icon(Icons.loop, color: Colors.white),
                    label: Text('Loop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserIconButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 1200;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: isMobile ? _buildFloatingAddButton() : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header with title and controls
                Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Title and description with search for mobile
                      if (isMobile) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.leaderboard,
                              color: Colors.blue[600],
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Leads Management',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  Text(
                                    'Manage and track your leads',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12),
                            // Search box and filter icon next to heading
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      onChanged: _onSearch,
                                      decoration: InputDecoration(
                                        hintText: 'Search...',
                                        prefixIcon: Icon(
                                          Icons.search,
                                          size: 18,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  IconButton(
                                    onPressed: _showFilterDialog,
                                    icon: Icon(Icons.filter_list, size: 20),
                                    tooltip: 'Filters',
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.blue[50],
                                      foregroundColor: Colors.blue[600],
                                      padding: EdgeInsets.all(8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.leaderboard,
                                        color: Colors.blue[600],
                                        size: 28,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Leads Management',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Manage and track your leads',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isWide) ...[
                              IconButton(
                                onPressed: _exportLeads,
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
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      SizedBox(height: isMobile ? 16 : 20),
                      // Compact stats and controls for mobile
                      if (isMobile) ...[
                        // Mobile: Compact horizontal stats bar
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
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
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildCompactStatItem(
                                  'Total',
                                  _calculateStats()['total'].toString(),
                                  Colors.blue,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: Colors.grey[300],
                              ),
                              Expanded(
                                child: _buildCompactStatItem(
                                  'New',
                                  _calculateStats()['new'].toString(),
                                  Colors.orange,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: Colors.grey[300],
                              ),
                              Expanded(
                                child: _buildCompactStatItem(
                                  'Waiting',
                                  _calculateStats()['waiting'].toString(),
                                  Colors.purple,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: Colors.grey[300],
                              ),
                              Expanded(
                                child: _buildCompactStatItem(
                                  'Approved',
                                  _calculateStats()['approved'].toString(),
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Mobile controls removed - filter and export buttons hidden for mobile
                      ] else ...[
                        // Desktop layout
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: _onSearch,
                                decoration: InputDecoration(
                                  hintText: 'Search leads...',
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.grey[600],
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.blue[600]!,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
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
                                onChanged: (value) {
                                  if (value != null) _onFilterChanged(value);
                                },
                                underline: Container(),
                                items: _filterOptions
                                    .map(
                                      (filter) => DropdownMenuItem(
                                        value: filter,
                                        child: Text(filter),
                                      ),
                                    )
                                    .toList(),
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
                                value: _sortBy,
                                onChanged: (value) {
                                  if (value != null) _onSortChanged(value);
                                },
                                underline: Container(),
                                items: _sortOptions
                                    .map(
                                      (sort) => DropdownMenuItem(
                                        value: sort,
                                        child: Text('Sort by $sort'),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            SizedBox(width: 16),
                            IconButton(
                              onPressed: _showFilterDialog,
                              icon: Icon(Icons.filter_list),
                              tooltip: 'Advanced Filters',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.blue[50],
                                foregroundColor: Colors.blue[600],
                              ),
                            ),
                            SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _showAddLeadDialog,
                              icon: Icon(Icons.add),
                              label: Text('Add New Lead'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _exportLeads,
                              icon: Icon(Icons.file_download),
                              label: Text('Export'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple[600],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
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
                    ],
                  ),
                ),
                // Content area
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(isMobile ? 16 : 24),
                    child: isMobile
                        ? _buildMobileCardsView()
                        : _buildDesktopTableView(),
                  ),
                ),
              ],
            ),
    );
  }

  Map<String, int> _calculateStats() {
    int total = _filteredLeads.length;
    int newCount = 0;
    int waitingCount = 0;
    int approvedCount = 0;

    for (final lead in _filteredLeads) {
      final status = _getLeadStatus(lead);
      switch (status) {
        case 'New/Progress':
          newCount++;
          break;
        case 'Waiting for Approval':
          waitingCount++;
          break;
        case 'Approved':
          approvedCount++;
          break;
      }
    }

    return {
      'total': total,
      'new': newCount,
      'waiting': waitingCount,
      'approved': approvedCount,
    };
  }

  Widget _buildTableRow(Map<String, dynamic> lead, int index) {
    final leadId = lead['lead_id'] ?? '';
    final formattedLeadId =
        'Tobler-${leadId.toString().substring(0, 4).toUpperCase()}';
    final status = _getLeadStatus(lead);
    final statusColor = _getStatusColor(status);
    final aluminiumArea =
        double.tryParse(lead['aluminium_area']?.toString() ?? '0') ?? 0;
    final msWeight = double.tryParse(lead['ms_weight']?.toString() ?? '0') ?? 0;
    final rate = double.tryParse(lead['rate_sqm']?.toString() ?? '0') ?? 0;
    final isSelected = _selectedLeads.contains(leadId.toString());

    return Container(
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Material(
        color: isSelected ? Colors.blue[50] : Colors.transparent,
        child: InkWell(
          onTap: () => _toggleLeadSelection(leadId.toString()),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleLeadSelection(leadId.toString()),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedLeadId,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatDate(lead['date']),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    lead['project_name'] ?? '',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    lead['client_name'] ?? '',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    lead['project_location'] ?? '',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '${aluminiumArea.toStringAsFixed(1)} sqm',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '${msWeight.toStringAsFixed(1)} kg',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '₹${rate.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '₹${(aluminiumArea * rate).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _viewLeadDetails(lead),
                        icon: Icon(Icons.visibility, size: 20),
                        tooltip: 'View Details',
                        color: Colors.blue[600],
                      ),
                      IconButton(
                        onPressed: () => _queryLead(lead),
                        icon: Icon(Icons.question_mark, size: 20),
                        tooltip: 'Query Lead',
                        color: Colors.orange[600],
                      ),
                      IconButton(
                        onPressed: () => _editLead(lead),
                        icon: Icon(Icons.edit, size: 20),
                        tooltip: 'Edit Lead',
                        color: Colors.green[600],
                      ),
                      IconButton(
                        onPressed: () =>
                            _showStatusUpdateDialog(lead['lead_id'], status),
                        icon: Icon(Icons.update, size: 20),
                        tooltip: 'Update Status',
                        color: Colors.purple[600],
                      ),
                      IconButton(
                        onPressed: () => _deleteLead(lead),
                        icon: Icon(Icons.delete, size: 20),
                        tooltip: 'Delete Lead',
                        color: Colors.red[600],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCardsView() {
    return ListView.builder(
      itemCount: _filteredLeads.length,
      itemBuilder: (context, index) {
        final lead = _filteredLeads[index];
        final status = _getLeadStatus(lead);
        final statusColor = _getStatusColor(status);
        final isSelected = _selectedLeads.contains(lead['lead_id'].toString());

        return Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              // Enhanced card header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue[50]!,
                      Colors.blue[100]!.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedLeads.add(lead['lead_id'].toString());
                            } else {
                              _selectedLeads.remove(lead['lead_id'].toString());
                            }
                            _updateSelectAll();
                          });
                        },
                        activeColor: Colors.blue[600],
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tobler-${lead['lead_id'].toString().substring(0, 4).toUpperCase()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _formatDate(lead['date']),
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
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Enhanced card content
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project section with icon
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.business,
                            size: 16,
                            color: Colors.blue[600],
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Project',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                lead['project_name'] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Client section with icon
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.green[600],
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Client',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                lead['client_name'] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Location section with icon
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.orange[600],
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Location',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                lead['project_location'] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Metrics section
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildMetricItem(
                              'Area',
                              (lead['aluminium_area']?.toString() ?? '0'),
                              'sqm',
                              Icons.area_chart,
                              Colors.blue,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey[300],
                          ),
                          Expanded(
                            child: _buildMetricItem(
                              'Weight',
                              (lead['ms_weight']?.toString() ?? '0'),
                              'kg',
                              Icons.fitness_center,
                              Colors.purple,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey[300],
                          ),
                          Expanded(
                            child: _buildMetricItem(
                              'Rate',
                              '₹${lead['rate_sqm']?.toString() ?? '0'}',
                              '',
                              Icons.attach_money,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    // User icon action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildUserIconButton(
                          onPressed: () => _viewLeadDetails(lead),
                          icon: Icons.visibility,
                          color: Colors.blue[600]!,
                          tooltip: 'View Details',
                        ),
                        _buildUserIconButton(
                          onPressed: () => _queryLead(lead),
                          icon: Icons.question_answer,
                          color: Colors.orange[600]!,
                          tooltip: 'Query',
                        ),
                        _buildUserIconButton(
                          onPressed: () => _editLead(lead),
                          icon: Icons.edit,
                          color: Colors.green[600]!,
                          tooltip: 'Edit',
                        ),
                        _buildUserIconButton(
                          onPressed: () => _showStatusUpdateDialog(
                            lead['lead_id'],
                            _getLeadStatus(lead),
                          ),
                          icon: Icons.update,
                          color: Colors.purple[600]!,
                          tooltip: 'Status',
                        ),
                        _buildUserIconButton(
                          onPressed: () => _deleteLead(lead),
                          icon: Icons.delete,
                          color: Colors.red[600]!,
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        Text(
          label + (unit.isNotEmpty ? ' ($unit)' : ''),
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStatItem(String label, String value, Color color) {
    final isSelected = _getSelectedFilterFromLabel(label) == _selectedFilter;

    return InkWell(
      onTap: () => _onStatItemTap(label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: color, width: 1) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? color : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSelectedFilterFromLabel(String label) {
    switch (label.toLowerCase()) {
      case 'total':
        return 'All';
      case 'new':
        return 'New/Progress';
      case 'waiting':
        return 'Waiting for Approval';
      case 'approved':
        return 'Approved';
      default:
        return 'All';
    }
  }

  void _onStatItemTap(String label) {
    final filterValue = _getSelectedFilterFromLabel(label);
    _onFilterChanged(filterValue);
  }

  Widget _buildDesktopTableView() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                // Select all row
                Row(
                  children: [
                    Checkbox(
                      value: _selectAll,
                      onChanged: (value) {
                        setState(() {
                          _selectAll = value ?? false;
                          if (_selectAll) {
                            _selectedLeads = _filteredLeads
                                .map((lead) => lead['lead_id'].toString())
                                .toSet();
                          } else {
                            _selectedLeads.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Select All',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    Text(
                      '${_filteredLeads.length} leads',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Column headers row
                Row(
                  children: [
                    SizedBox(width: 48), // Space for checkbox
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Lead ID',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Project',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Client',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Location',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Area',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Weight',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Rate',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Actions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Table body
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.filter_list, color: Colors.blue[600]),
              SizedBox(width: 8),
              Text('Advanced Filters'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status Filter
                DropdownButtonFormField<String>(
                  value: _selectedFilter,
                  decoration: InputDecoration(
                    labelText: 'Status Filter',
                    border: OutlineInputBorder(),
                  ),
                  items: _filterOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value ?? 'All';
                    });
                  },
                ),
                SizedBox(height: 16),
                // Sort By
                DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: InputDecoration(
                    labelText: 'Sort By',
                    border: OutlineInputBorder(),
                  ),
                  items: _sortOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value ?? 'date';
                    });
                  },
                ),
                SizedBox(height: 16),
                // Date Range (if needed)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'From Date',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () {
                          // TODO: Implement date picker
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'To Date',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () {
                          // TODO: Implement date picker
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _applyFilters();
                Navigator.of(context).pop();
              },
              child: Text('Apply Filters'),
            ),
          ],
        );
      },
    );
  }
}

// Relationship Management Page
class RelationshipManagementPage extends StatefulWidget {
  final String currentUserId;
  final String currentUserEmail;
  final String currentUserType;

  const RelationshipManagementPage({
    super.key,
    required this.currentUserId,
    required this.currentUserEmail,
    required this.currentUserType,
  });

  @override
  State<RelationshipManagementPage> createState() =>
      _RelationshipManagementPageState();
}

class _RelationshipManagementPageState
    extends State<RelationshipManagementPage> {
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _sortBy = 'name';
  bool _sortAscending = true;

  // Filter and sort options
  final List<String> _filterOptions = [
    'All',
    'Active',
    'Inactive',
    'VIP',
    'Prospect',
    'Customer',
    'Lead',
  ];

  final List<String> _sortOptions = [
    'name',
    'email',
    'phone',
    'company',
    'last_contact',
    'status',
    'priority',
    'created_at',
  ];

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;

      // Fetch all contacts from multiple sources
      List<Map<String, dynamic>> allContacts = [];

      // First, fetch leads created by the current user
      final userLeads = await client
          .from('leads')
          .select(
            'id, client_name, project_name, main_contact_name, main_contact_designation, main_contact_email, main_contact_mobile',
          )
          .eq('lead_generated_by', widget.currentUserId);

      // Create a map of lead IDs for quick lookup
      final Set<String> userLeadIds = userLeads
          .map((lead) => lead['id'].toString())
          .toSet();

      // Fetch lead contacts for leads created by the current user
      try {
        final leadContacts = await client
            .from('lead_contacts')
            .select('lead_id, contact_name, designation, email, mobile')
            .inFilter('lead_id', userLeadIds.toList());

        for (var contact in leadContacts) {
          // Find the corresponding lead to get client and project info
          final lead = userLeads.firstWhere(
            (lead) => lead['id'].toString() == contact['lead_id'].toString(),
            orElse: () => {},
          );

          allContacts.add({
            'id': '${contact['lead_id']}_${contact['contact_name'] ?? ''}',
            'name': contact['contact_name'] ?? '',
            'designation': contact['designation'] ?? '',
            'email': contact['email'] ?? '',
            'mobile': contact['mobile'] ?? '',
            'client_name': lead['client_name'] ?? '',
            'project_name': lead['project_name'] ?? '',
            'lead_id': contact['lead_id'],
            'source': 'lead_contacts',
            'type': 'Lead Contact',
          });
        }
      } catch (e) {
        debugPrint('Lead contacts not available: $e');
      }

      // Add main contacts from leads created by the current user
      for (var lead in userLeads) {
        if (lead['main_contact_name'] != null &&
            lead['main_contact_name'].toString().isNotEmpty) {
          allContacts.add({
            'id': '${lead['id']}_main',
            'name': lead['main_contact_name'] ?? '',
            'designation': lead['main_contact_designation'] ?? '',
            'email': lead['main_contact_email'] ?? '',
            'mobile': lead['main_contact_mobile'] ?? '',
            'client_name': lead['client_name'] ?? '',
            'project_name': lead['project_name'] ?? '',
            'lead_id': lead['id'],
            'source': 'leads',
            'type': 'Main Contact',
          });
        }
      }

      setState(() {
        _contacts = allContacts;
        _filteredContacts = allContacts;
        _isLoading = false;
      });

      _applyFiltersAndSort();
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch contacts: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    List<Map<String, dynamic>> filtered = _contacts;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((contact) {
        final name = (contact['name'] ?? '').toString().toLowerCase();
        final email = (contact['email'] ?? '').toString().toLowerCase();
        final mobile = (contact['mobile'] ?? '').toString().toLowerCase();
        final clientName = (contact['client_name'] ?? '')
            .toString()
            .toLowerCase();
        final projectName = (contact['project_name'] ?? '')
            .toString()
            .toLowerCase();
        final designation = (contact['designation'] ?? '')
            .toString()
            .toLowerCase();
        final query = _searchQuery.toLowerCase();

        return name.contains(query) ||
            email.contains(query) ||
            mobile.contains(query) ||
            clientName.contains(query) ||
            projectName.contains(query) ||
            designation.contains(query);
      }).toList();
    }

    // Apply status filter
    if (_selectedFilter != 'All') {
      filtered = filtered.where((contact) {
        final status = contact['status'] ?? '';
        final type = contact['type'] ?? '';

        switch (_selectedFilter) {
          case 'Active':
            return status == 'active' || type == 'Customer';
          case 'Inactive':
            return status == 'inactive';
          case 'VIP':
            return contact['priority'] == 'high' || contact['is_vip'] == true;
          case 'Prospect':
            return type == 'Lead Contact' || status == 'prospect';
          case 'Customer':
            return type == 'Customer';
          case 'Lead':
            return type == 'Main Contact' || type == 'Lead Contact';
          default:
            return true;
        }
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      dynamic aValue = a[_sortBy] ?? '';
      dynamic bValue = b[_sortBy] ?? '';

      if (aValue is String && bValue is String) {
        aValue = aValue.toLowerCase();
        bValue = bValue.toLowerCase();
      }

      int comparison = 0;
      if (aValue < bValue) {
        comparison = -1;
      } else if (aValue > bValue) {
        comparison = 1;
      }

      return _sortAscending ? comparison : -comparison;
    });

    setState(() {
      _filteredContacts = filtered;
    });
  }

  void _showContactDetails(Map<String, dynamic> contact) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
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
                      Icon(Icons.person, color: Colors.blue[700]),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact Details - ${contact['name'] ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              'Type: ${contact['type'] ?? 'N/A'} | Source: ${contact['source'] ?? 'N/A'}',
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
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailSection('Basic Information', [
                          _buildDetailRow('Name', contact['name'] ?? 'N/A'),
                          _buildDetailRow('Email', contact['email'] ?? 'N/A'),
                          _buildDetailRow('Mobile', contact['mobile'] ?? 'N/A'),
                          _buildDetailRow(
                            'Designation',
                            contact['designation'] ?? 'N/A',
                          ),
                          _buildDetailRow('Type', contact['type'] ?? 'N/A'),
                        ]),
                        SizedBox(height: 20),

                        _buildDetailSection('Lead Information', [
                          _buildDetailRow(
                            'Client Name',
                            contact['client_name'] ?? 'N/A',
                          ),
                          _buildDetailRow(
                            'Project Name',
                            contact['project_name'] ?? 'N/A',
                          ),
                          _buildDetailRow(
                            'Lead ID',
                            contact['lead_id']?.toString() ?? 'N/A',
                          ),
                        ]),
                        SizedBox(height: 20),

                        SizedBox(height: 20),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _editContact(contact),
                              icon: Icon(Icons.edit),
                              label: Text('Edit'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _addInteraction(contact),
                              icon: Icon(Icons.add),
                              label: Text('Add Interaction'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _scheduleFollowUp(contact),
                              icon: Icon(Icons.schedule),
                              label: Text('Schedule Follow-up'),
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

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
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
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 14), softWrap: true),
          ),
        ],
      ),
    );
  }

  void _editContact(Map<String, dynamic> contact) {
    // TODO: Implement contact editing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit contact functionality coming soon!')),
    );
  }

  void _addInteraction(Map<String, dynamic> contact) {
    // TODO: Implement add interaction
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Add interaction functionality coming soon!')),
    );
  }

  void _scheduleFollowUp(Map<String, dynamic> contact) {
    // TODO: Implement schedule follow-up
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Schedule follow-up functionality coming soon!')),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter & Sort Options'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status Filter
                DropdownButtonFormField<String>(
                  value: _selectedFilter,
                  decoration: InputDecoration(
                    labelText: 'Status Filter',
                    border: OutlineInputBorder(),
                  ),
                  items: _filterOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value ?? 'All';
                    });
                  },
                ),
                SizedBox(height: 16),
                // Sort By
                DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: InputDecoration(
                    labelText: 'Sort By',
                    border: OutlineInputBorder(),
                  ),
                  items: _sortOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value ?? 'name';
                    });
                  },
                ),
                SizedBox(height: 16),
                // Sort Direction
                Row(
                  children: [
                    Text('Sort Direction: '),
                    Switch(
                      value: _sortAscending,
                      onChanged: (value) {
                        setState(() {
                          _sortAscending = value;
                        });
                      },
                    ),
                    Text(_sortAscending ? 'Ascending' : 'Descending'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _applyFiltersAndSort();
                Navigator.of(context).pop();
              },
              child: Text('Apply Filters'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchContacts, child: Text('Retry')),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.people, size: 32, color: Colors.blue[700]),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Relationship Management',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        'Manage all your contacts and customer relationships',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _showFilterDialog,
                  icon: Icon(Icons.filter_list),
                  tooltip: 'Filter & Sort',
                ),
                IconButton(
                  onPressed: _fetchContacts,
                  icon: Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: EdgeInsets.all(20),
            child: TextField(
              decoration: InputDecoration(
                hintText:
                    'Search contacts by name, email, mobile, client, or project...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFiltersAndSort();
              },
            ),
          ),

          // Stats Cards
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Contacts',
                    _contacts.length.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Active',
                    _contacts
                        .where(
                          (c) =>
                              c['status'] == 'active' ||
                              c['type'] == 'Customer',
                        )
                        .length
                        .toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'VIP',
                    _contacts
                        .where(
                          (c) => c['priority'] == 'high' || c['is_vip'] == true,
                        )
                        .length
                        .toString(),
                    Icons.star,
                    Colors.orange,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Prospects',
                    _contacts
                        .where(
                          (c) =>
                              c['type'] == 'Lead Contact' ||
                              c['status'] == 'prospect',
                        )
                        .length
                        .toString(),
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Contacts List
          Expanded(
            child: _filteredContacts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No contacts found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getContactColor(contact),
                            child: Text(
                              _getContactInitials(contact),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            contact['name'] ?? 'N/A',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact['email'] ?? 'N/A',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                '${contact['client_name'] ?? 'N/A'} • ${contact['project_name'] ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${contact['designation'] ?? 'N/A'} • ${contact['type'] ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'view':
                                  _showContactDetails(contact);
                                  break;
                                case 'edit':
                                  _editContact(contact);
                                  break;
                                case 'interaction':
                                  _addInteraction(contact);
                                  break;
                                case 'followup':
                                  _scheduleFollowUp(contact);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility),
                                    SizedBox(width: 8),
                                    Text('View Details'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'interaction',
                                child: Row(
                                  children: [
                                    Icon(Icons.add),
                                    SizedBox(width: 8),
                                    Text('Add Interaction'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'followup',
                                child: Row(
                                  children: [
                                    Icon(Icons.schedule),
                                    SizedBox(width: 8),
                                    Text('Schedule Follow-up'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _showContactDetails(contact),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add new contact
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Add new contact functionality coming soon!'),
            ),
          );
        },
        tooltip: 'Add New Contact',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getContactColor(Map<String, dynamic> contact) {
    final type = contact['type'] ?? '';
    final priority = contact['priority'] ?? '';

    if (priority == 'high' || contact['is_vip'] == true) {
      return Colors.orange;
    }

    switch (type) {
      case 'Customer':
        return Colors.green;
      case 'Main Contact':
        return Colors.blue;
      case 'Lead Contact':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getContactInitials(Map<String, dynamic> contact) {
    final name = contact['name'] ?? '';
    if (name.isEmpty) return '?';

    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }
}
