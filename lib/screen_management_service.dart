import 'package:supabase_flutter/supabase_flutter.dart';

class ScreenManagementService {
  static const String supabaseUrl = 'https://vlapmwwroraolpgyfrtg.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsYXBtd3dyb3Jhb2xwZ3lmcnRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIwNDE3NzQsImV4cCI6MjA2NzYxNzc3NH0.3nyd2GT9DD_FMFTsJyiEqAjTIH7uREQ8R-dcamXwenQ';

  static final SupabaseClient client = SupabaseClient(
    supabaseUrl,
    supabaseAnonKey,
  );

  static Future<List<Map<String, dynamic>>> fetchScreens() async {
    final response = await client
        .from('users')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> addScreen({
    required String userName,
    required String userType,
    required String status,
    required String screenName,
    String? screenType,
    String? description,
  }) async {
    await client.from('users').insert({
      'user_name': userName,
      'user_type': userType,
      'status': status,
      'screen_name': screenName,
      'screen_type': screenType,
      'description': description,
    });
  }

  static Future<void> updateScreen({
    required String id,
    required String userName,
    required String userType,
    required String status,
    required String screenName,
    String? screenType,
    String? description,
  }) async {
    await client
        .from('users')
        .update({
          'user_name': userName,
          'user_type': userType,
          'status': status,
          'screen_name': screenName,
          'screen_type': screenType,
          'description': description,
        })
        .eq('id', id);
  }

  static Future<void> deleteScreen(String id) async {
    await client.from('users').delete().eq('id', id);
  }
}
