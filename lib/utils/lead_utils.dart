import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeadUtils {
  /// Fetches leads for a specific user ID from Supabase
  /// This function filters leads by the lead_generated_by field
  static Future<List<Map<String, dynamic>>> fetchLeadsByUserId(
    String userId,
  ) async {
    try {
      final client = Supabase.instance.client;

      // Fetch leads data for the specific user
      final leadsResult = await client
          .from('leads')
          .select(
            'id, created_at, project_name, client_name, project_location, lead_generated_by, lead_type',
          )
          .eq('lead_generated_by', userId) // Filter by user ID
          .order('created_at', ascending: false);

      // Fetch proposal_input data for Area and MS Weight
      final proposalInputResult = await client
          .from('proposal_input')
          .select('lead_id, input, value');

      // Fetch admin_response data for Rate sq/m and approval status
      final adminResponseResult = await client
          .from('admin_response')
          .select('lead_id, rate_sqm, status, remark');

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
        final adminResponseData = adminResponseMap[leadId];

        // Calculate MS Weight average
        final msWeights = msWeightMap[leadId] ?? [];
        final msWeightAverage = msWeights.isNotEmpty
            ? msWeights.reduce((a, b) => a + b) / msWeights.length
            : 0.0;

        // Calculate total amount
        final aluminiumArea = aluminiumAreaMap[leadId] ?? 0;
        final rate = adminResponseData?['rate_sqm'] ?? 0;
        final totalAmount = aluminiumArea * rate * 1.18; // Including GST

        joinedLeads.add({
          'lead_id': leadId,
          'date': lead['created_at'],
          'project_name': lead['project_name'] ?? '',
          'client_name': lead['client_name'] ?? '',
          'project_location': lead['project_location'] ?? '',
          'aluminium_area': aluminiumArea,
          'ms_weight': msWeightAverage,
          'rate_sqm': rate,
          'total_amount': totalAmount,
          'approved': adminResponseData?['status'] == 'Approved',
          'status': adminResponseData?['status'] ?? 'New',
        });
      }

      return joinedLeads;
    } catch (e) {
      debugPrint('Error in fetchLeadsByUserId: $e');
      rethrow;
    }
  }

  /// Fetches all leads (for admin users)
  static Future<List<Map<String, dynamic>>> fetchAllLeads() async {
    try {
      final client = Supabase.instance.client;

      // Fetch all leads data
      final leadsResult = await client
          .from('leads')
          .select(
            'id, created_at, project_name, client_name, project_location, lead_generated_by, lead_type',
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

        // Calculate total amount
        final aluminiumArea = aluminiumAreaMap[leadId] ?? 0;
        final rate = adminResponseData?['rate_sqm'] ?? 0;
        final totalAmount = aluminiumArea * rate * 1.18; // Including GST

        joinedLeads.add({
          'lead_id': leadId,
          'date': lead['created_at'],
          'project_name': lead['project_name'] ?? '',
          'client_name': lead['client_name'] ?? '',
          'project_location': lead['project_location'] ?? '',
          'sales_person_name': salesPersonName,
          'aluminium_area': aluminiumArea,
          'ms_weight': msWeightAverage,
          'rate_sqm': rate,
          'total_amount': totalAmount,
          'approved': adminResponseData?['status'] == 'Approved',
          'status': adminResponseData?['status'] ?? 'New',
        });
      }

      return joinedLeads;
    } catch (e) {
      debugPrint('Error in fetchAllLeads: $e');
      rethrow;
    }
  }

  /// Gets the status of a lead based on its data
  static String getLeadStatus(Map<String, dynamic> lead) {
    // Check if lead is approved (found in admin_response table)
    if (lead['approved'] == true) {
      return 'Approved';
    }

    // Check if lead has proposal input (found in proposal_input table)
    if (lead['aluminium_area'] != null && lead['aluminium_area'] > 0) {
      return 'Waiting for Approval';
    }

    // Check if lead is within 12 hours of creation
    final createdAt = lead['date'];
    if (createdAt != null) {
      final DateTime leadDate = createdAt is String
          ? DateTime.parse(createdAt)
          : createdAt as DateTime;
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(leadDate);

      if (difference.inHours <= 12) {
        return 'New';
      }
    }

    // Default status
    return 'Proposal Progress';
  }

  /// Gets the color for a lead status
  static int getStatusColor(String status) {
    switch (status) {
      case 'New':
        return 0xFF4CAF50; // Vibrant green (matching New card icon)
      case 'Proposal Progress':
        return 0xFFFF9800; // Vibrant orange (matching Proposal Progress card icon)
      case 'Waiting for Approval':
        return 0xFF9C27B0; // Vibrant purple (matching Waiting Approval card icon)
      case 'Approved':
        return 0xFF4CAF50; // Vibrant green (matching Approved card icon)
      default:
        return 0xFF9E9E9E; // Grey
    }
  }

  /// Calculates total amount for a lead
  static double calculateTotalAmount(double aluminiumArea, double rate) {
    return aluminiumArea * rate * 1.18; // Including GST
  }

  /// Fetches leads for the active user from cache memory
  /// This function gets the user_id from SharedPreferences cache and fetches their leads
  static Future<List<Map<String, dynamic>>> fetchLeadsForActiveUser() async {
    try {
      // Import SharedPreferences for cache access
      final prefs = await SharedPreferences.getInstance();

      // Get cached user_id from memory
      final cachedUserId = prefs.getString('user_id');
      final cachedSessionId = prefs.getString('session_id');
      final cachedSessionActive = prefs.getBool('session_active');
      final cachedUserType = prefs.getString('user_type');

      debugPrint('[CACHE] Cached user_id: $cachedUserId');
      debugPrint('[CACHE] Cached session_id: $cachedSessionId');
      debugPrint('[CACHE] Cached session_active: $cachedSessionActive');
      debugPrint('[CACHE] Cached user_type: $cachedUserType');

      // Validate cache data
      if (cachedUserId == null ||
          cachedSessionId == null ||
          cachedSessionActive != true) {
        debugPrint('[CACHE] Invalid cache data, throwing error for fallback');
        throw Exception('Invalid cache data');
      }

      debugPrint('[CACHE] Using cached user_id: $cachedUserId');

      // Fetch leads using the cached user_id
      return await fetchLeadsByUserId(cachedUserId);
    } catch (e) {
      debugPrint('Error in fetchLeadsForActiveUser: $e');
      rethrow;
    }
  }
}
