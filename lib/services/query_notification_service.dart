import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class QueryNotificationService {
  static const String _unreadQueriesKey = 'unread_queries';

  /// Check if a lead has unread queries for the current user
  static Future<bool> hasUnreadQueries(String leadId, String userId) async {
    try {
      final client = Supabase.instance.client;

      // Get current user's username
      final userResult = await client
          .from('users')
          .select('username')
          .eq('id', userId)
          .single();

      final username = userResult['username'] as String?;
      if (username == null) return false;

      // The leadId should be the actual UUID from the leads table
      // If it's not a valid UUID, we can't proceed
      if (leadId.isEmpty || leadId == 'null') {
        debugPrint('Invalid leadId: $leadId');
        return false;
      }
      
      String actualLeadId = leadId;

      // Check if there are any queries for this lead where current user is the receiver
      final unreadQueries = await client
          .from('queries')
          .select('id')
          .eq('lead_id', actualLeadId)
          .eq('receiver_name', username);

      return unreadQueries.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking unread queries: $e');
      return false;
    }
  }

  /// Mark queries as read for a specific lead and user
  static Future<void> markQueriesAsRead(String leadId, String userId) async {
    try {
      // Update local cache to mark as read
      await _updateUnreadQueriesCache(leadId, userId, false);
    } catch (e) {
      debugPrint('Error marking queries as read: $e');
    }
  }

  /// Get unread query count for a specific lead and user
  static Future<int> getUnreadQueryCount(String leadId, String userId) async {
    try {
      final client = Supabase.instance.client;

      // Get current user's username
      final userResult = await client
          .from('users')
          .select('username')
          .eq('id', userId)
          .single();

      final username = userResult['username'] as String?;
      if (username == null) return 0;

      // The leadId should be the actual UUID from the leads table
      // If it's not a valid UUID, we can't proceed
      if (leadId.isEmpty || leadId == 'null') {
        debugPrint('Invalid leadId: $leadId');
        return 0;
      }
      
      String actualLeadId = leadId;

      // Get unread queries for this lead where current user is the receiver
      final unreadQueries = await client
          .from('queries')
          .select('id')
          .eq('lead_id', actualLeadId)
          .eq('receiver_name', username);

      return unreadQueries.length;
    } catch (e) {
      debugPrint('Error getting unread query count: $e');
      return 0;
    }
  }

  /// Get all unread query counts for a user across all leads
  static Future<Map<String, int>> getAllUnreadQueryCounts(String userId) async {
    try {
      final client = Supabase.instance.client;

      // Get current user's username
      final userResult = await client
          .from('users')
          .select('username')
          .eq('id', userId)
          .single();

      final username = userResult['username'] as String?;
      if (username == null) return {};

      final unreadQueries = await client
          .from('queries')
          .select('lead_id')
          .eq('receiver_name', username);

      final Map<String, int> counts = {};
      for (final query in unreadQueries) {
        final leadId = query['lead_id'].toString();
        counts[leadId] = (counts[leadId] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      debugPrint('Error getting all unread query counts: $e');
      return {};
    }
  }

  /// Update local cache for unread queries
  static Future<void> _updateUnreadQueriesCache(
    String leadId,
    String userId,
    bool hasUnread,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_unreadQueriesKey}_${userId}_$leadId';

      if (hasUnread) {
        await prefs.setBool(key, true);
      } else {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('Error updating unread queries cache: $e');
    }
  }

  /// Get cached unread status for a lead
  static Future<bool> getCachedUnreadStatus(
    String leadId,
    String userId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_unreadQueriesKey}_${userId}_$leadId';
      return prefs.getBool(key) ?? false;
    } catch (e) {
      debugPrint('Error getting cached unread status: $e');
      return false;
    }
  }

  /// Clear all cached unread status for a user
  static Future<void> clearUnreadCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith('${_unreadQueriesKey}_${userId}_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Error clearing unread cache: $e');
    }
  }
}
