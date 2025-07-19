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
}
