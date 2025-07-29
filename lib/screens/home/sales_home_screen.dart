// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; // Added for jsonEncode
import 'package:crm_app/widgets/profile_page.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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
    _NavItem('Leads', Icons.people_outline),
    _NavItem('Opportunities', Icons.trending_up),
    _NavItem('Reports', Icons.bar_chart),
    _NavItem('Chat', Icons.chat),
    _NavItem('Profile', Icons.person),
  ];

  late final List<Widget> _pages = <Widget>[
    Center(child: Text('Sales Dashboard')),
    _LeadsPage(
      currentUserType: widget.currentUserType,
      currentUserEmail: widget.currentUserEmail,
      currentUserId: widget.currentUserId,
    ),
    Center(child: Text('Opportunities')),
    Center(child: Text('Reports')),
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
  List<Map<String, dynamic>> leads = [];
  Map<String, dynamic>? _selectedLead;
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _attachments = [];
  List<Map<String, dynamic>> _activityTimeline = [];
  List<Map<String, dynamic>> _initialQuote = [];
  // Add state for initial quote status dropdown
  List<String> _initialQuoteStatuses = [];
  String? _selectedQuoteStatus;
  Map<String, dynamic>? _displayedInitialQuote;
  bool _isActivityLoading = false;
  bool _isEditMode = false;
  final _editFormKey = GlobalKey<FormState>();
  Map<String, TextEditingController> _editControllers = {};

  // Commented out unused fields to resolve linter warnings but keep them for future use
  // Map<String, dynamic>? _editingQuote;
  // final Map<int, Map<String, TextEditingController>> _initialQuoteControllers = {};

  // Add a state variable to track view-only mode
  bool _isViewOnly = false;
  // Add a state variable to control timeline-only mode
  bool _showTimelineOnly = false;

  // Add state for initial quote edit mode and editable table data
  bool _isInitialQuoteEditMode = false;
  List<Map<String, TextEditingController>> _editableQuoteRows = [];

  @override
  void initState() {
    super.initState();
    _fetchLeads();
  }

  Future<void> _fetchLeads() async {
    setState(() {
      _selectedLead = null;
    });
    try {
      final client = Supabase.instance.client;
      // Filter leads to show only those created by the current sales person
      final data = await client
          .from('leads')
          .select('*')
          .eq('lead_generated_by', widget.currentUserId)
          .order('created_at', ascending: false);
      setState(() {
        leads = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      // Optionally handle error
    }
  }

  Future<void> _fetchLeadDetails(String leadId) async {
    setState(() {
      _contacts = [];
      _attachments = [];
      _activityTimeline = [];
      _initialQuote = [];
      _initialQuoteStatuses = [];
      _selectedQuoteStatus = null;
      _displayedInitialQuote = null;
      _isActivityLoading = true;
    });
    try {
      final client = Supabase.instance.client;
      final lead = await client
          .from('leads')
          .select('*')
          .eq('id', leadId)
          .maybeSingle();
      final contacts = await client
          .from('lead_contacts')
          .select('*')
          .eq('lead_id', leadId);
      final attachments = await client
          .from('lead_attachments')
          .select('*')
          .eq('lead_id', leadId);
      final activities = await client
          .from('lead_activity')
          .select('*')
          .eq('lead_id', leadId)
          .order('activity_date', ascending: false)
          .order('activity_time', ascending: false);
      final initialQuote = await client
          .from('initial_quote')
          .select('*')
          .eq('lead_id', leadId)
          .order('created_at', ascending: true);
      // Prepare status list and default selection for Scaffolding
      List<String> statuses = [];
      Map<String, dynamic>? displayedQuote;
      String? selectedStatus;
      if (lead != null &&
          lead['lead_type'] == 'Scaffolding' &&
          initialQuote.isNotEmpty) {
        statuses = initialQuote
            .map<String>((q) => q['update_status']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
        // Default to 'New' if available, else first
        selectedStatus = statuses.contains('New')
            ? 'New'
            : (statuses.isNotEmpty ? statuses.first : null);
        // Fix: If only one row, use it directly
        if (initialQuote.length == 1) {
          displayedQuote = initialQuote.first;
          selectedStatus = initialQuote.first['update_status']?.toString();
        } else {
          displayedQuote = initialQuote.firstWhere(
            (q) => q['update_status'] == selectedStatus,
            orElse: () => initialQuote.first,
          );
        }
      }
      setState(() {
        _selectedLead = lead;
        _contacts = List<Map<String, dynamic>>.from(contacts);
        _attachments = List<Map<String, dynamic>>.from(attachments);
        _activityTimeline = List<Map<String, dynamic>>.from(activities);
        _initialQuote = List<Map<String, dynamic>>.from(initialQuote);
        _initialQuoteStatuses = statuses;
        _selectedQuoteStatus = selectedStatus;
        _displayedInitialQuote = displayedQuote;
        _isActivityLoading = false;
      });
    } catch (e) {
      setState(() {
        _isActivityLoading = false;
      });
    }
  }

  Future<void> _addActivity({
    required String leadId,
    required String userName,
    required String activity,
    String? changesMade,
  }) async {
    final now = DateTime.now();
    final date = DateFormat('yyyy-MM-dd').format(now);
    final time = DateFormat('HH:mm:ss').format(now);
    final client = Supabase.instance.client;
    await client.from('lead_activity').insert({
      'lead_id': leadId,
      'activity_date': date,
      'activity_time': time,
      'user_name': userName,
      'activity': activity,
      'changes_made': changesMade ?? '',
    });
    await _fetchLeadDetails(leadId); // Refresh timeline
  }

  void _cancelEdit() {
    setState(() {
      _isEditMode = false;
      _editControllers = {};
    });
  }

  Future<void> _saveEdit() async {
    if (!_editFormKey.currentState!.validate() || _selectedLead == null) return;
    final client = Supabase.instance.client;
    final leadId = _selectedLead!['id'];
    final updatedFields = {
      'client_name': _editControllers['client_name']!.text.trim(),
      'project_name': _editControllers['project_name']!.text.trim(),
      'project_location': _editControllers['project_location']!.text.trim(),
      'lead_type': _editControllers['lead_type']!.text.trim(),
      'main_contact_name': _editControllers['main_contact_name']!.text.trim(),
      'main_contact_designation': _editControllers['main_contact_designation']!
          .text
          .trim(),
      'main_contact_email': _editControllers['main_contact_email']!.text.trim(),
      'main_contact_mobile': _editControllers['main_contact_mobile']!.text
          .trim(),
      'remark': _editControllers['remark']!.text.trim(),
    };
    await client.from('leads').update(updatedFields).eq('id', leadId);
    await _addActivity(
      leadId: leadId,
      userName: 'Current User', // Replace with actual user
      activity: 'Edit',
      changesMade: 'Edited lead details',
    );
    setState(() {
      _isEditMode = false;
      _editControllers = {};
    });
    await _fetchLeadDetails(leadId);
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
        onAdd: (lead) async {
          await _fetchLeads();
        },
        userType: widget.currentUserType,
        userEmail: widget.currentUserEmail,
        userId: widget.currentUserId,
      ),
    );
  }

  // Call this from the navigation bar's 'Leads' button
  void showLeadsList() {
    setState(() {
      _selectedLead = null;
      _isViewOnly = false;
      _showTimelineOnly = false;
    });
    _fetchLeads();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedLead != null) {
      final lead = _selectedLead!;
      // Allow editing for all Sales, Admin, and Developer users
      final bool canEdit =
          widget.currentUserType == 'Sales' ||
          widget.currentUserType == 'Admin' ||
          widget.currentUserType == 'Developer';
      final detailsSection = Card(
        margin: EdgeInsets.zero,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          width: double.infinity,
          height: 450, // Fixed height for consistent grid
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _isEditMode
                  ? [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lead Details',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: _saveEdit,
                                child: Text('Save'),
                              ),
                              SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: _cancelEdit,
                                child: Text('Cancel'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Form(
                        key: _editFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _editTextField('Client Name', 'client_name'),
                            _editTextField('Project Name', 'project_name'),
                            _editTextField(
                              'Project Location',
                              'project_location',
                            ),
                            _editTextField('Lead Type', 'lead_type'),
                            SizedBox(height: 24),
                            Text(
                              'Main Contact',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Divider(),
                            _editTextField('Name', 'main_contact_name'),
                            _editTextField(
                              'Designation',
                              'main_contact_designation',
                            ),
                            _editTextField(
                              'Email',
                              'main_contact_email',
                              email: true,
                            ),
                            _editTextField('Mobile', 'main_contact_mobile'),
                            SizedBox(height: 24),
                            Text(
                              'Remark',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Divider(),
                            _editTextField(
                              'Remark',
                              'remark',
                              minLines: 2,
                              maxLines: 4,
                            ),
                          ],
                        ),
                      ),
                    ]
                  : [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lead Details',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Row(
                            children: [
                              if (canEdit && !_isViewOnly)
                                OutlinedButton(
                                  onPressed: _startEdit,
                                  child: Text('Edit'),
                                ),
                              if (canEdit && !_isViewOnly) SizedBox(width: 8),
                              if (canEdit && !_isViewOnly)
                                ElevatedButton(
                                  onPressed: () async {
                                    if (_selectedLead != null) {
                                      await _addActivity(
                                        leadId: _selectedLead!['id'],
                                        userName:
                                            'Current User', // Replace with actual user
                                        activity: 'Publish',
                                        changesMade: 'Published lead',
                                      );
                                    }
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Publish action')),
                                    );
                                  },
                                  child: Text('Publish'),
                                ),
                              if (canEdit && !_isViewOnly) SizedBox(width: 8),
                              // DELETE ICON REMOVED FROM LEAD DETAILS CARD
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      _detailRow('Client Name', lead['client_name']),
                      _detailRow('Project Name', lead['project_name']),
                      _detailRow('Project Location', lead['project_location']),
                      _detailRow('Lead Type', lead['lead_type']),
                      SizedBox(height: 24),
                      Text(
                        'Main Contact',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Divider(),
                      _detailRow('Name', lead['main_contact_name']),
                      _detailRow(
                        'Designation',
                        lead['main_contact_designation'],
                      ),
                      _detailRow('Email', lead['main_contact_email']),
                      _detailRow('Mobile', lead['main_contact_mobile']),
                      SizedBox(height: 24),
                      Text(
                        'Remark',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Divider(),
                      _detailRow('Remark', lead['remark']),
                    ],
            ),
          ),
        ),
      );
      final contactsSection = Card(
        margin: EdgeInsets.zero,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          child: _contacts.isNotEmpty
              ? SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Other Contacts',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Divider(),
                      ..._contacts.map(
                        (c) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _detailRow('Name', c['contact_name']),
                              _detailRow('Designation', c['designation']),
                              _detailRow('Email', c['email']),
                              _detailRow('Mobile', c['mobile']),
                              Divider(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Center(child: Text('No contacts available')),
        ),
      );
      final initialQuoteSection =
          (_selectedLead != null &&
              _selectedLead!['lead_type'] == 'Scaffolding')
          ? Card(
              margin: EdgeInsets.zero,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                child: (_displayedInitialQuote != null)
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Heading and action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Initial Quote',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Row(
                                children: [
                                  if (canEdit && !_isViewOnly)
                                    OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          _isInitialQuoteEditMode = true;
                                          _initEditableQuoteRows();
                                        });
                                      },
                                      child: Text('Edit'),
                                    ),
                                  if (canEdit && !_isViewOnly)
                                    SizedBox(width: 8),
                                  if (canEdit && !_isViewOnly)
                                    ElevatedButton(
                                      onPressed: () async {
                                        await _saveInitialQuoteEdits();
                                        Navigator.pop(context);
                                      },
                                      child: Text('Update'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          if (_initialQuoteStatuses.length > 1)
                            Row(
                              children: [
                                Text(
                                  'Status: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 12),
                                DropdownButton<String>(
                                  value: _selectedQuoteStatus,
                                  items: _initialQuoteStatuses
                                      .map(
                                        (status) => DropdownMenuItem<String>(
                                          value: status,
                                          child: Text(status),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedQuoteStatus = val;
                                        _displayedInitialQuote = _initialQuote
                                            .firstWhere(
                                              (q) => q['update_status'] == val,
                                              orElse: () => _initialQuote.first,
                                            );
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          SizedBox(height: 12),
                          (_isInitialQuoteEditMode)
                              ? Column(
                                  children: [
                                    (_editableQuoteRows.length > 2)
                                        ? SizedBox(
                                            height: 220,
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.vertical,
                                              child: Table(
                                                border: TableBorder.all(
                                                  color: Colors.grey,
                                                ),
                                                defaultColumnWidth:
                                                    IntrinsicColumnWidth(),
                                                children: [
                                                  TableRow(
                                                    children: [
                                                      for (final header in [
                                                        'Item name (Detail)',
                                                        'Unit Weight (kg)',
                                                        'Quantity',
                                                        'Ex-Factory Price',
                                                        'Unit Price',
                                                        'Profit (%)',
                                                        'Total',
                                                        'Per/Kg Price',
                                                      ])
                                                        Container(
                                                          color:
                                                              Colors.grey[200],
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 8,
                                                                horizontal: 8,
                                                              ),
                                                          child: Text(
                                                            header,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  ...List.generate(_editableQuoteRows.length, (
                                                    rowIdx,
                                                  ) {
                                                    final row =
                                                        _editableQuoteRows[rowIdx];
                                                    return TableRow(
                                                      children: [
                                                        for (final key in [
                                                          'item_name',
                                                          'unit_weight',
                                                          'quantity',
                                                          'ex_factory_price',
                                                          'unit_price',
                                                          'profit_percent',
                                                          'total',
                                                          'one_kg_price',
                                                        ])
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  4.0,
                                                                ),
                                                            child: TextFormField(
                                                              controller:
                                                                  row[key],
                                                              decoration: InputDecoration(
                                                                border:
                                                                    InputBorder
                                                                        .none,
                                                                isDense: true,
                                                                contentPadding:
                                                                    EdgeInsets.symmetric(
                                                                      vertical:
                                                                          8,
                                                                      horizontal:
                                                                          8,
                                                                    ),
                                                              ),
                                                              keyboardType:
                                                                  (key ==
                                                                      'item_name')
                                                                  ? TextInputType
                                                                        .text
                                                                  : TextInputType
                                                                        .number,
                                                              onEditingComplete:
                                                                  _saveInitialQuoteEdits,
                                                            ),
                                                          ),
                                                      ],
                                                    );
                                                  }),
                                                  // Total row
                                                  TableRow(
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              4.0,
                                                            ),
                                                        child: Text('Total:'),
                                                      ),
                                                      for (
                                                        int i = 1;
                                                        i < 8;
                                                        i++
                                                      )
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                4.0,
                                                              ),
                                                          child: Text(
                                                            '0.00',
                                                          ), // You can calculate sums if needed
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : Table(
                                            border: TableBorder.all(
                                              color: Colors.grey,
                                            ),
                                            defaultColumnWidth:
                                                IntrinsicColumnWidth(),
                                            children: [
                                              TableRow(
                                                children: [
                                                  for (final header in [
                                                    'Item name (Detail)',
                                                    'Unit Weight (kg)',
                                                    'Quantity',
                                                    'Ex-Factory Price',
                                                    'Unit Price',
                                                    'Profit (%)',
                                                    'Total',
                                                    'Per/Kg Price',
                                                  ])
                                                    Container(
                                                      color: Colors.grey[200],
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 8,
                                                            horizontal: 8,
                                                          ),
                                                      child: Text(
                                                        header,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              ...List.generate(
                                                _editableQuoteRows.length,
                                                (rowIdx) {
                                                  final row =
                                                      _editableQuoteRows[rowIdx];
                                                  return TableRow(
                                                    children: [
                                                      for (final key in [
                                                        'item_name',
                                                        'unit_weight',
                                                        'quantity',
                                                        'ex_factory_price',
                                                        'unit_price',
                                                        'profit_percent',
                                                        'total',
                                                        'one_kg_price',
                                                      ])
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                4.0,
                                                              ),
                                                          child: TextFormField(
                                                            controller:
                                                                row[key],
                                                            decoration: InputDecoration(
                                                              border:
                                                                  InputBorder
                                                                      .none,
                                                              isDense: true,
                                                              contentPadding:
                                                                  EdgeInsets.symmetric(
                                                                    vertical: 8,
                                                                    horizontal:
                                                                        8,
                                                                  ),
                                                            ),
                                                            keyboardType:
                                                                (key ==
                                                                    'item_name')
                                                                ? TextInputType
                                                                      .text
                                                                : TextInputType
                                                                      .number,
                                                            onEditingComplete:
                                                                _saveInitialQuoteEdits,
                                                          ),
                                                        ),
                                                    ],
                                                  );
                                                },
                                              ),
                                              // Total row
                                              TableRow(
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          4.0,
                                                        ),
                                                    child: Text('Total:'),
                                                  ),
                                                  for (int i = 1; i < 8; i++)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            4.0,
                                                          ),
                                                      child: Text(
                                                        '0.00',
                                                      ), // You can calculate sums if needed
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                    SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        OutlinedButton.icon(
                                          icon: Icon(Icons.add),
                                          label: Text('Add Row'),
                                          onPressed: _addQuoteRow,
                                          style: OutlinedButton.styleFrom(
                                            shape: StadiumBorder(),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        OutlinedButton.icon(
                                          icon: Icon(Icons.remove),
                                          label: Text('Remove Row'),
                                          onPressed: _removeQuoteRow,
                                          style: OutlinedButton.styleFrom(
                                            shape: StadiumBorder(),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Item Name')),
                                      DataColumn(label: Text('Unit Weight')),
                                      DataColumn(label: Text('Quantity')),
                                      DataColumn(label: Text('Ex-Factory')),
                                      DataColumn(label: Text('Unit Price')),
                                      DataColumn(label: Text('Profit %')),
                                      DataColumn(label: Text('Total')),
                                      DataColumn(label: Text('Per/Kg')),
                                    ],
                                    rows: [
                                      DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              _displayedInitialQuote!['item_name']
                                                      ?.toString() ??
                                                  '',
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              _displayedInitialQuote!['unit_weight']
                                                      ?.toString() ??
                                                  '',
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              _displayedInitialQuote!['quantity']
                                                      ?.toString() ??
                                                  '',
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              _displayedInitialQuote!['ex_factory_price']
                                                      ?.toString() ??
                                                  '',
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              _displayedInitialQuote!['unit_price']
                                                      ?.toString() ??
                                                  '',
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              _displayedInitialQuote!['profit_percent']
                                                      ?.toString() ??
                                                  '',
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              _displayedInitialQuote!['total']
                                                      ?.toString() ??
                                                  '',
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              _displayedInitialQuote!['one_kg_price']
                                                      ?.toString() ??
                                                  '',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                        ],
                      )
                    : Center(child: Text('No initial quote available')),
              ),
            )
          : SizedBox.shrink();
      final attachmentsSection = Card(
        margin: EdgeInsets.zero,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          child: _attachments.isNotEmpty
              ? SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attachments',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Divider(),
                      ..._attachments.map(
                        (a) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _detailRow('File Name', a['file_name']),
                              _detailRow(
                                'File Link',
                                a['file_link'],
                                isLink: true,
                              ),
                              Divider(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Center(child: Text('No attachments available')),
        ),
      );
      final activityTimelineSection = Card(
        margin: EdgeInsets.zero,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              if (_activityTimeline.isEmpty) Text('No activity yet.'),
              if (!_isActivityLoading && _activityTimeline.isNotEmpty)
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _activityTimeline
                        .map(
                          (a) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${a['activity_date']} ${a['activity_time']}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      FutureBuilder<Map<String, dynamic>?>(
                                        future: fetchUserInfo(
                                          a['user_id'] ?? '',
                                        ),
                                        builder: (context, userSnapshot) {
                                          final user = userSnapshot.data;
                                          final userStr = user != null
                                              ? '${user['username'] ?? ''} (${user['employee_code'] ?? ''})'
                                              : (a['user_name'] ?? 'User');
                                          return Text(
                                            '$userStr - ${a['activity']}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          );
                                        },
                                      ),
                                      if ((a['changes_made'] ?? '')
                                          .toString()
                                          .isNotEmpty)
                                        Text('Changes: ${a['changes_made']}'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      );
      if (_showTimelineOnly) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: showLeadsList,
            ),
            title: Text('Activity Timeline'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.all(24),
            child: activityTimelineSection,
          ),
          backgroundColor: Colors.white,
        );
      }
      return SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 1100;
            if (isWide) {
              // 3-column responsive layout for web/desktop
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 32,
                      top: 24,
                      bottom: 8,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back),
                          onPressed: showLeadsList,
                          tooltip: 'Back to Leads',
                        ),
                        Text(
                          'Lead Details',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column (Lead Details + Initial Quote)
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              // Lead Details (top, large card)
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    32,
                                    0,
                                    16,
                                    12,
                                  ),
                                  child: detailsSection,
                                ),
                              ),
                              // Initial Quote (bottom, wide card)
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    32,
                                    0,
                                    16,
                                    24,
                                  ),
                                  child: initialQuoteSection,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Middle column (Attachments + Contact)
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              // Attachments (top, half)
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    0,
                                    0,
                                    16,
                                    12,
                                  ),
                                  child: attachmentsSection,
                                ),
                              ),
                              // Contacts (bottom, half)
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    0,
                                    0,
                                    16,
                                    24,
                                  ),
                                  child: contactsSection,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Right column (Activity Timeline, fixed width)
                        Container(
                          width: 340,
                          margin: const EdgeInsets.only(
                            top: 0,
                            right: 32,
                            bottom: 24,
                          ),
                          child: activityTimelineSection,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              // Mobile/tablet: stack vertically
              return SingleChildScrollView(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back),
                          onPressed: showLeadsList,
                          tooltip: 'Back to Leads',
                        ),
                        Text(
                          'Lead Details',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    // Lead Details Card
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: detailsSection,
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: attachmentsSection,
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: contactsSection,
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: initialQuoteSection,
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: activityTimelineSection,
                    ),
                  ],
                ),
              );
            }
          },
        ),
      );
    }
    // List view
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Leads',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Add Lead'),
                onPressed: _showAddLeadDialog,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final orientation = MediaQuery.of(context).orientation;
              final isWide =
                  constraints.maxWidth > 900 ||
                  orientation == Orientation.landscape;
              if (isWide) {
                // Grid for desktop/web and landscape
                return GridView.builder(
                  padding: const EdgeInsets.all(12), // reduced from 24
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12, // reduced from 16
                    mainAxisSpacing: 12, // reduced from 16
                    childAspectRatio: 1.7, // slightly taller for all icons
                  ),
                  itemCount: leads.length,
                  itemBuilder: (context, index) {
                    final lead = leads[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                      ), // reduced from 12
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () => _fetchLeadDetails(lead['id']),
                        child: Padding(
                          padding: const EdgeInsets.all(
                            12.0,
                          ), // reduced from 20
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    lead['client_name'] ?? '-',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.update,
                                          color: Color(0xFF1976D2),
                                        ),
                                        tooltip: 'Update',
                                        onPressed: () => _showSnack(
                                          context,
                                          'Update ${lead['client_name']}',
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.timeline,
                                          color: Color(0xFF1976D2),
                                        ),
                                        tooltip: 'Timeline',
                                        onPressed: () {
                                          setState(() {
                                            _showTimelineOnly = true;
                                            _isViewOnly = true;
                                          });
                                          _fetchLeadDetails(lead['id']);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 2), // reduced from 4
                              Text('Project: ${lead['project_name'] ?? '-'}'),
                              Text(
                                'Location: ${lead['project_location'] ?? '-'}',
                              ),
                              Text(
                                'Main Contact: ${lead['main_contact_name'] ?? '-'}',
                              ),
                              SizedBox(height: 6), // reduced from 12
                              Align(
                                alignment: Alignment.bottomLeft,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.remove_red_eye,
                                        color: Color(0xFF1976D2),
                                      ),
                                      tooltip: 'View',
                                      onPressed: () {
                                        setState(() {
                                          _isViewOnly = true;
                                        });
                                        _fetchLeadDetails(lead['id']);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Color(0xFF1976D2),
                                      ),
                                      tooltip: 'Edit',
                                      onPressed: () {
                                        setState(() {
                                          _isViewOnly = false;
                                          _isEditMode = true;
                                        });
                                        _fetchLeadDetails(lead['id']);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Color(0xFF1976D2),
                                      ),
                                      tooltip: 'Delete',
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('Delete Lead'),
                                            content: Text(
                                              'Are you sure you want to delete this lead?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          final client =
                                              Supabase.instance.client;
                                          await client
                                              .from('leads')
                                              .delete()
                                              .eq('id', lead['id']);
                                          _fetchLeads();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Lead deleted'),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.chat,
                                        color: Colors.orange,
                                      ),
                                      tooltip: 'Query',
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) =>
                                              SalesQueryDialog(lead: lead),
                                        );
                                      },
                                    ),
                                    FutureBuilder<int>(
                                      future: fetchNotificationCount(
                                        lead['username'] ?? '',
                                      ),
                                      builder: (context, snapshot) {
                                        final count = snapshot.data ?? 0;
                                        return Stack(
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.notifications,
                                                color: Colors.red,
                                              ),
                                              tooltip: 'Alert',
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      SalesAlertsDialog(
                                                        lead: lead,
                                                      ),
                                                );
                                              },
                                            ),
                                            if (count > 0)
                                              Positioned(
                                                right: 8,
                                                top: 8,
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  constraints:
                                                      const BoxConstraints(
                                                        minWidth: 16,
                                                        minHeight: 16,
                                                      ),
                                                  child: Text(
                                                    count.toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              } else {
                // List for portrait mobile/tablet
                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: leads.length,
                  itemBuilder: (context, index) {
                    final lead = leads[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () => _fetchLeadDetails(lead['id']),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    lead['client_name'] ?? '-',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.update,
                                          color: Color(0xFF1976D2),
                                        ),
                                        tooltip: 'Update',
                                        onPressed: () => _showSnack(
                                          context,
                                          'Update ${lead['client_name']}',
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.timeline,
                                          color: Color(0xFF1976D2),
                                        ),
                                        tooltip: 'Timeline',
                                        onPressed: () {
                                          setState(() {
                                            _showTimelineOnly = true;
                                            _isViewOnly = true;
                                          });
                                          _fetchLeadDetails(lead['id']);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
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
                              Align(
                                alignment: Alignment.bottomLeft,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.remove_red_eye,
                                        color: Color(0xFF1976D2),
                                      ),
                                      tooltip: 'View',
                                      onPressed: () {
                                        setState(() {
                                          _isViewOnly = true;
                                        });
                                        _fetchLeadDetails(lead['id']);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Color(0xFF1976D2),
                                      ),
                                      tooltip: 'Edit',
                                      onPressed: () {
                                        setState(() {
                                          _isViewOnly = false;
                                          _isEditMode = true;
                                        });
                                        _fetchLeadDetails(lead['id']);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Color(0xFF1976D2),
                                      ),
                                      tooltip: 'Delete',
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('Delete Lead'),
                                            content: Text(
                                              'Are you sure you want to delete this lead?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          final client =
                                              Supabase.instance.client;
                                          await client
                                              .from('leads')
                                              .delete()
                                              .eq('id', lead['id']);
                                          _fetchLeads();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Lead deleted'),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.chat,
                                        color: Colors.orange,
                                      ),
                                      tooltip: 'Query',
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) =>
                                              SalesQueryDialog(lead: lead),
                                        );
                                      },
                                    ),
                                    FutureBuilder<int>(
                                      future: fetchNotificationCount(
                                        lead['username'] ?? '',
                                      ),
                                      builder: (context, snapshot) {
                                        final count = snapshot.data ?? 0;
                                        return Stack(
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.notifications,
                                                color: Colors.red,
                                              ),
                                              tooltip: 'Alert',
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      SalesAlertsDialog(
                                                        lead: lead,
                                                      ),
                                                );
                                              },
                                            ),
                                            if (count > 0)
                                              Positioned(
                                                right: 8,
                                                top: 8,
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  constraints:
                                                      const BoxConstraints(
                                                        minWidth: 16,
                                                        minHeight: 16,
                                                      ),
                                                  child: Text(
                                                    count.toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _editTextField(
    String label,
    String key, {
    bool email = false,
    int? minLines,
    int? maxLines,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: _editControllers[key],
        decoration: InputDecoration(labelText: label),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Required';
          if (email &&
              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(v.trim())) {
            return 'Invalid email';
          }
          return null;
        },
        minLines: minLines,
        maxLines: maxLines,
      ),
    );
  }

  void _startEdit() {
    if (_selectedLead == null) return;
    setState(() {
      _isEditMode = true;
      _editControllers = {
        'client_name': TextEditingController(
          text: _selectedLead!['client_name'] ?? '',
        ),
        'project_name': TextEditingController(
          text: _selectedLead!['project_name'] ?? '',
        ),
        'project_location': TextEditingController(
          text: _selectedLead!['project_location'] ?? '',
        ),
        'lead_type': TextEditingController(
          text: _selectedLead!['lead_type'] ?? '',
        ),
        'main_contact_name': TextEditingController(
          text: _selectedLead!['main_contact_name'] ?? '',
        ),
        'main_contact_designation': TextEditingController(
          text: _selectedLead!['main_contact_designation'] ?? '',
        ),
        'main_contact_email': TextEditingController(
          text: _selectedLead!['main_contact_email'] ?? '',
        ),
        'main_contact_mobile': TextEditingController(
          text: _selectedLead!['main_contact_mobile'] ?? '',
        ),
        'remark': TextEditingController(text: _selectedLead!['remark'] ?? ''),
      };
    });
  }

  // Helper to initialize controllers from _initialQuote
  void _initEditableQuoteRows() {
    _editableQuoteRows = _initialQuote.map((row) {
      return {
        'item_name': TextEditingController(
          text: row['item_name']?.toString() ?? '',
        ),
        'unit_weight': TextEditingController(
          text: row['unit_weight']?.toString() ?? '',
        ),
        'quantity': TextEditingController(
          text: row['quantity']?.toString() ?? '',
        ),
        'ex_factory_price': TextEditingController(
          text: row['ex_factory_price']?.toString() ?? '',
        ),
        'unit_price': TextEditingController(
          text: row['unit_price']?.toString() ?? '',
        ),
        'profit_percent': TextEditingController(
          text: row['profit_percent']?.toString() ?? '',
        ),
        'total': TextEditingController(text: row['total']?.toString() ?? ''),
        'one_kg_price': TextEditingController(
          text: row['one_kg_price']?.toString() ?? '',
        ),
      };
    }).toList();
  }

  // Add row
  void _addQuoteRow() {
    setState(() {
      _editableQuoteRows.add({
        'item_name': TextEditingController(),
        'unit_weight': TextEditingController(),
        'quantity': TextEditingController(),
        'ex_factory_price': TextEditingController(),
        'unit_price': TextEditingController(),
        'profit_percent': TextEditingController(),
        'total': TextEditingController(),
        'one_kg_price': TextEditingController(),
      });
    });
  }

  // Remove row
  void _removeQuoteRow() {
    setState(() {
      if (_editableQuoteRows.isNotEmpty) _editableQuoteRows.removeLast();
    });
  }

  // Save edits
  Future<void> _saveInitialQuoteEdits() async {
    final client = Supabase.instance.client;
    for (int i = 0; i < _editableQuoteRows.length; i++) {
      final row = _editableQuoteRows[i];
      final id = _initialQuote.length > i ? _initialQuote[i]['id'] : null;
      final data = {
        'item_name': row['item_name']!.text.trim(),
        'unit_weight': double.tryParse(row['unit_weight']!.text) ?? 0,
        'quantity': double.tryParse(row['quantity']!.text) ?? 0,
        'ex_factory_price': double.tryParse(row['ex_factory_price']!.text) ?? 0,
        'unit_price': double.tryParse(row['unit_price']!.text) ?? 0,
        'profit_percent': double.tryParse(row['profit_percent']!.text) ?? 0,
        'total': double.tryParse(row['total']!.text) ?? 0,
        'one_kg_price': double.tryParse(row['one_kg_price']!.text) ?? 0,
      };
      if (id != null) {
        await client.from('initial_quote').update(data).eq('id', id);
      } else {
        await client.from('initial_quote').insert({
          ...data,
          'lead_id': _selectedLead!['id'],
        });
      }
    }
    await _fetchLeadDetails(_selectedLead!['id']);
    setState(() {
      _isInitialQuoteEditMode = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Initial quote updated')));
  }
}

class _AddLeadForm extends StatefulWidget {
  final String leadType;
  final void Function(Map<String, String>) onAdd;
  final String userType;
  final String userEmail;
  final String userId;
  const _AddLeadForm({
    required this.leadType,
    required this.onAdd,
    required this.userType,
    required this.userEmail,
    required this.userId,
  });
  @override
  State<_AddLeadForm> createState() => _AddLeadFormState();
}

class _AddLeadFormState extends State<_AddLeadForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController clientNameController = TextEditingController();
  final TextEditingController projectNameController = TextEditingController();
  final TextEditingController projectLocationController =
      TextEditingController();
  final TextEditingController remarkController = TextEditingController();

  List<Map<String, TextEditingController>> contacts = [];
  List<Map<String, TextEditingController>> attachments = [];

  // Initial Quote datagrid state
  List<List<TextEditingController>> quoteTable = [];
  int quoteRows = 3;
  int quoteCols = 3;

  final List<String> quoteHeaders = [
    'Item name (Detail)',
    'Unit Weight (kg)',
    'Quantity',
    'Ex-Factory Price',
    'Unit Price',
    'Profit (%)',
    'Total',
    'Per/Kg Price',
  ];

  @override
  void initState() {
    super.initState();
    _addContact();
    _addAttachment();
    _initQuoteTable();
  }

  void _addContact() {
    contacts.add({
      'name': TextEditingController(),
      'designation': TextEditingController(),
      'email': TextEditingController(),
      'mobile': TextEditingController(),
    });
    setState(() {});
  }

  void _removeContact(int i) {
    if (contacts.length > 1) {
      contacts.removeAt(i);
      setState(() {});
    }
  }

  void _addAttachment() {
    attachments.add({
      'fileName': TextEditingController(),
      'fileLink': TextEditingController(),
    });
    setState(() {});
  }

  void _removeAttachment(int i) {
    if (attachments.length > 1) {
      attachments.removeAt(i);
      setState(() {});
    }
  }

  void _initQuoteTable() {
    quoteCols = 8;
    quoteTable = List.generate(
      quoteRows,
      (_) => List.generate(quoteCols, (_) => TextEditingController()),
    );
  }

  void _addQuoteRow() {
    setState(() {
      quoteTable.add(List.generate(quoteCols, (_) => TextEditingController()));
      quoteRows++;
    });
  }

  void _removeQuoteRow() {
    if (quoteRows > 1) {
      setState(() {
        quoteTable.removeLast();
        quoteRows--;
      });
    }
  }

  Widget _buildInitialQuoteSection() {
    // Calculate sums for summary row
    double sumQuantity = 0;
    double sumTotal = 0;
    double sumProfit = 0;
    double sumUnitWeight = 0;
    for (final row in quoteTable) {
      sumQuantity += double.tryParse(row[2].text) ?? 0;
      sumTotal += double.tryParse(row[6].text) ?? 0;
      sumProfit += double.tryParse(row[5].text) ?? 0;
      sumUnitWeight += double.tryParse(row[1].text) ?? 0;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Initial Quote', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                Container(
                  constraints: BoxConstraints(minWidth: 700),
                  child: Table(
                    border: TableBorder.all(color: Colors.grey),
                    defaultColumnWidth: IntrinsicColumnWidth(),
                    children: [
                      TableRow(
                        children: List.generate(quoteCols, (colIdx) {
                          return Container(
                            color: Colors.grey[200],
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                            child: Text(
                              quoteHeaders[colIdx],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        }),
                      ),
                      ...List.generate(quoteRows, (rowIdx) {
                        return TableRow(
                          children: List.generate(quoteCols, (colIdx) {
                            return Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: TextFormField(
                                controller: quoteTable[rowIdx][colIdx],
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 8,
                                  ),
                                ),
                                keyboardType: (colIdx == 0)
                                    ? TextInputType.text
                                    : TextInputType.number,
                                readOnly:
                                    colIdx == 4 ||
                                    colIdx == 6 ||
                                    colIdx ==
                                        7, // Unit Price, Total, 1Kg Price are calculated
                                onChanged: (val) {
                                  final unitWeight =
                                      double.tryParse(
                                        quoteTable[rowIdx][1].text,
                                      ) ??
                                      0;
                                  final qty =
                                      double.tryParse(
                                        quoteTable[rowIdx][2].text,
                                      ) ??
                                      0;
                                  final exFactory =
                                      double.tryParse(
                                        quoteTable[rowIdx][3].text,
                                      ) ??
                                      0;
                                  final profit =
                                      double.tryParse(
                                        quoteTable[rowIdx][5].text,
                                      ) ??
                                      0;
                                  // Calculate Unit Price
                                  final unitPrice =
                                      exFactory * (1 + profit / 100);
                                  quoteTable[rowIdx][4].text = unitPrice
                                      .toStringAsFixed(2);
                                  // Calculate Total
                                  final total = unitPrice * qty;
                                  quoteTable[rowIdx][6].text = total
                                      .toStringAsFixed(2);
                                  // Calculate Per/Kg Price
                                  final perKgPrice = unitWeight > 0
                                      ? unitPrice / unitWeight
                                      : 0;
                                  quoteTable[rowIdx][7].text = perKgPrice
                                      .toStringAsFixed(2);
                                  setState(() {}); // Update summary row
                                },
                              ),
                            );
                          }),
                        );
                      }),
                      // Summary row
                      TableRow(
                        children: List.generate(quoteCols, (colIdx) {
                          String value = '';
                          if (colIdx == 0) value = 'Total:';
                          if (colIdx == 1) {
                            value = sumUnitWeight.toStringAsFixed(2);
                          }
                          if (colIdx == 2) {
                            value = sumQuantity.toStringAsFixed(2);
                          }
                          if (colIdx == 5) value = sumProfit.toStringAsFixed(2);
                          if (colIdx == 6) value = sumTotal.toStringAsFixed(2);
                          return Container(
                            color: Colors.grey[100],
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                            child: Text(
                              value,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey[800],
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('Add Row'),
                      onPressed: _addQuoteRow,
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: Icon(Icons.remove),
                      label: Text('Remove Row'),
                      onPressed: _removeQuoteRow,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    final maxWidth = MediaQuery.of(context).size.width * 0.95;
    final isScaffolding = widget.leadType.toLowerCase() == 'scaffolding';
    return Stack(
      children: [
        Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxHeight,
              maxWidth: maxWidth,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: isScaffolding
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 700;
                          if (isWide) {
                            // Two-column layout with button at bottom right
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left side (unchanged)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // ... left side fields ...
                                          Text(
                                            'Add New Lead (${widget.leadType})',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Info',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextFormField(
                                            controller: clientNameController,
                                            decoration: InputDecoration(
                                              labelText: 'Client Name',
                                            ),
                                            validator: (v) =>
                                                v!.isEmpty ? 'Required' : null,
                                          ),
                                          TextFormField(
                                            controller: projectNameController,
                                            decoration: InputDecoration(
                                              labelText: 'Project Name',
                                            ),
                                            validator: (v) =>
                                                v!.isEmpty ? 'Required' : null,
                                          ),
                                          TextFormField(
                                            controller:
                                                projectLocationController,
                                            decoration: InputDecoration(
                                              labelText: 'Project Location',
                                            ),
                                            validator: (v) =>
                                                v!.isEmpty ? 'Required' : null,
                                          ),
                                          TextFormField(
                                            controller: remarkController,
                                            decoration: InputDecoration(
                                              labelText: 'Remark',
                                              alignLabelWithHint: true,
                                            ),
                                            minLines: 2,
                                            maxLines: 4,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'Contact',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          ...List.generate(
                                            contacts.length,
                                            (i) => Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (i == 0)
                                                  Text(
                                                    'Main Contact',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                if (i > 0)
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        'Contact ${i + 1}',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              Colors.grey[700],
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.remove_circle,
                                                          color: Colors.red,
                                                        ),
                                                        onPressed: () =>
                                                            _removeContact(i),
                                                        tooltip:
                                                            'Remove Contact',
                                                      ),
                                                    ],
                                                  ),
                                                TextFormField(
                                                  controller:
                                                      contacts[i]['name'],
                                                  decoration: InputDecoration(
                                                    labelText:
                                                        'Contact Person Name',
                                                  ),
                                                  validator: (v) => v!.isEmpty
                                                      ? 'Required'
                                                      : null,
                                                ),
                                                TextFormField(
                                                  controller:
                                                      contacts[i]['designation'],
                                                  decoration: InputDecoration(
                                                    labelText: 'Designation',
                                                  ),
                                                ),
                                                TextFormField(
                                                  controller:
                                                      contacts[i]['email'],
                                                  decoration: InputDecoration(
                                                    labelText: 'Email',
                                                  ),
                                                ),
                                                TextFormField(
                                                  controller:
                                                      contacts[i]['mobile'],
                                                  decoration: InputDecoration(
                                                    labelText: 'Mobile No.',
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                              ],
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: TextButton.icon(
                                              icon: Icon(Icons.add),
                                              label: Text('Add Contact'),
                                              onPressed: _addContact,
                                            ),
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'Attachment Link',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          ...List.generate(
                                            attachments.length,
                                            (i) => Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (i > 0)
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        'Attachment ${i + 1}',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              Colors.grey[700],
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.remove_circle,
                                                          color: Colors.red,
                                                        ),
                                                        onPressed: () =>
                                                            _removeAttachment(
                                                              i,
                                                            ),
                                                        tooltip:
                                                            'Remove Attachment',
                                                      ),
                                                    ],
                                                  ),
                                                TextFormField(
                                                  controller:
                                                      attachments[i]['fileName'],
                                                  decoration: InputDecoration(
                                                    labelText: 'File Name',
                                                  ),
                                                ),
                                                TextFormField(
                                                  controller:
                                                      attachments[i]['fileLink'],
                                                  decoration: InputDecoration(
                                                    labelText: 'File Link',
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                              ],
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: TextButton.icon(
                                              icon: Icon(Icons.add),
                                              label: Text('Add Attachment'),
                                              onPressed: _addAttachment,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Vertical divider
                                    Container(
                                      width: 1,
                                      height: 600,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                      color: Colors.grey[300],
                                    ),
                                    // Right side: Initial Quote datagrid
                                    Expanded(
                                      child: _buildInitialQuoteSection(),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 32),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      right: 24,
                                      bottom: 16,
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (!_formKey.currentState!
                                            .validate()) {
                                          return;
                                        }
                                        final client = Supabase.instance.client;
                                        try {
                                          // 1. Insert main lead
                                          final leadInsert = await client
                                              .from('leads')
                                              .insert({
                                                'lead_type': widget.leadType,
                                                'client_name':
                                                    clientNameController.text
                                                        .trim(),
                                                'project_name':
                                                    projectNameController.text
                                                        .trim(),
                                                'project_location':
                                                    projectLocationController
                                                        .text
                                                        .trim(),
                                                'remark': remarkController.text
                                                    .trim(),
                                                'main_contact_name':
                                                    contacts[0]['name']!.text
                                                        .trim(),
                                                'main_contact_designation':
                                                    contacts[0]['designation']!
                                                        .text
                                                        .trim(),
                                                'main_contact_email':
                                                    contacts[0]['email']!.text
                                                        .trim(),
                                                'main_contact_mobile':
                                                    contacts[0]['mobile']!.text
                                                        .trim(),
                                                'user_type': widget.userType,
                                                'user_email': widget.userEmail,
                                                'lead_generated_by':
                                                    widget.userId,
                                              })
                                              .select()
                                              .single();
                                          final leadId = leadInsert['id'];
                                          final userId = widget.userId;
                                          // 2. Insert additional contacts
                                          for (
                                            int i = 1;
                                            i < contacts.length;
                                            i++
                                          ) {
                                            await client
                                                .from('lead_contacts')
                                                .insert({
                                                  'lead_id': leadId,
                                                  'contact_name':
                                                      contacts[i]['name']!.text
                                                          .trim(),
                                                  'designation':
                                                      contacts[i]['designation']!
                                                          .text
                                                          .trim(),
                                                  'email': contacts[i]['email']!
                                                      .text
                                                      .trim(),
                                                  'mobile':
                                                      contacts[i]['mobile']!
                                                          .text
                                                          .trim(),
                                                });
                                          }
                                          // 3. Insert attachments
                                          for (final att in attachments) {
                                            if (att['fileName']!.text
                                                    .trim()
                                                    .isNotEmpty ||
                                                att['fileLink']!.text
                                                    .trim()
                                                    .isNotEmpty) {
                                              await client
                                                  .from('lead_attachments')
                                                  .insert({
                                                    'lead_id': leadId,
                                                    'file_name':
                                                        att['fileName']!.text
                                                            .trim(),
                                                    'file_link':
                                                        att['fileLink']!.text
                                                            .trim(),
                                                  });
                                            }
                                          }
                                          // 4. Insert lead activity
                                          final now = DateTime.now();
                                          final activityDate = DateFormat(
                                            'yyyy-MM-dd',
                                          ).format(now);
                                          final activityTime = DateFormat(
                                            'HH:mm:ss',
                                          ).format(now);

                                          // Get user name from users table
                                          final userData = await client
                                              .from('users')
                                              .select('username')
                                              .eq('id', userId)
                                              .single();
                                          final userName =
                                              userData['username'] ??
                                              'Unknown User';

                                          await client
                                              .from('lead_activity')
                                              .insert({
                                                'lead_id': leadId,
                                                'user_id': userId,
                                                'user_name': userName,
                                                'activity': 'lead_created',
                                                'changes_made': jsonEncode({
                                                  'lead_type': widget.leadType,
                                                  'client_name':
                                                      clientNameController.text
                                                          .trim(),
                                                  'project_name':
                                                      projectNameController.text
                                                          .trim(),
                                                  'project_location':
                                                      projectLocationController
                                                          .text
                                                          .trim(),
                                                  'remark': remarkController
                                                      .text
                                                      .trim(),
                                                  'main_contact_name':
                                                      contacts[0]['name']!.text
                                                          .trim(),
                                                  'main_contact_designation':
                                                      contacts[0]['designation']!
                                                          .text
                                                          .trim(),
                                                  'main_contact_email':
                                                      contacts[0]['email']!.text
                                                          .trim(),
                                                  'main_contact_mobile':
                                                      contacts[0]['mobile']!
                                                          .text
                                                          .trim(),
                                                  'user_type': widget.userType,
                                                  'user_email':
                                                      widget.userEmail,
                                                  'lead_generated_by':
                                                      widget.userId,
                                                }),
                                                'created_at': now
                                                    .toIso8601String(),
                                                'activity_date': activityDate,
                                                'activity_time': activityTime,
                                              });
                                          // 5. Insert initial quote rows
                                          for (final row in quoteTable) {
                                            final itemName = row[0].text.trim();
                                            if (itemName.isEmpty) continue;
                                            final unitWeight =
                                                double.tryParse(row[1].text) ??
                                                0;
                                            final qty =
                                                double.tryParse(row[2].text) ??
                                                0;
                                            final exFactory =
                                                double.tryParse(row[3].text) ??
                                                0;
                                            final unitPrice =
                                                double.tryParse(row[4].text) ??
                                                (exFactory *
                                                    (1 +
                                                        (double.tryParse(
                                                                  row[5].text,
                                                                ) ??
                                                                0) /
                                                            100));
                                            final profit =
                                                double.tryParse(row[5].text) ??
                                                0;
                                            final perKgPrice = unitWeight > 0
                                                ? unitPrice / unitWeight
                                                : 0;
                                            await client
                                                .from('initial_quote')
                                                .insert({
                                                  'lead_id': leadId,
                                                  'user_id': userId,
                                                  'item_name': itemName,
                                                  'unit_weight': unitWeight,
                                                  'quantity': qty,
                                                  'ex_factory_price': exFactory,
                                                  'unit_price': unitPrice,
                                                  'profit_percent': profit,
                                                  'one_kg_price': perKgPrice,
                                                });
                                          }
                                          // Show success and close dialog
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Lead created successfully!',
                                                ),
                                              ),
                                            );
                                            Navigator.of(context).pop();
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Failed to create lead: ${e.toString()}',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 16,
                                        ),
                                        textStyle: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      child: Text('Submit'),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            // Mobile: stack layout
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ... left side fields ...
                                Text(
                                  'Add New Lead (${widget.leadType})',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Info',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextFormField(
                                  controller: clientNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Client Name',
                                  ),
                                  validator: (v) =>
                                      v!.isEmpty ? 'Required' : null,
                                ),
                                TextFormField(
                                  controller: projectNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Project Name',
                                  ),
                                  validator: (v) =>
                                      v!.isEmpty ? 'Required' : null,
                                ),
                                TextFormField(
                                  controller: projectLocationController,
                                  decoration: InputDecoration(
                                    labelText: 'Project Location',
                                  ),
                                  validator: (v) =>
                                      v!.isEmpty ? 'Required' : null,
                                ),
                                TextFormField(
                                  controller: remarkController,
                                  decoration: InputDecoration(
                                    labelText: 'Remark',
                                    alignLabelWithHint: true,
                                  ),
                                  minLines: 2,
                                  maxLines: 4,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Contact',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ...List.generate(
                                  contacts.length,
                                  (i) => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (i == 0)
                                        Text(
                                          'Main Contact',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      if (i > 0)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Contact ${i + 1}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.remove_circle,
                                                color: Colors.red,
                                              ),
                                              onPressed: () =>
                                                  _removeContact(i),
                                              tooltip: 'Remove Contact',
                                            ),
                                          ],
                                        ),
                                      TextFormField(
                                        controller: contacts[i]['name'],
                                        decoration: InputDecoration(
                                          labelText: 'Contact Person Name',
                                        ),
                                        validator: (v) =>
                                            v!.isEmpty ? 'Required' : null,
                                      ),
                                      TextFormField(
                                        controller: contacts[i]['designation'],
                                        decoration: InputDecoration(
                                          labelText: 'Designation',
                                        ),
                                      ),
                                      TextFormField(
                                        controller: contacts[i]['email'],
                                        decoration: InputDecoration(
                                          labelText: 'Email',
                                        ),
                                      ),
                                      TextFormField(
                                        controller: contacts[i]['mobile'],
                                        decoration: InputDecoration(
                                          labelText: 'Mobile No.',
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    icon: Icon(Icons.add),
                                    label: Text('Add Contact'),
                                    onPressed: _addContact,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Attachment Link',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ...List.generate(
                                  attachments.length,
                                  (i) => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (i > 0)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Attachment ${i + 1}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.remove_circle,
                                                color: Colors.red,
                                              ),
                                              onPressed: () =>
                                                  _removeAttachment(i),
                                              tooltip: 'Remove Attachment',
                                            ),
                                          ],
                                        ),
                                      TextFormField(
                                        controller: attachments[i]['fileName'],
                                        decoration: InputDecoration(
                                          labelText: 'File Name',
                                        ),
                                      ),
                                      TextFormField(
                                        controller: attachments[i]['fileLink'],
                                        decoration: InputDecoration(
                                          labelText: 'File Link',
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    icon: Icon(Icons.add),
                                    label: Text('Add Attachment'),
                                    onPressed: _addAttachment,
                                  ),
                                ),
                                SizedBox(height: 24),
                                // Initial Quote section in stack
                                _buildInitialQuoteSection(),
                                SizedBox(height: 32),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      right: 24,
                                      bottom: 16,
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (!_formKey.currentState!
                                            .validate()) {
                                          return;
                                        }
                                        final client = Supabase.instance.client;
                                        try {
                                          // 1. Insert main lead
                                          final leadInsert = await client
                                              .from('leads')
                                              .insert({
                                                'lead_type': widget.leadType,
                                                'client_name':
                                                    clientNameController.text
                                                        .trim(),
                                                'project_name':
                                                    projectNameController.text
                                                        .trim(),
                                                'project_location':
                                                    projectLocationController
                                                        .text
                                                        .trim(),
                                                'remark': remarkController.text
                                                    .trim(),
                                                'main_contact_name':
                                                    contacts[0]['name']!.text
                                                        .trim(),
                                                'main_contact_designation':
                                                    contacts[0]['designation']!
                                                        .text
                                                        .trim(),
                                                'main_contact_email':
                                                    contacts[0]['email']!.text
                                                        .trim(),
                                                'main_contact_mobile':
                                                    contacts[0]['mobile']!.text
                                                        .trim(),
                                                'user_type': widget.userType,
                                                'user_email': widget.userEmail,
                                                'lead_generated_by':
                                                    widget.userId,
                                              })
                                              .select()
                                              .single();
                                          final leadId = leadInsert['id'];
                                          final userId = widget.userId;
                                          // 2. Insert additional contacts
                                          for (
                                            int i = 1;
                                            i < contacts.length;
                                            i++
                                          ) {
                                            await client
                                                .from('lead_contacts')
                                                .insert({
                                                  'lead_id': leadId,
                                                  'contact_name':
                                                      contacts[i]['name']!.text
                                                          .trim(),
                                                  'designation':
                                                      contacts[i]['designation']!
                                                          .text
                                                          .trim(),
                                                  'email': contacts[i]['email']!
                                                      .text
                                                      .trim(),
                                                  'mobile':
                                                      contacts[i]['mobile']!
                                                          .text
                                                          .trim(),
                                                });
                                          }
                                          // 3. Insert attachments
                                          for (final att in attachments) {
                                            if (att['fileName']!.text
                                                    .trim()
                                                    .isNotEmpty ||
                                                att['fileLink']!.text
                                                    .trim()
                                                    .isNotEmpty) {
                                              await client
                                                  .from('lead_attachments')
                                                  .insert({
                                                    'lead_id': leadId,
                                                    'file_name':
                                                        att['fileName']!.text
                                                            .trim(),
                                                    'file_link':
                                                        att['fileLink']!.text
                                                            .trim(),
                                                  });
                                            }
                                          }
                                          // 4. Insert lead activity
                                          final now = DateTime.now();
                                          final activityDate = DateFormat(
                                            'yyyy-MM-dd',
                                          ).format(now);
                                          final activityTime = DateFormat(
                                            'HH:mm:ss',
                                          ).format(now);

                                          // Get user name from users table
                                          final userData = await client
                                              .from('users')
                                              .select('username')
                                              .eq('id', userId)
                                              .single();
                                          final userName =
                                              userData['username'] ??
                                              'Unknown User';

                                          await client
                                              .from('lead_activity')
                                              .insert({
                                                'lead_id': leadId,
                                                'user_id': userId,
                                                'user_name': userName,
                                                'activity': 'lead_created',
                                                'changes_made': jsonEncode({
                                                  'lead_type': widget.leadType,
                                                  'client_name':
                                                      clientNameController.text
                                                          .trim(),
                                                  'project_name':
                                                      projectNameController.text
                                                          .trim(),
                                                  'project_location':
                                                      projectLocationController
                                                          .text
                                                          .trim(),
                                                  'remark': remarkController
                                                      .text
                                                      .trim(),
                                                  'main_contact_name':
                                                      contacts[0]['name']!.text
                                                          .trim(),
                                                  'main_contact_designation':
                                                      contacts[0]['designation']!
                                                          .text
                                                          .trim(),
                                                  'main_contact_email':
                                                      contacts[0]['email']!.text
                                                          .trim(),
                                                  'main_contact_mobile':
                                                      contacts[0]['mobile']!
                                                          .text
                                                          .trim(),
                                                  'user_type': widget.userType,
                                                  'user_email':
                                                      widget.userEmail,
                                                  'lead_generated_by':
                                                      widget.userId,
                                                }),
                                                'created_at': now
                                                    .toIso8601String(),
                                                'activity_date': activityDate,
                                                'activity_time': activityTime,
                                              });
                                          // 5. Insert initial quote rows
                                          for (final row in quoteTable) {
                                            final itemName = row[0].text.trim();
                                            if (itemName.isEmpty) continue;
                                            final unitWeight =
                                                double.tryParse(row[1].text) ??
                                                0;
                                            final qty =
                                                double.tryParse(row[2].text) ??
                                                0;
                                            final exFactory =
                                                double.tryParse(row[3].text) ??
                                                0;
                                            final unitPrice =
                                                double.tryParse(row[4].text) ??
                                                (exFactory *
                                                    (1 +
                                                        (double.tryParse(
                                                                  row[5].text,
                                                                ) ??
                                                                0) /
                                                            100));
                                            final profit =
                                                double.tryParse(row[5].text) ??
                                                0;
                                            final perKgPrice = unitWeight > 0
                                                ? unitPrice / unitWeight
                                                : 0;
                                            await client
                                                .from('initial_quote')
                                                .insert({
                                                  'lead_id': leadId,
                                                  'user_id': userId,
                                                  'item_name': itemName,
                                                  'unit_weight': unitWeight,
                                                  'quantity': qty,
                                                  'ex_factory_price': exFactory,
                                                  'unit_price': unitPrice,
                                                  'profit_percent': profit,
                                                  'one_kg_price': perKgPrice,
                                                });
                                          }
                                          // Show success and close dialog
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Lead created successfully!',
                                                ),
                                              ),
                                            );
                                            Navigator.of(context).pop();
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Failed to create lead: ${e.toString()}',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 16,
                                        ),
                                        textStyle: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      child: Text('Submit'),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ... single-column fields ...
                          Text(
                            'Add New Lead (${widget.leadType})',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Info',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextFormField(
                            controller: clientNameController,
                            decoration: InputDecoration(
                              labelText: 'Client Name',
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          TextFormField(
                            controller: projectNameController,
                            decoration: InputDecoration(
                              labelText: 'Project Name',
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          TextFormField(
                            controller: projectLocationController,
                            decoration: InputDecoration(
                              labelText: 'Project Location',
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          TextFormField(
                            controller: remarkController,
                            decoration: InputDecoration(
                              labelText: 'Remark',
                              alignLabelWithHint: true,
                            ),
                            minLines: 2,
                            maxLines: 4,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Contact',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...List.generate(
                            contacts.length,
                            (i) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (i == 0)
                                  Text(
                                    'Main Contact',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                if (i > 0)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Contact ${i + 1}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.remove_circle,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _removeContact(i),
                                        tooltip: 'Remove Contact',
                                      ),
                                    ],
                                  ),
                                TextFormField(
                                  controller: contacts[i]['name'],
                                  decoration: InputDecoration(
                                    labelText: 'Contact Person Name',
                                  ),
                                  validator: (v) =>
                                      v!.isEmpty ? 'Required' : null,
                                ),
                                TextFormField(
                                  controller: contacts[i]['designation'],
                                  decoration: InputDecoration(
                                    labelText: 'Designation',
                                  ),
                                ),
                                TextFormField(
                                  controller: contacts[i]['email'],
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                  ),
                                ),
                                TextFormField(
                                  controller: contacts[i]['mobile'],
                                  decoration: InputDecoration(
                                    labelText: 'Mobile No.',
                                  ),
                                ),
                                SizedBox(height: 8),
                              ],
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              icon: Icon(Icons.add),
                              label: Text('Add Contact'),
                              onPressed: _addContact,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Attachment Link',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...List.generate(
                            attachments.length,
                            (i) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (i > 0)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Attachment ${i + 1}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.remove_circle,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _removeAttachment(i),
                                        tooltip: 'Remove Attachment',
                                      ),
                                    ],
                                  ),
                                TextFormField(
                                  controller: attachments[i]['fileName'],
                                  decoration: InputDecoration(
                                    labelText: 'File Name',
                                  ),
                                ),
                                TextFormField(
                                  controller: attachments[i]['fileLink'],
                                  decoration: InputDecoration(
                                    labelText: 'File Link',
                                  ),
                                ),
                                SizedBox(height: 8),
                              ],
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              icon: Icon(Icons.add),
                              label: Text('Add Attachment'),
                              onPressed: _addAttachment,
                            ),
                          ),
                          SizedBox(height: 32),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: 24,
                                bottom: 16,
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }
                                  final client = Supabase.instance.client;
                                  try {
                                    // 1. Insert main lead
                                    final leadInsert = await client
                                        .from('leads')
                                        .insert({
                                          'lead_type': widget.leadType,
                                          'client_name': clientNameController
                                              .text
                                              .trim(),
                                          'project_name': projectNameController
                                              .text
                                              .trim(),
                                          'project_location':
                                              projectLocationController.text
                                                  .trim(),
                                          'remark': remarkController.text
                                              .trim(),
                                          'main_contact_name':
                                              contacts[0]['name']!.text.trim(),
                                          'main_contact_designation':
                                              contacts[0]['designation']!.text
                                                  .trim(),
                                          'main_contact_email':
                                              contacts[0]['email']!.text.trim(),
                                          'main_contact_mobile':
                                              contacts[0]['mobile']!.text
                                                  .trim(),
                                          'user_type': widget.userType,
                                          'user_email': widget.userEmail,
                                          'lead_generated_by': widget.userId,
                                        })
                                        .select()
                                        .single();
                                    final leadId = leadInsert['id'];
                                    final userId = widget.userId;
                                    // 2. Insert additional contacts
                                    for (int i = 1; i < contacts.length; i++) {
                                      await client
                                          .from('lead_contacts')
                                          .insert({
                                            'lead_id': leadId,
                                            'contact_name': contacts[i]['name']!
                                                .text
                                                .trim(),
                                            'designation':
                                                contacts[i]['designation']!.text
                                                    .trim(),
                                            'email': contacts[i]['email']!.text
                                                .trim(),
                                            'mobile': contacts[i]['mobile']!
                                                .text
                                                .trim(),
                                          });
                                    }
                                    // 3. Insert attachments
                                    for (final att in attachments) {
                                      if (att['fileName']!.text
                                              .trim()
                                              .isNotEmpty ||
                                          att['fileLink']!.text
                                              .trim()
                                              .isNotEmpty) {
                                        await client
                                            .from('lead_attachments')
                                            .insert({
                                              'lead_id': leadId,
                                              'file_name': att['fileName']!.text
                                                  .trim(),
                                              'file_link': att['fileLink']!.text
                                                  .trim(),
                                            });
                                      }
                                    }
                                    // 4. Insert lead activity
                                    final now = DateTime.now();
                                    final activityDate = DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(now);
                                    final activityTime = DateFormat(
                                      'HH:mm:ss',
                                    ).format(now);

                                    // Get user name from users table
                                    final userData = await client
                                        .from('users')
                                        .select('username')
                                        .eq('id', userId)
                                        .single();
                                    final userName =
                                        userData['username'] ?? 'Unknown User';

                                    await client.from('lead_activity').insert({
                                      'lead_id': leadId,
                                      'user_id': userId,
                                      'user_name': userName,
                                      'activity': 'lead_created',
                                      'changes_made': jsonEncode({
                                        'lead_type': widget.leadType,
                                        'client_name': clientNameController.text
                                            .trim(),
                                        'project_name': projectNameController
                                            .text
                                            .trim(),
                                        'project_location':
                                            projectLocationController.text
                                                .trim(),
                                        'remark': remarkController.text.trim(),
                                        'main_contact_name':
                                            contacts[0]['name']!.text.trim(),
                                        'main_contact_designation':
                                            contacts[0]['designation']!.text
                                                .trim(),
                                        'main_contact_email':
                                            contacts[0]['email']!.text.trim(),
                                        'main_contact_mobile':
                                            contacts[0]['mobile']!.text.trim(),
                                        'user_type': widget.userType,
                                        'user_email': widget.userEmail,
                                        'lead_generated_by': widget.userId,
                                      }),
                                      'created_at': now.toIso8601String(),
                                      'activity_date': activityDate,
                                      'activity_time': activityTime,
                                    });
                                    // Show success and close dialog
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Lead created successfully!',
                                          ),
                                        ),
                                      );
                                      Navigator.of(context).pop();
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to create lead: ${e.toString()}',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: Text('Submit'),
                              ),
                            ),
                          ),
                        ],
                      ),
              ), // End of Form
            ), // End of SingleChildScrollView
          ), // End of ConstrainedBox
        ), // End of Dialog
      ], // End of Stack children
    ); // End of Stack
  } // End of build
} // End of _AddLeadForm

Widget _detailRow(String label, dynamic value, {bool isLink = false}) {
  return Builder(
    builder: (context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '  $label:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: isLink && value != null && value.toString().isNotEmpty
                ? Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: GestureDetector(
                            onTap: () async {
                              final url = value.toString();
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
                              value.toString(),
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.copy, size: 16),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: value.toString()),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Link copied to clipboard')),
                          );
                        },
                        tooltip: 'Copy link',
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Text(
                          value == null || value.toString().isEmpty
                              ? '-'
                              : value.toString(),
                        ),
                      ),
                      if (label == 'File Name' &&
                          value != null &&
                          value.toString().isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.copy, size: 16),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: value.toString()),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('File name copied to clipboard'),
                              ),
                            );
                          },
                          tooltip: 'Copy file name',
                        ),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
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
