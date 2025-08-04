# Admin Function Flows & Supabase Connections

## 📋 Table of Contents
1. [Admin Home Screen Structure](#admin-home-screen-structure)
2. [Navigation & Authentication](#navigation--authentication)
3. [Dashboard Analytics](#dashboard-analytics)
4. [Lead Management](#lead-management)
5. [User Management](#user-management)
6. [Settings Management](#settings-management)
7. [Profile Management](#profile-management)
8. [Supabase Table Connections](#supabase-table-connections)
9. [Data Flow Diagrams](#data-flow-diagrams)

---

## 🏗️ Admin Home Screen Structure

### **Main Components:**
```dart
class AdminHomeScreen extends StatefulWidget {
  // Navigation pages
  late final List<Widget> _pages = <Widget>[
    AdminDashboardPage(),     // Dashboard Analytics
    LeadTable(),             // Lead Management
    UserManagementPage(),     // User Management
    AdminSettingsPage(),      // Settings
    ProfilePage(),           // Profile
  ];
}
```

### **Navigation Items:**
- **Dashboard** - Analytics and insights
- **Leads Management** - Lead CRUD operations
- **User Management** - User administration
- **Settings** - System configuration
- **Profile** - User profile management
- **Logout** - Session termination

---

## 🔐 Navigation & Authentication

### **Logout Flow:**
```dart
Future<void> _logout() async {
  // 1. Update user online status
  await setUserOnlineStatus(false);
  
  // 2. Get current user ID
  final userId = Supabase.instance.client.auth.currentUser?.id;
  
  // 3. Update session status in Supabase
  if (userId != null) {
    await updateUserSessionActiveMCP(userId, false);
    await updateUserOnlineStatusMCP(userId, false);
  }
  
  // 4. Update by email as fallback
  final prefs = await SharedPreferences.getInstance();
  final email = prefs.getString('user_email');
  if (email != null) {
    await updateUserOnlineStatusByEmailMCP(email, false);
  }
  
  // 5. Clear session and redirect
  await clearLoginSession();
  await Supabase.instance.client.auth.signOut();
  
  // 6. Navigate to login
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => const LoginScreen()),
    (route) => false,
  );
}
```

### **Supabase Tables Used:**
- `auth.users` - User authentication
- `users` - User profile data
- `dev_user` - Developer user data

---

## 📊 Dashboard Analytics

### **AdminDashboardPage Class:**
```dart
class _AdminDashboardPageState extends State<AdminDashboardPage> {
  // State variables
  String _selectedTimePeriod = 'Quarter';
  String _selectedCurrency = 'INR';
  String _activeLeadTab = 'Won';
  
  // Data collections
  List<Map<String, dynamic>> _leadPerformanceData = [];
  List<Map<String, dynamic>> _filteredLeadData = [];
  Map<String, int> _leadStatusDistribution = {};
  Map<String, dynamic> _dashboardData = {};
  List<BarChartGroupData> _barChartData = [];
}
```

### **Dashboard Data Fetching:**

#### **1. Main Dashboard Data:**
```dart
Future<void> _fetchDashboardData() async {
  final client = Supabase.instance.client;
  
  // Fetch leads with status filtering
  final leads = await client
      .from('leads')
      .select('*')
      .inFilter('lead_status', ['Won', 'Lost', 'Loop'])
      .gte('created_at', startDate.toIso8601String())
      .lte('created_at', endDate.toIso8601String());
      
  // Calculate metrics
  double totalRevenue = 0;
  double totalAluminiumArea = 0;
  int qualifiedLeads = 0;
  
  for (final lead in leads) {
    totalRevenue += lead['revenue'] ?? 0;
    totalAluminiumArea += lead['aluminium_area'] ?? 0;
    if (lead['lead_status'] == 'Won') qualifiedLeads++;
  }
  
  // Update state
  setState(() {
    _dashboardData = {
      'totalRevenue': {'value': '₹${totalRevenue.toStringAsFixed(0)}', 'percentage': '+0.0%'},
      'aluminiumArea': {'value': '${totalAluminiumArea.toStringAsFixed(0)} m²', 'percentage': '+0.0%'},
      'qualifiedLeads': {'value': '$qualifiedLeads', 'percentage': '+0.0%'},
    };
  });
}
```

#### **2. Lead Performance Data:**
```dart
Future<void> _fetchLeadPerformanceData() async {
  final client = Supabase.instance.client;
  
  // Fetch leads with detailed information
  final leads = await client
      .from('leads')
      .select('''
        id, client_name, project_name, lead_status, 
        revenue, aluminium_area, created_at, 
        lead_generated_by, project_location
      ''')
      .order('created_at', ascending: false);
      
  // Fetch usernames for lead generators
  final leadsWithUsernames = await Future.wait(
    leads.map((lead) async {
      final username = await _fetchUsernameByUserId(lead['lead_generated_by']);
      return {...lead, 'username': username ?? 'Unknown'};
    }),
  );
  
  setState(() {
    _leadPerformanceData = leadsWithUsernames;
    _filteredLeadData = leadsWithUsernames;
  });
}
```

#### **3. Chart Data:**
```dart
Future<void> _fetchChartData() async {
  final client = Supabase.instance.client;
  
  // Fetch leads for chart visualization
  final leads = await client
      .from('leads')
      .select('lead_status, created_at, revenue')
      .gte('created_at', startDate.toIso8601String())
      .lte('created_at', endDate.toIso8601String());
      
  // Process data for charts
  final monthlyData = <String, Map<String, double>>{};
  
  for (final lead in leads) {
    final date = DateTime.parse(lead['created_at']);
    final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    
    if (!monthlyData.containsKey(monthKey)) {
      monthlyData[monthKey] = {'Won': 0, 'Lost': 0, 'Loop': 0};
    }
    
    final status = lead['lead_status'] ?? 'Unknown';
    monthlyData[monthKey]![status] = (monthlyData[monthKey]![status] ?? 0) + 1;
  }
  
  // Convert to chart format
  final chartData = monthlyData.entries.map((entry) {
    return BarChartGroupData(
      x: entry.key.hashCode,
      barRods: [
        BarChartRodData(toY: entry.value['Won'] ?? 0, color: Colors.green),
        BarChartRodData(toY: entry.value['Lost'] ?? 0, color: Colors.red),
        BarChartRodData(toY: entry.value['Loop'] ?? 0, color: Colors.orange),
      ],
    );
  }).toList();
  
  setState(() {
    _barChartData = chartData;
  });
}
```

#### **4. Lead Status Distribution:**
```dart
Future<void> _fetchLeadStatusDistributionData() async {
  final client = Supabase.instance.client;
  
  // Count leads by status
  final wonLeads = await client
      .from('leads')
      .select('id', const FetchOptions(count: CountOption.exact))
      .eq('lead_status', 'Won');
      
  final lostLeads = await client
      .from('leads')
      .select('id', const FetchOptions(count: CountOption.exact))
      .eq('lead_status', 'Lost');
      
  final loopLeads = await client
      .from('leads')
      .select('id', const FetchOptions(count: CountOption.exact))
      .eq('lead_status', 'Loop');
  
  setState(() {
    _leadStatusDistribution = {
      'Won': wonLeads.count ?? 0,
      'Lost': lostLeads.count ?? 0,
      'Loop': loopLeads.count ?? 0,
    };
  });
}
```

### **Supabase Tables Used:**
- `leads` - Main lead data
- `users` - User information
- `dev_user` - Developer user data

---

## 📋 Lead Management

### **LeadTable Class:**
```dart
class _AdminLeadsPageState extends State<_AdminLeadsPage> {
  List<Map<String, dynamic>> leads = [];
  bool _isLoading = true;
  String? _error;
  int? _expandedIndex;
  List<Map<String, dynamic>> _activityTimeline = [];
  List<Map<String, dynamic>> _mainContacts = [];
  List<Map<String, dynamic>> _leadContacts = [];
}
```

### **Lead Operations:**

#### **1. Fetch All Leads:**
```dart
Future<void> _fetchLeads() async {
  setState(() {
    _isLoading = true;
    _error = null;
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
```

#### **2. Fetch Lead Activity Timeline:**
```dart
Future<void> _fetchActivityTimeline(String leadId) async {
  setState(() {
    _isActivityLoading = true;
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
```

#### **3. Fetch Lead Contacts:**
```dart
Future<void> _fetchContacts(String leadId) async {
  setState(() {
    _isContactsLoading = true;
    _mainContacts = [];
    _leadContacts = [];
  });
  
  try {
    final client = Supabase.instance.client;
    
    // Fetch main contacts
    final mainContactsResult = await client
        .from('main_contact')
        .select('*')
        .eq('lead_id', leadId)
        .order('created_at', ascending: false);
        
    // Fetch lead contacts
    final leadContactsResult = await client
        .from('lead_contact')
        .select('*')
        .eq('lead_id', leadId)
        .order('created_at', ascending: false);
        
    setState(() {
      _mainContacts = List<Map<String, dynamic>>.from(mainContactsResult);
      _leadContacts = List<Map<String, dynamic>>.from(leadContactsResult);
      _isContactsLoading = false;
    });
  } catch (e) {
    setState(() {
      _contactsError = 'Failed to fetch contacts: ${e.toString()}';
      _isContactsLoading = false;
    });
  }
}
```

#### **4. Update Lead Status:**
```dart
Future<void> _updateLeadStatus(String leadId, String newStatus) async {
  try {
    final client = Supabase.instance.client;
    
    // Update lead status
    await client
        .from('leads')
        .update({'lead_status': newStatus})
        .eq('id', leadId);
        
    // Log activity
    await client.from('lead_activity').insert({
      'lead_id': leadId,
      'activity_type': 'status_update',
      'activity_description': 'Status changed to $newStatus',
      'activity_date': DateTime.now().toIso8601String(),
      'activity_time': DateTime.now().toIso8601String(),
    });
    
    // Refresh data
    await _fetchLeads();
    
  } catch (e) {
    debugPrint('Error updating lead status: $e');
  }
}
```

### **Supabase Tables Used:**
- `leads` - Lead information
- `lead_activity` - Activity timeline
- `main_contact` - Primary contacts
- `lead_contact` - Additional contacts

---

## 👥 User Management

### **UserManagementPage Class:**
```dart
class _UserManagementPageState extends State<UserManagementPage> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _devUsers = [];
  bool _isLoading = false;
  String? _error;
  String _activeTab = 'users';
}
```

### **User Operations:**

#### **1. Fetch All Users:**
```dart
Future<void> _fetchUsers() async {
  setState(() {
    _isLoading = true;
    _error = null;
  });
  
  try {
    final client = Supabase.instance.client;
    
    // Fetch regular users
    final users = await client
        .from('users')
        .select('*')
        .order('created_at', ascending: false);
        
    // Fetch developer users
    final devUsers = await client
        .from('dev_user')
        .select('*')
        .order('created_at', ascending: false);
        
    setState(() {
      _users = List<Map<String, dynamic>>.from(users);
      _devUsers = List<Map<String, dynamic>>.from(devUsers);
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _error = 'Failed to fetch users: ${e.toString()}';
      _isLoading = false;
    });
  }
}
```

#### **2. Create New User:**
```dart
Future<void> _createUser(Map<String, dynamic> userData) async {
  try {
    final client = Supabase.instance.client;
    
    // Create user in auth
    final authResponse = await client.auth.admin.createUser(
      AdminUserAttributes(
        email: userData['email'],
        password: userData['password'],
        emailConfirm: true,
      ),
    );
    
    // Add user profile data
    await client.from('users').insert({
      'id': authResponse.user!.id,
      'username': userData['username'],
      'employee_code': userData['employee_code'],
      'user_type': userData['user_type'],
      'created_at': DateTime.now().toIso8601String(),
    });
    
    // Refresh user list
    await _fetchUsers();
    
  } catch (e) {
    debugPrint('Error creating user: $e');
  }
}
```

#### **3. Update User:**
```dart
Future<void> _updateUser(String userId, Map<String, dynamic> updates) async {
  try {
    final client = Supabase.instance.client;
    
    await client
        .from('users')
        .update(updates)
        .eq('id', userId);
        
    // Refresh user list
    await _fetchUsers();
    
  } catch (e) {
    debugPrint('Error updating user: $e');
  }
}
```

#### **4. Delete User:**
```dart
Future<void> _deleteUser(String userId) async {
  try {
    final client = Supabase.instance.client;
    
    // Delete user profile
    await client
        .from('users')
        .delete()
        .eq('id', userId);
        
    // Delete from auth (requires admin privileges)
    await client.auth.admin.deleteUser(userId);
    
    // Refresh user list
    await _fetchUsers();
    
  } catch (e) {
    debugPrint('Error deleting user: $e');
  }
}
```

### **Supabase Tables Used:**
- `auth.users` - Authentication users
- `users` - User profiles
- `dev_user` - Developer users

---

## ⚙️ Settings Management

### **AdminSettingsPage Class:**
```dart
class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final TextEditingController _projectCodeController = TextEditingController();
  bool _isLoading = false;
  String? _currentProjectCode;
}
```

### **Settings Operations:**

#### **1. Load Current Project Code:**
```dart
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
    setState(() {
      _currentProjectCode = null;
      _projectCodeController.text = '';
    });
  }
}
```

#### **2. Save Project Code:**
```dart
Future<void> _saveProjectCode() async {
  if (_projectCodeController.text.trim().isEmpty) {
    return;
  }
  
  setState(() {
    _isLoading = true;
  });
  
  try {
    final client = Supabase.instance.client;
    final baseCode = _projectCodeController.text.trim();
    
    // Get existing codes to generate sequence
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
    
    final newProjectCode = '$baseCode-${nextSequence.toString().padLeft(5, '0')}';
    
    // Update settings
    await client.from('settings').update({'project_code': newProjectCode});
    
    setState(() {
      _currentProjectCode = newProjectCode;
      _isLoading = false;
    });
    
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    debugPrint('Error saving project code: $e');
  }
}
```

### **Supabase Tables Used:**
- `settings` - System configuration

---

## 👤 Profile Management

### **ProfilePage Class:**
```dart
class ProfilePage extends StatelessWidget {
  final String currentUserId;
  
  const ProfilePage({super.key, required this.currentUserId});
}
```

### **Profile Operations:**

#### **1. Fetch User Profile:**
```dart
Future<Map<String, dynamic>?> _fetchUserProfile(String userId) async {
  try {
    final client = Supabase.instance.client;
    
    // Try users table first
    var user = await client
        .from('users')
        .select('*')
        .eq('id', userId)
        .maybeSingle();
        
    if (user != null) {
      return user;
    }
    
    // Try dev_user table
    user = await client
        .from('dev_user')
        .select('*')
        .eq('id', userId)
        .maybeSingle();
        
    return user;
  } catch (e) {
    debugPrint('Error fetching user profile: $e');
    return null;
  }
}
```

#### **2. Update User Profile:**
```dart
Future<void> _updateUserProfile(String userId, Map<String, dynamic> updates) async {
  try {
    final client = Supabase.instance.client;
    
    // Try updating users table first
    await client
        .from('users')
        .update(updates)
        .eq('id', userId);
        
  } catch (e) {
    // If users table fails, try dev_user table
    try {
      await client
          .from('dev_user')
          .update(updates)
          .eq('id', userId);
    } catch (e2) {
      debugPrint('Error updating user profile: $e2');
    }
  }
}
```

### **Supabase Tables Used:**
- `users` - User profiles
- `dev_user` - Developer profiles

---

## 🗄️ Supabase Table Connections

### **Primary Tables:**

#### **1. Authentication Tables:**
```sql
-- User authentication
auth.users
├── id (UUID, Primary Key)
├── email (String)
├── encrypted_password (String)
├── created_at (Timestamp)
└── updated_at (Timestamp)
```

#### **2. User Management Tables:**
```sql
-- Regular users
users
├── id (UUID, Foreign Key to auth.users.id)
├── username (String)
├── employee_code (String)
├── user_type (String)
├── created_at (Timestamp)
└── updated_at (Timestamp)

-- Developer users
dev_user
├── id (UUID, Foreign Key to auth.users.id)
├── username (String)
├── employee_code (String)
├── user_type (String)
├── created_at (Timestamp)
└── updated_at (Timestamp)
```

#### **3. Lead Management Tables:**
```sql
-- Main leads
leads
├── id (UUID, Primary Key)
├── client_name (String)
├── project_name (String)
├── project_location (String)
├── lead_status (String)
├── revenue (Decimal)
├── aluminium_area (Decimal)
├── lead_generated_by (UUID, Foreign Key)
├── created_at (Timestamp)
└── updated_at (Timestamp)

-- Lead activity
lead_activity
├── id (UUID, Primary Key)
├── lead_id (UUID, Foreign Key to leads.id)
├── activity_type (String)
├── activity_description (String)
├── activity_date (Date)
├── activity_time (Time)
└── created_at (Timestamp)

-- Main contacts
main_contact
├── id (UUID, Primary Key)
├── lead_id (UUID, Foreign Key to leads.id)
├── contact_name (String)
├── contact_email (String)
├── contact_mobile (String)
└── created_at (Timestamp)

-- Lead contacts
lead_contact
├── id (UUID, Primary Key)
├── lead_id (UUID, Foreign Key to leads.id)
├── contact_name (String)
├── contact_email (String)
├── contact_mobile (String)
└── created_at (Timestamp)
```

#### **4. Settings Table:**
```sql
-- System settings
settings
├── id (UUID, Primary Key)
├── project_code (String)
├── created_at (Timestamp)
└── updated_at (Timestamp)
```

### **Table Relationships:**
```
auth.users (1) ── (1) users
auth.users (1) ── (1) dev_user
users (1) ── (N) leads (lead_generated_by)
leads (1) ── (N) lead_activity
leads (1) ── (N) main_contact
leads (1) ── (N) lead_contact
```

---

## 🔄 Data Flow Diagrams

### **Dashboard Data Flow:**
```
1. Admin Dashboard Page Loads
   ↓
2. Fetch Dashboard Data
   ├── _fetchDashboardData()
   ├── _fetchLeadPerformanceData()
   ├── _fetchChartData()
   └── _fetchLeadStatusDistributionData()
   ↓
3. Supabase Queries
   ├── SELECT * FROM leads WHERE lead_status IN ('Won', 'Lost', 'Loop')
   ├── SELECT * FROM users WHERE id = lead_generated_by
   └── COUNT(*) FROM leads GROUP BY lead_status
   ↓
4. Process Data
   ├── Calculate revenue totals
   ├── Calculate area totals
   ├── Generate chart data
   └── Update UI state
   ↓
5. Display Dashboard
   ├── Revenue cards
   ├── Performance charts
   ├── Lead status distribution
   └── Lead performance table
```

### **Lead Management Flow:**
```
1. Lead Management Page Loads
   ↓
2. Fetch All Leads
   ├── _fetchLeads()
   └── SELECT * FROM leads ORDER BY created_at DESC
   ↓
3. Display Lead List
   ├── Lead cards/table
   ├── Status indicators
   └── Action buttons
   ↓
4. Lead Actions
   ├── View Details
   │   ├── _fetchActivityTimeline(leadId)
   │   ├── _fetchContacts(leadId)
   │   └── Display modal/dialog
   ├── Update Status
   │   ├── _updateLeadStatus(leadId, newStatus)
   │   ├── UPDATE leads SET lead_status = newStatus
   │   └── INSERT INTO lead_activity
   └── Delete Lead
       ├── DELETE FROM leads WHERE id = leadId
       └── Refresh lead list
```

### **User Management Flow:**
```
1. User Management Page Loads
   ↓
2. Fetch All Users
   ├── _fetchUsers()
   ├── SELECT * FROM users
   └── SELECT * FROM dev_user
   ↓
3. Display User List
   ├── User cards/table
   ├── User type indicators
   └── Action buttons
   ↓
4. User Actions
   ├── Create User
   │   ├── _createUser(userData)
   │   ├── INSERT INTO auth.users
   │   └── INSERT INTO users/dev_user
   ├── Update User
   │   ├── _updateUser(userId, updates)
   │   └── UPDATE users/dev_user SET ...
   └── Delete User
       ├── _deleteUser(userId)
       ├── DELETE FROM users/dev_user
       └── DELETE FROM auth.users
```

### **Settings Management Flow:**
```
1. Settings Page Loads
   ↓
2. Load Current Settings
   ├── _loadCurrentProjectCode()
   └── SELECT project_code FROM settings LIMIT 1
   ↓
3. Display Settings Form
   ├── Project code input
   └── Save button
   ↓
4. Save Settings
   ├── _saveProjectCode()
   ├── Generate new project code
   └── UPDATE settings SET project_code = newCode
```

---

## 🔧 Helper Functions

### **Username Fetching:**
```dart
Future<String?> _fetchUsernameByUserId(String? userId) async {
  if (userId == null) return null;
  
  final client = Supabase.instance.client;
  try {
    // Try users table first
    var user = await client
        .from('users')
        .select('username')
        .eq('id', userId)
        .maybeSingle();
        
    if (user != null) {
      return user['username'];
    }
    
    // Try dev_user table
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
```

### **Date Range Calculation:**
```dart
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
    default:
      startDate = DateTime(now.year, now.month - 3, now.day);
  }
  
  return {'start': startDate, 'end': endDate};
}
```

---

## 📊 Performance Optimizations

### **1. Efficient Queries:**
- Use `select()` to fetch only needed columns
- Use `order()` for proper sorting
- Use `limit()` for pagination
- Use `inFilter()` for multiple value filtering

### **2. State Management:**
- Implement loading states for better UX
- Use `setState()` efficiently
- Handle errors gracefully
- Cache frequently accessed data

### **3. Real-time Updates:**
- Use Supabase real-time subscriptions for live data
- Implement optimistic updates
- Handle offline scenarios

### **4. Security:**
- Implement Row Level Security (RLS)
- Validate user permissions
- Sanitize user inputs
- Use parameterized queries

---

## 🚀 Best Practices

### **1. Error Handling:**
```dart
try {
  // Supabase operation
} catch (e) {
  debugPrint('Error: $e');
  setState(() {
    _error = 'Operation failed: ${e.toString()}';
    _isLoading = false;
  });
}
```

### **2. Loading States:**
```dart
setState(() {
  _isLoading = true;
  _error = null;
});

// Perform operation

setState(() {
  _isLoading = false;
});
```

### **3. Data Validation:**
```dart
if (data == null || data.isEmpty) {
  setState(() {
    _error = 'No data available';
  });
  return;
}
```

### **4. Memory Management:**
```dart
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

---

This documentation provides a comprehensive overview of all admin function flows and Supabase connections in the CRM application. Each section includes detailed code examples, table structures, and data flow diagrams for better understanding and maintenance. 