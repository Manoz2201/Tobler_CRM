import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class SupabaseDiagnostic {
  static final client = Supabase.instance.client;
  
  /// Comprehensive Supabase diagnostic test
  static Future<Map<String, dynamic>> runFullDiagnostic() async {
    final results = <String, dynamic>{};
    
    print('🔍 Starting Supabase Diagnostic...');
    
    // 1. Test basic connectivity
    results['connectivity'] = await testConnectivity();
    
    // 2. Test authentication
    results['authentication'] = await testAuthentication();
    
    // 3. Test table access
    results['table_access'] = await testTableAccess();
    
    // 4. Test RLS policies
    results['rls_policies'] = await testRLSPolicies();
    
    // 5. Test performance
    results['performance'] = await testPerformance();
    
    print('✅ Diagnostic completed');
    return results;
  }
  
  /// Test basic connectivity
  static Future<Map<String, dynamic>> testConnectivity() async {
    try {
      print('📡 Testing connectivity...');
      
      final startTime = DateTime.now();
      final response = await client
          .from('users')
          .select('count')
          .limit(1)
          .timeout(const Duration(seconds: 10));
      
      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;
      
      return {
        'status': 'success',
        'response_time_ms': responseTime,
        'message': 'Connection successful',
        'data': response
      };
      
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
        'error_type': _getErrorType(e.toString())
      };
    }
  }
  
  /// Test authentication
  static Future<Map<String, dynamic>> testAuthentication() async {
    try {
      print('🔐 Testing authentication...');
      
      final user = client.auth.currentUser;
      if (user != null) {
        return {
          'status': 'success',
          'user_id': user.id,
          'email': user.email,
          'message': 'User authenticated'
        };
      } else {
        return {
          'status': 'warning',
          'message': 'No authenticated user found'
        };
      }
      
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString()
      };
    }
  }
  
  /// Test table access
  static Future<Map<String, dynamic>> testTableAccess() async {
    final tables = [
      'users',
      'leads', 
      'lead_contacts',
      'lead_attachments',
      'lead_activity',
      'queries',
      'proposal_input',
      'proposal_file',
      'proposal_remark',
      'admin_response',
      'invitation',
      'system_config'
    ];
    
    final results = <String, Map<String, dynamic>>{};
    
    for (final table in tables) {
      try {
        final response = await client
            .from(table)
            .select('count')
            .limit(1)
            .timeout(const Duration(seconds: 5));
        
        results[table] = {
          'status': 'success',
          'accessible': true,
          'data': response
        };
        
      } catch (e) {
        results[table] = {
          'status': 'error',
          'accessible': false,
          'message': e.toString(),
          'error_type': _getErrorType(e.toString())
        };
      }
    }
    
    return results;
  }
  
  /// Test RLS policies
  static Future<Map<String, dynamic>> testRLSPolicies() async {
    try {
      print('🛡️ Testing RLS policies...');
      
      // Test if user can access their own data
      final user = client.auth.currentUser;
      if (user != null) {
        final ownData = await client
            .from('users')
            .select('id, username, email')
            .eq('id', user.id)
            .single();
        
        return {
          'status': 'success',
          'own_data_accessible': true,
          'user_data': ownData
        };
      } else {
        return {
          'status': 'warning',
          'message': 'No authenticated user to test RLS'
        };
      }
      
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString()
      };
    }
  }
  
  /// Test performance
  static Future<Map<String, dynamic>> testPerformance() async {
    try {
      print('⚡ Testing performance...');
      
      final startTime = DateTime.now();
      
      // Test multiple concurrent requests
      final futures = <Future>[];
      for (int i = 0; i < 5; i++) {
        futures.add(client
            .from('users')
            .select('count')
            .limit(1));
      }
      
      await Future.wait(futures);
      
      final endTime = DateTime.now();
      final totalTime = endTime.difference(startTime).inMilliseconds;
      
      return {
        'status': 'success',
        'concurrent_requests': 5,
        'total_time_ms': totalTime,
        'average_time_ms': totalTime / 5,
        'performance': totalTime < 1000 ? 'excellent' : 
                      totalTime < 3000 ? 'good' : 'poor'
      };
      
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString()
      };
    }
  }
  
  /// Get error type from error message
  static String _getErrorType(String error) {
    if (error.contains('timeout')) return 'timeout';
    if (error.contains('unauthorized')) return 'authentication';
    if (error.contains('not found')) return 'not_found';
    if (error.contains('permission')) return 'permission';
    if (error.contains('connection')) return 'connection';
    if (error.contains('network')) return 'network';
    return 'unknown';
  }
  
  /// Quick health check
  static Future<bool> quickHealthCheck() async {
    try {
      await client
          .from('users')
          .select('count')
          .limit(1)
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      print('❌ Health check failed: $e');
      return false;
    }
  }
  
  /// Print diagnostic results
  static void printResults(Map<String, dynamic> results) {
    print('\n📊 SUPABASE DIAGNOSTIC RESULTS');
    print('=' * 50);
    
    for (final entry in results.entries) {
      print('\n🔍 ${entry.key.toUpperCase()}:');
      
      if (entry.value is Map) {
        final data = entry.value as Map<String, dynamic>;
        for (final item in data.entries) {
          print('  ${item.key}: ${item.value}');
        }
      } else {
        print('  ${entry.value}');
      }
    }
    
    print('\n' + '=' * 50);
  }
  
  /// Generate recovery recommendations
  static List<String> getRecommendations(Map<String, dynamic> results) {
    final recommendations = <String>[];
    
    // Check connectivity issues
    if (results['connectivity']?['status'] == 'error') {
      recommendations.add('🔧 Check your internet connection');
      recommendations.add('🔧 Verify Supabase URL is correct');
      recommendations.add('🔧 Check if Supabase service is down');
    }
    
    // Check authentication issues
    if (results['authentication']?['status'] == 'error') {
      recommendations.add('🔐 Verify your API keys are correct');
      recommendations.add('🔐 Check if user session is valid');
      recommendations.add('🔐 Try logging out and back in');
    }
    
    // Check table access issues
    final tableAccess = results['table_access'] as Map<String, dynamic>?;
    if (tableAccess != null) {
      final failedTables = tableAccess.entries
          .where((entry) => entry.value['status'] == 'error')
          .map((entry) => entry.key)
          .toList();
      
      if (failedTables.isNotEmpty) {
        recommendations.add('🗄️ Check RLS policies for tables: ${failedTables.join(', ')}');
        recommendations.add('🗄️ Verify table schemas are correct');
        recommendations.add('🗄️ Check if tables exist in database');
      }
    }
    
    // Check performance issues
    final performance = results['performance'] as Map<String, dynamic>?;
    if (performance?['performance'] == 'poor') {
      recommendations.add('⚡ Consider optimizing database queries');
      recommendations.add('⚡ Check for long-running transactions');
      recommendations.add('⚡ Monitor connection pool usage');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('✅ All systems appear to be working correctly');
    }
    
    return recommendations;
  }
}

// Usage example:
// void main() async {
//   final results = await SupabaseDiagnostic.runFullDiagnostic();
//   SupabaseDiagnostic.printResults(results);
//   
//   final recommendations = SupabaseDiagnostic.getRecommendations(results);
//   for (final recommendation in recommendations) {
//     print(recommendation);
//   }
// } 