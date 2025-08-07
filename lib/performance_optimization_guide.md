# Supabase Data Loading Performance Optimization Guide

## Current Performance Issues Identified

### 1. **Sequential Query Execution**
**Problem**: Multiple queries are executed one after another instead of in parallel.
```dart
// Current inefficient approach
final leadsResult = await client.from('leads').select(...);
final usersResult = await client.from('users').select(...);
final proposalInputResult = await client.from('proposal_input').select(...);
```

**Solution**: Use `Future.wait()` for parallel execution
```dart
// Optimized parallel approach
final futures = await Future.wait([
  client.from('leads').select(...),
  client.from('users').select(...),
  client.from('proposal_input').select(...),
]);
```

### 2. **No Data Caching**
**Problem**: Data is fetched from Supabase every time, even for frequently accessed data.

**Solution**: Implement caching with SharedPreferences
```dart
// Add to existing files
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DataCache {
  static const String _cachePrefix = 'data_cache_';
  
  static Future<void> cacheData(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_cachePrefix$key', jsonEncode({
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }
  
  static Future<dynamic> getCachedData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('$_cachePrefix$key');
    if (cached != null) {
      final decoded = jsonDecode(cached);
      final timestamp = DateTime.parse(decoded['timestamp']);
      if (DateTime.now().difference(timestamp).inMinutes < 5) {
        return decoded['data'];
      }
    }
    return null;
  }
}
```

### 3. **No Pagination**
**Problem**: All data is fetched at once, causing slow loading with large datasets.

**Solution**: Implement pagination
```dart
// Add pagination to existing queries
final leadsResult = await client
    .from('leads')
    .select('id, created_at, project_name, client_name, project_location, lead_generated_by')
    .order('created_at', ascending: false)
    .range(offset, offset + limit - 1) // Add pagination
    .timeout(const Duration(seconds: 10));
```

### 4. **Inefficient Data Processing**
**Problem**: Client-side calculations and data processing slow down the UI.

**Solution**: Move calculations to database level or optimize processing
```dart
// Optimize data processing with lookup maps
final userMap = <String, String>{};
for (final user in usersResult) {
  userMap[user['id']] = user['username'] ?? '';
}

// Use lookup maps instead of nested loops
for (final lead in leadsResult) {
  final salesPersonName = userMap[lead['lead_generated_by']] ?? '';
  // Process lead data efficiently
}
```

### 5. **Missing Query Optimization**
**Problem**: Queries don't use proper indexing or filtering.

**Solution**: Optimize queries with proper filtering and indexing
```dart
// Add proper filtering to reduce data transfer
final leadsResult = await client
    .from('leads')
    .select('id, created_at, project_name, client_name, project_location, lead_generated_by')
    .eq('lead_generated_by', currentUserId) // Add user filter
    .gte('created_at', startDate.toIso8601String()) // Add date filter
    .lte('created_at', endDate.toIso8601String())
    .order('created_at', ascending: false)
    .limit(50); // Add limit
```

## Implementation Steps

### Step 1: Add Caching to Existing Screens

**For `admin_home_screen.dart`:**
```dart
// Add at the top of the file
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Add caching methods
class AdminDataCache {
  static Future<void> cacheLeads(List<Map<String, dynamic>> leads) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_leads_cache', jsonEncode({
      'data': leads,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }
  
  static Future<List<Map<String, dynamic>>?> getCachedLeads() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('admin_leads_cache');
    if (cached != null) {
      final decoded = jsonDecode(cached);
      final timestamp = DateTime.parse(decoded['timestamp']);
      if (DateTime.now().difference(timestamp).inMinutes < 3) {
        return List<Map<String, dynamic>>.from(decoded['data']);
      }
    }
    return null;
  }
}

// Modify _fetchLeads method
Future<void> _fetchLeads() async {
  setState(() {
    _isLoading = true;
  });

  try {
    // Try to get from cache first
    final cachedLeads = await AdminDataCache.getCachedLeads();
    if (cachedLeads != null) {
      debugPrint('⚡ Using cached leads data');
      setState(() {
        _leads = cachedLeads;
        _isLoading = false;
      });
      return;
    }

    // Fetch from Supabase if cache is empty or expired
    final client = Supabase.instance.client;
    
    // Execute queries in parallel
    final futures = await Future.wait([
      client.from('leads').select('id, created_at, project_name, client_name, project_location, lead_generated_by').order('created_at', ascending: false),
      client.from('users').select('id, username'),
      client.from('proposal_input').select('lead_id, input, value'),
      client.from('admin_response').select('lead_id, rate_sqm, status, remark'),
    ]);

    final leadsResult = futures[0] as List<dynamic>;
    final usersResult = futures[1] as List<dynamic>;
    final proposalInputResult = futures[2] as List<dynamic>;
    final adminResponseResult = futures[3] as List<dynamic>;

    // Process data efficiently with lookup maps
    final userMap = <String, String>{};
    for (final user in usersResult) {
      userMap[user['id']] = user['username'] ?? '';
    }

    // Process and join data
    final processedLeads = _processLeadsData(leadsResult, userMap, proposalInputResult, adminResponseResult);
    
    // Cache the results
    await AdminDataCache.cacheLeads(processedLeads);

    setState(() {
      _leads = processedLeads;
      _isLoading = false;
    });
  } catch (e) {
    debugPrint('Error loading data: $e');
    setState(() {
      _isLoading = false;
    });
  }
}
```

### Step 2: Optimize Database Queries

