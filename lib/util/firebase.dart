import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:pippidi/data/user.dart';

class Firebase {
  static final db = FirebaseDatabase.instance.ref();
  static final auth = FirebaseAuth.instance;
  final List _streams = [];
  static final LEADERBOARD = 5;

  // Throttling for friend updates
  static Timer? _friendUpdateThrottleTimer;
  static const Duration _FRIEND_UPDATE_THROTTLE = Duration(milliseconds: 500);
  static bool _friendUpdatePending = false;

  // Local caching
  static List? _cachedLeaderboard;
  static DateTime? _leaderboardCacheTime;
  static const Duration _LEADERBOARD_CACHE_DURATION = Duration(minutes: 5);

  static Map<String, Map<String, dynamic>> _cachedUserData = {};
  static const Duration _USER_CACHE_DURATION = Duration(minutes: 10);

  // Offline queue management
  static final List<Map<String, dynamic>> _offlineQueue = [];
  static StreamSubscription? _connectivitySubscription;

  static Future<void> signInAnonymously() async {
    try {
      await auth.signInAnonymously();
      print("Signed in anonymously: ${auth.currentUser?.uid}");

      // Enable offline persistence for better offline support
      try {
        FirebaseDatabase.instance.setPersistenceEnabled(true);
        FirebaseDatabase.instance
            .setPersistenceCacheSizeBytes(10000000); // 10MB cache
      } catch (e) {
        print("Failed to enable offline persistence: $e");
      }
    } catch (e) {
      print("Anonymous sign-in error: $e");
    }
  }

