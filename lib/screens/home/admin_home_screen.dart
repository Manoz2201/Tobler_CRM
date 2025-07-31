import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:crm_app/widgets/profile_page.dart';
import 'package:crm_app/screens/home/developer_home_screen.dart'
    show UserManagementPage, RoleManagementPage;
import 'package:intl/intl.dart';

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
  bool _isDockedLeft = true;
  double _dragOffsetX = 0.0;

  final ScrollController _scrollbarController = ScrollController();

  final List<_NavItem> _navItems = const [
    _NavItem('Dashboard', Icons.dashboard),
    _NavItem('Lead', Icons.leaderboard),
    _NavItem('User Management', Icons.group),
    _NavItem('Role Management', Icons.security),
    _NavItem('AI', Icons.auto_awesome),
    _NavItem('Settings', Icons.settings),
    _NavItem('Analytics', Icons.bar_chart),
    _NavItem('Chat', Icons.chat),
    _NavItem('Profile', Icons.person),
  ];

  late final List<Widget> _pages = <Widget>[
    const Center(child: Text('Admin Dashboard')),
    LeadTable(),
    UserManagementPage(),
    RoleManagementPage(),
    const Center(child: Text('Search')),
    AdminSettingsPage(),
    const Center(child: Text('Analytics')),
    const Center(child: Text('Chat')),
    ProfilePage(),
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

  Widget _buildMobileNavigationBar() {
    return Container(
      height: 60,
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
        child: Container(
          height: 60,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate item width to show exactly 5 items
              final itemWidth = constraints.maxWidth / 5;

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
    _NavItem item,
    int index,
    bool isSelected,
    double width,
  ) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: EdgeInsets.all(4),
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
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 8,
                  color: isSelected ? Colors.blue[600] : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
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
                color: Color.fromARGB((0.15 * 255).round(), 255, 255, 255),
              ),
            ),
            Container(
              width: 72,
              height: screenHeight * 0.8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Color.fromARGB((0.3 * 255).round(), 255, 255, 255),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB((0.05 * 255).toInt(), 0, 0, 0),
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
                                    color: Color.fromARGB(
                                      (0.18 * 255).round(),
                                      255,
                                      255,
                                      255,
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
                                color: Color.fromARGB(
                                  (0.18 * 255).round(),
                                  255,
                                  255,
                                  255,
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
                    right:
                        0, // Remove right padding to prevent overlap with Actions column
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
                      top: screenHeight * 0.1,
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) =>
                            _onHorizontalDragUpdate(details, screenWidth),
                        onHorizontalDragEnd: (_) =>
                            _onHorizontalDragEnd(screenWidth),
                        child: _buildNavBar(screenHeight, screenWidth),
                      ),
                    );
                  },
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

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}

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

                        // Activity Timeline
                        if (activityTimeline.isNotEmpty)
                          _buildDetailSection(
                            'Activity Timeline',
                            activityTimeline
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

  Widget _buildActivityTimelineItem(Map<String, dynamic> activity) {
    final activityDate = _formatDate(activity['activity_date']);
    final activityTime = activity['activity_time'] ?? '';
    final activityText = activity['activity'] ?? 'N/A';
    final changesMade = activity['changes_made'] ?? '';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  '$activityDate $activityTime:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activityText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (changesMade.isNotEmpty)
                      Text(
                        'Changes: $changesMade',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
  Set<String> _selectedLeads = {};
  bool _selectAll = false;
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
    _selectAll =
        _selectedLeads.length == _filteredLeads.length &&
        _filteredLeads.isNotEmpty;
  }

  void _bulkApprove() {
    if (_selectedLeads.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select leads to approve')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bulk Approve Leads'),
        content: Text(
          'Are you sure you want to approve ${_selectedLeads.length} selected leads?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement bulk approve logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${_selectedLeads.length} leads approved successfully',
                  ),
                ),
              );
              setState(() {
                _selectedLeads.clear();
                _selectAll = false;
              });
            },
            child: Text('Approve'),
          ),
        ],
      ),
    );
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
              0.0,
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
            child: Container(
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

  Widget _buildMobileStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onSort,
  ) {
    return Container(
      width: 80, // Smaller width for icon-only cards
      padding: EdgeInsets.all(8),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Sort button with icon only
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: onSort,
              borderRadius: BorderRadius.circular(8),
              child: Icon(icon, color: color, size: 20),
            ),
          ),
          const SizedBox(height: 6),
          // Count value below icon
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
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

  Widget _buildBulkActions() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Text(
            '${_selectedLeads.length} leads selected',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _bulkApprove,
            icon: Icon(Icons.approval),
            label: Text('Bulk Approve'),
            style: TextButton.styleFrom(foregroundColor: Colors.green[700]),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedLeads.clear();
                _selectAll = false;
              });
            },
            icon: Icon(Icons.clear),
            label: Text('Clear Selection'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
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
    final isSelected = _selectedLeads.contains(leadId.toString());

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
      padding: EdgeInsets.only(right: 24),
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
    final isSelected = _selectedLeads.contains(leadId.toString());

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
        color: isSelected ? Colors.blue[50] : Colors.white,
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
          onTap: () => _toggleLeadSelection(leadId.toString()),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) =>
                          _toggleLeadSelection(leadId.toString()),
                    ),
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

  void _sortByStatus(String status) {
    setState(() {
      switch (status) {
        case 'total':
          // Show all leads
          _filteredLeads = List.from(_leads);
          break;
        case 'new':
          // Show only new leads
          _filteredLeads = _leads.where((lead) {
            final status = _getLeadStatus(lead);
            return status == 'New';
          }).toList();
          break;
        case 'proposalProgress':
          // Show only proposal progress leads
          _filteredLeads = _leads.where((lead) {
            final status = _getLeadStatus(lead);
            return status == 'Proposal Progress';
          }).toList();
          break;
        case 'waiting':
          // Show leads waiting for approval
          _filteredLeads = _leads.where((lead) {
            final adminResponse = lead['approved'];
            return adminResponse == null;
          }).toList();
          break;
        case 'approved':
          // Show only approved leads
          _filteredLeads = _leads.where((lead) {
            final adminResponse = lead['approved'];
            return adminResponse == true;
          }).toList();
          break;
      }
    });

    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filtered by $status'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.blue[600],
      ),
    );
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

  Widget _buildActivityTimelineItem(Map<String, dynamic> activity) {
    final activityDate = _formatDate(activity['activity_date']);
    final activityTime = activity['activity_time'] ?? '';
    final activityType = activity['activity'] ?? 'N/A';
    final changesMade = activity['changes_made'];

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date, time, and activity type
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: Colors.blue[600]),
              SizedBox(width: 8),
              Text(
                '$activityDate $activityTime',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  activityType.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),

          // Changes section if available
          if (changesMade != null) ...[
            Text(
              'Changes Made:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 6),
            _buildChangesDisplay(changesMade),
          ],
        ],
      ),
    );
  }

  Widget _buildChangesDisplay(dynamic changesData) {
    try {
      // Try to parse as JSON if it's a string
      Map<String, dynamic> changes;
      if (changesData is String) {
        changes = Map<String, dynamic>.from(jsonDecode(changesData));
      } else if (changesData is Map) {
        changes = Map<String, dynamic>.from(changesData);
      } else {
        return Text(
          changesData.toString(),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: changes.entries.map((entry) {
          final key = entry.key;
          final value = entry.value;

          // Format the key for better readability
          String formattedKey = key
              .replaceAll('_', ' ')
              .split(' ')
              .map(
                (word) => word.isNotEmpty
                    ? word[0].toUpperCase() + word.substring(1)
                    : '',
              )
              .join(' ');

          return Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.only(top: 6, right: 8),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedKey,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 2),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          value?.toString() ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    } catch (e) {
      // Fallback for non-JSON data
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          changesData.toString(),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      );
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

                        // Activity Timeline
                        if (activityTimeline.isNotEmpty)
                          _buildDetailSection(
                            'Activity Timeline',
                            activityTimeline
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
    // TODO: Implement query lead functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Query submitted for Lead ${lead['lead_id']}'),
        backgroundColor: Colors.orange,
      ),
    );
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
