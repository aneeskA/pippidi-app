// ignore: uri_does_not_exist
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Utility class for custom error reporting and logging to enhance Android Vitals insights
class ErrorReporting {
  /// Log a non-fatal error with custom message and additional context
  static void logError(dynamic error, StackTrace? stackTrace,
      {String? message, Map<String, dynamic>? additionalData}) {
    try {
      // Set custom keys for better categorization in Firebase Console
      if (additionalData != null) {
        additionalData.forEach((key, value) {
          FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
        });
      }

      // Log custom message if provided
      if (message != null) {
        FirebaseCrashlytics.instance.log(message);
      }

      // Record the error (non-fatal)
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: false);
    } catch (e) {
      // Fallback logging if Crashlytics fails
      print('Error reporting failed: $e');
      print('Original error: $error');
      print('Stack trace: $stackTrace');
    }
  }

  /// Log a fatal error that caused app crash
  static void logFatalError(dynamic error, StackTrace? stackTrace,
      {String? message, Map<String, dynamic>? additionalData}) {
    try {
      // Set custom keys for better categorization
      if (additionalData != null) {
        additionalData.forEach((key, value) {
          FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
        });
      }

      // Log custom message if provided
      if (message != null) {
        FirebaseCrashlytics.instance.log(message);
      }

      // Record the fatal error
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
    } catch (e) {
      // Fallback logging if Crashlytics fails
      print('Fatal error reporting failed: $e');
      print('Original error: $error');
      print('Stack trace: $stackTrace');
    }
  }

  /// Log user actions for better context in crash reports
  static void logUserAction(String action, {Map<String, dynamic>? parameters}) {
    try {
      String logMessage = 'User Action: $action';
      if (parameters != null && parameters.isNotEmpty) {
        logMessage += ' - Parameters: $parameters';
      }
      FirebaseCrashlytics.instance.log(logMessage);

      // Set user action as custom key
      FirebaseCrashlytics.instance.setCustomKey('last_user_action', action);
      FirebaseCrashlytics.instance
          .setCustomKey('action_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      print('User action logging failed: $e');
    }
  }

  /// Set user identifier for crash reports (anonymized)
  static void setUserIdentifier(String userId) {
    try {
      FirebaseCrashlytics.instance.setUserIdentifier(userId);
    } catch (e) {
      print('Setting user identifier failed: $e');
    }
  }

  /// Set custom key-value pairs for crash context
  static void setCustomKey(String key, String value) {
    try {
      FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (e) {
      print('Setting custom key failed: $e');
    }
  }

  /// Log performance metrics for Android Vitals
  static void logPerformanceMetric(String metricName, int value,
      {String? unit}) {
    try {
      String logMessage = 'Performance Metric: $metricName = $value';
      if (unit != null) {
        logMessage += ' $unit';
      }
      FirebaseCrashlytics.instance.log(logMessage);
      FirebaseCrashlytics.instance
          .setCustomKey('perf_$metricName', value.toString());
    } catch (e) {
      print('Performance metric logging failed: $e');
    }
  }

  /// Log app lifecycle events
  static void logAppLifecycleEvent(String event,
      {Map<String, dynamic>? context}) {
    try {
      String logMessage = 'App Lifecycle: $event';
      if (context != null && context.isNotEmpty) {
        logMessage += ' - Context: $context';
      }
      FirebaseCrashlytics.instance.log(logMessage);
      FirebaseCrashlytics.instance.setCustomKey('app_lifecycle_event', event);
      FirebaseCrashlytics.instance.setCustomKey(
          'lifecycle_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      print('App lifecycle logging failed: $e');
    }
  }
}
