import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:pippidi/data/user.dart';
import 'package:pippidi/util/firebase.dart' as fb;

// Public reusable function to sync FCM token (accepts optional provided token for refreshes)
Future<void> syncFCMToken([String? providedToken]) async {
  try {
    final userId = User().id;
    if (userId.isEmpty) {
      print('User ID not available yet, skipping FCM token sync');
      return;
    }

    String? token =
        providedToken ?? await FirebaseMessaging.instance.getToken();
    if (token != null && token.isNotEmpty) {
      await fb.Firebase.write('users/$userId', {'fcmToken': token});
    } else {
      print('No valid FCM token available for sync');
    }
  } catch (e) {
    print('Error syncing FCM token: $e');
    // Optional: ErrorReporting.logError(e, StackTrace.current, message: 'FCM sync failed');
  }
}
