import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'data_cache_service.dart';

class OptimizedDataService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Fetch leads with optimized queries and caching
  static Future<List<Map<String, dynamic>>> fetchLeadsOptimized({
    String? userId,
    int limit = 50,
    int offset = 0,
    bool useCache = true,
  }) async {
    try {
      // Try to get from cache first
      if (useCache) {
        final cachedLeads = await DataCacheService.getCachedLeads();
        if (cachedLeads != null) {
          debugPrint('⚡ Using cached leads data');
          return cachedLeads;
        }
      }

      debugPrint('🔄 Fetching leads from Supabase...');
      final stopwatch = Stopwatch()..start();

      // Build query with conditional filters
      dynamic query = _client.from('leads').select('''
            id, created_at, project_name, client_name, 
            project_location, lead_generated_by, lead_type
          ''');

      // Add user filter if specified
      if (userId != null) {
        query = query.eq('lead_generated_by', userId);
      }

      // Add ordering and pagination
      query = query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final leadsResult = await query.timeout(const Duration(seconds: 15));

      debugPrint(
        '📊 Fetched ${leadsResult.length} leads in ${stopwatch.elapsedMilliseconds}ms',
      );

      // Cache the results
      if (useCache && leadsResult.isNotEmpty) {
        await DataCacheService.cacheLeads(leadsResult);
      }

      return List<Map<String, dynamic>>.from(leadsResult);
    } catch (e) {
      debugPrint('❌ Error fetching leads: $e');
      rethrow;
    }
  }

  /// Fetch all related data in parallel for dashboard
  static Future<Map<String, dynamic>> fetchDashboardDataOptimized({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    bool useCache = true,
  }) async {
    try {
      // Try to get from cache first
      if (useCache) {
        final cachedData = await DataCacheService.getCachedDashboardData();
        if (cachedData != null) {
          debugPrint('⚡ Using cached dashboard data');
          return cachedData;
        }
      }

      debugPrint('🔄 Fetching dashboard data from Supabase...');
      final stopwatch = Stopwatch()..start();

      // Execute all queries in parallel
      final futures = await Future.wait([
        _fetchLeadsForDashboard(userId, startDate, endDate),
        fetchUsersOptimized(),
        fetchProposalInputOptimized(),
        fetchAdminResponseOptimized(),
      ]);

      final leads = futures[0];
      final users = futures[1];
      final proposalInput = futures[2];
      final adminResponse = futures[3];

      // Process data efficiently
      final processedData = await _processDashboardData(
        leads,
        users,
        proposalInput,
        adminResponse,
      );

      debugPrint(
        '📊 Processed dashboard data in ${stopwatch.elapsedMilliseconds}ms',
      );

      // Cache the results
      if (useCache) {
        await DataCacheService.cacheDashboardData(processedData);
      }

      return processedData;
    } catch (e) {
      debugPrint('❌ Error fetching dashboard data: $e');
      rethrow;
    }
  }

  /// Fetch users with caching
  static Future<List<Map<String, dynamic>>> fetchUsersOptimized({
    bool useCache = true,
  }) async {
    try {
      // Try to get from cache first
      if (useCache) {
        final cachedUsers = await DataCacheService.getCachedUsers();
        if (cachedUsers != null) {
          debugPrint('⚡ Using cached users data');
          return cachedUsers;
        }
      }

      debugPrint('🔄 Fetching users from Supabase...');

      final usersResult = await _client
          .from('users')
          .select('id, username, email, role')
          .timeout(const Duration(seconds: 15));

      debugPrint('📊 Fetched ${usersResult.length} users');

      // Cache the results
      if (useCache && usersResult.isNotEmpty) {
        await DataCacheService.cacheUsers(usersResult);
      }

      return List<Map<String, dynamic>>.from(usersResult);
    } catch (e) {
      debugPrint('❌ Error fetching users: $e');
      rethrow;
    }
  }

  /// Fetch proposal input data with caching
  static Future<List<Map<String, dynamic>>> fetchProposalInputOptimized({
    bool useCache = true,
  }) async {
    try {
      // Try to get from cache first
      if (useCache) {
        final cachedData = await DataCacheService.getCachedProposalInput();
        if (cachedData != null) {
          debugPrint('⚡ Using cached proposal input data');
          return cachedData;
        }
      }

      debugPrint('🔄 Fetching proposal input from Supabase...');

      final result = await _client
          .from('proposal_input')
          .select('lead_id, input, value')
          .timeout(const Duration(seconds: 15));

      debugPrint('📊 Fetched ${result.length} proposal input records');

      // Cache the results
      if (useCache && result.isNotEmpty) {
        await DataCacheService.cacheProposalInput(result);
      }

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('❌ Error fetching proposal input: $e');
      rethrow;
    }
  }

  /// Fetch admin response data with caching
  static Future<List<Map<String, dynamic>>> fetchAdminResponseOptimized({
    bool useCache = true,
  }) async {
    try {
      // Try to get from cache first
      if (useCache) {
        final cachedData = await DataCacheService.getCachedAdminResponse();
        if (cachedData != null) {
          debugPrint('⚡ Using cached admin response data');
          return cachedData;
        }
      }

      debugPrint('🔄 Fetching admin response from Supabase...');

      final result = await _client
          .from('admin_response')
          .select('lead_id, rate_sqm, status, remark')
          .timeout(const Duration(seconds: 15));

      debugPrint('📊 Fetched ${result.length} admin response records');

      // Cache the results
      if (useCache && result.isNotEmpty) {
        await DataCacheService.cacheAdminResponse(result);
      }

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('❌ Error fetching admin response: $e');
      rethrow;
    }
  }

  /// Fetch leads for dashboard with date filters
  static Future<List<Map<String, dynamic>>> _fetchLeadsForDashboard(
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    // Build query with filters first, then ordering
    dynamic query = _client.from('leads').select('''
          id, created_at, project_name, client_name, 
          project_location, lead_generated_by, lead_type
        ''');

    if (userId != null) {
      query = query.eq('lead_generated_by', userId);
    }

    if (startDate != null) {
      query = query.gte('created_at', startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.lte('created_at', endDate.toIso8601String());
    }

    // Add ordering after filters
    query = query.order('created_at', ascending: false);

    final result = await query.timeout(const Duration(seconds: 15));
    return List<Map<String, dynamic>>.from(result);
  }

  /// Process dashboard data efficiently
  static Future<Map<String, dynamic>> _processDashboardData(
    List<Map<String, dynamic>> leads,
    List<Map<String, dynamic>> users,
    List<Map<String, dynamic>> proposalInput,
    List<Map<String, dynamic>> adminResponse,
  ) async {
    // Create lookup maps for efficient processing
    final userMap = <String, String>{};
    for (final user in users) {
      userMap[user['id']] = user['username'] ?? '';
    }

    final proposalInputMap = <String, Map<String, dynamic>>{};
    for (final input in proposalInput) {
      final leadId = input['lead_id']?.toString();
      if (leadId != null) {
        final inputName = input['input']?.toString().toLowerCase() ?? '';
        final value = double.tryParse(input['value']?.toString() ?? '0') ?? 0;

        if (!proposalInputMap.containsKey(leadId)) {
          proposalInputMap[leadId] = {
            'aluminium_area': 0.0,
            'ms_weight_values': <double>[],
          };
        }

        if (inputName.contains('aluminium') || inputName.contains('alu')) {
          proposalInputMap[leadId]!['aluminium_area'] =
              (proposalInputMap[leadId]!['aluminium_area'] as double) + value;
        }

        if (inputName.contains('ms') || inputName.contains('ms wt.')) {
          final msWeightValues =
              proposalInputMap[leadId]!['ms_weight_values'] as List<double>;
          msWeightValues.add(value);
        }
      }
    }

    final adminResponseMap = <String, Map<String, dynamic>>{};
    for (final response in adminResponse) {
      final leadId = response['lead_id']?.toString();
      if (leadId != null) {
        adminResponseMap[leadId] = response;
      }
    }

    // Process leads with calculated data
    final processedLeads = <Map<String, dynamic>>[];
    for (final lead in leads) {
      final leadId = lead['id']?.toString();
      if (leadId != null) {
        final salesPersonName = userMap[lead['lead_generated_by']] ?? '';
        final adminResponseData = adminResponseMap[leadId];
        final proposalData = proposalInputMap[leadId];

        // Calculate MS Weight average
        final msWeightValues =
            proposalData?['ms_weight_values'] as List<double>? ?? [];
        final msWeightAverage = msWeightValues.isNotEmpty
            ? msWeightValues.reduce((a, b) => a + b) / msWeightValues.length
            : 0.0;

        processedLeads.add({
          'lead_id': leadId,
          'date': lead['created_at'],
          'project_name': lead['project_name'] ?? '',
          'client_name': lead['client_name'] ?? '',
          'project_location': lead['project_location'] ?? '',
          'sales_person_name': salesPersonName,
          'aluminium_area': proposalData?['aluminium_area'] ?? 0,
          'ms_weight': msWeightAverage,
          'rate_sqm': adminResponseData?['rate_sqm'] ?? 0,
          'approved': adminResponseData?['status'] == 'Approved',
          'total_amount': _calculateTotalAmount(
            proposalData?['aluminium_area'] ?? 0,
            adminResponseData?['rate_sqm'] ?? 0,
          ),
        });
      }
    }

    return {
      'leads': processedLeads,
      'total_leads': processedLeads.length,
      'total_amount': processedLeads
          .map((lead) => lead['total_amount'] as double)
          .fold(0.0, (sum, amount) => sum + amount),
    };
  }

  /// Calculate total amount with GST
  static double _calculateTotalAmount(double aluminiumArea, double rateSqm) {
    return aluminiumArea * rateSqm * 1.18; // Including 18% GST
  }

  /// Clear all caches
  static Future<void> clearAllCaches() async {
    await DataCacheService.clearAllCaches();
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return DataCacheService.getCacheStats();
  }
}
