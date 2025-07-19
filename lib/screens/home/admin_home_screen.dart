import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  bool _isDockedLeft = true;
  double _dragOffsetX = 0.0;

  final List<_NavItem> _navItems = const [
    _NavItem('Dashboard', Icons.dashboard),
    _NavItem('Users', Icons.people_outline),
    _NavItem('Leads', Icons.assignment), // Changed from Reports to Leads
    _NavItem('Settings', Icons.settings),
    _NavItem('Profile', Icons.person),
  ];

  late final List<Widget> _pages = <Widget>[
    const Center(child: Text('Admin Dashboard')),
    const Center(child: Text('User Management')),
    _AdminLeadsPage(), // New leads page for admin
    const Center(child: Text('Settings')),
    const Center(child: Text('Profile')),
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
          // Mobile layout: bottom navigation bar
          return Scaffold(
            body: _pages[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: _navItems
                  .map(
                    (item) => BottomNavigationBarItem(
                      icon: Icon(item.icon),
                      label: item.label,
                    ),
                  )
                  .toList(),
              selectedItemColor: const Color(0xFF1976D2),
              unselectedItemColor: Colors.grey[400],
              type: BottomNavigationBarType.fixed,
              backgroundColor: Color.fromARGB(
                (0.95 * 255).round(),
                255,
                255,
                255,
              ),
              elevation: 8,
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

  void _expandCard(int index) async {
    final leadId = leads[index]['id'];
    setState(() {
      _expandedIndex = index;
    });
    await _fetchActivityTimeline(leadId);
  }

  void _collapseCard() {
    setState(() {
      _expandedIndex = null;
      _activityTimeline = [];
    });
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
                                          onTap: () {},
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
