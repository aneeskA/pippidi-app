import 'package:hive_flutter/hive_flutter.dart';
import 'user_data.dart';
import 'user.dart';
import 'questions.dart';
import 'package:pippidi/util/constants.dart';

class UserManager {
  static const String BOXNAME = "user_manager";
  static const String USERS_KEY = "users";
  static const String CURRENT_USER_ID_KEY = "current_user_id";
  static const String MIGRATION_COMPLETED_KEY = "migration_completed_v2";

  static final UserManager _instance = UserManager._internal();
  static UserManager get instance => _instance;

  late final Box _box;
  final List<UserData> _users = <UserData>[];
  String? _currentUserId;
  bool _initialized = false;

  UserManager._internal();

  Future<void> initialize() async {
    if (_initialized) return;
    _box = await Hive.openBox(BOXNAME);
    await _loadUsers();
    await _checkAndPerformMigration();
    _initialized = true;
  }

  Future<void> _loadUsers() async {
    final usersData = _box.get(USERS_KEY, defaultValue: {});
    _users.clear(); // Clear existing users

    // Load current user ID first so we can use it as fallback during user loading
    _currentUserId = _box.get(CURRENT_USER_ID_KEY)?.toString();

    if (usersData is Map) {
      // Legacy Map format - convert to array
      for (final entry in usersData.entries) {
        final userId = entry.key?.toString() ?? '';
        final userData = entry.value;
        if (userId.isNotEmpty && userData is Map) {
          try {
            final loadedUser =
                UserData.fromJson(userId, Map<String, dynamic>.from(userData));

            // Validate that the loaded user has the correct userId
            final userToStore = loadedUser.userId == userId
                ? loadedUser
                : UserData(
                    userId: userId,
                    name: loadedUser.name,
                    profilePicBase64: loadedUser.profilePicBase64,
                    score: loadedUser.score,
                    scoreHistory: loadedUser.scoreHistory,
                    correct: loadedUser.correct,
                    wrong: loadedUser.wrong,
                    badges: loadedUser.badges,
                    noNegativeMarks: loadedUser.noNegativeMarks,
                    firstNotificationPromptShown:
                        loadedUser.firstNotificationPromptShown,
                    lastLeaderboardScore: loadedUser.lastLeaderboardScore,
                    firstTime: loadedUser.firstTime,
                    friends: loadedUser.friends,
                    categoryProgress: loadedUser.categoryProgress,
                    personalizedQuestions: loadedUser.personalizedQuestions,
                    createdAt: loadedUser.createdAt,
                    modifiedAt: loadedUser.modifiedAt,
                  );

            if (loadedUser.userId != userId) {
              print(
                  'ERROR: Loaded user has wrong userId! Expected: $userId, Got: ${loadedUser.userId}, name: ${loadedUser.name} - Corrected to $userId');
            }

            _users.add(userToStore);
          } catch (e) {
            print(
                'Error loading user $userId: $e - creating default user to prevent data loss');
            _users.add(UserData.create(userId: userId, name: 'Recovered User'));
          }
        }
      }
    } else if (usersData is List) {
      // New array format - load directly
      for (final userData in usersData) {
        if (userData is Map) {
          try {
            // For array format, we need to extract userId from the data
            String userId = userData['userId']?.toString() ?? '';

            // Fallback: if userId is empty but we have a current user ID, use that
            if (userId.isEmpty && _currentUserId != null) {
              userId = _currentUserId!;
            }

            if (userId.isNotEmpty) {
              final loadedUser = UserData.fromJson(
                  userId, Map<String, dynamic>.from(userData));
              _users.add(loadedUser);
            } else {
              print('UserManager: Skipping user with empty userId');
            }
          } catch (e) {
            print('Error loading user from array: $e');
          }
        }
      }
    }

    // If no current user is set but we have users, set the first one as current
    if (_currentUserId == null && _users.isNotEmpty) {
      _currentUserId = _users.first.userId;
      await _box.put(CURRENT_USER_ID_KEY, _currentUserId);
    }
  }

  Future<void> _checkAndPerformMigration() async {
    final migrationCompleted =
        _box.get(MIGRATION_COMPLETED_KEY, defaultValue: false);
    if (!migrationCompleted) {
      await _performMigration();
      await _box.put(MIGRATION_COMPLETED_KEY, true);
    }
  }

