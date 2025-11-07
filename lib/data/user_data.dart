import 'dart:convert';
import 'dart:typed_data';

class UserData {
  // Basic user information
  final String userId;
  String name;
  String profilePicBase64;

  // Cached decoded profile picture bytes
  Uint8List? _profilePicBytesCache;

  // Game statistics
  int score;
  List<int> scoreHistory;
  int correct;
  int wrong;

  // Game state
  List<String> badges;
  int noNegativeMarks;
  bool firstNotificationPromptShown;

  // Skip feature
  int consecutiveCorrectAnswers;
  int skipCount;

  // Leaderboard tracking
  int lastLeaderboardScore;

  // First time flag
  bool firstTime;

  // Friends list - stored as [name, score, id, badge]
  List<List<dynamic>> friends;

  // Question progress per category
  Map<String, Map<String, dynamic>> categoryProgress;

  // Personalized question sequences per category (intro + randomized questions)
  Map<String, List<dynamic>> personalizedQuestions;

  // Timestamps
  DateTime? createdAt;
  DateTime? modifiedAt;

  UserData({
    required this.userId,
    required this.name,
    this.profilePicBase64 = '',
    this.score = 0,
    List<int>? scoreHistory,
    this.correct = 0,
    this.wrong = 0,
    List<String>? badges,
    this.noNegativeMarks = 0,
    this.firstNotificationPromptShown = false,
    this.lastLeaderboardScore = 0,
    this.firstTime = true,
    List<List<dynamic>>? friends,
    Map<String, Map<String, dynamic>>? categoryProgress,
    Map<String, List<dynamic>>? personalizedQuestions,
    this.consecutiveCorrectAnswers = 0,
    this.skipCount = 0,
    this.createdAt,
    this.modifiedAt,
  })  : scoreHistory = List.unmodifiable(scoreHistory ?? []),
        badges = List.unmodifiable(badges ?? []),
        friends = List.unmodifiable(friends ?? []),
        categoryProgress = Map.unmodifiable(categoryProgress ?? {}),
        personalizedQuestions = Map.unmodifiable(
            personalizedQuestions ?? <String, List<dynamic>>{});

  // Helper method to safely parse categoryProgress from JSON
  static Map<String, Map<String, dynamic>> _parseCategoryProgress(
      dynamic data) {
    if (data == null) return <String, Map<String, dynamic>>{};

    try {
      if (data is Map) {
        final result = <String, Map<String, dynamic>>{};
        for (final entry in data.entries) {
          final key = entry.key?.toString() ?? '';
          final value = entry.value;
          if (key.isNotEmpty && value is Map) {
            result[key] = Map<String, dynamic>.from(value);
          } else if (key.isNotEmpty) {
            result[key] = <String, dynamic>{};
          }
        }
        return result;
      }
      return <String, Map<String, dynamic>>{};
    } catch (e) {
      print('Error parsing categoryProgress: $e');
      return <String, Map<String, dynamic>>{};
    }
  }

  // Helper method to safely parse personalizedQuestions from JSON
  static Map<String, List<dynamic>> _parsePersonalizedQuestions(dynamic data) {
    if (data == null) return <String, List<dynamic>>{};

    try {
      if (data is Map) {
        final result = <String, List<dynamic>>{};
        for (final entry in data.entries) {
          final key = entry.key?.toString() ?? '';
          final value = entry.value;
          if (key.isNotEmpty && value is List) {
            result[key] = List<dynamic>.from(value);
          } else if (key.isNotEmpty) {
            result[key] = <dynamic>[];
          }
        }
        return result;
      }
      return <String, List<dynamic>>{};
    } catch (e) {
      print('Error parsing personalizedQuestions: $e');
      return <String, List<dynamic>>{};
    }
  }

  // Factory constructor to create new user
  factory UserData.create({
    required String userId,
    required String name,
    String? profilePic,
  }) {
    final now = DateTime.now();
    return UserData(
      userId: userId,
      name: name,
      profilePicBase64: profilePic ?? '',
      createdAt: now,
      modifiedAt: now,
    );
  }

