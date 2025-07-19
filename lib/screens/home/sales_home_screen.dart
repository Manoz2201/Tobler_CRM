// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; // Added for jsonEncode

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

  final List<_NavItem> _navItems = const [
    _NavItem('Dashboard', Icons.dashboard),
    _NavItem('Leads', Icons.people_outline),
    _NavItem('Opportunities', Icons.trending_up),
    _NavItem('Reports', Icons.bar_chart),
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
    Center(child: Text('Profile')),
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
  bool _isActivityLoading = false;
  bool _isInitialQuoteLoading = false;
  String? _activityError;
  String? _initialQuoteError;
  bool _isEditMode = false;
  final _editFormKey = GlobalKey<FormState>();
  Map<String, TextEditingController> _editControllers = {};

  // Controllers for editing initial quote
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _unitWeightController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _exFactoryController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _profitPercentController =
      TextEditingController();
  final TextEditingController _totalController = TextEditingController();

  Map<String, dynamic>? _editingQuote;

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

  String _calculatePerKg(
    dynamic unitPrice,
    dynamic unitWeight,
    dynamic quantity,
  ) {
    try {
      final price = double.tryParse(unitPrice?.toString() ?? '0') ?? 0;
      final weight = double.tryParse(unitWeight?.toString() ?? '0') ?? 0;
      final qty = double.tryParse(quantity?.toString() ?? '0') ?? 0;

      if (weight <= 0 || qty <= 0) return '0.00';

      final unitKg = weight / qty;
      if (unitKg <= 0) return '0.00';

      final perKg = price / unitKg;
      return perKg.toStringAsFixed(2);
    } catch (e) {
      return '0.00';
    }
  }

  Future<void> _fetchLeadDetails(String leadId) async {
    setState(() {
      _contacts = [];
      _attachments = [];
      _activityTimeline = [];
      _initialQuote = [];
      _isActivityLoading = true;
      _isInitialQuoteLoading = true;
      _activityError = null;
      _initialQuoteError = null;
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
      setState(() {
        _selectedLead = lead;
        _contacts = List<Map<String, dynamic>>.from(contacts);
        _attachments = List<Map<String, dynamic>>.from(attachments);
        _activityTimeline = List<Map<String, dynamic>>.from(activities);
        _initialQuote = List<Map<String, dynamic>>.from(initialQuote);
        _isActivityLoading = false;
        _isInitialQuoteLoading = false;
      });
    } catch (e) {
      setState(() {
        _isActivityLoading = false;
        _isInitialQuoteLoading = false;
        _activityError = 'Failed to fetch activity: ${e.toString()}';
        _initialQuoteError = 'Failed to fetch initial quote: ${e.toString()}';
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
    });
    _fetchLeads();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedLead != null) {
      final lead = _selectedLead!;
      // Allow editing if the current user is the creator of the lead,
      // or if the user is an Admin or Developer.
      final bool canEdit =
          (lead['user_type'] == widget.currentUserType &&
              lead['user_email'] == widget.currentUserEmail) ||
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
                              if (canEdit)
                                OutlinedButton(
                                  onPressed: _startEdit,
                                  child: Text('Edit'),
                                ),
                              if (canEdit) SizedBox(width: 8),
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
      final contactsSection = _contacts.isNotEmpty
          ? Card(
              margin: EdgeInsets.zero,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                width: double.infinity,
                height: 350, // Fixed height for consistent grid
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Other Contacts',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Divider(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _contacts
                              .map(
                                (c) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _detailRow('Name', c['contact_name']),
                                      _detailRow(
                                        'Designation',
                                        c['designation'],
                                      ),
                                      _detailRow('Email', c['email']),
                                      _detailRow('Mobile', c['mobile']),
                                      Divider(),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SizedBox.shrink();
      final initialQuoteSection = _initialQuote.isNotEmpty
          ? Card(
              margin: EdgeInsets.zero,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardPadding = 40.0; // 20 left + 20 right
                  final columnCount = 8;
                  final availableWidth = constraints.maxWidth - cardPadding;
                  final columnWidth = availableWidth / columnCount;
                  final isMobile = constraints.maxWidth < 600;
                  final fontSize = isMobile ? 10.0 : 14.0;
                  final headerFontSize = isMobile ? 11.0 : 14.0;
                  final headers = isMobile
                      ? [
                          'Item',
                          'T. Kg',
                          'Qty',
                          'X Fac.',
                          'U/Rs.',
                          'Gain',
                          'Sum',
                          'P/Kg',
                        ]
                      : [
                          'Item Name',
                          'Weight',
                          'Qty',
                          'Ex-Factory',
                          'Unit Price',
                          'Profit %',
                          'Total',
                          'Per/Kg',
                        ];
                  return Container(
                    width: double.infinity,
                    height: 180,
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Initial Quote',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            // Always show Edit/Update buttons for testing
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () => _showEditInitialQuoteDialog(
                                    _initialQuote.first,
                                  ),
                                  child: Text('Edit'),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    textStyle: TextStyle(fontSize: 14),
                                  ),
                                  onPressed: () =>
                                      _updateInitialQuote(_initialQuote.first),
                                  child: Text('Update'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (_isInitialQuoteLoading)
                          Center(child: CircularProgressIndicator()),
                        if (_initialQuoteError != null)
                          Text(
                            _initialQuoteError!,
                            style: TextStyle(color: Colors.red),
                          ),
                        if (!_isInitialQuoteLoading &&
                            _initialQuoteError == null)
                          DataTable(
                            dataTextStyle: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w400,
                            ),
                            headingTextStyle: TextStyle(
                              fontSize: headerFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                            columnSpacing: 0,
                            horizontalMargin: 0,
                            columns: List.generate(
                              columnCount,
                              (i) => DataColumn(
                                label: SizedBox(
                                  width: columnWidth,
                                  child: Text(
                                    headers[i],
                                    style: TextStyle(fontSize: headerFontSize),
                                  ),
                                ),
                              ),
                            ),
                            rows: _initialQuote.map((quote) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    SizedBox(
                                      width: columnWidth,
                                      child: Text(
                                        quote['item_name']?.toString() ?? '',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: fontSize),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: columnWidth,
                                      child: Text(
                                        quote['unit_weight']?.toString() ?? '',
                                        style: TextStyle(fontSize: fontSize),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: columnWidth,
                                      child: Text(
                                        quote['quantity']?.toString() ?? '',
                                        style: TextStyle(fontSize: fontSize),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: columnWidth,
                                      child: Text(
                                        quote['ex_factory_price']?.toString() ??
                                            '',
                                        style: TextStyle(fontSize: fontSize),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: columnWidth,
                                      child: Text(
                                        quote['unit_price']?.toString() ?? '',
                                        style: TextStyle(fontSize: fontSize),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: columnWidth,
                                      child: Text(
                                        quote['profit_percent']?.toString() ??
                                            '',
                                        style: TextStyle(fontSize: fontSize),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: columnWidth,
                                      child: Text(
                                        quote['total']?.toString() ?? '',
                                        style: TextStyle(fontSize: fontSize),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: columnWidth,
                                      child: Text(
                                        _calculatePerKg(
                                          quote['unit_price'],
                                          quote['unit_weight'],
                                          quote['quantity'],
                                        ),
                                        style: TextStyle(fontSize: fontSize),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  );
                },
              ),
            )
          : SizedBox.shrink();

      final attachmentsSection = _attachments.isNotEmpty
          ? Card(
              margin: EdgeInsets.zero,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    width: double.infinity,
                    height: 350,
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attachments',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Divider(),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _attachments
                                  .map(
                                    (a) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _detailRow(
                                            'File Name',
                                            a['file_name'],
                                          ),
                                          _detailRow(
                                            'File Link',
                                            a['file_link'],
                                            isLink: true,
                                          ),
                                          Divider(),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          : SizedBox.shrink();
      // Activity Timeline card (placeholder for now)
      final activityTimelineSection = Card(
        margin: EdgeInsets.zero,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          width: double.infinity,
          height: 400, // Fixed height for consistent grid
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
                Text(_activityError!, style: TextStyle(color: Colors.red)),
              if (!_isActivityLoading &&
                  _activityError == null &&
                  _activityTimeline.isEmpty)
                Text('No activity yet.'),
              if (!_isActivityLoading &&
                  _activityError == null &&
                  _activityTimeline.isNotEmpty)
                Expanded(
                  child: SingleChildScrollView(
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
                ),
            ],
          ),
        ),
      );
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
                      height: 340,
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: detailsSection,
                    ),
                    // Attachments Card
                    Container(
                      width: double.infinity,
                      height: 140,
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: attachmentsSection,
                    ),
                    // Initial Quote Card
                    Container(
                      width: double.infinity,
                      height: 180,
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: initialQuoteSection,
                    ),
                    // Activity Timeline Card
                    Container(
                      width: double.infinity,
                      height: 180,
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
          child: ListView.builder(
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
                        Text(
                          lead['client_name'] ?? '-',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text('Project: ${lead['project_name'] ?? '-'}'),
                        Text('Location: ${lead['project_location'] ?? '-'}'),
                        Text(
                          'Main Contact: ${lead['main_contact_name'] ?? '-'}',
                        ),
                        SizedBox(height: 12),
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
                                      onTap: () =>
                                          _fetchLeadDetails(lead['id']),
                                    ),
                                    _LeadActionButton(
                                      icon: Icons.edit,
                                      label: 'Edit',
                                      onTap: () => _showSnack(
                                        context,
                                        'Edit ${lead['client_name']}',
                                      ),
                                    ),
                                    _LeadActionButton(
                                      icon: Icons.update,
                                      label: 'Update',
                                      onTap: () => _showSnack(
                                        context,
                                        'Update ${lead['client_name']}',
                                      ),
                                    ),
                                    _LeadActionButton(
                                      icon: Icons.timeline,
                                      label: 'Timeline',
                                      onTap: () => _showSnack(
                                        context,
                                        'Timeline for ${lead['client_name']}',
                                      ),
                                    ),
                                    _LeadActionButton(
                                      icon: Icons.list_alt,
                                      label: 'Activity',
                                      onTap: () => _showSnack(
                                        context,
                                        'Activity for ${lead['client_name']}',
                                      ),
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
                ),
              );
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

  void _showEditInitialQuoteDialog(Map<String, dynamic> quote) {
    _editingQuote = quote;
    _itemNameController.text = quote['item_name']?.toString() ?? '';
    _unitWeightController.text = quote['unit_weight']?.toString() ?? '';
    _quantityController.text = quote['quantity']?.toString() ?? '';
    _exFactoryController.text = quote['ex_factory_price']?.toString() ?? '';
    _unitPriceController.text = quote['unit_price']?.toString() ?? '';
    _profitPercentController.text = quote['profit_percent']?.toString() ?? '';
    _totalController.text = quote['total']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Initial Quote'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _itemNameController,
                decoration: InputDecoration(labelText: 'Item Name'),
              ),
              TextField(
                controller: _unitWeightController,
                decoration: InputDecoration(labelText: 'Weight'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _quantityController,
                decoration: InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _exFactoryController,
                decoration: InputDecoration(labelText: 'Ex-Factory'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _unitPriceController,
                decoration: InputDecoration(labelText: 'Unit Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _profitPercentController,
                decoration: InputDecoration(labelText: 'Profit %'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _totalController,
                decoration: InputDecoration(labelText: 'Total'),
                keyboardType: TextInputType.number,
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
              setState(() {
                _editingQuote = {
                  ...?_editingQuote,
                  'item_name': _itemNameController.text,
                  'unit_weight': _unitWeightController.text,
                  'quantity': _quantityController.text,
                  'ex_factory_price': _exFactoryController.text,
                  'unit_price': _unitPriceController.text,
                  'profit_percent': _profitPercentController.text,
                  'total': _totalController.text,
                };
              });
              Navigator.of(context).pop();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateInitialQuote(Map<String, dynamic> quote) async {
    if (_editingQuote == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('initial_quote')
          .update({
            'item_name': _editingQuote!['item_name'],
            'unit_weight':
                double.tryParse(_editingQuote!['unit_weight'].toString()) ?? 0,
            'quantity':
                int.tryParse(_editingQuote!['quantity'].toString()) ?? 0,
            'ex_factory_price':
                double.tryParse(
                  _editingQuote!['ex_factory_price'].toString(),
                ) ??
                0,
            'unit_price':
                double.tryParse(_editingQuote!['unit_price'].toString()) ?? 0,
            'profit_percent':
                double.tryParse(_editingQuote!['profit_percent'].toString()) ??
                0,
            'total': double.tryParse(_editingQuote!['total'].toString()) ?? 0,
            'published': true,
          })
          .eq('id', quote['id']);
      // Refresh UI
      await _fetchLeadDetails(_selectedLead!['id']);
      Navigator.of(context).pop(); // Close loading
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Published!'),
          content: Text(
            'Initial quote has been published and is now visible to all users.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to update initial quote: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
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
  return Padding(
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
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    value.toString(),
                    style: TextStyle(color: Colors.blue),
                  ),
                )
              : Text(
                  value == null || value.toString().isEmpty
                      ? '-'
                      : value.toString(),
                ),
        ),
      ],
    ),
  );
}
