import 'package:supabase_flutter/supabase_flutter.dart';

class UserManagementService {
  static final client = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> fetchUsers() async {
    try {
      final data = await client
          .from('user_management')
          .select('*')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  static Future<void> addUser({
    required String userName,
    required String userType,
    required String status,
    required String screenName,
    required String screenType,
    required String description,
  }) async {
    try {
      await client.from('user_management').insert({
        'user_name': userName,
        'user_type': userType,
        'status': status,
        'screen_name': screenName,
        'screen_type': screenType,
        'description': description,
      });
    } catch (e) {
      throw Exception('Failed to add user');
    }
  }

  static Future<void> addUserRaw(Map<String, dynamic> user) async {
    try {
      await client.from('user_management').insert(user);
    } catch (e) {
      throw Exception('Failed to duplicate user');
    }
  }

  static Future<void> updateUser({
    required String id,
    required String userName,
    required String userType,
    required String status,
    required String screenName,
    required String screenType,
    required String description,
  }) async {
    try {
      await client
          .from('user_management')
          .update({
            'user_name': userName,
            'user_type': userType,
            'status': status,
            'screen_name': screenName,
            'screen_type': screenType,
            'description': description,
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to update user');
    }
  }

  static Future<void> deleteUser(String id) async {
    try {
      await client.from('user_management').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete user');
    }
  }

  static Future<Map<String, dynamic>?> fetchUserById(String id) async {
    try {
      final data = await client
          .from('user_management')
          .select('*')
          .eq('id', id)
          .single();
      return Map<String, dynamic>.from(data);
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateUserRaw(
    String id,
    Map<String, dynamic> user,
  ) async {
    try {
      // Only include non-null, non-empty values
      final cleanData = <String, dynamic>{};
      user.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty && key != 'id' && key != 'created_at') {
          cleanData[key] = value;
        }
      });
      
      // Only update if there are fields to update
      if (cleanData.isNotEmpty) {
        await client.from('user_management').update(cleanData).eq('id', id);
      }
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }
}
