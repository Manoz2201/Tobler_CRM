import 'dart:io';

class TimezoneUtils {
  static bool _isInitialized = false;
  static String? _currentTimezone;
  static double _timezoneOffset = 0.0;

  /// Initialize timezone data and detect current timezone
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Detect current timezone
      await _detectCurrentTimezone();

      _isInitialized = true;
    } catch (e) {
      // Fallback to UTC
      _currentTimezone = 'UTC';
      _timezoneOffset = 0.0;
    }
  }

  /// Detect current timezone based on platform
  static Future<void> _detectCurrentTimezone() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // For mobile, use device timezone
        final now = DateTime.now();
        final offset = now.timeZoneOffset;
        final offsetHours = offset.inHours;
        final offsetMinutes = offset.inMinutes % 60;

        _timezoneOffset = offset.inMinutes / 60.0;

        // Map common timezone offsets to timezone names
        if (offsetHours == 5 && offsetMinutes == 30) {
          _currentTimezone = 'Asia/Kolkata'; // India
        } else if (offsetHours == 0) {
          _currentTimezone = 'UTC';
        } else if (offsetHours == -5) {
          _currentTimezone = 'America/New_York';
        } else if (offsetHours == -8) {
          _currentTimezone = 'America/Los_Angeles';
        } else if (offsetHours == 1) {
          _currentTimezone = 'Europe/London';
        } else {
          // Create custom timezone based on offset
          _currentTimezone =
              'Custom_${offsetHours > 0 ? '+' : ''}$offsetHours:${offsetMinutes.toString().padLeft(2, '0')}';
        }
      } else {
        // For web/desktop, try to detect from browser/system
        _currentTimezone = 'UTC';
        _timezoneOffset = 0.0;
      }
    } catch (e) {
      _currentTimezone = 'UTC';
      _timezoneOffset = 0.0;
    }
  }

  /// Get current timezone name
  static String getCurrentTimezone() {
    return _currentTimezone ?? 'UTC';
  }

  /// Convert UTC datetime to local timezone
  static DateTime convertToLocal(DateTime utcDateTime) {
    if (!_isInitialized) {
      return utcDateTime;
    }

    try {
      // Simple timezone offset calculation
      final offset = getTimezoneOffset();
      final offsetHours = offset.floor();
      final offsetMinutes = ((offset - offsetHours) * 60).round();

      final localDateTime = utcDateTime.add(
        Duration(hours: offsetHours, minutes: offsetMinutes),
      );
      return localDateTime;
    } catch (e) {
      return utcDateTime;
    }
  }

  /// Convert local datetime to UTC
  static DateTime convertToUTC(DateTime localDateTime) {
    if (!_isInitialized) {
      return localDateTime;
    }

    try {
      // Simple timezone offset calculation
      final offset = getTimezoneOffset();
      final offsetHours = offset.floor();
      final offsetMinutes = ((offset - offsetHours) * 60).round();

      final utcDateTime = localDateTime.subtract(
        Duration(hours: offsetHours, minutes: offsetMinutes),
      );
      return utcDateTime;
    } catch (e) {
      return localDateTime;
    }
  }

  /// Get timezone offset in hours
  static double getTimezoneOffset() {
    if (!_isInitialized) return 0.0;
    return _timezoneOffset;
  }

  /// Format datetime with timezone info
  static String formatWithTimezone(DateTime dateTime) {
    if (!_isInitialized) {
      return dateTime.toIso8601String();
    }

    try {
      final offset = getTimezoneOffset();
      final offsetString = offset >= 0
          ? '+${offset.toStringAsFixed(2)}'
          : offset.toStringAsFixed(2);
      return '${dateTime.toIso8601String()} ($_currentTimezone $offsetString)';
    } catch (e) {
      return dateTime.toIso8601String();
    }
  }

  /// Check if two datetimes are in the same timezone
  static bool isSameTimezone(DateTime dateTime1, DateTime dateTime2) {
    return dateTime1.timeZoneOffset == dateTime2.timeZoneOffset;
  }

  /// Get timezone info for debugging
  static Map<String, dynamic> getTimezoneInfo() {
    return {
      'timezone': _currentTimezone,
      'offset_hours': getTimezoneOffset(),
      'is_initialized': _isInitialized,
      'current_time_local': DateTime.now().toString(),
      'current_time_utc': DateTime.now().toUtc().toString(),
    };
  }
}
