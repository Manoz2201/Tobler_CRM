# 🔗 Supabase Connections & Functions Documentation

## 📋 Overview
This document details all Supabase data fetch and push operations for each user role in the CRM application.

---

## 🔧 **ADMIN ROLE** - Supabase Operations

### **📊 Dashboard Data Fetching**
```dart
// Location: lib/screens/home/admin_home_screen.dart

// 1. Fetch all leads for admin dashboard
final leadsResult = await client
    .from('leads')
    .select('id, created_at, project_name, client_name, project_location, lead_generated_by')
    .order('created_at', ascending: false);

// 2. Fetch proposal inputs for calculations
final proposalInputResult = await client
    .from('proposal_input')
    .select('lead_id, input, value');

// 3. Fetch admin responses
final adminResponseResult = await client
    .from('admin_response')
    .select('lead_id, rate_sqm, status, remark, project_id');

// 4. Fetch lead attachments
final leadAttachments = await client
    .from('lead_attachments')
    .select('lead_id, file_name, file_link, created_at');

// 5. Fetch lead activity
final leadActivity = await client
    .from('lead_activity')
    .select('lead_id, activity_type, changes_made, created_at, user_id')
    .order('created_at', ascending: false);
```

### **👥 User Management Operations**
```dart
// 1. Fetch all users
final usersResult = await client
    .from('users')
    .select('id, username, email, user_type, created_at, is_active');

// 2. Fetch developer users
final devUsersResult = await client
    .from('dev_user')
    .select('id, username, email, user_type, created_at, is_active');

// 3. Update user status
await client
    .from('users')
    .update({'is_active': false})
    .eq('id', userId);

// 4. Delete user
await client
    .from('users')
    .delete()
    .eq('id', userId);
```

### **📈 Analytics & Reports**
```dart
// 1. Fetch lead statistics
final leadStats = await client
    .from('leads')
    .select('lead_type, status, created_at')
    .gte('created_at', startDate)
    .lte('created_at', endDate);

// 2. Fetch revenue data
final revenueData = await client
    .from('admin_response')
    .select('rate_sqm, status, created_at')
    .eq('status', 'approved');

// 3. Fetch user activity
final userActivity = await client
    .from('lead_activity')
    .select('user_id, activity_type, created_at')
    .order('created_at', ascending: false);
```

---

## 💼 **SALES ROLE** - Supabase Operations

### **📋 Lead Management**
```dart
// Location: lib/screens/home/sales_home_screen.dart

// 1. Fetch leads for current sales user only
final leadsResult = await client
    .from('leads')
    .select('id, created_at, project_name, client_name, project_location, lead_generated_by')
    .eq('lead_generated_by', currentUserId) // Filter by active user
    .order('created_at', ascending: false);

// 2. Create new lead
await client
    .from('leads')
    .insert({
      'project_name': projectName,
      'client_name': clientName,
      'project_location': location,
      'lead_generated_by': currentUserId,
      'lead_type': 'Monolithic Formwork',
      'status': 'new'
    });

// 3. Update lead status
await client
    .from('leads')
    .update({'status': newStatus})
    .eq('id', leadId);
```

### **📎 Lead Attachments**
```dart
// 1. Upload attachment
await client
    .from('lead_attachments')
    .insert({
      'lead_id': leadId,
      'file_name': fileName,
      'file_link': fileUrl,
      'uploaded_by': currentUserId
    });

// 2. Fetch lead attachments
final attachments = await client
    .from('lead_attachments')
    .select('file_name, file_link, created_at')
    .eq('lead_id', leadId);
```

### **👥 Lead Contacts**
```dart
// 1. Add contact to lead
await client
    .from('lead_contacts')
    .insert({
      'lead_id': leadId,
      'contact_name': contactName,
      'designation': designation,
      'email': email,
      'mobile': mobile
    });

// 2. Fetch lead contacts
final contacts = await client
    .from('lead_contacts')
    .select('contact_name, designation, email, mobile')
    .eq('lead_id', leadId);
```

