import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:pippidi/util/firebase.dart';
import 'dart:convert';
import 'package:pippidi/data/questions.dart';
import 'package:pippidi/util/constants.dart';
import 'package:pippidi/util/fcm_sync.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'user_manager.dart';
import 'user_data.dart';

class User {
  // Keep the old constants for backwards compatibility
  static const String BOXNAME = "user";
  static const String USERNAME = "USERNAME";
  static const String ID = "ID";
  static const String SCORE = "SCORE";
  static const String SCOREHISTORY = "SCOREHISTORY";
  static const String CORRECT = "CORRECT";
  static const String WRONG = "WRONG";
  static const String FIRSTTIME = "FIRSTTIME";
  static const String FRIENDS = "FRIENDS";
  static const String PROFILEPIC = "PROFILEPIC";
  static const String BADGES = "BADGES";
  static const String NONEGATIVEMARK = "NONEGATIVEMARK";
  static const int CORRECTANSWER = 100;
  static const int WRONGANSWER = -50;
  static const String FIRST_NOTIFICATION_PROMPT = "FIRST_NOTIFICATION_PROMPT";

  // Legacy properties removed - all data now accessed through UserManager

  // Firebase sync batching
  static Timer? _syncTimer;
  static const Duration _SYNC_INTERVAL = Duration(seconds: 30);
  static bool _needsSync = false;

  // Leaderboard update optimization
  static Timer? _leaderboardCheckTimer;
  static const Duration _LEADERBOARD_CHECK_INTERVAL = Duration(seconds: 60);
  static bool _leaderboardCheckPending = false;

  // Global leaderboard data storage
  static List _globalLeaderboard = [];

  // Cached profile picture bytes for current user
  static Uint8List? _currentUserProfilePicBytesCache;

  static final User _instance = User._internal();
  static UserManager? _userManager;
  static bool _initialized = false;

  factory User() {
    return _instance;
  }

  User._internal() {
    // Initialize will be called externally
  }

  static Future<void> initialize() async {
    if (_initialized) return;

    _userManager = UserManager.instance;
    await _userManager!.initialize();

    // Load legacy data for backwards compatibility
    _loadLegacyData();

    _initialized = true;
  }

  static void _loadLegacyData() {
    // Legacy data loading no longer needed since all getters use UserManager directly
  }

  // Public method to sync current user data to Firebase and perform leaderboard check
  void syncCurrentUser() {
    _syncNow();
    final user = _getCurrentUser();
    if (user != null) {
      _performLeaderboardCheckForUser(user.userId);
    }
  }

  // Public method to reload legacy data from current user
  void loadLegacyData() {
    _loadLegacyData();
  }

  // Helper method to get current user data
  static UserData? _getCurrentUser() {
    if (!_initialized || _userManager == null) return null;
    return _userManager!.currentUser;
  }

  // Helper method to update current user data
  static Future<void> _updateCurrentUser(UserData updatedUser) async {
    if (!_initialized || _userManager == null) return;
    await _userManager!.updateCurrentUser(updatedUser);
    _loadLegacyData(); // Refresh legacy properties
  }

  // Helper methods for badge rules to access current user's data
  static List<int> get _currentUserScoreHistory {
    return _getCurrentUser()?.scoreHistory ?? [];
  }

  static int get _currentUserScore {
    return _getCurrentUser()?.score ?? 0;
  }

  static void setNoNegativeMark(int count) {
    final user = _getCurrentUser();
    if (user != null) {
      final updatedUser =
          user.copyWith(noNegativeMarks: user.noNegativeMarks + count);
      _updateCurrentUser(updatedUser);
    }
  }

  void reduceNoNegativeMarkBy(int count) {
    final user = _getCurrentUser();
    if (user != null) {
      final updatedUser =
          user.copyWith(noNegativeMarks: user.noNegativeMarks - count);
      _updateCurrentUser(updatedUser);
    }
  }

  int get noNegativeMark {
    return _getCurrentUser()?.noNegativeMarks ?? 0;
  }

  int get consecutiveCorrectAnswers {
    return _getCurrentUser()?.consecutiveCorrectAnswers ?? 0;
  }

  int get skipCount {
    return _getCurrentUser()?.skipCount ?? 0;
  }

  String get name {
    return _getCurrentUser()?.name ?? '';
  }

  set name(String name) {
    final user = _getCurrentUser();
    if (user != null) {
      final updatedUser = user.copyWith(name: name);
      _updateCurrentUser(updatedUser);
    }
  }

  String get id {
    return _getCurrentUser()?.userId ?? '';
  }

  set id(String id) {
    // ID should not be changed after creation, but keep for compatibility
    // This would require switching users in UserManager
  }

  int get score {
    return _getCurrentUser()?.score ?? 0;
  }