  static Future<void> write(String path, Map<String, dynamic> data) async {
    final operation = {
      'path': path,
      'data': data,
      'timestamp': DateTime.now(),
      'attempts': 0,
    };

    try {
      await db.child(path).update(data);
      // Clear any queued operations for this path
      _offlineQueue.removeWhere((op) => op['path'] == path);
    } catch (e) {
      // Log to Crashlytics for monitoring
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Firebase write failed for path: $path',
        information: ['data: $data', 'auth_uid: ${auth.currentUser?.uid}'],
      );
      // Add to offline queue for retry
      _offlineQueue.add(operation);
      _processOfflineQueue();
      // Don't rethrow - operation is queued
    }
  }

  Future<Map<String, dynamic>> read(String id) async {
    // Check cache first
    if (_cachedUserData.containsKey(id)) {
      final cachedEntry = _cachedUserData[id]!;
      final cacheTime = cachedEntry['_cacheTime'] as DateTime?;
      if (cacheTime != null &&
          DateTime.now().difference(cacheTime) < _USER_CACHE_DURATION) {
        // Return cached data without '_cacheTime'
        final cachedData = Map<String, dynamic>.from(cachedEntry);
        cachedData.remove('_cacheTime');
        return cachedData;
      } else {
        // Remove expired cache entry
        _cachedUserData.remove(id);
      }
    }

    try {
      final snapshot = await db.child('users/$id').get();
      if (!snapshot.exists) {
        return {};
      }

      Map<String, dynamic> data = jsonDecode(jsonEncode(snapshot.value));
      data["id"] = id;

      // Cache the result
      final cachedData = Map<String, dynamic>.from(data);
      cachedData['_cacheTime'] = DateTime.now();
      _cachedUserData[id] = cachedData;

      return data;
    } catch (e) {
      print("firebase read error: $e");
      return {};
    }
  }

  Future currentLeaderBoard() async {
    // Return cached data if still fresh
    if (_cachedLeaderboard != null &&
        _leaderboardCacheTime != null &&
        DateTime.now().difference(_leaderboardCacheTime!) <
            _LEADERBOARD_CACHE_DURATION) {
      return _cachedLeaderboard!;
    }

    List currentLeaderBoard = [];
    for (int i = 0; i < LEADERBOARD; i++) {
      final snapshot = await db.child('top/${i}').get();
      if (!snapshot.exists) {
        continue;
      }

      Map data = jsonDecode(jsonEncode(snapshot.value));
      currentLeaderBoard.add([
        data["name"],
        data["score"],
        data["id"],
        data["badge"],
        data["index"]
      ]);
    }

    // Cache the result
    _cachedLeaderboard = List.from(currentLeaderBoard);
    _leaderboardCacheTime = DateTime.now();

    return currentLeaderBoard;
  }

  void activateListeners() {
    List friends = User().friends;
    friends.forEach((friend) {
      addListener(friend);
    });

    for (int i = 0; i < LEADERBOARD; i++) {
      leaderListener(i);
    }
  }

  void leaderListener(int index) {
    StreamSubscription stream =
        db.child('top/${index}').onValue.listen((event) {
      if (event.snapshot.value == null) {
        return;
      }

      final Map data = jsonDecode(jsonEncode(event.snapshot.value));
      // update leaderboard
      User().updateLeader(index, data);

      _throttledFriendUpdate(); // Reuse the same throttling for leaderboard updates
    });

    _streams.add(stream);
  }

  void addListener(List friend) {
    StreamSubscription stream =
        db.child('users/${friend[2]}/score').onValue.listen((event) {
      final int score = jsonDecode(jsonEncode(event.snapshot.value));
      User().updateFriend = <String, dynamic>{
        "id": friend[2],
        "score": score,
      };
      _throttledFriendUpdate();
    });

    _streams.add(stream);

    stream = db.child('users/${friend[2]}/badge').onValue.listen((event) {
      final int badge = jsonDecode(jsonEncode(event.snapshot.value));
      User().updateFriend = <String, dynamic>{
        "id": friend[2],
        "badge": badge,
      };
      _throttledFriendUpdate();
    });

    _streams.add(stream);

    stream = db.child('users/${friend[2]}/name').onValue.listen((event) {
      final String name = jsonDecode(jsonEncode(event.snapshot.value));
      User().updateFriend = <String, dynamic>{
        "id": friend[2],
        "name": name,
      };
      _throttledFriendUpdate();
    });

    _streams.add(stream);
  }

  // Throttle friend list refreshes to reduce UI rebuilds
  static void _throttledFriendUpdate() {
    _friendUpdatePending = true;

    if (_friendUpdateThrottleTimer?.isActive ?? false) {
      return; // Timer already running, just mark pending
    }

    _friendUpdateThrottleTimer = Timer(_FRIEND_UPDATE_THROTTLE, () {
      if (_friendUpdatePending) {
        _friendUpdatePending = false;
        User().friendListRefreshController.add(true);
      }
    });
  }

  void deactivateListeners() {
    _streams.forEach((stream) {
      stream.cancel();
    });

    // Clean up throttling timer
    _friendUpdateThrottleTimer?.cancel();
    _friendUpdatePending = false;

    // Clean up connectivity subscription
    _connectivitySubscription?.cancel();
  }

  // Clear caches when needed (e.g., when user logs out)
  static void clearCaches() {
    _cachedLeaderboard = null;
    _leaderboardCacheTime = null;
    _cachedUserData.clear();
  }

  // Force refresh leaderboard cache
  static void invalidateLeaderboardCache() {
    _cachedLeaderboard = null;
    _leaderboardCacheTime = null;
  }

  // Process offline queue when connectivity is restored
  static void _processOfflineQueue() {
    if (_offlineQueue.isEmpty) return;

    // Process queue in background
    Future.microtask(() async {
      final operationsToRetry = List.from(_offlineQueue);
      _offlineQueue.clear();

      for (final operation in operationsToRetry) {
        operation['attempts'] = (operation['attempts'] ?? 0) + 1;

        try {
          await db.child(operation['path']).update(operation['data']);
        } catch (e) {
          // Check if this is a permission error for FCM token writes (expected)
          final errorMessage = e.toString();
          final isFCMTokenWrite =
              operation['path']?.toString().contains('users/') == true &&
                  operation['data']?.toString().contains('fcm_token') == true;

          if (errorMessage.contains('permission-denied') && isFCMTokenWrite) {
            // Expected permission error for FCM tokens with anonymous auth
            // Don't log to Crashlytics as this is normal behavior
            print(
                'FCM token write failed due to permissions (expected with anonymous auth)');
          } else {
            // Log other unexpected errors to Crashlytics
            FirebaseCrashlytics.instance.recordError(
              e,
              StackTrace.current,
              reason:
                  'Queued Firebase operation failed after ${operation['attempts']} attempts',
              information: [
                'path: ${operation['path']}',
                'data: ${operation['data']}'
              ],
            );
          }

          // Re-queue if attempts < 3 and not too old
          final age = DateTime.now().difference(operation['timestamp']);
          if (operation['attempts'] < 3 && age.inHours < 24) {
            _offlineQueue.add(operation);
          } else {
            // Dropping failed operation
            FirebaseCrashlytics.instance.recordError(
              Exception('Dropped failed Firebase operation'),
              StackTrace.current,
              reason: 'Operation dropped after max attempts',
              information: [
                'path: ${operation['path']}',
                'attempts: ${operation['attempts']}'
              ],
            );
          }
        }

        // Small delay between operations
        await Future.delayed(Duration(milliseconds: 100));
      }
    });
  }

  // Check connectivity and process queue when online
  static void onConnectivityChanged(bool isOnline) {
    if (isOnline && _offlineQueue.isNotEmpty) {
      _processOfflineQueue();
    }
  }

  void setLeader(int index, Map<String, dynamic> data) {
    write('top/${index}', data);
  }
}