### **💬 Lead Communications**
```dart
// 1. Send query/message
await client
    .from('queries')
    .insert({
      'lead_id': leadId,
      'sender_name': senderName,
      'receiver_name': receiverName,
      'query_message': message,
      'sender_id': currentUserId
    });

// 2. Fetch queries for lead
final queries = await client
    .from('queries')
    .select('sender_name, receiver_name, query_message, created_at')
    .eq('lead_id', leadId)
    .order('created_at', ascending: false);
```

### **📊 Sales Dashboard**
```dart
// 1. Fetch sales analytics
final salesData = await client
    .from('leads')
    .select('status, created_at, lead_type')
    .eq('lead_generated_by', currentUserId);

// 2. Fetch proposal status
final proposalStatus = await client
    .from('proposal_input')
    .select('lead_id, input, value')
    .eq('lead_id', leadId);

// 3. Fetch admin responses
final adminResponses = await client
    .from('admin_response')
    .select('lead_id, rate_sqm, status, remark')
    .eq('lead_id', leadId);
```

---

## 🏗️ **PROPOSAL ENGINEER ROLE** - Supabase Operations

### **📊 Dashboard Analytics**
```dart
// Location: lib/screens/home/proposal_engineer_home_screen.dart

// 1. Fetch all leads (inquiries)
final allLeads = await client
    .from('leads')
    .select('''
      id, created_at, client_name, project_name, project_location, 
      lead_generated_by, remark, main_contact_name, main_contact_email, 
      main_contact_mobile, lead_type
    ''')
    .order('created_at', ascending: false);

// 2. Fetch lead contacts
final leadContacts = await client
    .from('lead_contacts')
    .select('lead_id, contact_name, designation, email, mobile, created_at');

// 3. Fetch lead attachments
final leadAttachments = await client
    .from('lead_attachments')
    .select('lead_id, file_name, file_link, created_at');

// 4. Fetch lead activity
final leadActivity = await client
    .from('lead_activity')
    .select('lead_id, activity_type, changes_made, created_at, user_id')
    .order('created_at', ascending: false);

// 5. Fetch queries (communications)
final queries = await client
    .from('queries')
    .select('lead_id, sender_name, receiver_name, query_message, created_at')
    .order('created_at', ascending: false);
```

### **📄 Proposal Management**
```dart
// 1. Fetch proposal files
final proposalFiles = await client
    .from('proposal_file')
    .select('lead_id, file_name, file_link, created_at, user_id');

// 2. Upload proposal file
await client
    .from('proposal_file')
    .insert({
      'lead_id': leadId,
      'file_name': fileName,
      'file_link': fileUrl,
      'user_id': currentUserId
    });

// 3. Fetch proposal inputs
final proposalInputs = await client
    .from('proposal_input')
    .select('lead_id, input, value, remark, created_at, user_id');

// 4. Add proposal input
await client
    .from('proposal_input')
    .insert({
      'lead_id': leadId,
      'input': inputName,
      'value': inputValue,
      'remark': remark,
      'user_id': currentUserId
    });

// 5. Fetch proposal remarks
final proposalRemarks = await client
    .from('proposal_remark')
    .select('lead_id, remark, created_at, user_id');

// 6. Add proposal remark
await client
    .from('proposal_remark')
    .insert({
      'lead_id': leadId,
      'remark': remark,
      'user_id': currentUserId
    });
```