**Add database indexes for better performance:**
```sql
-- Add these indexes to your Supabase database
CREATE INDEX IF NOT EXISTS idx_leads_created_at ON leads(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_leads_lead_generated_by ON leads(lead_generated_by);
CREATE INDEX IF NOT EXISTS idx_proposal_input_lead_id ON proposal_input(lead_id);
CREATE INDEX IF NOT EXISTS idx_admin_response_lead_id ON admin_response(lead_id);
CREATE INDEX IF NOT EXISTS idx_users_id ON users(id);
```

### Step 3: Implement Pagination

**For large datasets, add pagination:**
```dart
class PaginatedDataFetcher {
  static const int pageSize = 50;
  int _currentOffset = 0;
  bool _hasMoreData = true;
  
  Future<List<Map<String, dynamic>>> fetchNextPage() async {
    if (!_hasMoreData) return [];
    
    final client = Supabase.instance.client;
    final result = await client
        .from('leads')
        .select('id, created_at, project_name, client_name, project_location, lead_generated_by')
        .order('created_at', ascending: false)
        .range(_currentOffset, _currentOffset + pageSize - 1)
        .timeout(const Duration(seconds: 10));
    
    _currentOffset += pageSize;
    _hasMoreData = result.length == pageSize;
    
    return List<Map<String, dynamic>>.from(result);
  }
  
  void reset() {
    _currentOffset = 0;
    _hasMoreData = true;
  }
}
```

### Step 4: Add Loading States and Error Handling

**Improve user experience with better loading states:**
```dart
// Add to existing screens
bool _isLoadingMore = false;
bool _hasError = false;
String _errorMessage = '';

// Add pull-to-refresh functionality
RefreshIndicator(
  onRefresh: () async {
    await _refreshData();
  },
  child: ListView.builder(
    itemCount: _leads.length + (_hasMoreData ? 1 : 0),
    itemBuilder: (context, index) {
      if (index == _leads.length) {
        return _buildLoadMoreButton();
      }
      return _buildLeadItem(_leads[index]);
    },
  ),
)

Widget _buildLoadMoreButton() {
  if (_isLoadingMore) {
    return const Center(child: CircularProgressIndicator());
  }
  return ElevatedButton(
    onPressed: _hasMoreData ? _loadMoreData : null,
    child: const Text('Load More'),
  );
}
```

### Step 5: Optimize Network Requests

**Add request deduplication and timeout handling:**
```dart
class NetworkOptimizer {
  static final Map<String, Future<dynamic>> _pendingRequests = {};
  
  static Future<T> deduplicateRequest<T>(
    String key,
    Future<T> Function() request,
  ) async {
    if (_pendingRequests.containsKey(key)) {
      return await _pendingRequests[key] as T;
    }
    
    final future = request();
    _pendingRequests[key] = future;
    
    try {
      final result = await future;
      return result;
    } finally {
      _pendingRequests.remove(key);
    }
  }
}

// Usage
final leads = await NetworkOptimizer.deduplicateRequest(
  'fetch_leads_$userId',
  () => client.from('leads').select(...),
);
```

## Performance Monitoring

**Add performance monitoring to track improvements:**
```dart
class PerformanceMonitor {
  static final Map<String, List<int>> _metrics = {};
  
  static void startTimer(String operation) {
    _metrics[operation] = [DateTime.now().millisecondsSinceEpoch];
  }
  
  static void endTimer(String operation) {
    if (_metrics.containsKey(operation) && _metrics[operation]!.isNotEmpty) {
      final startTime = _metrics[operation]!.first;
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final duration = endTime - startTime;
      
      debugPrint('⏱️ $operation took ${duration}ms');
      
      // Log to analytics or monitoring service
      _logPerformance(operation, duration);
    }
  }
  
  static void _logPerformance(String operation, int duration) {
    // Implement logging to your preferred service
    debugPrint('📊 Performance: $operation - ${duration}ms');
  }
}

// Usage
PerformanceMonitor.startTimer('fetch_leads');
final leads = await fetchLeads();
PerformanceMonitor.endTimer('fetch_leads');
```

## Expected Performance Improvements

1. **Caching**: 70-90% reduction in load times for cached data
2. **Parallel Queries**: 50-70% reduction in initial load times
3. **Pagination**: 80-90% reduction in memory usage and initial load time
4. **Optimized Processing**: 30-50% reduction in UI blocking time
5. **Network Optimization**: 20-40% reduction in redundant requests

## Implementation Priority

1. **High Priority**: Add caching to existing screens
2. **High Priority**: Implement parallel query execution
3. **Medium Priority**: Add pagination for large datasets
4. **Medium Priority**: Optimize database queries with indexes
5. **Low Priority**: Add performance monitoring

## Testing Performance Improvements

**Add performance testing methods:**
```dart
class PerformanceTester {
  static Future<void> testDataLoading() async {
    final stopwatch = Stopwatch()..start();
    
    // Test current implementation
    await _testCurrentImplementation();
    final currentTime = stopwatch.elapsedMilliseconds;
    
    stopwatch.reset();
    
    // Test optimized implementation
    await _testOptimizedImplementation();
    final optimizedTime = stopwatch.elapsedMilliseconds;
    
    debugPrint('📊 Performance Test Results:');
    debugPrint('Current: ${currentTime}ms');
    debugPrint('Optimized: ${optimizedTime}ms');
    debugPrint('Improvement: ${((currentTime - optimizedTime) / currentTime * 100).toStringAsFixed(1)}%');
  }
}
```

This guide provides a comprehensive approach to optimizing Supabase data loading performance while maintaining code quality and avoiding linter errors.