  Future<void> _performMigration() async {
    try {
      // Check if old user data exists
      final userBox = await Hive.openBox('user');
      final questionsBox = await Hive.openBox('questions');

      // Check if there's existing user data to migrate
      final oldUserId = userBox.get('ID');
      final oldUserName = userBox.get('USERNAME');

      print(
          'UserManager: Migration - old user ID: $oldUserId, old user name: $oldUserName');

      if (oldUserId != null && oldUserName != null) {
        try {
          // Migrate user data with safe type casting
          final userData = UserData(
            userId: oldUserId,
            name: oldUserName,
            profilePicBase64: (userBox.get('PROFILEPIC') as String?) ?? '',
            score: (userBox.get('SCORE') as int?) ?? 0,
            scoreHistory: _safeListCast<int>(userBox.get('SCOREHISTORY')),
            correct: (userBox.get('CORRECT') as int?) ?? 0,
            wrong: (userBox.get('WRONG') as int?) ?? 0,
            badges: _safeListCast<String>(userBox.get('BADGES')),
            noNegativeMarks: (userBox.get('NONEGATIVEMARK') as int?) ?? 0,
            firstNotificationPromptShown:
                (userBox.get('FIRST_NOTIFICATION_PROMPT') as bool?) ?? false,
            lastLeaderboardScore: 0, // Start with 0 for migrated users
            firstTime: (userBox.get('FIRSTTIME') as bool?) ?? true,
            friends: _migrateFriendsList(userBox.get('FRIENDS')),
            categoryProgress: _migrateQuestionProgress(questionsBox),
            personalizedQuestions: _migratePersonalizedQuestions(questionsBox),
            createdAt: DateTime.now(),
            modifiedAt: DateTime.now(),
          );

          // Add migrated user to our system
          _users.add(userData);
          _currentUserId = oldUserId;
          await _saveUsers();
        } catch (e) {
          print('Migration failed for user data: $e');
          // Create a minimal user if migration fails
          final minimalUserData = UserData.create(
            userId: oldUserId,
            name: oldUserName,
          );
          _users.add(minimalUserData);
          _currentUserId = oldUserId;
          await _saveUsers();
        }
      } else {
        // No existing data, migration not needed
        print(
            'UserManager: Migration - No existing user data found in old box');
      }

      // Close the boxes we opened for migration
      await userBox.close();
      await questionsBox.close();
    } catch (e) {
      print('Migration failed: $e');
      // Don't fail the app if migration fails, just continue
    }
  }

  Map<String, Map<String, dynamic>> _migrateQuestionProgress(Box questionsBox) {
    final categories = questionsBox.get('CATEGORIES');
    if (categories is Map) {
      try {
        // Safely convert the categories map
        final migratedProgress = Map<String, Map<String, dynamic>>.from(
          categories.map((key, value) => MapEntry(
                key.toString(),
                value is Map ? Map<String, dynamic>.from(value) : {},
              )),
        );

        // For migrated users from single-user system, preserve ALL data exactly as-is
        // Since there was only one user in the old system, maintain exact state
        // No resets needed - direct 1:1 migration preserving index, progress, and history
        // Keep: index, score, history, limit, completed_questions (everything)

        return migratedProgress;
      } catch (e) {
        print('Error migrating question progress: $e');
        return {};
      }
    }
    return {};
  }

  Map<String, List<dynamic>> _migratePersonalizedQuestions(Box questionsBox) {
    final categories = questionsBox.get('CATEGORIES');
    if (categories is Map) {
      try {
        final personalizedQuestions = <String, List<dynamic>>{};
        final addedQuestions = <String, List<dynamic>>{};

        // Extract the full question lists from old categories
        categories.forEach((categoryKey, categoryData) {
          if (categoryData is Map) {
            final categoryName = categoryKey.toString();
            final questions = categoryData['questions'];

            if (questions is List && questions.isNotEmpty) {
              // Use the questions as they existed in the old system
              // This preserves any downloaded questions that were already added
              personalizedQuestions[categoryName] = List.from(questions);

              // Also extract downloaded questions (beyond base questions) for global pool
              final baseQuestionCount = _getBaseQuestionCount(categoryName);
              if (questions.length > baseQuestionCount) {
                // These are downloaded questions - save them for global pool
                final downloadedQuestions =
                    questions.sublist(baseQuestionCount);
                addedQuestions[categoryName] = List.from(downloadedQuestions);
                // Found downloaded questions to preserve in global pool
              }
            }
          }
        });

        // Save all questions from old system as the base for migrated installations
        // This ensures new users get the same questions as the migrated user had
        questionsBox.put('migrated_base_questions', categories);

        return personalizedQuestions;
      } catch (e) {
        print('Error migrating personalized questions: $e');
        return {};
      }
    }
    return {};
  }