  // Factory constructor from JSON
  factory UserData.fromJson(String userId, Map<String, dynamic> json) {
    // Parse fields with error handling to prevent data corruption from breaking user loading
    String name = '';
    try {
      name = json['name'] ?? '';
    } catch (e) {
      print('Error parsing name for user $userId: $e');
    }

    String profilePicBase64 = '';
    try {
      profilePicBase64 = json['profilePic'] ?? '';
    } catch (e) {
      print('Error parsing profilePic for user $userId: $e');
    }

    int score = 0;
    try {
      score = json['score'] ?? 0;
    } catch (e) {
      print('Error parsing score for user $userId: $e');
    }

    List<int> scoreHistory = [];
    try {
      scoreHistory = List<int>.from(json['scoreHistory'] ?? []);
    } catch (e) {
      print('Error parsing scoreHistory for user $userId: $e');
      scoreHistory = [];
    }

    int correct = 0;
    try {
      correct = json['correct'] ?? 0;
    } catch (e) {
      print('Error parsing correct for user $userId: $e');
    }

    int wrong = 0;
    try {
      wrong = json['wrong'] ?? 0;
    } catch (e) {
      print('Error parsing wrong for user $userId: $e');
    }

    List<String> badges = [];
    try {
      badges = List<String>.from(json['badges'] ?? []);
    } catch (e) {
      print('Error parsing badges for user $userId: $e');
      badges = [];
    }

    int noNegativeMarks = 0;
    try {
      noNegativeMarks = json['noNegativeMarks'] ?? 0;
    } catch (e) {
      print('Error parsing noNegativeMarks for user $userId: $e');
    }

    bool firstNotificationPromptShown = false;
    try {
      firstNotificationPromptShown =
          json['firstNotificationPromptShown'] ?? false;
    } catch (e) {
      print('Error parsing firstNotificationPromptShown for user $userId: $e');
    }

    int lastLeaderboardScore = 0;
    try {
      lastLeaderboardScore = json['lastLeaderboardScore'] ?? 0;
    } catch (e) {
      print('Error parsing lastLeaderboardScore for user $userId: $e');
    }

    bool firstTime = true;
    try {
      firstTime = json['firstTime'] ?? true;
    } catch (e) {
      print('Error parsing firstTime for user $userId: $e');
    }

    List<List<dynamic>> friends = [];
    try {
      friends = List<List<dynamic>>.from(json['friends'] ?? []);
    } catch (e) {
      print('Error parsing friends for user $userId: $e');
      friends = [];
    }

    Map<String, Map<String, dynamic>> categoryProgress =
        _parseCategoryProgress(json['categoryProgress']);

    Map<String, List<dynamic>> personalizedQuestions =
        _parsePersonalizedQuestions(json['personalizedQuestions']);

    int consecutiveCorrectAnswers = 0;
    try {
      consecutiveCorrectAnswers = json['consecutiveCorrectAnswers'] ?? 0;
    } catch (e) {
      print('Error parsing consecutiveCorrectAnswers for user $userId: $e');
    }

    int skipCount = 0;
    try {
      skipCount = json['skipCount'] ?? 0;
    } catch (e) {
      print('Error parsing skipCount for user $userId: $e');
    }

    DateTime? createdAt;
    try {
      createdAt =
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null;
    } catch (e) {
      print('Error parsing createdAt for user $userId: $e');
      createdAt = null;
    }

    DateTime? modifiedAt;
    try {
      modifiedAt = json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'])
          : null;
    } catch (e) {
      print('Error parsing modifiedAt for user $userId: $e');
      modifiedAt = null;
    }

    return UserData(
      userId: userId,
      name: name,
      profilePicBase64: profilePicBase64,
      score: score,
      scoreHistory: scoreHistory,
      correct: correct,
      wrong: wrong,
      badges: badges,
      noNegativeMarks: noNegativeMarks,
      firstNotificationPromptShown: firstNotificationPromptShown,
      lastLeaderboardScore: lastLeaderboardScore,
      firstTime: firstTime,
      friends: friends,
      categoryProgress: categoryProgress,
      personalizedQuestions: personalizedQuestions,
      consecutiveCorrectAnswers: consecutiveCorrectAnswers,
      skipCount: skipCount,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'profilePic': profilePicBase64,
      'score': score,
      'scoreHistory': scoreHistory,
      'correct': correct,
      'wrong': wrong,
      'badges': badges,
      'noNegativeMarks': noNegativeMarks,
      'firstNotificationPromptShown': firstNotificationPromptShown,
      'lastLeaderboardScore': lastLeaderboardScore,
      'firstTime': firstTime,
      'friends': friends,
      'categoryProgress': categoryProgress,
      'personalizedQuestions': personalizedQuestions,
      'consecutiveCorrectAnswers': consecutiveCorrectAnswers,
      'skipCount': skipCount,
      'createdAt': createdAt?.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
    };
  }

