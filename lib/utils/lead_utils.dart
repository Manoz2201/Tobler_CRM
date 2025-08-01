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
            'id, created_at, project_name, client_name, project_location, lead_generated_by',
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
          'status': adminResponseData?['status'] ?? 'New/Progress',
        });
      }

      return joinedLeads;
    } catch (e) {
      debugPrint('Error in fetchLeadsByUserId: $e');
      rethrow;
    }
  }

  /// Fetches leads for the active user from cache memory
  /// This function gets the user_id from SharedPreferences cache
  static Future<List<Map<String, dynamic>>> fetchLeadsForActiveUser() async {
    try {
      // Get cached user data
      final prefs = await SharedPreferences.getInstance();
      final cachedUserId = prefs.getString('user_id');
      final cachedSessionId = prefs.getString('session_id');
      final cachedSessionActive = prefs.getBool('session_active');

      debugPrint('[CACHE] Fetching leads for cached user_id: $cachedUserId');
      debugPrint('[CACHE] Session active: $cachedSessionActive');

      // Validate cache data
      if (cachedUserId == null || 
          cachedSessionId == null || 
          cachedSessionActive != true) {
        debugPrint('[CACHE] Invalid cache data, cannot fetch leads');
        throw Exception('No valid cached user session found');
      }

      // Fetch leads using cached user_id
      return await fetchLeadsByUserId(cachedUserId);
    } catch (e) {
      debugPrint('Error in fetchLeadsForActiveUser: $e');
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
          'status': adminResponseData?['status'] ?? 'New/Progress',
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
    if (lead['approved'] == true) {
      return 'Approved';
    }
    if (lead['rate_sqm'] != null && lead['rate_sqm'] > 0) {
      return 'Waiting for Approval';
    }
    if (lead['aluminium_area'] != null && lead['aluminium_area'] > 0) {
      return 'Proposal Progress';
    }
    return 'New/Progress';
  }

  /// Gets the color for a lead status
  static int getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return 0xFF4CAF50; // Green
      case 'Waiting for Approval':
        return 0xFFFF9800; // Orange
      case 'Proposal Progress':
        return 0xFF2196F3; // Blue
      case 'New/Progress':
        return 0xFF9E9E9E; // Grey
      default:
        return 0xFF9E9E9E; // Grey
    }
  }

  /// Calculates total amount for a lead
  static double calculateTotalAmount(double aluminiumArea, double rate) {
    return aluminiumArea * rate * 1.18; // Including GST
  }
}