  // Get the base question count for each category (without downloaded questions)
  // For migration purposes, we assume the old system had 0 base questions
  // All questions in the old system are treated as "downloaded" to preserve them
  int _getBaseQuestionCount(String category) {
    // Return 0 to treat all old questions as downloaded and preserve them
    return 0;
  }

  List<List<dynamic>> _migrateFriendsList(dynamic friendsData) {
    if (friendsData == null) return [];

    try {
      // Handle different possible formats that Hive might have stored
      if (friendsData is List) {
        return List<List<dynamic>>.from(friendsData);
      } else if (friendsData is Map) {
        // If it's stored as a map, convert to list format
        return [];
      }
      return [];
    } catch (e) {
      print('Error migrating friends list: $e');
      return [];
    }
  }

  List<T> _safeListCast<T>(dynamic data) {
    if (data == null) return [];
    try {
      if (data is List) {
        return List<T>.from(data);
      }
      return [];
    } catch (e) {
      print('Error casting list to $T: $e');
      return [];
    }
  }

  Future<void> _saveUsers() async {
    final usersData = <Map<String, dynamic>>[];
    for (final user in _users) {
      usersData.add(user.toJson());
    }
    await _box.put(USERS_KEY, usersData);
  }

  // Get all users
  Map<String, UserData> get users {
    // Since we're now using List<UserData>, convert to Map for backward compatibility
    final usersMap = <String, UserData>{};
    for (final user in _users) {
      // Return copies to prevent external mutation
      usersMap[user.userId] = user.copyWith();
    }

    return usersMap;
  }

  // Get current user
  UserData? get currentUser {
    if (_currentUserId == null) return null;
    try {
      final user = _users.firstWhere((user) => user.userId == _currentUserId);
      return user.copyWith();
    } catch (e) {
      print(
          'UserManager: ERROR - Could not find current user $_currentUserId in users list');
      return null;
    }
  }

  // Get current user ID
  String? get currentUserId => _currentUserId;

  // Check if user exists
  bool userExists(String userId) {
    return _users.any((user) => user.userId == userId);
  }

  // Check if new user can be created
  bool canCreateUser() {
    return _users.length < Malayalam.maxUsersAllowed;
  }

  // Create new user
  Future<UserData> createUser({
    required String userId,
    required String name,
    String? profilePic,
    bool firstTime =
        false, // Users created outside onboarding are already onboarded
  }) async {
    if (_users.any((user) => user.userId == userId)) {
      throw Exception('User with ID $userId already exists');
    }

    // Check if a user with the same name already exists
    if (_users.any((user) => user.name == name)) {
      throw Exception(
          'A user with the name "$name" already exists. Please choose a different name.');
    }

    // Check if maximum users limit is reached
    if (_users.length >= Malayalam.maxUsersAllowed) {
      throw Exception(
          'Maximum number of users (${Malayalam.maxUsersAllowed}) reached. Cannot create more users.');
    }

    final userData = UserData(
      userId: userId,
      name: name,
      profilePicBase64: profilePic ?? '',
      firstTime: firstTime,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
    );

    _users.add(userData);
    await _saveUsers();

    // Populate personalized questions for the new user
    // This ensures new users get all available questions immediately
    await Questions.instance.populatePersonalizedQuestionsForUser(userData);

    // If this is the first user, make it current
    if (_currentUserId == null) {
      await switchToUser(userId);
    }

    return userData;
  }

  // Switch to user
  Future<void> switchToUser(String userId) async {
    if (!_users.any((user) => user.userId == userId)) {
      throw Exception('User with ID $userId does not exist');
    }

    // Sync the current user before switching (if any)
    if (_currentUserId != null) {
      User().syncCurrentUser();
    }

    // Perform in-memory switch first (critical for UI consistency)
    _currentUserId = userId;
    User().clearProfilePicCache(); // Clear cached profile picture bytes
    User().loadLegacyData(); // Load legacy properties from new current user

    // Validate that the switch was successful
    if (_currentUserId != userId) {
      print(
          'ERROR: _currentUserId was not set correctly! Expected: $userId, Got: $_currentUserId');
      _currentUserId = userId; // Fix it
    }

    // Validate that the user exists
    if (!_users.any((user) => user.userId == userId)) {
      print('ERROR: User $userId does not exist in _users after switch!');
    }

    // Mark the user as onboarded when they become the current user
    final currentUser = _users.firstWhere((user) => user.userId == userId);
    if (currentUser.firstTime) {
      final updatedUser = currentUser.copyWith(firstTime: false);
      final index = _users.indexWhere((user) => user.userId == userId);
      _users[index] = updatedUser;
      await _saveUsers();
    }

    // Persist current ID to Hive synchronously (critical for app state consistency)
    try {
      await _box.put(CURRENT_USER_ID_KEY, _currentUserId);
    } catch (error) {
      print(
          'UserManager: ERROR - Failed to persist current user ID to Hive: $error');
      // This is critical - rethrow to prevent inconsistent state
      rethrow;
    }
  }