### **📈 Technical Calculations**
```dart
// 1. Calculate area calculations
final areaCalculations = <String, double>{};
for (final input in proposalInputs) {
  final inputType = input['input']?.toString().toLowerCase() ?? '';
  final value = double.tryParse(input['value']?.toString() ?? '0') ?? 0;
  
  if (inputType.contains('area') || inputType.contains('alu')) {
    areaCalculations[leadId] = (areaCalculations[leadId] ?? 0) + value;
  }
}

// 2. Calculate MS weight data
final msWeightData = <String, List<double>>{};
for (final input in proposalInputs) {
  final inputType = input['input']?.toString().toLowerCase() ?? '';
  final value = double.tryParse(input['value']?.toString() ?? '0') ?? 0;
  
  if (inputType.contains('ms') || inputType.contains('weight')) {
    if (!msWeightData.containsKey(leadId)) {
      msWeightData[leadId] = [];
    }
    msWeightData[leadId]!.add(value);
  }
}
```

---

## 👨‍💻 **DEVELOPER ROLE** - Supabase Operations

### **👥 User Management**
```dart
// Location: lib/screens/home/developer_home_screen.dart

// 1. Fetch all users
final usersResult = await client
    .from('users')
    .select('id, username, email, user_type, created_at, is_active')
    .order('created_at', ascending: false);

// 2. Fetch developer users
final devUsersResult = await client
    .from('dev_user')
    .select('id, username, email, user_type, created_at, is_active')
    .order('created_at', ascending: false);

// 3. Update user information
await client
    .from('users')
    .update({
      'username': newUsername,
      'email': newEmail,
      'user_type': newUserType,
      'is_active': isActive
    })
    .eq('id', userId);

// 4. Delete user
await client
    .from('users')
    .delete()
    .eq('id', userId);
```

### **📧 Invitation System**
```dart
// 1. Send invitation
await client
    .from('invitation')
    .insert({
      'user_name': userName,
      'email': email,
      'mobile_no': mobileNo,
      'user_type': userType,
      'active': false
    });

// 2. Fetch invited users
final invitationData = await client
    .from('invitation')
    .select('user_name, mobile_no, email, user_type, created_at, is_registered')
    .eq('active', false)
    .order('created_at', ascending: false);

// 3. Fetch verification codes
final emails = invitationData
    .map((e) => e['email'] as String?)
    .whereType<String>()
    .toList();

final usersData = await client
    .from('users')
    .select('email, verification_code')
    .inFilter('email', emails);
```

### **🔧 System Configuration**
```dart
// 1. Update system settings
await client
    .from('system_config')
    .update({
      'setting_name': settingName,
      'setting_value': settingValue,
      'updated_by': currentUserId
    })
    .eq('setting_name', settingName);

// 2. Fetch system settings
final systemSettings = await client
    .from('system_config')
    .select('setting_name, setting_value, updated_at');
```

---

## 🔐 **AUTHENTICATION & SESSION MANAGEMENT**

### **🔑 Login Operations**
```dart
// Location: lib/screens/auth/login_screen.dart

// 1. Authenticate user
final session = await Supabase.instance.client.auth.signInWithPassword(
  email: email,
  password: password,
);

// 2. Check user in users table
final userResult = await Supabase.instance.client
    .from('users')
    .select('id, username, user_type, is_active')
    .eq('id', session.user.id)
    .single();

// 3. Check user in dev_user table
final devUserResult = await Supabase.instance.client
    .from('dev_user')
    .select('id, username, user_type, is_active')
    .eq('id', session.user.id)
    .single();
```

### **🚪 Logout Operations**
```dart
// 1. Update user session status
await client
    .from('users')
    .update({'session_active': false})
    .eq('id', userId);

// 2. Sign out from Supabase
await Supabase.instance.client.auth.signOut();
```

### **📱 Session Management**
```dart
// 1. Update user online status
await client
    .from('users')
    .update({'online_status': true, 'last_active': DateTime.now().toIso8601String()})
    .eq('id', userId);

// 2. Validate session
final sessionValid = await client
    .from('users')
    .select('session_active, last_active')
    .eq('id', userId)
    .single();
```

---

## 📊 **COMMON DATA OPERATIONS**

