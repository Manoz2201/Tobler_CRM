// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; // Added for jsonEncode

class ProposalHomeScreen extends StatefulWidget {
  final String? currentUserId;
  const ProposalHomeScreen({super.key, this.currentUserId});

  @override
  State<ProposalHomeScreen> createState() => _ProposalHomeScreenState();
}

class _ProposalHomeScreenState extends State<ProposalHomeScreen> {
  int _selectedIndex = 0;
  bool _isDockedLeft = true;
  double _dragOffsetX = 0.0;

  final List<_NavItem> _navItems = const [
    _NavItem('Dashboard', Icons.dashboard),
    _NavItem('Proposals', Icons.description),
    _NavItem('Clients', Icons.people_outline),
    _NavItem('Reports', Icons.bar_chart),
    _NavItem('Profile', Icons.person),
  ];

  late final List<Widget> _pages = <Widget>[
    const Center(child: Text('Proposal Engineer Dashboard')),
    ProposalScreen(currentUserId: widget.currentUserId),
    const Center(child: Text('Clients List')),
    const Center(child: Text('Reports')),
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
          // Mobile layout with bottom nav
          return Scaffold(
            body: _pages[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
              items: _navItems
                  .map(
                    (item) => BottomNavigationBarItem(
                      icon: Icon(item.icon),
                      label: item.label,
                    ),
                  )
                  .toList(),
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: const Color(0xFF1976D2),
              unselectedItemColor: Colors.grey[400],
              type: BottomNavigationBarType.fixed,
            ),
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
          'id, client_name, project_name, project_location, created_at, remark, main_contact_name, main_contact_email, main_contact_mobile',
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

    return List<Map<String, dynamic>>.from(leadsWithoutProposals);
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
          'id, client_name, project_name, project_location, created_at, remark, main_contact_name, main_contact_email, main_contact_mobile',
        )
        .inFilter('id', submittedLeadIds.toList())
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(leadsData);
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
                              ],
                            ),
                          ),
                          // Vertical divider
                          Container(
                            width: 1,
                            height: 140,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            color: Colors.grey[300],
                          ),
                          // Right column (Main Contact only)
                          Expanded(
                            flex: 2,
                            child: Column(
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if ((lead['main_contact_email'] ?? '')
                                    .isNotEmpty)
                                  Text(
                                    lead['main_contact_email'] ?? '',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                if ((lead['main_contact_mobile'] ?? '')
                                    .isNotEmpty)
                                  Text(
                                    lead['main_contact_mobile'] ?? '',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: ElevatedButton(
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
                          const Divider(),
                          const SizedBox(height: 4),
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
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: ElevatedButton(
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
                            future: _fetchUserInfo(proposals.first['user_id']),
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
                            future: _fetchUserInfo(activity['user_id']),
                            builder: (context, userSnapshot) {
                              final user = userSnapshot.data;
                              final userStr = user != null
                                  ? '${user['username'] ?? ''} (${user['employee_code'] ?? ''})'
                                  : 'User';
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

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}

// Helper for label-value pairs
Widget _labelValue(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 2.0),
    child: Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value ?? '-', style: const TextStyle(fontWeight: FontWeight.w400)),
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
      'unit': TextEditingController(),
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
    if (widget.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in. Please log in again.'),
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final client = Supabase.instance.client;
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
            'user_id': widget.currentUserId,
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
            'unit': input['unit']!.text.trim(),
            'user_id': widget.currentUserId,
          });
        }
      }
      // Save remark
      if (remarkController.text.trim().isNotEmpty) {
        await client.from('proposal_remark').insert({
          'lead_id': leadId,
          'remark': remarkController.text.trim(),
          'user_id': widget.currentUserId,
        });
      }

      setState(() {
        _isLoading = false;
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Proposal submitted!')));
      await logLeadActivity(
        leadId: leadId,
        userId: widget.currentUserId!,
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
            height: isWide ? 600 : null,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelValue('Client Name', lead['client_name']),
        _labelValue('Project name', lead['project_name']),
        _labelValue('Project Location', lead['project_location']),
        Row(
          children: [
            const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text(
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
        ),
        const SizedBox(height: 12),
        const Divider(),
        const Text(
          'CONTACT',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
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
        ...otherContacts.map(
          (c) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              Text(
                c['contact_name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if ((c['email'] ?? '').isNotEmpty)
                Text(c['email'] ?? '', style: const TextStyle(fontSize: 13)),
              if ((c['mobile'] ?? '').isNotEmpty)
                Text(c['mobile'] ?? '', style: const TextStyle(fontSize: 13)),
            ],
          ),
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
                ),
                if ((a['file_link'] ?? '').isNotEmpty)
                  InkWell(
                    onTap: () {},
                    child: Text(
                      a['file_link'] ?? '',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Responsive Proposal Response Form Section
class _ProposalResponseForm extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Proposal Response',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('File Name'),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: List.generate(
                  files.length,
                  (i) => Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: files[i]['fileName'],
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: files[i]['fileLink'],
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_box, color: Colors.orange),
                        onPressed: onAddFile,
                      ),
                      if (files.length > 1)
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                          onPressed: () => onRemoveFile(i),
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
          controller: remarkController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Input'),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: List.generate(
                  inputs.length,
                  (i) => Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: inputs[i]['input'],
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: inputs[i]['value'],
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: inputs[i]['unit'],
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_box, color: Colors.orange),
                        onPressed: onAddInput,
                      ),
                      if (inputs.length > 1)
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                          onPressed: () => onRemoveInput(i),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.bottomRight,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSave,
              child: isLoading
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
Future<Map<String, dynamic>?> _fetchUserInfo(String userId) async {
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
