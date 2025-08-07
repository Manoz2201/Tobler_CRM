import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class DataCacheService {
  static const String _cachePrefix = 'data_cache_';
  static const Duration _defaultCacheDuration = Duration(minutes: 5);

  // Cache keys
  static const String _leadsCacheKey = 'leads';
  static const String _usersCacheKey = 'users';
  static const String _proposalInputCacheKey = 'proposal_input';
  static const String _adminResponseCacheKey = 'admin_response';
  static const String _dashboardDataCacheKey = 'dashboard_data';

  // In-memory cache for faster access
  static final Map<String, dynamic> _memoryCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};

  /// Cache data with timestamp
  static Future<void> cacheData(
    String key,
    dynamic data, {
    Duration? duration,
  }) async {
    final cacheKey = _cachePrefix + key;
    final expiryTime = DateTime.now().add(duration ?? _defaultCacheDuration);

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'timestamp': expiryTime.toIso8601String(),
      };

      await prefs.setString(cacheKey, jsonEncode(cacheData));

      // Update memory cache
      _memoryCache[cacheKey] = data;
      _cacheTimestamps[cacheKey] = expiryTime;

      debugPrint('📦 Cached data for key: $key (expires: $expiryTime)');
    } catch (e) {
      debugPrint('❌ Error caching data for key $key: $e');
    }
  }

  /// Get cached data if not expired
  static Future<dynamic> getCachedData(String key) async {
    final cacheKey = _cachePrefix + key;

    // Check memory cache first
    if (_memoryCache.containsKey(cacheKey)) {
      final expiryTime = _cacheTimestamps[cacheKey];
      if (expiryTime != null && DateTime.now().isBefore(expiryTime)) {
        debugPrint('⚡ Using memory cache for key: $key');
        return _memoryCache[cacheKey];
      } else {
        // Remove expired memory cache
        _memoryCache.remove(cacheKey);
        _cacheTimestamps.remove(cacheKey);
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString(cacheKey);

      if (cachedString != null) {
        final cachedData = jsonDecode(cachedString);
        final expiryTime = DateTime.parse(cachedData['timestamp']);

        if (DateTime.now().isBefore(expiryTime)) {
          // Update memory cache
          _memoryCache[cacheKey] = cachedData['data'];
          _cacheTimestamps[cacheKey] = expiryTime;

          debugPrint('📦 Using disk cache for key: $key');
          return cachedData['data'];
        } else {
          // Remove expired cache
          await prefs.remove(cacheKey);
          debugPrint('🗑️ Removed expired cache for key: $key');
        }
      }
    } catch (e) {
      debugPrint('❌ Error reading cache for key $key: $e');
    }

    return null;
  }

  /// Clear specific cache
  static Future<void> clearCache(String key) async {
    final cacheKey = _cachePrefix + key;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(cacheKey);

      // Clear memory cache
      _memoryCache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);

      debugPrint('🗑️ Cleared cache for key: $key');
    } catch (e) {
      debugPrint('❌ Error clearing cache for key $key: $e');
    }
  }

  /// Clear all caches
  static Future<void> clearAllCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          await prefs.remove(key);
        }
      }

      // Clear memory cache
      _memoryCache.clear();
      _cacheTimestamps.clear();

      debugPrint('🗑️ Cleared all caches');
    } catch (e) {
      debugPrint('❌ Error clearing all caches: $e');
    }
  }

  /// Check if cache is valid
  static Future<bool> isCacheValid(String key) async {
    final cachedData = await getCachedData(key);
    return cachedData != null;
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'memory_cache_size': _memoryCache.length,
      'memory_cache_keys': _memoryCache.keys.toList(),
      'cache_timestamps': _cacheTimestamps.map(
        (k, v) => MapEntry(k, v.toIso8601String()),
      ),
    };
  }

  // Specific cache methods for common data types
  static Future<void> cacheLeads(List<Map<String, dynamic>> leads) async {
    await cacheData(_leadsCacheKey, leads, duration: Duration(minutes: 3));
  }

  static Future<List<Map<String, dynamic>>?> getCachedLeads() async {
    final data = await getCachedData(_leadsCacheKey);
    return data != null ? List<Map<String, dynamic>>.from(data) : null;
  }

  static Future<void> cacheUsers(List<Map<String, dynamic>> users) async {
    await cacheData(_usersCacheKey, users, duration: Duration(minutes: 10));
  }

  static Future<List<Map<String, dynamic>>?> getCachedUsers() async {
    final data = await getCachedData(_usersCacheKey);
    return data != null ? List<Map<String, dynamic>>.from(data) : null;
  }

  static Future<void> cacheProposalInput(
    List<Map<String, dynamic>> proposalInput,
  ) async {
    await cacheData(
      _proposalInputCacheKey,
      proposalInput,
      duration: Duration(minutes: 5),
    );
  }

  static Future<List<Map<String, dynamic>>?> getCachedProposalInput() async {
    final data = await getCachedData(_proposalInputCacheKey);
    return data != null ? List<Map<String, dynamic>>.from(data) : null;
  }

  static Future<void> cacheAdminResponse(
    List<Map<String, dynamic>> adminResponse,
  ) async {
    await cacheData(
      _adminResponseCacheKey,
      adminResponse,
      duration: Duration(minutes: 5),
    );
  }

  static Future<List<Map<String, dynamic>>?> getCachedAdminResponse() async {
    final data = await getCachedData(_adminResponseCacheKey);
    return data != null ? List<Map<String, dynamic>>.from(data) : null;
  }

  static Future<void> cacheDashboardData(
    Map<String, dynamic> dashboardData,
  ) async {
    await cacheData(
      _dashboardDataCacheKey,
      dashboardData,
      duration: Duration(minutes: 2),
    );
  }

  static Future<Map<String, dynamic>?> getCachedDashboardData() async {
    final data = await getCachedData(_dashboardDataCacheKey);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }
}