  // Update current user data
  Future<void> updateCurrentUser(UserData updatedUser) async {
    if (_currentUserId == null) {
      print('UserManager: ERROR - No current user set for update');
      throw Exception('No current user set');
    }

    // Find and replace the current user
    final index = _users.indexWhere((user) => user.userId == _currentUserId);
    if (index != -1) {
      _users[index] = updatedUser;
    } else {
      print(
          'UserManager: ERROR - Current user $_currentUserId not found in _users list!');
      return;
    }

    await _saveUsers();
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    if (!_users.any((user) => user.userId == userId)) {
      throw Exception('User with ID $userId does not exist');
    }

    // Don't allow deleting the last user
    if (_users.length <= 1) {
      throw Exception('Cannot delete the last user');
    }

    _users.removeWhere((user) => user.userId == userId);
    await _saveUsers();

    // If we deleted the current user, switch to another one
    if (_currentUserId == userId) {
      _currentUserId = _users.first.userId;
      await _box.put(CURRENT_USER_ID_KEY, _currentUserId);
    }
  }

  // Get user by ID
  UserData? getUser(String userId) {
    try {
      return _users.firstWhere((user) => user.userId == userId).copyWith();
    } catch (e) {
      return null;
    }
  }

  // Update user by ID (not necessarily current user)
  Future<void> updateUserById(String userId, UserData updatedUser) async {
    final index = _users.indexWhere((user) => user.userId == userId);
    if (index != -1) {
      _users[index] = updatedUser;
      await _saveUsers();
    } else {
      print('ERROR: User $userId not found for update!');
    }
  }

  // Add new questions to all users - proactively populate personalized questions
  Future<void> addNewQuestionsToCategory(
      String category, List<dynamic> fullQuestionList) async {
    final usersToUpdate = <int, UserData>{}; // index -> updated user

    for (int i = 0; i < _users.length; i++) {
      final user = _users[i];
      final updatedPersonalized =
          Map<String, List<dynamic>>.from(user.personalizedQuestions);

      if (user.personalizedQuestions.containsKey(category)) {
        // User has already personalized this category - replace with full updated list
        // This ensures they get all questions (old + new) in a new randomized order
        final shuffledList = List.from(fullQuestionList)..shuffle();
        updatedPersonalized[category] = shuffledList;
      } else {
        // User hasn't accessed this category yet - proactively create personalized questions
        // This ensures new users get the full question set including newly downloaded questions
        final shuffledList = List.from(fullQuestionList)..shuffle();
        updatedPersonalized[category] = shuffledList;
      }

      usersToUpdate[i] =
          user.copyWith(personalizedQuestions: updatedPersonalized);
    }

    // Batch update all modified users
    if (usersToUpdate.isNotEmpty) {
      usersToUpdate.forEach((index, updatedUser) {
        _users[index] = updatedUser;
      });
      await _saveUsers();
    }
  }

  // Check if migration is completed
  bool get isMigrationCompleted {
    return _box.get(MIGRATION_COMPLETED_KEY, defaultValue: false);
  }

  // Get current migration status for debugging
  String get migrationStatus {
    final completed = _box.get(MIGRATION_COMPLETED_KEY, defaultValue: false);
    final version = MIGRATION_COMPLETED_KEY.split('_').last;
    return 'Migration v$version: ${completed ? "COMPLETED" : "PENDING"}';
  }

  // Force migration to run again (for emergency fixes)
  Future<void> forceMigration() async {
    await _box.put(MIGRATION_COMPLETED_KEY, false);
    print(
        'UserManager: Migration flag reset - will run migration on next app start');
  }

  // Emergency migration reset (call this from debug console if needed)
  static Future<void> resetMigrationForEmergency() async {
    final box = await Hive.openBox(BOXNAME);
    await box.put(MIGRATION_COMPLETED_KEY, false);
    await box.close();
    print('EMERGENCY: Migration flag reset globally');
  }

  // Force migration with version update (for major changes)
  Future<void> forceMigrationWithVersionUpdate(String newVersion) async {
    final newKey = "migration_completed_$newVersion";
    await _box.put(MIGRATION_COMPLETED_KEY, false); // Reset old flag
    // Update the constant for future migrations
    // Note: This changes the constant value, so use with caution
    await _box.put(newKey, false); // Set new version flag
    print(
        'UserManager: Migration updated to v$newVersion - will run on next app start');
  }
}