  set score(int newscore) {
    final user = _getCurrentUser();
    if (user != null) {
      final updatedUser = user.copyWith(score: newscore);
      _updateCurrentUser(updatedUser);
    }

    // Schedule batched Firebase update
    _scheduleFirebaseSync();
  }

  int get correct {
    return _getCurrentUser()?.correct ?? 0;
  }

  void correctAns() {
    final user = _getCurrentUser();
    if (user != null) {
      final updatedScoreHistory = List<int>.from(user.scoreHistory)
        ..insert(0, 1);
      final newConsecutiveCorrect = user.consecutiveCorrectAnswers + 1;
      final newCorrectCount = user.correct + 1;
      // Award a skip every 10 consecutive correct answers
      final newSkipCount = user.skipCount +
          (newConsecutiveCorrect % Malayalam.SKIP_CORRECT_THRESHOLD == 0
              ? 1
              : 0);

      final updatedUser = user.copyWith(
        correct: newCorrectCount,
        scoreHistory: updatedScoreHistory,
        consecutiveCorrectAnswers: newConsecutiveCorrect,
        skipCount: newSkipCount,
      );
      _updateCurrentUser(updatedUser);
    }
  }

  int get wrong {
    return _getCurrentUser()?.wrong ?? 0;
  }

  void wrongAns() {
    final user = _getCurrentUser();
    if (user != null) {
      final updatedScoreHistory = List<int>.from(user.scoreHistory)
        ..insert(0, 0);
      final updatedUser = user.copyWith(
        wrong: user.wrong + 1,
        scoreHistory: updatedScoreHistory,
        consecutiveCorrectAnswers:
            0, // Reset consecutive correct answers on wrong answer
      );
      _updateCurrentUser(updatedUser);
    }
  }

  void useSkip() {
    final user = _getCurrentUser();
    if (user != null && user.skipCount > 0) {
      final updatedUser = user.copyWith(
        skipCount: user.skipCount - 1,
        consecutiveCorrectAnswers:
            0, // Reset consecutive counter after using skip
      );
      _updateCurrentUser(updatedUser);
    }
  }

  bool get firstTime {
    return _getCurrentUser()?.firstTime ?? true;
  }

  set firstTime(bool value) {
    final user = _getCurrentUser();
    if (user != null) {
      final updatedUser = user.copyWith(firstTime: value);
      _updateCurrentUser(updatedUser);
    }
  }

  String get profilepic {
    return _getCurrentUser()?.profilePicBase64 ?? '';
  }

  // Set profile picture from file path - converts to base64 and stores in Hive
  set profilepic(String filePath) {
    if (filePath.isNotEmpty) {
      try {
        File file = File(filePath);
        if (file.existsSync()) {
          List<int> bytes = file.readAsBytesSync();
          String base64String = base64Encode(bytes);

          final user = _getCurrentUser();
          if (user != null) {
            final updatedUser = user.copyWith(profilePicBase64: base64String);
            _updateCurrentUser(updatedUser);
          }
        }
      } catch (e) {
        print('Error converting profile picture to base64: $e');
      }
    } else {
      final user = _getCurrentUser();
      if (user != null) {
        final updatedUser = user.copyWith(profilePicBase64: '');
        _updateCurrentUser(updatedUser);
      }
    }
  }

  // Clear cached profile picture bytes (called when switching users)
  void clearProfilePicCache() {
    _currentUserProfilePicBytesCache = null;
  }

  // Get profile picture as Uint8List for display
  Uint8List? get profilePicBytes {
    final currentUser = _getCurrentUser();
    if (currentUser == null) {
      _currentUserProfilePicBytesCache = null;
      return null;
    }

    final profilePicBase64 = currentUser.profilePicBase64;
    if (profilePicBase64.isEmpty) {
      _currentUserProfilePicBytesCache = null;
      return null;
    }

    // Return cached bytes if available
    if (_currentUserProfilePicBytesCache != null) {
      return _currentUserProfilePicBytesCache;
    }

    // Decode and cache the bytes
    try {
      _currentUserProfilePicBytesCache = base64Decode(profilePicBase64);
      return _currentUserProfilePicBytesCache;
    } catch (e) {
      print('Error decoding profile picture: $e');
      return null;
    }
  }

  bool get firstNotificationPromptShown {
    return _getCurrentUser()?.firstNotificationPromptShown ?? false;
  }

  set firstNotificationPromptShown(bool value) {
    final user = _getCurrentUser();
    if (user != null) {
      final updatedUser = user.copyWith(firstNotificationPromptShown: value);
      _updateCurrentUser(updatedUser);
    }
  }