  // Create a copy with updated fields
  UserData copyWith({
    String? name,
    String? profilePicBase64,
    int? score,
    List<int>? scoreHistory,
    int? correct,
    int? wrong,
    List<String>? badges,
    int? noNegativeMarks,
    bool? firstNotificationPromptShown,
    int? lastLeaderboardScore,
    bool? firstTime,
    List<List<dynamic>>? friends,
    Map<String, Map<String, dynamic>>? categoryProgress,
    Map<String, List<dynamic>>? personalizedQuestions,
    int? consecutiveCorrectAnswers,
    int? skipCount,
    DateTime? modifiedAt,
  }) {
    final newProfilePicBase64 = profilePicBase64 ?? this.profilePicBase64;
    final shouldClearCache =
        profilePicBase64 != null && profilePicBase64 != this.profilePicBase64;

    final userData = UserData(
      userId: userId,
      name: name ?? this.name,
      profilePicBase64: newProfilePicBase64,
      score: score ?? this.score,
      scoreHistory: scoreHistory ?? this.scoreHistory,
      correct: correct ?? this.correct,
      wrong: wrong ?? this.wrong,
      badges: badges ?? this.badges,
      noNegativeMarks: noNegativeMarks ?? this.noNegativeMarks,
      firstNotificationPromptShown:
          firstNotificationPromptShown ?? this.firstNotificationPromptShown,
      lastLeaderboardScore: lastLeaderboardScore ?? this.lastLeaderboardScore,
      firstTime: firstTime ?? this.firstTime,
      friends: friends ?? this.friends,
      categoryProgress: categoryProgress ?? this.categoryProgress,
      personalizedQuestions:
          personalizedQuestions ?? this.personalizedQuestions,
      consecutiveCorrectAnswers:
          consecutiveCorrectAnswers ?? this.consecutiveCorrectAnswers,
      skipCount: skipCount ?? this.skipCount,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? DateTime.now(),
    );

    // Clear cache if profile picture changed
    if (shouldClearCache) {
      userData._profilePicBytesCache = null;
    } else {
      // Copy existing cache if profile picture didn't change
      userData._profilePicBytesCache = this._profilePicBytesCache;
    }

    return userData;
  }

  // Get profile picture as Uint8List
  Uint8List? get profilePicBytes {
    // Return cached bytes if available
    if (_profilePicBytesCache != null) {
      return _profilePicBytesCache;
    }

    // Decode and cache the bytes
    if (profilePicBase64.isNotEmpty) {
      try {
        _profilePicBytesCache = base64Decode(profilePicBase64);
        return _profilePicBytesCache;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Get a unique key for this user's profile picture (for caching)
  String get profilePicKey => '$userId-${profilePicBase64.hashCode}';

  // Set profile picture from file path
  void setProfilePicFromPath(String filePath) {
    if (filePath.isNotEmpty) {
      // This would need to be handled by the caller since we don't have file I/O here
      // The UserManager or calling code should handle file reading
    } else {
      profilePicBase64 = '';
    }
  }

  // Get category progress for a specific category
  Map<String, dynamic>? getCategoryProgress(String category) {
    return categoryProgress[category];
  }

  // Update category progress
  void updateCategoryProgress(String category, Map<String, dynamic> progress) {
    categoryProgress[category] = progress;
  }

  // Add badge
  void addBadge(String badgeKey) {
    if (!badges.contains(badgeKey)) {
      badges.add(badgeKey);
    }
  }

  // Check if badge is won
  bool isBadgeWon(String badgeKey) {
    return badges.contains(badgeKey);
  }

  // Update score and history
  void updateScore(bool isCorrect,
      {int correctPoints = 100, int wrongPoints = -50}) {
    if (isCorrect) {
      score += correctPoints;
      correct++;
      scoreHistory.insert(0, 1); // Insert at beginning for speed
    } else {
      if (noNegativeMarks == 0) {
        score += wrongPoints;
      } else {
        noNegativeMarks--;
      }
      wrong++;
      scoreHistory.insert(0, 0); // Insert at beginning for speed
    }
  }

  // Add friend
  void addFriend(List<dynamic> friend) {
    // Check if friend already exists (friend[2] is id)
    final existingIndex = friends.indexWhere((f) => f[2] == friend[2]);
    if (existingIndex == -1) {
      friends.add(friend);
    } else {
      friends[existingIndex] = friend;
    }
  }

  // Remove friend
  void removeFriend(String friendId) {
    friends.removeWhere((f) => f[2] == friendId);
  }

  // Update friend
  void updateFriend(List<dynamic> updatedFriend) {
    final index = friends.indexWhere((f) => f[2] == updatedFriend[2]);
    if (index != -1) {
      friends[index] = updatedFriend;
    }
  }
}