### **🔍 Data Fetching Patterns**
```dart
// 1. Basic select with filtering
final data = await client
    .from('table_name')
    .select('column1, column2, column3')
    .eq('filter_column', filterValue)
    .order('created_at', ascending: false);

// 2. Complex queries with joins
final joinedData = await client
    .from('leads')
    .select('''
      *,
      lead_contacts(contact_name, email),
      lead_attachments(file_name, file_link)
    ''')
    .eq('id', leadId);

// 3. Aggregation queries
final stats = await client
    .from('leads')
    .select('status, count')
    .eq('lead_generated_by', userId)
    .group('status');
```

### **✏️ Data Insertion Patterns**
```dart
// 1. Single record insertion
await client
    .from('table_name')
    .insert({
      'column1': value1,
      'column2': value2,
      'created_at': DateTime.now().toIso8601String()
    });

// 2. Multiple records insertion
await client
    .from('table_name')
    .insert([
      {'column1': value1, 'column2': value2},
      {'column1': value3, 'column2': value4}
    ]);
```

### **🔄 Data Update Patterns**
```dart
// 1. Update single record
await client
    .from('table_name')
    .update({'column1': newValue})
    .eq('id', recordId);

// 2. Update multiple records
await client
    .from('table_name')
    .update({'status': newStatus})
    .inFilter('id', [id1, id2, id3]);
```

### **🗑️ Data Deletion Patterns**
```dart
// 1. Delete single record
await client
    .from('table_name')
    .delete()
    .eq('id', recordId);

// 2. Delete multiple records
await client
    .from('table_name')
    .delete()
    .inFilter('id', [id1, id2, id3]);
```

---

## 🗄️ **SUPABASE TABLES USED**

### **📋 Core Tables**
1. **`leads`** - Main lead/inquiry data
2. **`users`** - User accounts and profiles
3. **`dev_user`** - Developer user accounts
4. **`lead_contacts`** - Contact information for leads
5. **`lead_attachments`** - Files attached to leads
6. **`lead_activity`** - Activity tracking for leads
7. **`queries`** - Communication messages
8. **`proposal_input`** - Technical input data
9. **`proposal_file`** - Proposal documents
10. **`proposal_remark`** - Proposal comments
11. **`admin_response`** - Admin feedback and rates
12. **`invitation`** - User invitation system

### **🔧 Configuration Tables**
1. **`system_config`** - System settings
2. **`user_sessions`** - Session management
3. **`verification_codes`** - Email verification

---

## 🚀 **PERFORMANCE OPTIMIZATION**

### **⚡ Best Practices**
```dart
// 1. Use timeouts for long operations
final result = await client
    .from('table_name')
    .select('*')
    .timeout(const Duration(seconds: 10));

// 2. Limit data with pagination
final paginatedData = await client
    .from('table_name')
    .select('*')
    .range(0, 49); // First 50 records

// 3. Use specific column selection
final specificData = await client
    .from('table_name')
    .select('id, name, email') // Only needed columns
    .eq('status', 'active');

// 4. Cache frequently accessed data
final cachedData = await SharedPreferences.getInstance();
await cachedData.setString('user_data', jsonEncode(userData));
```

---

## 🔒 **SECURITY CONSIDERATIONS**

### **🛡️ Row Level Security (RLS)**
- All tables should have RLS policies
- Users can only access their own data
- Admins can access all data
- Proper role-based access control

### **🔐 Authentication**
- JWT tokens for session management
- Secure password handling
- Email verification for new users
- Session timeout and cleanup

---

## 📝 **ERROR HANDLING**

### **⚠️ Common Error Patterns**
```dart
try {
  final result = await client
      .from('table_name')
      .select('*')
      .eq('id', recordId)
      .single();
} catch (e) {
  if (e.toString().contains('No rows returned')) {
    // Handle no data found
  } else if (e.toString().contains('timeout')) {
    // Handle timeout
  } else {
    // Handle other errors
  }
}
```

---

**📚 This documentation covers all Supabase operations for the CRM application across all user roles.** 