  void updateScore(bool correct, {String? category}) {
    final user = _getCurrentUser();
    if (user != null) {
      int newScore = user.score;
      int newNoNegativeMarks = user.noNegativeMarks;

      // Category-specific scoring
      int correctPoints, wrongPoints;
      if (category != null) {
        final scoring = Questions.getCategoryScoring(category);
        correctPoints = scoring['correct']!;
        wrongPoints = scoring['wrong']!;
      } else {
        correctPoints = CORRECTANSWER;
        wrongPoints = WRONGANSWER;
      }

      if (correct) {
        newScore += correctPoints;
        // Reset no negative marks protection completely when user gets correct answer
        newNoNegativeMarks = 0;
      } else {
        if (newNoNegativeMarks == 0) {
          newScore += wrongPoints;
        } else {
          newNoNegativeMarks--;
        }
      }

      // Call the appropriate answer method to update history
      if (correct) {
        correctAns();
      } else {
        wrongAns();
      }

      // Update the score again since correctAns/wrongAns don't handle score
      final finalUser = _getCurrentUser();
      if (finalUser != null) {
        final finalUpdatedUser = finalUser.copyWith(
            score: newScore, noNegativeMarks: newNoNegativeMarks);
        _updateCurrentUser(finalUpdatedUser);
      }
    }

    // Batch Firebase update - sync every 30 seconds or when app closes
    _scheduleFirebaseSync();

    // Schedule leaderboard check - only check periodically, not after every answer
    _scheduleLeaderboardCheck();

    bestowBadge(); // check if the user won any badge

    FirebaseAnalytics.instance.logPostScore(score: score);
    // Helper method (add at class end)
    void _directRequestPermission() async {
      await FirebaseMessaging.instance.getNotificationSettings();
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        await messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          // provisional: false (default—full popup for upgrade)
          sound: true,
        );
        await syncFCMToken(); // Re-sync for full access
      }
    }

    if (_currentUserScoreHistory.length == 3 && !firstNotificationPromptShown) {
      firstNotificationPromptShown = true;
      _directRequestPermission();
    }
  }

  List get friends {
    return _getCurrentUser()?.friends ?? [];
  }

  StreamController<String> friendAddtionUpdateController =
      StreamController<String>.broadcast();

  StreamController<bool> friendListRefreshController =
      StreamController<bool>.broadcast();

  StreamController<List> badgeWonController =
      StreamController<List>.broadcast();

  void dispose() {
    if (!friendAddtionUpdateController.isClosed) {
      friendAddtionUpdateController.close();
    }

    if (!friendListRefreshController.isClosed) {
      friendListRefreshController.close();
    }

    if (!badgeWonController.isClosed) {
      badgeWonController.close();
    }

    // Sync any pending changes before disposing
    _syncNow();
    _syncTimer?.cancel();

    // Perform any pending leaderboard checks
    if (_leaderboardCheckPending) {
      final user = _getCurrentUser();
      if (user != null) {
        _performLeaderboardCheckForUser(user.userId);
      }
    }
    _leaderboardCheckTimer?.cancel();
  }

  // Schedule Firebase sync with debouncing
  void _scheduleFirebaseSync() {
    _needsSync = true;

    // Cancel existing timer and create new one
    _syncTimer?.cancel();
    _syncTimer = Timer(_SYNC_INTERVAL, _syncNow);
  }

  // Immediately sync to Firebase
  void _syncNow() {
    final user = _getCurrentUser();
    if (!_needsSync || user == null || user.userId.isEmpty) return;

    _needsSync = false;
    _syncTimer?.cancel();

    try {
      Firebase.write('users/${user.userId}', {
        'score': user.score,
        'badge': user.badges.length,
        'name': user.name,
        'modifiedAt': DateTime.now().toIso8601String()
      });
    } catch (e) {
      // If sync fails, mark for retry
      _needsSync = true;
    }
  }

  // Schedule leaderboard check with debouncing
  void _scheduleLeaderboardCheck() {
    final user = _getCurrentUser();
    if (user == null) return;

    final score = user.score;
    final lastLeaderboardScore = user.lastLeaderboardScore;

    // Only schedule if score has changed significantly since last check
    const int SCORE_CHANGE_THRESHOLD =
        50; // Only check if score changed by 50+ points
    if ((score - lastLeaderboardScore).abs() < SCORE_CHANGE_THRESHOLD) {
      return;
    }

    _leaderboardCheckPending = true;

    // Cancel existing timer and create new one
    // Capture the current user ID at scheduling time
    final userIdToCheck = user.userId;
    _leaderboardCheckTimer?.cancel();
    _leaderboardCheckTimer = Timer(_LEADERBOARD_CHECK_INTERVAL,
        () => _performLeaderboardCheckForUser(userIdToCheck));
  }

  // Perform leaderboard check for a specific user
  void _performLeaderboardCheckForUser(String userId) async {
    // Get the specific user by ID, not the current user
    final user = UserManager.instance.getUser(userId);
    if (!_leaderboardCheckPending || user == null || user.userId.isEmpty)
      return;

    _leaderboardCheckPending = false;
    _leaderboardCheckTimer?.cancel();

    try {
      List currentLeaderboard = await Firebase().currentLeaderBoard();
      updateIfLeader(currentLeaderboard);

      // Update the user's last leaderboard score
      final updatedUser = user.copyWith(lastLeaderboardScore: user.score);
      await UserManager.instance.updateUserById(userId, updatedUser);
    } catch (e) {
      print('Leaderboard check failed: $e');
      // Retry after a shorter interval on failure
      _leaderboardCheckTimer = Timer(
          Duration(seconds: 30), () => _performLeaderboardCheckForUser(userId));
    }
  }

  void addFriend(String id) async {
    const oneSec = const Duration(seconds: 3);
    Timer _timer;
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) {
        friendAddtionUpdateController.add(Malayalam.friendChecking(id));
        timer.cancel();
      },
    );
    final fbuser = await Firebase().read(id);
    _timer.cancel();
    if (fbuser.isEmpty) {
      friendAddtionUpdateController.add(Malayalam.friendNotFound(id));
      return;
    }

    final user = _getCurrentUser();
    if (user != null) {
      // Check if friend already exists
      final existingFriends = List<Map<String, dynamic>>.from(user.friends);
      final found =
          existingFriends.where((element) => element[2] == fbuser["id"]);

      if (found.isNotEmpty) {
        final friend = fbuser["name"] + '(' + fbuser["id"] + ')';
        friendAddtionUpdateController.add(Malayalam.friendAdded(friend));
        return;
      }

      // Add new friend
      List f = [fbuser["name"], fbuser["score"], fbuser["id"], fbuser["badge"]];
      user.friends.add(f);

      final updatedUser = user.copyWith(friends: user.friends);
      await _updateCurrentUser(updatedUser);

      Firebase().addListener(f);

      final friend = fbuser["name"] + '(' + fbuser["id"] + ')';
      friendAddtionUpdateController.add(Malayalam.friendAdded(friend));
    }
  }

  set updateFriend(Map<String, dynamic> value) {
    final user = _getCurrentUser();
    if (user != null) {
      for (int i = 0; i < user.friends.length; i++) {
        if (user.friends[i][2] == value["id"]) {
          if (value.containsKey("score")) {
            user.friends[i][1] = value["score"];
          }
          if (value.containsKey("badge")) {
            user.friends[i][3] = value["badge"];
          }
          if (value.containsKey("name")) {
            user.friends[i][0] = value["name"];
          }

          final updatedUser = user.copyWith(friends: user.friends);
          _updateCurrentUser(updatedUser);
          return;
        }
      }
    }
  }

  set deleteFriend(String id) {
    final user = _getCurrentUser();
    if (user != null) {
      user.friends.removeWhere((friend) => friend[2] == id);

      final updatedUser = user.copyWith(friends: user.friends);
      _updateCurrentUser(updatedUser);

      // TODO stop firebase listen?
    }
  }

  List get leaderboard {
    final user = _getCurrentUser();
    if (user == null) return [];

    // Start with global leaderboard data (filter out null entries)
    List list = _globalLeaderboard.where((element) => element != null).toList();

    // Add current user if not already in the list
    bool userIncluded = list.any((element) => element[2] == user.userId);
    if (!userIncluded) {
      list.add([user.name, user.score, user.userId, user.badges.length]);
    }

    // Add friends if not already in the list
    for (var friend in user.friends) {
      bool friendIncluded = list.any((element) => element[2] == friend[2]);
      if (!friendIncluded) {
        list.add(friend);
      }
    }

    // Deduplicate by user ID, keeping the highest score for each user
    List deduped = [];
    Map<String, dynamic> userMap = {};
    list.forEach((element) {
      if (element.length <= 0) {
        return;
      }

      String userId = element[2];
      if (!userMap.containsKey(userId) || userMap[userId][1] < element[1]) {
        userMap[userId] = element;
      }
    });

    deduped = userMap.values.toList();

    // Sort by score descending
    deduped.sort((b, a) => a[1].compareTo(b[1]));
    return jsonDecode(jsonEncode(deduped));
  }

  // rules for giving out badges
  List<Map<String, dynamic>> _badgeRules = [
    {
      "key": "1",
      "name": "ഗംഭീരം",
      "description": "ആദ്യത്തെ ശരി ഉത്തരത്തിന്",
      "rule": () {
        // proceed iff this badge is not won already
        // check _scoreHistory for a match
        // if match, assign the badge - update the local cache and firebase
        // return intimation string
        if (isBadgeWon("1")) {
          return "";
        }

        if (_currentUserScoreHistory.isNotEmpty &&
            _currentUserScoreHistory.first == 1) {
          addBadge("1");
          return Malayalam.badgeWonText('1');
        }

        return "";
      },
      "progress": () {
        if (_currentUserScoreHistory.isNotEmpty &&
            _currentUserScoreHistory.first == 1) {
          return 1.0;
        }

        return 0.5; // special case
      },
      "progressCaption": "ആദ്യത്തെ ശരി ഉത്തരം നേടുമ്പോൾ",
      "badgeIconCode": 0xf3bb, // spa_outline
    },
    {
      "key": "2",
      "name": "അതിഗംഭീരം",
      "description": "തുടർച്ചയായ മൂന്ന് ശരി ഉത്തരത്തിന്",
      "rule": () {
        if (isBadgeWon("2")) {
          return "";
        }

        if (continuousAnswer(3) == false) {
          return "";
        }

        addBadge("2");
        setNoNegativeMark(1);
        return "അതിഗംഭീരം! അടുപ്പിച്ച് മൂന്ന് ശരിയുത്തരം";
      },
      "progress": () {
        return nearnessToContinuousAnswer(3);
      },
      "progressCaption": "തുടർച്ചയായ മൂന്ന് ശരി ഉത്തരം നേടുമ്പോൾ",
      "badgeIconCode": 0xef32, // casino_outline
    },
    {
      "key": "8",
      "name": "പൊളി",
      "description": "ആയിരം പോയിന്റ് നേടിയതിന്",
      "rule": () {
        if (isBadgeWon("8")) {
          return "";
        }

        if (_currentUserScore < 1000) {
          return "";
        }

        addBadge("8");
        setNoNegativeMark(2);
        return "പൊളി! ആയിരം പോയിന്റ് നേടി";
      },
      "progress": () {
        return nearnessToScore(1000);
      },
      "progressCaption": "ആയിരം പോയിന്റ് നേടുമ്പോൾ",
      "badgeIconCode": 0xf3db, // stairs_outline
    },
    {
      "key": "3",
      "name": "അടിപൊളി",
      "description": "തുടർച്ചയായ അഞ്ച് ശരി ഉത്തരത്തിന്",
      "rule": () {
        if (isBadgeWon("3")) {
          return "";
        }

        if (continuousAnswer(5) == false) {
          return "";
        }

        addBadge("3");
        setNoNegativeMark(2);
        return "അടിപൊളി! അടുപ്പിച്ച് അഞ്ച് ശരിയുത്തരം";
      },
      "progress": () {
        return nearnessToContinuousAnswer(5);
      },
      "progressCaption": "തുടർച്ചയായ അഞ്ച് ശരി ഉത്തരം നേടുമ്പോൾ",
      "badgeIconCode": 0xf31b, // rice_bowl_outline
    },
    {
      "key": "9",
      "name": "കിടു",
      "description": "രണ്ടായിരം പോയിന്റ് നേടിയതിന്",
      "rule": () {
        if (isBadgeWon("9")) {
          return "";
        }

        if (_currentUserScore < 2000) {
          return "";
        }

        addBadge("9");
        setNoNegativeMark(2);
        return "കിടു! രണ്ടായിരം പോയിന്റ് നേടി";
      },
      "progress": () {
        return nearnessToScore(2000);
      },
      "progressCaption": "രണ്ടായിരം പോയിന്റ് നേടുമ്പോൾ",
      "badgeIconCode": 0xf0bd, // gamepad_outline
    },
    {
      "key": "4",
      "name": "കിക്കിടു",
      "description": "തുടർച്ചയായ പത്ത് ശരി ഉത്തരത്തിന്",
      "rule": () {
        if (isBadgeWon("4")) {
          return "";
        }

        if (continuousAnswer(10) == false) {
          return "";
        }

        addBadge("4");
        setNoNegativeMark(3);
        return "കിക്കിടു! അടുപ്പിച്ച് പത്ത് ശരിയുത്തരം";
      },
      "progress": () {
        return nearnessToContinuousAnswer(10);
      },
      "progressCaption": "അടുപ്പിച്ച് പത്ത് ശരിയുത്തരം നേടുമ്പോൾ",
      "badgeIconCode": 0xf116, // houseboat_outline
    },
    {
      "key": "10",
      "name": "ബല്ലേ ബല്ലേ",
      "description": "അയ്യായിരം പോയിന്റ് നേടിയതിന്",
      "rule": () {
        if (isBadgeWon("10")) {
          return "";
        }

        if (_currentUserScore < 5000) {
          return "";
        }

        addBadge("10");
        setNoNegativeMark(2);
        return "ബല്ലേ ബല്ലേ! അയ്യായിരം പോയിന്റ് നേടി.";
      },
      "progress": () {
        return nearnessToScore(5000);
      },
      "progressCaption": "അയ്യായിരം പോയിന്റ് നേടുമ്പോൾ",
      "badgeIconCode": 0xf456, // track changes_outline
    },
    {
      "key": "12",
      "name": "എന്റമ്മോ",
      "description": "തുടർച്ചയായ ഇരുപത് ശരി ഉത്തരത്തിന്",
      "rule": () {
        if (isBadgeWon("12")) {
          return "";
        }

        if (continuousAnswer(20) == false) {
          return "";
        }

        addBadge("12");
        setNoNegativeMark(3);
        return "എന്റമ്മോ! അടുപ്പിച്ച് ഇരുപത് ശരിയുത്തരം.";
      },
      "progress": () {
        return nearnessToContinuousAnswer(20);
      },
      "progressCaption": "തുടർച്ചയായ ഇരുപത് ശരി ഉത്തരം നേടുമ്പോൾ",
      "badgeIconCode": 0xefe8, // donut large_outline
    },
    {
      "key": "11",
      "name": "തങ്കപ്പൻ",
      "description": "പതിനായിരം പോയിന്റ് നേടിയതിന്",
      "rule": () {
        if (isBadgeWon("11")) {
          return "";
        }

        if (_currentUserScore < 10000) {
          return "";
        }

        addBadge("11");
        setNoNegativeMark(3);
        return "തങ്കപ്പൻ! പതിനായിരം പോയിന്റ് നേടി";
      },
      "progress": () {
        return nearnessToScore(10000);
      },
      "progressCaption": "പതിനായിരം പോയിന്റ് നേടുമ്പോൾ",
      "badgeIconCode": 0xef03, // bubble chart_outline
    },
    {
      "key": "5",
      "name": "പൊന്നപ്പൻ",
      "description": "തുടർച്ചയായ അമ്പത് ശരി ഉത്തരത്തിന്",
      "rule": () {
        if (isBadgeWon("5")) {
          return "";
        }

        if (continuousAnswer(50) == false) {
          return "";
        }

        addBadge("5");
        setNoNegativeMark(5);
        return "പൊന്നപ്പൻ! അടുപ്പിച്ച് അമ്പത് ശരിയുത്തരം";
      },
      "progress": () {
        return nearnessToContinuousAnswer(50);
      },
      "progressCaption": "തുടർച്ചയായ അമ്പത് ശരി ഉത്തരം നേടുമ്പോൾ",
      "badgeIconCode": 0xf0616, // hub_outline
    },
    {
      "key": "14",
      "name": "തമ്പുരാൻ",
      "description": "പതിനയ്യായിരം പോയിന്റ് നേടിയതിന്",
      "rule": () {
        if (isBadgeWon("14")) {
          return "";
        }

        if (_currentUserScore < 15000) {
          return "";
        }

        addBadge("14");
        setNoNegativeMark(3);
        return "തമ്പുരാൻ! പതിനയ്യായിരം പോയിന്റ് നേടി";
      },
      "progress": () {
        return nearnessToScore(15000);
      },
      "progressCaption": "പതിനയ്യായിരം പോയിന്റ് നേടുമ്പോൾ",
      "badgeIconCode": 0xf3dc, // star_outline
    },
    {
      "key": "13",
      "name": "കുമ്പിടി",
      "description": "തുടർച്ചയായ നൂറ് ശരി ഉത്തരത്തിന്",
      "rule": () {
        if (isBadgeWon("13")) {
          return "";
        }

        if (continuousAnswer(100) == false) {
          return "";
        }

        addBadge("13");
        setNoNegativeMark(10);
        return "കുമ്പിടി! അടുപ്പിച്ച് നൂറ് ശരിയുത്തരം";
      },
      "progress": () {
        return nearnessToContinuousAnswer(100);
      },
      "progressCaption": "തുടർച്ചയായ നൂറ് ശരി ഉത്തരം നേടുമ്പോൾ",
      "badgeIconCode": 0xf0682, // token_outline
    },
    {
      "key": "15",
      "name": "പുലി",
      "description": "ഇരുപതിനായിരം പോയിന്റ് നേടിയതിന്",
      "rule": () {
        if (isBadgeWon("15")) {
          return "";
        }

        if (_currentUserScore < 20000) {
          return "";
        }

        addBadge("15");
        setNoNegativeMark(3);
        return "പുലി! ഇരുപതിനായിരം പോയിന്റ് നേടി";
      },
      "progress": () {
        return nearnessToScore(20000);
      },
      "progressCaption": "ഇരുപതിനായിരം പോയിന്റ് നേടുമ്പോൾ",
      "badgeIconCode": 0xf06a1, // workspace premium_outline
    },
    {
      "key": "16",
      "name": "പുപ്പുലി",
      "description": "തുടർച്ചയായ ഇരുനൂറ് ശരി ഉത്തരത്തിന്",
      "rule": () {
        if (isBadgeWon("16")) {
          return "";
        }

        if (continuousAnswer(200) == false) {
          return "";
        }

        addBadge("16");
        setNoNegativeMark(20);
        return "പുപ്പുലി! അടുപ്പിച്ച് ഇരുനൂറ് ശരിയുത്തരം";
      },
      "progress": () {
        return nearnessToContinuousAnswer(200);
      },
      "progressCaption": "തുടർച്ചയായ ഇരുനൂറ് ശരി ഉത്തരം നേടുമ്പോൾ",
      "badgeIconCode": 0xf285, // pets_outline
    },
    {
      "key": "17",
      "name": "ബാഹുബലി",
      "description": "അമ്പതിനായിരം പോയിന്റ് നേടിയതിന്",
      "rule": () {
        if (isBadgeWon("17")) {
          return "";
        }

        if (_currentUserScore < 50000) {
          return "";
        }

        addBadge("17");
        setNoNegativeMark(10);
        return "ബാഹുബലി! അമ്പതിനായിരം പോയിന്റ് നേടി";
      },
      "progress": () {
        return nearnessToScore(50000);
      },
      "progressCaption": "അമ്പതിനായിരം പോയിന്റ് നേടുമ്പോൾ",
      "badgeIconCode": 0xf07a, // workspace premium_outline
    },
    {
      "key": "18",
      "name": "ഡിങ്കൻ",
      "description": "ഒരു ലക്ഷം പോയിന്റ് നേടിയതിന്",
      "rule": () {
        if (isBadgeWon("18")) {
          return "";
        }

        if (_currentUserScore < 100000) {
          return "";
        }

        addBadge("18");
        setNoNegativeMark(20);
        return "ഡിങ്കൻ! ഒരു ലക്ഷം പോയിന്റ് നേടി";
      },
      "progress": () {
        return nearnessToScore(100000);
      },
      "progressCaption": "ഒരു ലക്ഷം പോയിന്റ് നേടുമ്പോൾ",
      "badgeIconCode": 0xf0697, // workspace premium_outline
    },
  ];

  List get badges {
    return _getCurrentUser()?.badges ?? [];
  }

  static double nearnessToScore(int targetScore) {
    final user = UserManager.instance.currentUser;
    final score = user?.score ?? 0;

    if (score == 0 || score < 0) {
      return 0;
    }

    double p = score / targetScore;
    if (p < 0.05) {
      return 0.05;
    }

    return p;
  }

  static double nearnessToContinuousAnswer(int targetCount) {
    final user = UserManager.instance.currentUser;
    final scoreHistory = user?.scoreHistory ?? [];

    int correct = 0;
    for (int i = 0; i < scoreHistory.length; i++) {
      if (scoreHistory[i] == 0) {
        break;
      }

      if (scoreHistory[i] == 1) {
        correct++;
      }

      if (targetCount == correct) {
        break;
      }
    }

    if (correct == 0) {
      return 0;
    }

    double p = correct / targetCount;
    if (p < 0.05) {
      return 0.05;
    }

    return p;
  }

  List get badgeProgress {
    List progress = []; // [ [key, caption, progress] ]

    // Add skip counter badge if skipCount > 10
    if (skipCount > 10) {
      String skipCaption = "സ്കിപ്പ്: $skipCount ലഭ്യം";
      progress.add(
          ["skip_counter", skipCaption, 1.0, 0xe047]); // skip_next icon code
    }

    _badgeRules.asMap().forEach((key, rule) {
      if (!isBadgeWon(rule["key"])) {
        double p = rule['progress']();
        String caption = rule['name'] + " പതക്കം: " + rule['progressCaption'];
        progress.add([rule["key"], caption, p, rule["badgeIconCode"]]);
      }
    });

    return jsonDecode(jsonEncode(progress));
  }

  List get fullBadgeProgress {
    List progress = []; // [ [key, caption, progress] ]

    // Add skip counter badge if skipCount > 10
    if (skipCount > 10) {
      String skipCaption = "സ്കിപ്പ്: $skipCount ലഭ്യം";
      progress.add(
          ["skip_counter", skipCaption, 1.0, 0xe047]); // skip_next icon code
    }

    _badgeRules.asMap().forEach((key, rule) {
      if (!isBadgeWon(rule["key"])) {
        double p = rule['progress']();
        String caption = rule['name'] + " പതക്കം: " + rule['progressCaption'];
        progress.add([rule["key"], caption, p, rule["badgeIconCode"]]);
      } else {
        String caption = rule['name'] + " പതക്കം: " + rule['progressCaption'];
        progress.add([rule["key"], caption, 1.0, rule["badgeIconCode"]]);
      }
    });

    return jsonDecode(jsonEncode(progress));
  }

  List get sortedBadgeProgress {
    List badges = fullBadgeProgress;
    badges.sort((b, a) => a[2].compareTo(b[2]));
    return badges;
  }

  static void addBadge(String key) {
    final user = UserManager.instance.currentUser;
    if (user != null && !user.badges.contains(key)) {
      final updatedBadges = List<String>.from(user.badges)..add(key);
      final updatedUser = user.copyWith(badges: updatedBadges);
      UserManager.instance.updateCurrentUser(updatedUser);
    }
    // Schedule batched Firebase update
    _instance._scheduleFirebaseSync();
  }

  static bool isBadgeWon(String key) {
    final user = UserManager.instance.currentUser;
    return user?.badges.contains(key) ?? false;
  }

  List get badgeList {
    return _badgeRules;
  }

  void bestowBadge() {
    // when called, loops through badge rules
    // if match, assigns the badge
    // pushes out notification in the stream
    _badgeRules.asMap().forEach((key, value) {
      String result = value['rule']();
      if (result != "") {
        List won = [value['key'], result, value["badgeIconCode"]];
        badgeWonController.add(won);
      }
    });
  }

  static bool continuousAnswer(int count) {
    final user = UserManager.instance.currentUser;
    final scoreHistory = user?.scoreHistory ?? [];

    int correct = 0;
    for (int i = 0; i < scoreHistory.length; i++) {
      if (scoreHistory[i] == 0) {
        break;
      }

      if (scoreHistory[i] == 1) {
        correct++;
      }

      if (count == correct) {
        return true;
      }
    }

    if (correct != count) {
      return false;
    }

    return true;
  }

  static bool continuousWrong(int count) {
    final user = UserManager.instance.currentUser;
    final scoreHistory = user?.scoreHistory ?? [];

    int wrong = 0;
    for (int i = 0; i < scoreHistory.length; i++) {
      if (scoreHistory[i] == 1) {
        break;
      }

      if (scoreHistory[i] == 0) {
        wrong++;
      }

      if (count == wrong) {
        return true;
      }
    }

    if (wrong != count) {
      return false;
    }

    return true;
  }

  void updateLeader(int index, Map data) {
    // Ensure we have enough slots in the global leaderboard list
    while (_globalLeaderboard.length <= index) {
      _globalLeaderboard.add(null);
    }

    // Store the leader data at the specified index
    _globalLeaderboard[index] = [
      data['name'],
      data['score'],
      data['id'],
      data['badge'] ?? 0,
      index
    ];

    // Trigger UI update for leaderboard changes
    friendListRefreshController.add(true);
  }

  void updateIfLeader(List currentLeaderboard) async {
    final user = _getCurrentUser();
    if (user == null) return;

    List sorted = jsonDecode(jsonEncode(currentLeaderboard));
    // sort based on user ids
    sorted.sort((b, a) => a[1].compareTo(b[1]));
    // remove duplicate user ids [2]
    final seen = Set<String>();
    sorted = sorted.where((element) => seen.add(element[2])).toList();

    // find if i belong to the leaderboard
    // if yes, check if I already present in the leaderboard
    // if no, find a place to write my score
    bool amILeader = sorted.length < Firebase.LEADERBOARD ? true : false;
    int myPosition = -1;
    List<int> zeros = List.filled(Firebase.LEADERBOARD, 0);
    for (var i = 0; i < sorted.length; i++) {
      if (amILeader == false && user.score > sorted[i][1]) {
        amILeader = true;
      }

      if (myPosition == -1 && user.userId == sorted[i][2]) {
        myPosition = sorted[i][4];
      }

      zeros[sorted[i][4]] = 1;
    }

    if (!amILeader) {
      return;
    }

    // I am leader
    if (myPosition != -1) {
      // my score needs to be overwritten
      Firebase().setLeader(myPosition, {
        'name': user.name,
        'score': user.score,
        'id': user.userId,
        'badge': user.badges.length,
        'index': myPosition,
      });

      return;
    }

    // insert score if a position is found in the leaderboard
    for (var i = 0; i < zeros.length; i++) {
      if (zeros[i] == 0) {
        // update score with mine at index i
        Firebase().setLeader(i, {
          'name': user.name,
          'score': user.score,
          'id': user.userId,
          'badge': user.badges.length,
          'index': i,
        });

        return;
      }
    }

    // need to replace last position with my score
    Firebase().setLeader(sorted[Firebase.LEADERBOARD - 1][4], {
      'name': user.name,
      'score': user.score,
      'id': user.userId,
      'badge': user.badges.length,
      'index': sorted[Firebase.LEADERBOARD - 1][4],
    });

    return;
  }
}
