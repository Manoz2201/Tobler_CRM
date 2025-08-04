import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crm_app/widgets/profile_page.dart';
import 'package:crm_app/screens/home/developer_home_screen.dart'
    show UserManagementPage;
import 'package:intl/intl.dart';
import '../settings/currency_settings_screen.dart';
import '../../utils/navigation_utils.dart';
import '../auth/login_screen.dart';
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

// Helper function to copy text to clipboard
Future<void> copyToClipboard(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }
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

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  bool _isCollapsed = false;
  final Map<int, bool> _hoveredItems = {};

  List<NavItem> get _navItems {
    // Admin users get all navigation items including Leads Management
    return NavigationUtils.getNavigationItemsForRole('admin');
  }

  late final List<Widget> _pages = <Widget>[
    AdminDashboardPage(), // Dashboard
    LeadTable(), // Leads Management
    UserManagementPage(), // User Management
    AdminSettingsPage(), // Settings
    ProfilePage(), // Profile
    // Logout is handled separately in _onItemTapped
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
          // Mobile layout: custom navigation bar
          return Scaffold(
            body: _pages[_selectedIndex],
            bottomNavigationBar: _buildMobileNavigationBar(),
          );
        }
      },
    );
  }
}

// Using NavItem from navigation_utils.dart instead of _NavItem

class _AdminLeadsPage extends StatefulWidget {
  @override
  State<_AdminLeadsPage> createState() => _AdminLeadsPageState();
}

class _AdminLeadsPageState extends State<_AdminLeadsPage> {
  List<Map<String, dynamic>> leads = [];
  bool _isLoading = true;
  String? _error;
  int? _expandedIndex; // For mobile: which card is expanded
  List<Map<String, dynamic>> _activityTimeline = [];
  bool _isActivityLoading = false;
  String? _activityError;
  List<Map<String, dynamic>> _mainContacts = [];
  List<Map<String, dynamic>> _leadContacts = [];
  bool _isContactsLoading = false;
  String? _contactsError;

  @override
  void initState() {
    super.initState();
    _fetchLeads();
  }

  Future<void> _fetchLeads() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _expandedIndex = null;
    });
    try {
      final client = Supabase.instance.client;
      final data = await client
          .from('leads')
          .select('*')
          .order('created_at', ascending: false);
      setState(() {
        leads = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch leads: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchActivityTimeline(String leadId) async {
    setState(() {
      _isActivityLoading = true;
      _activityError = null;
      _activityTimeline = [];
    });
    try {
      final client = Supabase.instance.client;
      final activities = await client
          .from('lead_activity')
          .select('*')
          .eq('lead_id', leadId)
          .order('activity_date', ascending: false)
          .order('activity_time', ascending: false);
      setState(() {
        _activityTimeline = List<Map<String, dynamic>>.from(activities);
        _isActivityLoading = false;
      });
    } catch (e) {
      setState(() {
        _activityError = 'Failed to fetch activity: ${e.toString()}';
        _isActivityLoading = false;
      });
    }
  }

  Future<void> _fetchContacts(String leadId) async {
    setState(() {
      _isContactsLoading = true;
      _contactsError = null;
      _mainContacts = [];
      _leadContacts = [];
    });
    try {
      final client = Supabase.instance.client;

      // Fetch main contacts
      try {
        final mainContactsResult = await client
            .from('main_contact')
            .select('*')
            .eq('lead_id', leadId)
            .order('created_at', ascending: false);
        setState(() {
          _mainContacts = List<Map<String, dynamic>>.from(mainContactsResult);
        });
      } catch (e) {
        debugPrint('Main contacts not available: $e');
      }

      // Fetch lead contacts
      try {
        final leadContactsResult = await client
            .from('lead_contacts')
            .select('*')
            .eq('lead_id', leadId)
            .order('created_at', ascending: false);
        setState(() {
          _leadContacts = List<Map<String, dynamic>>.from(leadContactsResult);
        });
      } catch (e) {
        debugPrint('Lead contacts not available: $e');
      }

      setState(() {
        _isContactsLoading = false;
      });
    } catch (e) {
      setState(() {
        _contactsError = 'Failed to fetch contacts: ${e.toString()}';
        _isContactsLoading = false;
      });
    }
  }

  void _expandCard(int index) async {
    final leadId = leads[index]['id'];
    setState(() {
      _expandedIndex = index;
    });
    await Future.wait([_fetchActivityTimeline(leadId), _fetchContacts(leadId)]);
  }

  void _collapseCard() {
    setState(() {
      _expandedIndex = null;
      _activityTimeline = [];
      _mainContacts = [];
      _leadContacts = [];
    });
  }

  void _viewLeadDetails(Map<String, dynamic> lead) async {
    final leadId = lead['id'];

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

      // Fetch any follow-ups related to this lead
      List<Map<String, dynamic>> followUps = [];
      try {
        followUps = await client
            .from('follow_ups')
            .select('*')
            .eq('lead_id', leadId)
            .order('due_date', ascending: true);
      } catch (e) {
        // Follow-ups table might not exist
        debugPrint('Follow-ups not available: $e');
      }

      // Fetch any quotations related to this lead
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

      // Fetch any invoices related to this lead
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
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.99,
            height: MediaQuery.of(context).size.width < 600
                ? MediaQuery.of(context).size.height * 0.99 + 10
                : MediaQuery.of(context).size.height * 0.9,
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(8),
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
                    padding: EdgeInsets.all(8),
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
                              'Created Date',
                              _formatDate(adminResponse['created_at']),
                            ),
                          ]),
                        if (adminResponse != null) SizedBox(height: 20),

                        // Comments
                        if (comments.isNotEmpty)
                          _buildDetailSection(
                            'Comments',
                            comments
                                .map(
                                  (comment) => _buildDetailRowForDialog(
                                    '${comment['comment'] ?? 'N/A'} (${comment['created_at'] != null ? _formatDate(comment['created_at']) : 'N/A'})',
                                    comment['user_name'] ?? 'N/A',
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
                            'Lead Contacts',
                            leadContacts
                                .map(
                                  (contact) => _buildDetailRowForDialog(
                                    '${contact['name'] ?? 'N/A'} (${contact['role'] ?? 'N/A'})',
                                    '${contact['email'] ?? 'N/A'} | ${contact['phone'] ?? 'N/A'} | ${contact['notes'] ?? 'N/A'}',
                                  ),
                                )
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
                                  (file) => _buildDetailRowForDialog(
                                    '${file['file_name'] ?? 'N/A'} (${file['username'] ?? 'N/A'})',
                                    '${file['file_link'] ?? 'N/A'}${file['created_at'] != null ? ' - ${_formatDate(file['created_at'])}' : ''}',
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

                        // Activity Timeline section removed - unused method
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

  Widget _buildDetailRowForDialog(String label, String value) {
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

  Widget _buildDetailRowWithCopy(
    String label,
    String value, {
    bool isUrl = false,
  }) {
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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUrl ? Colors.blue[600] : Colors.grey[800],
                      decoration: isUrl ? TextDecoration.underline : null,
                    ),
                    softWrap: true,
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

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = date is String ? DateTime.parse(date) : date as DateTime;
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _getLeadStatus(Map<String, dynamic> lead) {
    // Check if lead is approved first
    if (lead['approved'] == true) {
      return 'Approved';
    }

    final createdAt = lead['created_at'];
    if (createdAt == null) return 'Unknown';

    try {
      final createdDateTime = createdAt is String
          ? DateTime.parse(createdAt)
          : createdAt as DateTime;
      final now = DateTime.now();
      final difference = now.difference(createdDateTime);

      // Check if lead is within last 6 hours
      if (difference.inHours <= 6) {
        return 'New';
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: TextStyle(color: Colors.red)),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        if (isWide) {
          // Web/tablet: grid view
          int crossAxisCount = constraints.maxWidth > 1200
              ? 3
              : constraints.maxWidth > 900
              ? 2
              : 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Leads',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh),
                      tooltip: 'Refresh',
                      onPressed: _fetchLeads,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: leads.length,
                  itemBuilder: (context, index) {
                    final lead = leads[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lead['lead_type'] ?? '-',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              lead['client_name'] ?? '-',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text('Project: ${lead['project_name'] ?? '-'}'),
                            Text(
                              'Location: ${lead['project_location'] ?? '-'}',
                            ),
                            Text(
                              'Main Contact: ${lead['main_contact_name'] ?? '-'}',
                            ),
                            Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        _LeadActionButton(
                                          icon: Icons.remove_red_eye,
                                          label: 'View',
                                          onTap: () => _viewLeadDetails(lead),
                                        ),
                                        _LeadActionButton(
                                          icon: Icons.edit,
                                          label: 'Edit',
                                          onTap: () {},
                                        ),
                                        _LeadActionButton(
                                          icon: Icons.update,
                                          label: 'Update',
                                          onTap: () {},
                                        ),
                                        _LeadActionButton(
                                          icon: Icons.timeline,
                                          label: 'Timeline',
                                          onTap: () {},
                                        ),
                                        _LeadActionButton(
                                          icon: Icons.list_alt,
                                          label: 'Activity',
                                          onTap: () {},
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        } else {
          // Mobile: stack/list view with expandable card
          if (_expandedIndex != null) {
            final lead = leads[_expandedIndex!];
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back),
                            onPressed: _collapseCard,
                            tooltip: 'Back to Leads',
                          ),
                          Text(
                            'Lead Details',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lead['lead_type'] ?? '-',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                lead['client_name'] ?? '-',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text('Project: ${lead['project_name'] ?? '-'}'),
                              Text(
                                'Location: ${lead['project_location'] ?? '-'}',
                              ),
                              Text(
                                'Main Contact: ${lead['main_contact_name'] ?? '-'}',
                              ),
                              SizedBox(height: 12),
                              Text('Remark: ${lead['remark'] ?? '-'}'),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Activity Timeline',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Divider(),
                              if (_isActivityLoading)
                                Center(child: CircularProgressIndicator()),
                              if (_activityError != null)
                                Text(
                                  _activityError!,
                                  style: TextStyle(color: Colors.red),
                                ),
                              if (!_isActivityLoading &&
                                  _activityError == null &&
                                  _activityTimeline.isEmpty)
                                Text('No activity yet.'),
                              if (!_isActivityLoading &&
                                  _activityError == null &&
                                  _activityTimeline.isNotEmpty)
                                ..._activityTimeline.map(
                                  (a) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${a['activity_date']} ${a['activity_time']}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                a['activity'] ?? '-',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if ((a['changes_made'] ?? '')
                                                  .toString()
                                                  .isNotEmpty)
                                                Text(
                                                  'Changes: ${a['changes_made']}',
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Main Contacts Section
                      if (_mainContacts.isNotEmpty)
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Main Contacts',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Divider(),
                                if (_isContactsLoading)
                                  Center(child: CircularProgressIndicator()),
                                if (_contactsError != null)
                                  Text(
                                    _contactsError!,
                                    style: TextStyle(color: Colors.red),
                                  ),
                                if (!_isContactsLoading &&
                                    _contactsError == null)
                                  ..._mainContacts.map(
                                    (contact) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${contact['name'] ?? 'N/A'} (${contact['designation'] ?? 'N/A'})',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Email: ${contact['email'] ?? 'N/A'}',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                          Text(
                                            'Phone: ${contact['phone'] ?? 'N/A'}',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                          if (contact['company'] != null)
                                            Text(
                                              'Company: ${contact['company']}',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      // Lead Contacts Section
                      if (_leadContacts.isNotEmpty)
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Contacts',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Divider(),
                                if (_isContactsLoading)
                                  Center(child: CircularProgressIndicator()),
                                if (_contactsError != null)
                                  Text(
                                    _contactsError!,
                                    style: TextStyle(color: Colors.red),
                                  ),
                                if (!_isContactsLoading &&
                                    _contactsError == null)
                                  ..._leadContacts.map(
                                    (contact) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${contact['name'] ?? 'N/A'} (${contact['role'] ?? 'N/A'})',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Email: ${contact['email'] ?? 'N/A'}',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                          Text(
                                            'Phone: ${contact['phone'] ?? 'N/A'}',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                          if (contact['notes'] != null)
                                            Text(
                                              'Notes: ${contact['notes']}',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }
          // Show all cards
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Leads',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh),
                      tooltip: 'Refresh',
                      onPressed: _fetchLeads,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: leads.length,
                  itemBuilder: (context, index) {
                    final lead = leads[index];
                    return GestureDetector(
                      onTap: () => _expandCard(index),
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lead['lead_type'] ?? '-',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                lead['client_name'] ?? '-',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text('Project: ${lead['project_name'] ?? '-'}'),
                              Text(
                                'Location: ${lead['project_location'] ?? '-'}',
                              ),
                              Text(
                                'Main Contact: ${lead['main_contact_name'] ?? '-'}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
      },
    );
  }
}

class _LeadActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LeadActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label),
        onPressed: onTap,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final TextEditingController _projectCodeController = TextEditingController();
  bool _isLoading = false;
  String? _currentProjectCode;

  @override
  void initState() {
    super.initState();
    _loadCurrentProjectCode();
  }

  @override
  void dispose() {
    _projectCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProjectCode() async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('settings')
          .select('project_code')
          .limit(1)
          .single();

      setState(() {
        _currentProjectCode = response['project_code'];
        _projectCodeController.text = _currentProjectCode ?? '';
      });
    } catch (e) {
      // Handle error or no existing project code
      setState(() {
        _currentProjectCode = null;
        _projectCodeController.text = '';
      });
    }
  }

  Future<void> _saveProjectCode() async {
    if (_projectCodeController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please enter a project code')));
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final client = Supabase.instance.client;
      final baseCode = _projectCodeController.text.trim();

      // Get the next sequence number
      final existingCodes = await client
          .from('settings')
          .select('project_code')
          .like('project_code', '$baseCode-%');

      int nextSequence = 1;
      if (existingCodes.isNotEmpty) {
        final sequences = existingCodes
            .map((code) {
              final parts = code['project_code'].split('-');
              if (parts.length > 1) {
                return int.tryParse(parts.last) ?? 0;
              }
              return 0;
            })
            .where((seq) => seq > 0)
            .toList();

        if (sequences.isNotEmpty) {
          nextSequence = sequences.reduce((a, b) => a > b ? a : b) + 1;
        }
      }

      final newProjectCode =
          '$baseCode-${nextSequence.toString().padLeft(5, '0')}';

      // Update all settings entries with the new project code
      await client.from('settings').update({'project_code': newProjectCode});

      if (mounted) {
        setState(() {
          _currentProjectCode = newProjectCode;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Project code saved: $newProjectCode')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving project code: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 32),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Project Code Configuration',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Set the base project code. The system will automatically generate sequential codes like "Tobler-00001", "Tobler-00002", etc.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 24),
                      TextField(
                        controller: _projectCodeController,
                        decoration: InputDecoration(
                          labelText: 'Base Project Code',
                          hintText: 'e.g., Tobler',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.code),
                        ),
                      ),
                      SizedBox(height: 16),
                      if (_currentProjectCode != null)
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue[700]),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Current Project Code: $_currentProjectCode',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProjectCode,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Saving...'),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save),
                                    SizedBox(width: 8),
                                    Text('Save Project Code'),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LeadTable extends StatefulWidget {
  const LeadTable({super.key});

  @override
  State<LeadTable> createState() => _LeadTableState();
}

class _LeadTableState extends State<LeadTable> {
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

  bool _showAdvancedFilters = false;
  final Map<String, dynamic> _advancedFilters = {
    'dateRange': null,
    'salesPerson': 'All',
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
    'sales_person_name',
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

      // Fetch leads data
      final leadsResult = await client
          .from('leads')
          .select(
            'id, created_at, project_name, client_name, project_location, lead_generated_by',
          )
          .order('created_at', ascending: false);

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

      // Initialize total amounts for each lead
      for (final lead in joinedLeads) {
        final leadId = lead['lead_id'].toString();
        final aluminiumArea =
            double.tryParse(lead['aluminium_area']?.toString() ?? '0') ?? 0;
        final rate = double.tryParse(lead['rate_sqm']?.toString() ?? '0') ?? 0;
        final totalAmount = aluminiumArea * rate * 1.18;
        _totalAmounts[leadId] = totalAmount;
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

  void _exportLeads() {
    _showCryptoKeyValidationDialog();
  }

  // Step 1: Show crypto key validation dialog
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
              child: Text('Validate Key'),
            ),
          ],
        );
      },
    );
  }

  // Step 2: Validate crypto key against database
  Future<void> _validateCryptoKey(String cryptoKey) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Validating crypto key...'),
              ],
            ),
          );
        },
      );

      // Check if crypto key exists and is active
      final result = await Supabase.instance.client
          .from('crypto')
          .select('*')
          .eq('crypto_key', cryptoKey)
          .eq('is_active', true)
          .maybeSingle();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      if (result != null) {
        debugPrint('Crypto key validated successfully');
        if (mounted) {
          _showExportOptionsDialog(cryptoKey);
        }
      } else {
        if (mounted) {
          _showErrorDialog('Invalid crypto key. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }
      debugPrint('Error validating crypto key: $e');
      if (mounted) {
        _showErrorDialog('Error validating crypto key: $e');
      }
    }
  }

  // Step 3: Show export options dialog (CSV/PDF)
  void _showExportOptionsDialog(String cryptoKey) {
    String selectedFormat = 'CSV';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.file_download, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Export Options'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Choose your export format:',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        Icon(Icons.table_chart, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('CSV Format'),
                      ],
                    ),
                    subtitle: Text('Comma-separated values'),
                    value: 'CSV',
                    groupValue: selectedFormat,
                    onChanged: (value) {
                      setState(() {
                        selectedFormat = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.red),
                        SizedBox(width: 8),
                        Text('PDF Format'),
                      ],
                    ),
                    subtitle: Text('Portable document format'),
                    value: 'PDF',
                    groupValue: selectedFormat,
                    onChanged: (value) {
                      setState(() {
                        selectedFormat = value!;
                      });
                    },
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
                    _generateExport(cryptoKey, selectedFormat);
                  },
                  child: Text('Generate Export'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Step 4: Generate export based on format
  Future<void> _generateExport(String cryptoKey, String format) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Generating $format export...'),
              ],
            ),
          );
        },
      );

      // Get all leads data
      List<Map<String, dynamic>> exportData = _filteredLeads;

      // Generate content based on format
      String exportContent;
      String fileName;

      if (format == 'CSV') {
        exportContent = _generateCSVContent(exportData);
        fileName = 'leads_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      } else {
        exportContent = _generatePDFContent(exportData);
        fileName = 'leads_export_${DateTime.now().millisecondsSinceEpoch}.pdf';
      }

      Navigator.of(context).pop(); // Close loading dialog

      // Show preview with download option
      _showExportPreviewWithDownload(exportContent, format, fileName);
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      debugPrint('Error generating export: $e');
      _showErrorDialog('Error generating export: $e');
    }
  }

  // Generate CSV content
  String _generateCSVContent(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 'No data to export';

    // Get headers from first item
    List<String> headers = data.first.keys.toList();

    // Create CSV content
    StringBuffer csv = StringBuffer();

    // Add headers
    csv.writeln(headers.join(','));

    // Add data rows
    for (var row in data) {
      List<String> values = headers.map((header) {
        var value = row[header]?.toString() ?? '';
        // Escape commas and quotes
        if (value.contains(',') || value.contains('"')) {
          value = '"${value.replaceAll('"', '""')}"';
        }
        return value;
      }).toList();
      csv.writeln(values.join(','));
    }

    return csv.toString();
  }

  // Generate PDF content (simplified - in real app you'd use a PDF library)
  String _generatePDFContent(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 'No data to export';

    StringBuffer pdf = StringBuffer();
    pdf.writeln('LEADS EXPORT REPORT');
    pdf.writeln('Generated on: ${DateTime.now()}');
    pdf.writeln('Total Records: ${data.length}');
    pdf.writeln('');
    pdf.writeln('=' * 50);
    pdf.writeln('');

    for (int i = 0; i < data.length; i++) {
      pdf.writeln('Record ${i + 1}:');
      data[i].forEach((key, value) {
        pdf.writeln('  $key: ${value?.toString() ?? 'N/A'}');
      });
      pdf.writeln('');
    }

    return pdf.toString();
  }

  // Show export preview with download option
  void _showExportPreviewWithDownload(
    String content,
    String format,
    String fileName,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.preview, color: Colors.orange),
              SizedBox(width: 8),
              Text('Export Preview'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                Text(
                  'File: $fileName',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        content,
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12),
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
              child: Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _downloadExport(content, fileName);
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.download),
              label: Text('Download'),
            ),
          ],
        );
      },
    );
  }

  // Download export file to local device
  Future<void> _downloadExport(String content, String fileName) async {
    try {
      // Get the downloads directory using a safer approach
      Directory? downloadsDir;

      try {
        // Try to get the appropriate directory based on platform
        if (kIsWeb) {
          // Web platform - show download dialog
          _showWebDownloadDialog(content, fileName);
          return;
        } else {
          // Mobile/Desktop platforms
          downloadsDir = await _getDownloadsDirectory();
        }
      } catch (e) {
        debugPrint('Error getting downloads directory: $e');
        // Fallback to app documents directory
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir == null) {
        _showErrorDialog('Could not access downloads directory.');
        return;
      }

      // Create the file
      File file = File('${downloadsDir.path}/$fileName');
      await file.writeAsString(content);

      // Show success message with file path
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Export downloaded successfully!'),
                Text('File: $fileName', style: TextStyle(fontSize: 12)),
                Text(
                  'Location: ${file.path}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[300]),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                _openFile(file);
              },
            ),
          ),
        );
      }

      debugPrint('File saved to: ${file.path}');
    } catch (e) {
      debugPrint('Error downloading file: $e');
      if (mounted) {
        _showErrorDialog('Error downloading file: $e');
      }
    }
  }

  // Get downloads directory safely
  Future<Directory?> _getDownloadsDirectory() async {
    try {
      // Try to get downloads directory
      Directory? downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null && await downloadsDir.exists()) {
        return downloadsDir;
      }

      // Fallback to app documents directory
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      debugPrint('Error in _getDownloadsDirectory: $e');
      // Final fallback to app documents directory
      return await getApplicationDocumentsDirectory();
    }
  }

  // Show download dialog for web platform
  void _showWebDownloadDialog(String content, String fileName) {
    // For web, we'll show the content in a dialog that can be copied
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.download, color: Colors.blue),
              SizedBox(width: 8),
              Text('Export Content'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                Text(
                  'File: $fileName',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        content,
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12),
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
              child: Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Copy to clipboard
                Clipboard.setData(ClipboardData(text: content));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Content copied to clipboard!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.copy),
              label: Text('Copy to Clipboard'),
            ),
          ],
        );
      },
    );
  }

  // Open the downloaded file
  Future<void> _openFile(File file) async {
    try {
      if (await file.exists()) {
        // For now, just show file info
        // In a real app, you'd use url_launcher or file_opener
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('File Information'),
                content: FutureBuilder<int>(
                  future: file.length(),
                  builder: (context, snapshot) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('File: ${file.path.split('/').last}'),
                        Text('Size: ${snapshot.data ?? 0} bytes'),
                        Text('Path: ${file.path}'),
                      ],
                    );
                  },
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        if (mounted) {
          _showErrorDialog('File not found.');
        }
      }
    } catch (e) {
      debugPrint('Error opening file: $e');
      if (mounted) {
        _showErrorDialog('Error opening file: $e');
      }
    }
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

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
      // Desktop layout - original design
      return Row(
        children: [
          Icon(Icons.leaderboard, size: 32, color: Colors.blue[700]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lead Management',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  'Manage and track all leads in your system',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
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
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      );
    } else {
      // Mobile layout - compact design
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
              IconButton(
                onPressed: () {
                  setState(() {
                    _showAdvancedFilters = !_showAdvancedFilters;
                  });
                },
                icon: Icon(
                  Icons.filter_list,
                  color: Colors.blue[600],
                  size: 20,
                ),
                tooltip: 'Advanced Filters',
                padding: EdgeInsets.all(8),
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Manage and track all leads in your system',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          // Mobile stats cards with sort functionality
          _buildMobileStatsCards(),
          const SizedBox(height: 8),
          // Centered search box for mobile
          Center(
            child: SizedBox(
              width:
                  MediaQuery.of(context).size.width *
                  0.95, // 95% of screen width
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
                    vertical: 6,
                  ),
                ),
                onChanged: _onSearch,
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildStatsCards() {
    final stats = _calculateStats();

    return Row(
      children: [
        _buildStatCard(
          'Total Leads',
          stats['total'].toString(),
          Icons.leaderboard,
          Colors.blue,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'New',
          stats['new'].toString(),
          Icons.fiber_new,
          Colors.teal,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Proposal Progress',
          stats['proposalProgress'].toString(),
          Icons.new_releases,
          Colors.orange,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Waiting Approval',
          stats['waiting'].toString(),
          Icons.pending,
          Colors.purple,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Approved',
          stats['approved'].toString(),
          Icons.check_circle,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildMobileStatsCards() {
    final stats = _calculateStats();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              stats['total'].toString(),
              Colors.blue,
            ),
          ),
          Container(width: 1, height: 30, color: Colors.grey[300]),
          Expanded(
            child: _buildCompactStatItem(
              'New',
              stats['new'].toString(),
              Colors.teal,
            ),
          ),
          Container(width: 1, height: 30, color: Colors.grey[300]),
          Expanded(
            child: _buildCompactStatItem(
              'Proposal',
              stats['proposalProgress'].toString(),
              Colors.orange,
            ),
          ),
          Container(width: 1, height: 30, color: Colors.grey[300]),
          Expanded(
            child: _buildCompactStatItem(
              'Waiting',
              stats['waiting'].toString(),
              Colors.purple,
            ),
          ),
          Container(width: 1, height: 30, color: Colors.grey[300]),
          Expanded(
            child: _buildCompactStatItem(
              'Approved',
              stats['approved'].toString(),
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                borderRadius: BorderRadius.circular(12),
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
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndActions(bool isWide) {
    if (isWide) {
      // Desktop layout - original design
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search leads by ID, client, or project...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue[600]!),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: _onSearch,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButton<String>(
                  value: _selectedFilter,
                  underline: SizedBox(),
                  items: _filterOptions.map((String filter) {
                    return DropdownMenuItem<String>(
                      value: filter,
                      child: Text(filter),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _onFilterChanged(newValue);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButton<String>(
                  value: _sortBy,
                  underline: SizedBox(),
                  items: _sortOptions.map((String sort) {
                    return DropdownMenuItem<String>(
                      value: sort,
                      child: Text(_getSortLabel(sort)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _onSortChanged(newValue);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                    _applyFilters();
                  });
                },
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                tooltip: 'Sort Direction',
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showAdvancedFilters = !_showAdvancedFilters;
                  });
                },
                icon: Icon(Icons.filter_list),
                tooltip: 'Advanced Filters',
              ),
            ],
          ),
        ],
      );
    } else {
      // Mobile layout - search box integrated with header
      return SizedBox.shrink(); // No separate search section for mobile
    }
  }

  Widget _buildAdvancedFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        return Container(
          padding: EdgeInsets.all(isWide ? 16 : 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isWide ? 12 : 8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Advanced Filters',
                style: TextStyle(
                  fontSize: isWide ? 16 : 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (isWide) ...[
                // Desktop layout - horizontal arrangement
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Min Amount',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _advancedFilters['minAmount'] = value;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Max Amount',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _advancedFilters['maxAmount'] = value;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Location',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) {
                          _advancedFilters['location'] = value;
                        },
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Mobile layout - vertical arrangement with smaller inputs
                Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Min Amount',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        labelStyle: TextStyle(fontSize: 12),
                      ),
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 12),
                      onChanged: (value) {
                        _advancedFilters['minAmount'] = value;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Max Amount',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        labelStyle: TextStyle(fontSize: 12),
                      ),
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 12),
                      onChanged: (value) {
                        _advancedFilters['maxAmount'] = value;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        labelStyle: TextStyle(fontSize: 12),
                      ),
                      style: TextStyle(fontSize: 12),
                      onChanged: (value) {
                        _advancedFilters['location'] = value;
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
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
                      'Sales Person',
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
    final leadId = lead['lead_id'] ?? '';
    final formattedLeadId =
        'Tobler-${leadId.toString().substring(0, 4).toUpperCase()}';
    final status = _getLeadStatus(lead);
    final statusColor = _getStatusColor(status);
    final aluminiumArea =
        double.tryParse(lead['aluminium_area']?.toString() ?? '0') ?? 0;
    final msWeight = double.tryParse(lead['ms_weight']?.toString() ?? '0') ?? 0;
    final rate = double.tryParse(lead['rate_sqm']?.toString() ?? '0') ?? 0;

    // Calculate total amount dynamically
    String calculateTotalAmount() {
      // Get the current rate from the TextField controller
      final controller = _rateControllers[leadId.toString()];
      final currentRate = controller != null
          ? double.tryParse(controller.text) ?? 0
          : double.tryParse(lead['rate_sqm']?.toString() ?? '0') ?? 0;
      return (aluminiumArea * currentRate * 1.18).toStringAsFixed(2);
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedLeadId,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          _formatDate(lead['date']),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
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
                  flex: 1,
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
                      maxLines: 2,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${aluminiumArea.toStringAsFixed(2)} sq/m',
                          style: TextStyle(fontSize: 14),
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        SizedBox(height: 4),
                        _buildRateChainDisplay(leadId.toString()),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      '${msWeight.toStringAsFixed(2)} kg',
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
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: TextField(
                      controller: _rateControllers.putIfAbsent(
                        leadId.toString(),
                        () => TextEditingController(text: rate.toString()),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Rate',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        isDense: true,
                      ),
                      style: TextStyle(fontSize: 12),
                      onChanged: (val) {
                        // Calculate and store total amount in real-time
                        final aluminiumArea =
                            double.tryParse(
                              lead['aluminium_area']?.toString() ?? '0',
                            ) ??
                            0;
                        final currentRate = double.tryParse(val) ?? 0;
                        final totalAmount = aluminiumArea * currentRate * 1.18;
                        _totalAmounts[leadId.toString()] = totalAmount;

                        setState(() {});
                        _saveRateToDatabase(leadId.toString(), val);
                      },
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      '₹${calculateTotalAmount()}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
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
                      lead['sales_person_name'] ?? '',
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
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
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
                          onPressed: () => _showApproveDialog(
                            context,
                            lead,
                            calculateTotalAmount(),
                          ),
                          icon: Icon(Icons.approval, size: 18),
                          tooltip: 'Approve',
                          color: Colors.green[600],
                          padding: EdgeInsets.all(4),
                          constraints: BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _viewLeadDetails(lead),
                          icon: Icon(Icons.visibility, size: 18),
                          tooltip: 'View Details',
                          color: Colors.blue[600],
                          padding: EdgeInsets.all(4),
                          constraints: BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _queryLead(lead),
                          icon: Icon(Icons.question_mark, size: 18),
                          tooltip: 'Query',
                          color: Colors.orange[600],
                          padding: EdgeInsets.all(4),
                          constraints: BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _editLead(lead),
                          icon: Icon(Icons.edit, size: 18),
                          tooltip: 'Edit',
                          color: Colors.grey[600],
                          padding: EdgeInsets.all(4),
                          constraints: BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
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
    );
  }

  Widget _buildRateChainDisplay(String leadId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchRateChain(leadId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              Icon(Icons.timeline, size: 10, color: Colors.grey[600]),
              SizedBox(width: 4),
              Text(
                'Loading...',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Row(
            children: [
              Icon(Icons.timeline, size: 10, color: Colors.grey[600]),
              SizedBox(width: 4),
              Text(
                'No history',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          );
        }

        final rateChain = snapshot.data!;

        return SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Icon(Icons.timeline, size: 10, color: Colors.grey[600]),
              SizedBox(width: 4),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: rateChain.asMap().entries.map((entry) {
                      final index = entry.key;
                      final rate = entry.value;
                      final isLast = index == rateChain.length - 1;

                      return Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Text(
                              'R${index + 1}(₹${rate['rate_sqm']?.toString() ?? '0'})',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[600],
                              ),
                            ),
                          ),
                          if (!isLast) ...[
                            SizedBox(width: 2),
                            Icon(
                              Icons.arrow_forward,
                              size: 8,
                              color: Colors.grey[400],
                            ),
                            SizedBox(width: 2),
                          ],
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchRateChain(String leadId) async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('admin_response')
          .select('rate_sqm, created_at')
          .eq('lead_id', leadId)
          .not('rate_sqm', 'is', null)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching rate chain: $e');
      return [];
    }
  }

  Widget _buildMobileTable() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 7),
      itemCount: _filteredLeads.length,
      itemBuilder: (context, index) {
        final lead = _filteredLeads[index];
        return _buildMobileCard(lead, index);
      },
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> lead, int index) {
    final leadId = lead['lead_id'] ?? '';
    final formattedLeadId =
        'Tobler-${leadId.toString().substring(0, 4).toUpperCase()}';
    final status = _getLeadStatus(lead);
    final statusColor = _getStatusColor(status);
    final aluminiumArea =
        double.tryParse(lead['aluminium_area']?.toString() ?? '0') ?? 0;
    final msWeight = double.tryParse(lead['ms_weight']?.toString() ?? '0') ?? 0;
    final rate = double.tryParse(lead['rate_sqm']?.toString() ?? '0') ?? 0;

    // Calculate total amount dynamically
    String calculateTotalAmount() {
      // Use stored total amount if available, otherwise calculate
      final storedTotal = _totalAmounts[leadId.toString()];
      if (storedTotal != null) {
        return storedTotal.toStringAsFixed(2);
      }

      // Fallback calculation
      final controller = _rateControllers[leadId.toString()];
      final currentRate = controller != null
          ? double.tryParse(controller.text) ?? 0
          : double.tryParse(lead['rate_sqm']?.toString() ?? '0') ?? 0;
      return (aluminiumArea * currentRate * 1.18).toStringAsFixed(2);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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
                            formattedLeadId,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            lead['sales_person_name'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDetailRow('Project', lead['project_name'] ?? ''),
                _buildDetailRow('Client', lead['client_name'] ?? ''),
                _buildDetailRow('Location', lead['project_location'] ?? ''),
                _buildDetailRow('Date', _formatDate(lead['date'])),
                _buildDetailRow(
                  'Aluminium Area',
                  '${aluminiumArea.toStringAsFixed(2)} sq/m',
                ),
                _buildDetailRow(
                  'MS Weight',
                  '${msWeight.toStringAsFixed(2)} kg',
                ),
                _buildDetailRow('Rate sq/m', '₹${rate.toStringAsFixed(2)}'),
                // Editable rate field for mobile
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          'Rate sq/m:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _rateControllers.putIfAbsent(
                            leadId.toString(),
                            () => TextEditingController(text: rate.toString()),
                          ),
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter rate',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            isDense: true,
                          ),
                          style: TextStyle(fontSize: 14),
                          onChanged: (val) {
                            // Calculate and store total amount in real-time
                            final aluminiumArea =
                                double.tryParse(
                                  lead['aluminium_area']?.toString() ?? '0',
                                ) ??
                                0;
                            final currentRate = double.tryParse(val) ?? 0;
                            final totalAmount =
                                aluminiumArea * currentRate * 1.18;
                            _totalAmounts[leadId.toString()] = totalAmount;

                            setState(() {});
                            _saveRateToDatabase(leadId.toString(), val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (aluminiumArea > 0 || rate > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total + GST:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹${calculateTotalAmount()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showApproveDialog(
                          context,
                          lead,
                          calculateTotalAmount(),
                        ),
                        icon: Icon(Icons.approval, size: 16),
                        label: Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _viewLeadDetails(lead),
                      icon: Icon(Icons.visibility),
                      tooltip: 'View',
                    ),
                    IconButton(
                      onPressed: () => _queryLead(lead),
                      icon: Icon(Icons.question_mark),
                      tooltip: 'Query',
                    ),
                    IconButton(
                      onPressed: () => _editLead(lead),
                      icon: Icon(Icons.edit),
                      tooltip: 'Edit',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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
            child: Text(
              value,
              style: TextStyle(fontSize: 14),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
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
          const SizedBox(height: 16),
          Text(
            'No leads found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter criteria',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateStats() {
    int total = _leads.length;
    int newCount = 0;
    int proposalProgressCount = 0;
    int waitingCount = 0;
    int approvedCount = 0;

    for (final lead in _leads) {
      final status = _getLeadStatus(lead);
      switch (status) {
        case 'New':
          newCount++;
          break;
        case 'Proposal Progress':
          proposalProgressCount++;
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
      'proposalProgress': proposalProgressCount,
      'waiting': waitingCount,
      'approved': approvedCount,
    };
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      if (date is String) {
        final parsedDate = DateTime.parse(date);
        return DateFormat('yyyy-MM-dd').format(parsedDate);
      } else if (date is DateTime) {
        return DateFormat('yyyy-MM-dd').format(date);
      }
      return date.toString();
    } catch (e) {
      return date.toString();
    }
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'date':
        return 'Date';
      case 'lead_id':
        return 'Lead ID';
      case 'project_name':
        return 'Project';
      case 'client_name':
        return 'Client';
      case 'project_location':
        return 'Location';
      case 'aluminium_area':
        return 'Aluminium Area';
      case 'ms_weight':
        return 'MS Weight';
      case 'rate_sqm':
        return 'Rate sq/m';
      case 'sales_person_name':
        return 'Sales Person';
      case 'total_amount':
        return 'Amount';
      default:
        return sortBy;
    }
  }

  void _saveRateToDatabase(String leadId, String rate) async {
    try {
      // You can add a rate column to leads table or create a separate rates table
      // For now, we'll just update the local state
      // await Supabase.instance.client.from('leads').update({'rate': rate}).eq('id', leadId);
    } catch (e) {
      debugPrint('Error saving rate: $e');
    }
  }

  void _editLead(Map<String, dynamic> lead) {
    // Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit functionality for Lead ${lead['lead_id']}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showApproveDialog(
    BuildContext context,
    Map<String, dynamic> lead,
    String totalAmount,
  ) {
    _remarkController.clear(); // Clear previous remarks
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Final Review - Lead Approval'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lead ID: ${lead['lead_id']}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildReviewRow('Project Name:', lead['project_name'] ?? ''),
                _buildReviewRow('Client Name:', lead['client_name'] ?? ''),
                _buildReviewRow('Location:', lead['project_location'] ?? ''),
                const SizedBox(height: 16),
                Text(
                  'Financial Details:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                _buildReviewRow(
                  'Aluminium Area:',
                  '${lead['aluminium_area']} sq/m',
                ),
                _buildReviewRow('MS Weight:', '${lead['ms_weight']} kg'),
                _buildReviewRow(
                  'Rate sq/m:',
                  '₹${_rateControllers[lead['lead_id']]?.text ?? '0'}',
                ),
                _buildReviewRow(
                  'Total Amount + GST 18%:',
                  '₹$totalAmount',
                  isTotal: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'Remarks:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _remarkController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter any remarks or notes for this approval...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Please review the above details before approval.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _submitApproval(lead);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Submit Approval'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReviewRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  void _submitApproval(Map<String, dynamic> lead) async {
    final remark = _remarkController.text.trim();
    final rateValue = _rateControllers[lead['lead_id']]?.text ?? '0';
    final aluminiumArea =
        double.tryParse(lead['aluminium_area']?.toString() ?? '0') ?? 0;
    final msWeight = double.tryParse(lead['ms_weight']?.toString() ?? '0') ?? 0;
    final rate = double.tryParse(rateValue) ?? 0;
    final totalAmount = (aluminiumArea * rate * 1.18);

    try {
      final client = Supabase.instance.client;

      // Save to admin_response table
      await client.from('admin_response').insert({
        'lead_id': lead['lead_id'],
        'date': lead['date'],
        'project_name': lead['project_name'] ?? '',
        'client_name': lead['client_name'] ?? '',
        'location': lead['project_location'] ?? '',
        'aluminium_area': aluminiumArea,
        'ms_weight': msWeight,
        'rate_sqm': rate,
        'total_amount_gst': totalAmount,
        'status': 'Approved',
        'remark': remark,
      });

      // Mark lead as approved in local state
      setState(() {
        final leadIndex = _leads.indexWhere(
          (l) => l['lead_id'] == lead['lead_id'],
        );
        if (leadIndex != -1) {
          _leads[leadIndex]['approved'] = true;
          _filteredLeads = _leads.where((lead) {
            return lead['lead_id'].toString().toLowerCase().contains(
                  _searchText,
                ) ||
                (lead['client_name'] ?? '').toLowerCase().contains(
                  _searchText,
                ) ||
                (lead['project_name'] ?? '').toLowerCase().contains(
                  _searchText,
                );
          }).toList();
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lead ${lead['lead_id']} approved and saved successfully!${remark.isNotEmpty ? ' Remarks: $remark' : ''}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving approval: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewLeadDetails(Map<String, dynamic> lead) async {
    final leadId = lead['lead_id'];

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

      // Fetch any follow-ups related to this lead
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

      // Fetch any quotations related to this lead
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

      // Fetch any invoices related to this lead
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

      // Fetch main contact information (latest only)
      List<Map<String, dynamic>> mainContacts = [];
      try {
        mainContacts = await client
            .from('main_contact')
            .select('*')
            .eq('lead_id', leadId)
            .order('created_at', ascending: false)
            .limit(1);
      } catch (e) {
        // Main contact table might not exist
        debugPrint('Main contact not available: $e');
      }

      // Fetch lead attachments with user details
      List<Map<String, dynamic>> leadAttachments = [];
      try {
        final attachmentsResult = await client
            .from('lead_attachments')
            .select('*, users!lead_attachments_user_id_fkey(username)')
            .eq('lead_id', leadId)
            .order('created_at', ascending: false);

        leadAttachments = attachmentsResult.map((attachment) {
          final user = attachment['users'] as Map<String, dynamic>?;
          return {...attachment, 'username': user?['username'] ?? 'N/A'};
        }).toList();
      } catch (e) {
        // Lead attachments table might not exist
        debugPrint('Lead attachments not available: $e');
      }

      // Fetch lead contacts
      List<Map<String, dynamic>> leadContacts = [];
      try {
        leadContacts = await client
            .from('lead_contacts')
            .select('*')
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

      // Fetch proposal files with user details
      List<Map<String, dynamic>> proposalFiles = [];
      try {
        final proposalFilesResult = await client
            .from('proposal_file')
            .select('*, users!proposal_file_user_id_fkey(username)')
            .eq('lead_id', leadId)
            .order('created_at', ascending: false);

        proposalFiles = proposalFilesResult.map((file) {
          final user = file['users'] as Map<String, dynamic>?;
          return {...file, 'username': user?['username'] ?? 'N/A'};
        }).toList();
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

  Widget _buildDetailRowWithCopy(
    String label,
    String value, {
    bool isUrl = false,
  }) {
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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUrl ? Colors.blue[600] : Colors.grey[800],
                      decoration: isUrl ? TextDecoration.underline : null,
                    ),
                    softWrap: true,
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
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.99,
            height: MediaQuery.of(context).size.width < 600
                ? MediaQuery.of(context).size.height * 0.99 + 10
                : MediaQuery.of(context).size.height * 0.9,
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(8),
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
                    padding: EdgeInsets.all(8),
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

                        // Activity Timeline section removed - unused method
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
    // Implement query lead functionality
    try {
      // Here you would typically make an API call to query the lead
      // For now, we'll show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Query submitted for Lead ${lead['lead_id']}'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting query: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  String _getLeadStatus(Map<String, dynamic> lead) {
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
        return 'New';
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
      case 'New':
        return Colors.blue;
      case 'Proposal Progress':
        return Colors.orange;
      case 'Waiting for Approval':
        return Colors.purple;
      case 'Approved':
        return Colors.green;
      default:
        return Colors.grey;
    }
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
        return 'New';
      case 'proposal':
        return 'Proposal Progress';
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
}

// Admin Dashboard Page with requested elements
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isSearchExpanded = false;
  bool _isMenuExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedTimePeriod = 'Quarter'; // Default selected time period
  String _selectedCurrency = 'INR'; // Default currency
  
  // Lead Performance state
  String _activeLeadTab = 'Won'; // 'Won', 'Lost', 'Loop'
  List<Map<String, dynamic>> _leadPerformanceData = [];
  List<Map<String, dynamic>> _filteredLeadData = [];
  bool _isLoadingLeadData = false;
  final TextEditingController _leadSearchController = TextEditingController();
  
      // Chart data state
    List<BarChartGroupData> _barChartData = [];
    bool _isLoadingChartData = false;
  
  // Lead status distribution data state
  Map<String, int> _leadStatusDistribution = {
    'Won': 0,
    'Lost': 0,
    'Loop': 0,
  };
  bool _isLoadingLeadStatusData = false;
  
  // Dashboard data state
  Map<String, dynamic> _dashboardData = {
    'totalRevenue': {'value': '₹0', 'percentage': '+0.0%', 'isPositive': true},
    'aluminiumArea': {'value': '0 m²', 'percentage': '+0.0%', 'isPositive': true},
    'qualifiedLeads': {'value': '0', 'percentage': '+0.0%', 'isPositive': true},
  };
  
  bool _isLoading = false;
  
  // Currency conversion rates (you can fetch these from an API)
  final Map<String, double> _currencyRates = {
    'INR': 1.0,
    'USD': 0.012, // 1 INR = 0.012 USD (approximate)
    'EUR': 0.011, // 1 INR = 0.011 EUR (approximate)
    'CHF': 0.010, // 1 INR = 0.010 CHF (Swiss Franc, approximate)
    'GBP': 0.009, // 1 INR = 0.009 GBP (approximate)
  };
  
  // Currency symbols
  final Map<String, String> _currencySymbols = {
    'INR': '₹',
    'USD': '\$',
    'EUR': '€',
    'CHF': 'CHF ',
    'GBP': '£',
  };

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _fetchLeadPerformanceData();
    _fetchChartData();
    _fetchLeadStatusDistributionData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _leadSearchController.dispose();
    super.dispose();
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
        startDate = DateTime(now.year, now.month - 3, now.day); // Default to quarter
    }
    
    return {'start': startDate, 'end': endDate};
  }

  // Fetch dashboard data from Supabase
  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final client = Supabase.instance.client;
      final dateRange = _getDateRange(_selectedTimePeriod);
      
      // Fetch data from admin_response table for Won leads only
      final response = await client
          .from('admin_response')
          .select()
          .eq('update_lead_status', 'Won')
          .gte('updated_at', dateRange['start']!.toIso8601String())
          .lte('updated_at', dateRange['end']!.toIso8601String());

      // Calculate dashboard metrics
      await _calculateDashboardMetrics(response);
      
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      // Keep default values on error
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
      // Sum up total revenue from total_amount_gst field
      if (record['total_amount_gst'] != null) {
        totalRevenue += (record['total_amount_gst'] is num) ? record['total_amount_gst'].toDouble() : 0;
      }
      
      // Sum up aluminium area (assuming there's an aluminium_area field)
      if (record['aluminium_area'] != null) {
        totalAluminiumArea += (record['aluminium_area'] is num) ? record['aluminium_area'].toDouble() : 0;
      }
      
      qualifiedLeadsCount++;
    }

    // Get previous period data for comparison
    final previousPeriodData = await _getPreviousPeriodData();
    
    // Calculate percentages
    final revenuePercentage = _calculatePercentage(totalRevenue, previousPeriodData['revenue'] ?? 0);
    final aluminiumAreaPercentage = _calculatePercentage(totalAluminiumArea, previousPeriodData['aluminiumArea'] ?? 0);
    final leadsPercentage = _calculatePercentage(qualifiedLeadsCount.toDouble(), previousPeriodData['leads'] ?? 0);

    setState(() {
      _dashboardData = {
        'totalRevenue': {
          'value': _formatCurrency(totalRevenue, _selectedCurrency),
          'percentage': '${revenuePercentage >= 0 ? '+' : ''}${revenuePercentage.toStringAsFixed(1)}%',
          'isPositive': revenuePercentage >= 0,
        },
        'aluminiumArea': {
          'value': '${totalAluminiumArea.toStringAsFixed(0)} m²',
          'percentage': '${aluminiumAreaPercentage >= 0 ? '+' : ''}${aluminiumAreaPercentage.toStringAsFixed(1)}%',
          'isPositive': aluminiumAreaPercentage >= 0,
        },
        'qualifiedLeads': {
          'value': qualifiedLeadsCount.toString(),
          'percentage': '${leadsPercentage >= 0 ? '+' : ''}${leadsPercentage.toStringAsFixed(1)}%',
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
      
      // Calculate previous period date range
      final duration = currentDateRange['end']!.difference(currentDateRange['start']!);
      final previousStartDate = currentDateRange['start']!.subtract(duration);
      final previousEndDate = currentDateRange['start']!;
      
      // Fetch previous period data for Won leads only
      final previousResponse = await client
          .from('admin_response')
          .select()
          .eq('update_lead_status', 'Won')
          .gte('updated_at', previousStartDate.toIso8601String())
          .lte('updated_at', previousEndDate.toIso8601String());
      
      // Calculate previous period metrics
      double previousRevenue = 0;
      double previousAluminiumArea = 0;
      int previousLeadsCount = 0;
      
      for (var record in previousResponse) {
        if (record['total_amount_gst'] != null) {
          previousRevenue += (record['total_amount_gst'] is num) ? record['total_amount_gst'].toDouble() : 0;
        }
        if (record['aluminium_area'] != null) {
          previousAluminiumArea += (record['aluminium_area'] is num) ? record['aluminium_area'].toDouble() : 0;
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
      // Return default values on error
      return {
        'qualifiedArea': 0.0,
        'revenue': 0.0,
        'aluminiumArea': 0.0,
        'leads': 0.0,
      };
    }
  }

  // Calculate percentage change
  double _calculatePercentage(double current, double previous) {
    if (previous == 0) return 0;
    return ((current - previous) / previous) * 100;
  }

  // Format currency with K, M, B, T suffixes
  String _formatCurrency(double amount, String currency) {
    final symbol = _currencySymbols[currency] ?? '₹';
    final rate = _currencyRates[currency] ?? 1.0;
    final convertedAmount = amount * rate;
    
    if (convertedAmount < 1000) {
      return '$symbol${convertedAmount.toStringAsFixed(0)}';
    } else if (convertedAmount < 1000000) {
      return '$symbol${(convertedAmount / 1000).toStringAsFixed(2)}K';
    } else if (convertedAmount < 1000000000) {
      return '$symbol${(convertedAmount / 1000000).toStringAsFixed(2)}M';
    } else if (convertedAmount < 1000000000000) {
      return '$symbol${(convertedAmount / 1000000000).toStringAsFixed(2)}B';
    } else {
      return '$symbol${(convertedAmount / 1000000000000).toStringAsFixed(2)}T';
    }
  }

  // Refresh data when time period changes
  void _onTimePeriodChanged(String newPeriod) {
    setState(() {
      _selectedTimePeriod = newPeriod;
    });
    _fetchDashboardData();
    _fetchChartData();
    _fetchLeadStatusDistributionData();
  }

  // Refresh data when currency changes
  void _onCurrencyChanged(String newCurrency) {
    setState(() {
      _selectedCurrency = newCurrency;
    });
    _fetchDashboardData();
  }

  // Fetch lead performance data from admin_response table
  Future<void> _fetchLeadPerformanceData() async {
    setState(() {
      _isLoadingLeadData = true;
    });

    try {
      final client = Supabase.instance.client;
      
      // Fetch data from admin_response table based on active tab
      final response = await client
          .from('admin_response')
          .select('*')
          .eq('update_lead_status', _activeLeadTab)
          .order('updated_at', ascending: false)
          .timeout(const Duration(seconds: 10));

      setState(() {
        _leadPerformanceData = List<Map<String, dynamic>>.from(response);
        _filteredLeadData = List<Map<String, dynamic>>.from(response);
        _isLoadingLeadData = false;
      });
    } catch (e) {
      debugPrint('Error fetching lead performance data: $e');
      setState(() {
        _leadPerformanceData = [];
        _isLoadingLeadData = false;
      });
    }
  }

  // Handle tab selection for lead performance
  void _onLeadTabChanged(String tabValue) {
    setState(() {
      _activeLeadTab = tabValue;
    });
    _fetchLeadPerformanceData();
  }

  // Search and filter lead data
  void _filterLeadData(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredLeadData = List<Map<String, dynamic>>.from(_leadPerformanceData);
      });
    } else {
      final lowercaseQuery = query.toLowerCase();
      final filtered = _leadPerformanceData.where((lead) {
        // Search across all relevant fields
        return lead['project_id']?.toString().toLowerCase().contains(lowercaseQuery) == true ||
               lead['project_name']?.toString().toLowerCase().contains(lowercaseQuery) == true ||
               lead['client_name']?.toString().toLowerCase().contains(lowercaseQuery) == true ||
               lead['location']?.toString().toLowerCase().contains(lowercaseQuery) == true ||
               lead['aluminium_area']?.toString().toLowerCase().contains(lowercaseQuery) == true ||
               lead['rc_weight']?.toString().toLowerCase().contains(lowercaseQuery) == true ||
               lead['rate_sqm']?.toString().toLowerCase().contains(lowercaseQuery) == true ||
               lead['total_amount_gst']?.toString().toLowerCase().contains(lowercaseQuery) == true ||
               lead['sales_user']?.toString().toLowerCase().contains(lowercaseQuery) == true ||
               lead['update_lead_status']?.toString().toLowerCase().contains(lowercaseQuery) == true ||
               lead['lead_status_remark']?.toString().toLowerCase().contains(lowercaseQuery) == true ||
               lead['created_at']?.toString().toLowerCase().contains(lowercaseQuery) == true ||
               lead['updated_at']?.toString().toLowerCase().contains(lowercaseQuery) == true;
      }).toList();
      
      setState(() {
        _filteredLeadData = filtered;
      });
    }
  }

  // Fetch chart data from admin_response table
  Future<void> _fetchChartData() async {
    setState(() {
      _isLoadingChartData = true;
    });

    try {
      final client = Supabase.instance.client;
      final dateRange = _getDateRange(_selectedTimePeriod);
      
      // Fetch data from admin_response table where update_lead_status = 'Won'
      final response = await client
          .from('admin_response')
          .select('aluminium_area, total_amount_gst, updated_at')
          .eq('update_lead_status', 'Won')
          .gte('updated_at', dateRange['start']!.toIso8601String())
          .lte('updated_at', dateRange['end']!.toIso8601String())
          .order('updated_at', ascending: true)
          .timeout(const Duration(seconds: 10));

      // Process the data to create chart spots
      await _processChartData(response);
      
    } catch (e) {
      debugPrint('Error fetching chart data: $e');
      // Set default empty data on error
      setState(() {
        _barChartData = [];
        _isLoadingChartData = false;
      });
    }
  }

  // Process chart data and create spots
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
      
      // Only include data within the selected time period range
      if (updatedAt.isBefore(startDate) || updatedAt.isAfter(endDate)) {
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
      
      int qualifiedLeadCount = groupData.length; // Count of Won leads
      double totalRevenue = 0;

      for (var record in groupData) {
        totalRevenue += (record['total_amount_gst'] ?? 0).toDouble();
      }

      // Convert revenue to thousands for display
      final revenueInK = totalRevenue / 1000;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            // Qualified Lead count bar (Teal color)
            BarChartRodData(
              toY: qualifiedLeadCount.toDouble(),
              color: Colors.teal,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
            // Revenue bar (Pink color)
            BarChartRodData(
              toY: revenueInK,
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

  // Helper method to get month name
  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  // Helper method to get day of week name
  String _getDayOfWeekName(int dayOfWeek) {
    const days = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ];
    return days[dayOfWeek - 1];
  }

  // Helper method to get chart labels based on time period
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
        return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
        return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    }
  }

  // Fetch lead status distribution data from admin_response table
  Future<void> _fetchLeadStatusDistributionData() async {
    setState(() {
      _isLoadingLeadStatusData = true;
    });

    try {
      final client = Supabase.instance.client;
      final dateRange = _getDateRange(_selectedTimePeriod);
      
      // Fetch data from admin_response table for all lead statuses
      final response = await client
          .from('admin_response')
          .select('update_lead_status')
          .gte('updated_at', dateRange['start']!.toIso8601String())
          .lte('updated_at', dateRange['end']!.toIso8601String())
          .timeout(const Duration(seconds: 10));

      // Process the data to count lead statuses
      await _processLeadStatusDistributionData(response);
      
    } catch (e) {
      debugPrint('Error fetching lead status distribution data: $e');
      // Set default empty data on error
      setState(() {
        _leadStatusDistribution = {
          'Won': 0,
          'Lost': 0,
          'Loop': 0,
        };
        _isLoadingLeadStatusData = false;
      });
    }
  }

  // Process lead status distribution data
  Future<void> _processLeadStatusDistributionData(List<dynamic> data) async {
    Map<String, int> statusCounts = {
      'Won': 0,
      'Lost': 0,
      'Loop': 0,
    };

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



  // Build Syncfusion pie chart data
  List<ChartData> _buildSyncfusionPieChartData() {
    final totalLeads = _leadStatusDistribution.values.fold(0, (sum, count) => sum + count);
    final chartData = <ChartData>[];
    
    if (totalLeads == 0) {
      return chartData;
    }

    final colors = {
      'Won': Colors.green,
      'Lost': Colors.red,
      'Loop': Colors.orange,
    };

    for (var entry in _leadStatusDistribution.entries) {
      if (entry.value > 0) {
        chartData.add(
          ChartData(
            entry.key,
            entry.value.toDouble(),
            colors[entry.key]!,
          ),
        );
      }
    }

    return chartData;
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
              // Header with Dashboard heading, search bar, notification and chat icons
              _buildHeader(),
              SizedBox(height: 24),
              
              // Dashboard content
              Expanded(
                child: _buildDashboardContent(),
              ),
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
                    'Dashboard',
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
                                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
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
                                icon: Icon(Icons.search, color: Colors.grey[600]),
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
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _isMenuExpanded = !_isMenuExpanded;
                        });
                      },
                      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                      iconSize: 16,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              // Expanded menu (if expanded)
              if (_isMenuExpanded)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMobileMenuItem(
                            Icons.attach_money,
                            'Currency',
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Currency Settings'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              setState(() {
                                _isMenuExpanded = false;
                              });
                            },
                          ),
                          _buildMobileMenuItem(
                            Icons.schedule,
                            'Time Period',
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Time Period Settings'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              setState(() {
                                _isMenuExpanded = false;
                              });
                            },
                          ),
                          _buildMobileMenuItem(
                            Icons.notifications,
                            'Notifications',
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Notifications'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              setState(() {
                                _isMenuExpanded = false;
                              });
                            },
                            hasBadge: true,
                          ),
                          _buildMobileMenuItem(
                            Icons.chat,
                            'Chat',
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Chat'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              setState(() {
                                _isMenuExpanded = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        } else {
          // Desktop layout - original design
          return Row(
            children: [
              // Dashboard heading with icon (matching the image)
              Row(
                children: [
                  Icon(Icons.dashboard, color: Colors.grey[800], size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              
              Expanded(child: SizedBox()), // Flexible space
              
              // Right side actions - wrap in Flexible to prevent overflow
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Collapsible search bar on right top corner
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
                                  style: TextStyle(fontSize: 14),
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
                    
                    SizedBox(width: 12),
                    
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
                          // Navigate to currency settings screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CurrencySettingsScreen(
                                currentCurrency: _selectedCurrency,
                                onCurrencyChanged: _onCurrencyChanged,
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.attach_money, color: Colors.grey[600]),
                        iconSize: 20,
                      ),
                    ),
                    
                    SizedBox(width: 12),
                    
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
                          // Handle time period tap
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Time Period Settings'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: Icon(Icons.schedule, color: Colors.grey[600]),
                        iconSize: 20,
                      ),
                    ),
                    
                    SizedBox(width: 12),
                    
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
                          Center(
                            child: IconButton(
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
                          ),
                          // Notification badge
                          Positioned(
                            top: 8,
                            right: 8,
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
                    
                    SizedBox(width: 12),
                    
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
                      child: IconButton(
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
        final isWide = constraints.maxWidth > 900;
        
        if (isWide) {
          // Desktop layout - horizontal row
          return SingleChildScrollView(
            child: Column(
              children: [
                // Time Period Filter and Action Buttons
                _buildTimePeriodFilter(),
                SizedBox(height: 24),
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
                    Expanded(
                      child: _buildQualifiedAreaVsRevenueChart(),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildLeadStatusDistributionChart(),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                _buildLeadPerformanceTable(),
              ],
            ),
          );
        } else {
          // Mobile and tablet layout - custom layout
          
          return SingleChildScrollView(
            child: Column(
              children: [
                // Mobile Time Period Filter
                _buildMobileTimePeriodFilter(),
                SizedBox(height: 16),
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
                        // First row with Qualified Leads and Aluminum Area
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
                        // Second row with Total Revenue taking full width
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
                           Expanded(
                             flex: 1,
                             child: _buildLegendWithPercentage(),
                           ),
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
                                     pointColorMapper: (ChartData data, _) => data.color,
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
     final totalLeads = _leadStatusDistribution.values.fold(0, (sum, count) => sum + count);
     final colors = {
       'Won': Colors.green,
       'Lost': Colors.red,
       'Loop': Colors.orange,
     };

     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         ..._leadStatusDistribution.entries.map((entry) {
           if (entry.value == 0) return SizedBox.shrink();
           
           final percentage = totalLeads > 0 ? (entry.value / totalLeads * 100).toStringAsFixed(1) : '0.0';
           final color = colors[entry.key] ?? Colors.grey;
           
           return Padding(
             padding: EdgeInsets.only(bottom: 12),
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
                     children: [
                       Text(
                         entry.key,
                         style: TextStyle(
                           fontSize: 14,
                           fontWeight: FontWeight.w600,
                           color: Colors.grey[800],
                         ),
                       ),
                       SizedBox(height: 2),
                       Text(
                         '$entry.value leads ($percentage%)',
                         style: TextStyle(
                           fontSize: 12,
                           color: Colors.grey[600],
                         ),
                       ),
                     ],
                   ),
                 ),
               ],
             ),
           );
         }),
       ],
     );
   }

   Widget _buildMobileTimePeriodFilter() {
     final timePeriods = ['Week', 'Month', 'Quarter', 'Semester', 'Annual', 'Two Years', 'Three Years', 'Five Years'];
     
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
         SizedBox(height: 12),
         // Action Buttons Row
         Padding(
           padding: EdgeInsets.symmetric(horizontal: 8),
           child: Row(
             children: [
               Expanded(
                 child: ElevatedButton(
                   onPressed: () {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                         content: Text('Exporting data...'),
                         duration: Duration(seconds: 2),
                       ),
                     );
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.blue,
                     foregroundColor: Colors.white,
                     padding: EdgeInsets.symmetric(vertical: 8),
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(8),
                     ),
                   ),
                   child: Text(
                     'Export',
                     style: TextStyle(
                       fontSize: 12,
                       fontWeight: FontWeight.w600,
                     ),
                   ),
                 ),
               ),
               SizedBox(width: 8),
               Expanded(
                 child: OutlinedButton(
                   onPressed: () {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                         content: Text('Opening more filters...'),
                         duration: Duration(seconds: 2),
                       ),
                     );
                   },
                   style: OutlinedButton.styleFrom(
                     foregroundColor: Colors.grey[700],
                     side: BorderSide(color: Colors.grey[300]!),
                     padding: EdgeInsets.symmetric(vertical: 8),
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(8),
                     ),
                   ),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(Icons.filter_list, size: 14),
                       SizedBox(width: 4),
                       Text(
                         'More Filters',
                         style: TextStyle(
                           fontSize: 12,
                           fontWeight: FontWeight.w600,
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
     );
   }

   Widget _buildTimePeriodFilter() {
     final timePeriods = ['Week', 'Month', 'Quarter', 'Semester', 'Annual', 'Two Years', 'Three Years', 'Five Years'];
     
     return Row(
       children: [
         // Time Period Label
         Text(
           'Time Period:',
           style: TextStyle(
             fontSize: 14,
             fontWeight: FontWeight.w600,
             color: Colors.grey[800],
           ),
         ),
         SizedBox(width: 16),
         // Time Period Buttons
         Expanded(
           child: SingleChildScrollView(
             scrollDirection: Axis.horizontal,
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
                       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                       decoration: BoxDecoration(
                         color: isSelected ? Colors.blue[100] : Colors.transparent,
                         borderRadius: BorderRadius.circular(20),
                         border: Border.all(
                           color: isSelected ? Colors.blue : Colors.grey[300]!,
                           width: 1,
                         ),
                       ),
                       child: Text(
                         period,
                         style: TextStyle(
                           fontSize: 12,
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
         ),
         SizedBox(width: 16),
         // Export Button
         ElevatedButton(
           onPressed: () {
             // Handle export functionality
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text('Exporting data...'),
                 duration: Duration(seconds: 2),
               ),
             );
           },
           style: ElevatedButton.styleFrom(
             backgroundColor: Colors.blue,
             foregroundColor: Colors.white,
             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.circular(8),
             ),
           ),
           child: Text(
             'Export',
             style: TextStyle(
               fontSize: 12,
               fontWeight: FontWeight.w600,
             ),
           ),
         ),
         SizedBox(width: 8),
         // More Filters Button
         OutlinedButton(
           onPressed: () {
             // Handle more filters functionality
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text('Opening more filters...'),
                 duration: Duration(seconds: 2),
               ),
             );
           },
           style: OutlinedButton.styleFrom(
             foregroundColor: Colors.grey[700],
             side: BorderSide(color: Colors.grey[300]!),
             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.circular(8),
             ),
           ),
           child: Row(
             mainAxisSize: MainAxisSize.min,
             children: [
               Icon(Icons.filter_list, size: 16),
               SizedBox(width: 4),
               Text(
                 'More Filters',
                 style: TextStyle(
                   fontSize: 12,
                   fontWeight: FontWeight.w600,
                 ),
               ),
             ],
           ),
         ),
       ],
     );
   }

  Widget _buildDashboardCard(String title, String value, String percentage, IconData icon, Color color) {
    final isPositive = percentage.startsWith('+');
    final percentageColor = isPositive ? Colors.green : Colors.red;
    
    return InkWell(
      onTap: () {
        // Handle filter tap
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Filtered by: $title'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
              height: 28, // Increased height by 16 (from 12 to 28)
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
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMenuItem(IconData icon, String label, VoidCallback onTap, {bool hasBadge = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Stack(
              children: [
                Icon(icon, color: Colors.grey[600], size: 16),
                if (hasBadge)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
                'Qualified Lead vs Revenue',
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
                                final label = group.x.toInt() < labels.length ? labels[group.x.toInt()] : '';
                                final value = rod.toY.toStringAsFixed(1);
                                final seriesName = rodIndex == 0 ? 'Qualified Leads' : 'Revenue (K)';
                                
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
                                    final displayLabel = label.length > 8 ? '${label.substring(0, 8)}...' : label;
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
                                  return Text(_formatYAxisLabel(value), style: style);
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
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Qualified Leads',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(width: 24),
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
                'Revenue (K)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
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
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  // Build bar groups for the chart
  List<BarChartGroupData> _buildBarGroups() {
    return _barChartData;
  }

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
          // Header with title and search bar
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              
              if (isMobile) {
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
                          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                          suffixIcon: _leadSearchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                                  onPressed: () {
                                    _leadSearchController.clear();
                                    _filterLeadData('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                            suffixIcon: _leadSearchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: Colors.grey[600]),
                                    onPressed: () {
                                      _leadSearchController.clear();
                                      _filterLeadData('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildLeadTabs() {
    return Row(
      children: [
        _buildTab('Won Leads', _activeLeadTab == 'Won', 'Won'),
        SizedBox(width: 24),
        _buildTab('Lost Leads', _activeLeadTab == 'Lost', 'Lost'),
        SizedBox(width: 24),
        _buildTab('In Loop', _activeLeadTab == 'Loop', 'Loop'),
      ],
    );
  }

  Widget _buildTab(String title, bool isActive, String tabValue) {
    return GestureDetector(
      onTap: () {
        _onLeadTabChanged(tabValue);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.blue[600]! : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? Colors.blue[600] : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadTable() {
    if (_isLoadingLeadData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading lead data...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredLeadData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _leadSearchController.text.isNotEmpty ? Icons.search_off : Icons.inbox_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              _leadSearchController.text.isNotEmpty 
                  ? 'No search results found'
                  : 'No ${_activeLeadTab.toLowerCase()} leads found',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _leadSearchController.text.isNotEmpty
                  ? 'Try adjusting your search terms'
                  : 'Try selecting a different tab or check back later',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // For Windows screens, always use the desktop table layout
        // Mobile layout only for very small screens
        final isMobile = constraints.maxWidth < 400;
        final isTablet = constraints.maxWidth >= 400 && constraints.maxWidth < 800;
        
        if (isMobile) {
          return _buildMobileLeadTable();
        } else if (isTablet) {
          return _buildTabletLeadTable();
        } else {
          return _buildDesktopLeadTable();
        }
      },
    );
  }

  Widget _buildMobileLeadTable() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _filteredLeadData.length,
      itemBuilder: (context, index) {
        final lead = _filteredLeadData[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project Info Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMobileInfoItem('Project ID', lead['project_id'] ?? 'N/A', Colors.grey[100]!),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildMobileInfoItem('Status', lead['update_lead_status'] ?? 'N/A', _getStatusColor(lead['update_lead_status'] ?? '').withValues(alpha: 0.1)),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // Project Name and Sales User
                Row(
                  children: [
                    Expanded(
                      child: _buildMobileInfoItem('Project', lead['project_name'] ?? 'N/A', Colors.blue[50]!),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildMobileInfoItem('Sales User', lead['sales_user'] ?? 'N/A', Colors.indigo[50]!),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // Client and Location
                Row(
                  children: [
                    Expanded(
                      child: _buildMobileInfoItem('Client', lead['client_name'] ?? 'N/A', Colors.white),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildMobileInfoItem('Location', lead['location'] ?? 'N/A', Colors.white),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // Metrics Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMobileInfoItem('Area', lead['aluminium_area'] != null ? '${lead['aluminium_area'].toString()} m²' : 'N/A', Colors.green[50]!),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildMobileInfoItem('Rate', lead['rate_sqm'] != null ? '₹${lead['rate_sqm'].toString()}' : 'N/A', Colors.orange[50]!),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // Amount and Date
                Row(
                  children: [
                    Expanded(
                      child: _buildMobileInfoItem('Total', lead['total_amount_gst'] != null ? '₹${lead['total_amount_gst'].toString()}' : 'N/A', Colors.purple[50]!),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildMobileInfoItem('Closed', lead['updated_at'] != null ? DateTime.parse(lead['updated_at']).toLocal().toString().split('.')[0] : 'N/A', Colors.white),
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

  Widget _buildMobileInfoItem(String label, String value, Color backgroundColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLeadTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
          fontSize: 11,
        ),
        dataTextStyle: TextStyle(
          fontSize: 11,
          color: Colors.grey[700],
        ),
        columns: [
          DataColumn(label: SizedBox(width: 80, child: Text('PROJECT ID'))),
          DataColumn(label: SizedBox(width: 100, child: Text('PROJECT NAME'))),
          DataColumn(label: SizedBox(width: 90, child: Text('CLIENT NAME'))),
          DataColumn(label: SizedBox(width: 70, child: Text('LOCATION'))),
          DataColumn(label: SizedBox(width: 80, child: Text('AREA'))),
          DataColumn(label: SizedBox(width: 70, child: Text('RATE'))),
          DataColumn(label: SizedBox(width: 90, child: Text('TOTAL'))),
          DataColumn(label: SizedBox(width: 100, child: Text('SALES USER'))),
          DataColumn(label: SizedBox(width: 60, child: Text('STATUS'))),
          DataColumn(label: SizedBox(width: 100, child: Text('CLOSED DATE'))),
        ],
        rows: _filteredLeadData.map((lead) => _buildTabletLeadRow(lead)).toList(),
      ),
    );
  }

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
        DataCell(SizedBox(width: 80, child: Text(projectId, style: TextStyle(fontSize: 9), overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: 100, child: Text(projectName, style: TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: 90, child: Text(clientName, style: TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: 70, child: Text(location, style: TextStyle(fontSize: 9), overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: 80, child: Text(aluminiumArea, style: TextStyle(fontSize: 9), overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: 70, child: Text(rateSqm, style: TextStyle(fontSize: 9), overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: 90, child: Text(totalAmount, style: TextStyle(fontSize: 9), overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: 100, child: Text(salesUser, style: TextStyle(fontSize: 9), overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: 60, child: Text(status, style: TextStyle(fontSize: 9), overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: 100, child: Text(closedDate, style: TextStyle(fontSize: 9), overflow: TextOverflow.ellipsis))),
      ],
    );
  }

  Widget _buildDesktopLeadTable() {
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
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                _buildTableHeaderCell('PROJECT ID', 1),
                _buildTableHeaderCell('PROJECT NAME', 2),
                _buildTableHeaderCell('CLIENT NAME', 2),
                _buildTableHeaderCell('LOCATION', 1),
                _buildTableHeaderCell('ALUMINIUM AREA', 1),
                _buildTableHeaderCell('RC WEIGHT', 1),
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
          ..._filteredLeadData.map((lead) => _buildTableDataRow(lead)),
        ],
      ),
    );
  }



  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'won':
        return Colors.green[700]!;
      case 'lost':
        return Colors.red[700]!;
      case 'loop':
        return Colors.orange[700]!;
      default:
        return Colors.grey[700]!;
    }
  }



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
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: null, // Disabled for first page
                    child: Text(
                      'Previous',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
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
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
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
            overflow: TextOverflow.visible,
            softWrap: true,
            maxLines: null, // Allow unlimited lines
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
          _buildTableDataCell('${lead['aluminium_area']?.toString() ?? '0'} m²', 1),
          _buildTableDataCell(lead['rc_weight']?.toString() ?? 'N/A', 1),
          _buildTableDataCell('₹${lead['rate_sqm']?.toString() ?? '0'}', 1),
          _buildTableDataCell('₹${lead['total_amount_gst']?.toString() ?? '0'}', 1),
          _buildTableDataCell(lead['sales_user']?.toString() ?? 'N/A', 1),
          _buildTableDataCell(
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(lead['update_lead_status']).withValues(alpha: 0.1),
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
          _buildTableDataCell(lead['lead_status_remark']?.toString() ?? 'N/A', 1),
          _buildTableDataCell(_formatDate(lead['updated_at']), 1),
        ],
      ),
    );
  }

  // Build table data cell
  Widget _buildTableDataCell(dynamic content, int flex) {
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
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.visible,
                  softWrap: true,
                  maxLines: null, // Allow unlimited lines
                ),
              ),
      ),
    );
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



}
