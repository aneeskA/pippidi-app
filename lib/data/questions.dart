import 'dart:async';
import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pippidi/data/user.dart';
import 'package:pippidi/data/user_manager.dart';
import 'package:pippidi/data/user_data.dart';
import 'package:pippidi/questions/aanukalikam.dart';
import 'package:pippidi/questions/charithram.dart';
import 'package:pippidi/questions/cinema.dart';
import 'package:pippidi/questions/kadamkatha.dart';
import 'package:pippidi/questions/kusruthy.dart';
import 'package:pippidi/questions/letter.dart';
import 'package:pippidi/util/constants.dart';

class Questions {
  static const String BOXNAME = "questions";
  static const String CATEGORIES = "CATEGORIES";
  static const String KADAMKATHA = "KADAMKATHA";
  static const String CHARITHRAM = "CHARITHRAM";
  static const String KUSRUTHY = "KUSRUTHY";
  static const String AANUKALIKAM = "AANUKALIKAM";
  static const String CINEMA = "CINEMA";
  static const String LETTER = "LETTER";
  static const String VINTAGE = "VINTAGE";

  // Category-specific scoring rules
  static const Map<String, Map<String, int>> categoryScoring = {
    LETTER: {
      'correct': 50,
      'wrong': -25,
      'hint': -10,
    },
    // Default scoring for other categories
    'default': {
      'correct': 100,
      'wrong': -50,
      'hint': -25,
    },
  };

  // Get scoring points for a category
  static Map<String, int> getCategoryScoring(String category) {
    return categoryScoring[category] ?? categoryScoring['default']!;
  }

  int _vintage = -1;

  // Added questions from vintage downloads
  final Map<String, List<dynamic>> _addedQuestions = {};

  // Base category definitions (static data like questions and intro)
  final Map _baseCategories = {
    KADAMKATHA: {
      "name": KADAMKATHA,
      "intro": Kadamkatha.intro,
      "questions": Kadamkatha.questions,
    },
    CHARITHRAM: {
      "name": CHARITHRAM,
      "intro": Charithram.intro,
      "questions": Charithram.questions,
    },
    KUSRUTHY: {
      "name": KUSRUTHY,
      "intro": Kusruthy.intro,
      "questions": Kusruthy.questions,
    },
    AANUKALIKAM: {
      "name": AANUKALIKAM,
      "intro": Aanukalikam.intro,
      "questions": Aanukalikam.questions,
    },
    CINEMA: {
      "name": CINEMA,
      "intro": Cinema.intro,
      "questions": Cinema.questions,
    },
    LETTER: {
      "name": LETTER,
      "intro": Letter.intro,
      "questions": Letter.questions,
    },
  };

  bool isCategoryValid(String category) {
    return _baseCategories.containsKey(category);
  }

  late final Box _myBox;

  // Helper method to get current user's category progress
  Map<String, dynamic>? _getUserCategoryProgress(String category) {
    final currentUser = UserManager.instance.currentUser;
    if (currentUser == null) return null;

    final userProgress = currentUser.categoryProgress[category];
    if (userProgress != null) {
      // Return a modifiable copy of existing progress
      return Map<String, dynamic>.from(userProgress);
    }

    // Create new progress for this user
    return {
      "name": category,
      "index": 0,
      "limit": _getDefaultLimit(category),
      "score": 0,
      "history": [],
      "completed_questions": [],
    };
  }

  // Helper method to get or create personalized question sequence for user
  List<dynamic> _getPersonalizedQuestions(String category) {
    final currentUser = UserManager.instance.currentUser;
    if (currentUser == null) return [];

    // Check if personalized questions already exist for this category
    if (currentUser.personalizedQuestions.containsKey(category)) {
      return currentUser.personalizedQuestions[category]!;
    }

    // Create personalized question sequence
    final baseCategory = _baseCategories[category];
    if (baseCategory == null) return [];

    final introQuestions = List.from(baseCategory['intro'] ?? []);
    final mainQuestions = List.from(baseCategory['questions'] ?? []);

    // Shuffle main questions for randomization
    mainQuestions.shuffle();

    // Combine: intro questions first (in order) + randomized main questions
    final personalizedList = [...introQuestions, ...mainQuestions];

    // Store in user's personalized questions
    final updatedPersonalizedQuestions =
        Map<String, List<dynamic>>.from(currentUser.personalizedQuestions);
    updatedPersonalizedQuestions[category] = personalizedList;

    final updatedUser = currentUser.copyWith(
        personalizedQuestions: updatedPersonalizedQuestions);
    UserManager.instance.updateCurrentUser(updatedUser);

    return personalizedList;
  }

  // Populate personalized questions for a user who doesn't have them yet
  Future<void> populatePersonalizedQuestionsForUser(UserData user) async {
    final updatedPersonalizedQuestions =
        Map<String, List<dynamic>>.from(user.personalizedQuestions);
    bool needsUpdate = false;

    for (final category in _baseCategories.keys) {
      if (!user.personalizedQuestions.containsKey(category)) {
        final baseCategory = _baseCategories[category]!;
        final introQuestions = List.from(baseCategory['intro'] ?? []);
        final mainQuestions = List.from(baseCategory['questions'] ?? []);

        // Shuffle main questions for randomization
        mainQuestions.shuffle();

        // Combine: intro questions first (in order) + randomized main questions
        final personalizedList = [...introQuestions, ...mainQuestions];
        updatedPersonalizedQuestions[category] = personalizedList;
        needsUpdate = true;
      }
    }

    if (needsUpdate) {
      final updatedUser =
          user.copyWith(personalizedQuestions: updatedPersonalizedQuestions);
      await UserManager.instance.updateUserById(user.userId, updatedUser);
    }
  }

  // Helper method to update current user's category progress
  Future<void> _updateUserCategoryProgress(
      String category, Map<String, dynamic> progress) async {
    final currentUser = UserManager.instance.currentUser;
    if (currentUser == null) return;

    final updatedProgress =
        Map<String, Map<String, dynamic>>.from(currentUser.categoryProgress);
    updatedProgress[category] = progress;

    final updatedUser = currentUser.copyWith(categoryProgress: updatedProgress);
    await UserManager.instance.updateCurrentUser(updatedUser);
  }

  // Get default limit for a category
  int _getDefaultLimit(String category) {
    switch (category) {
      case KADAMKATHA:
        return 50;
      case CHARITHRAM:
      case CINEMA:
        return 25;
      case KUSRUTHY:
        return 51;
      case AANUKALIKAM:
      case LETTER:
        return -1; // free category
      default:
        return 0;
    }
  }

  static Questions? _instance;

  static Questions get instance {
    _instance ??= Questions._internal();
    return _instance!;
  }

  factory Questions() {
    return instance;
  }

  Questions._internal() {
    // Initialize Hive box (should be opened by main.dart)
    _myBox = Hive.box(BOXNAME);
    // Initialize vintage from global storage (still global)
    loadVintage();
    // Load migrated base questions if available (for migrated installations)
    _loadMigratedBaseQuestions();
  }

  void loadVintage() {
    _vintage = _myBox.get(VINTAGE) ?? -1;
    _loadAddedQuestions();
  }

  void _loadMigratedBaseQuestions() {
    final migrated = _myBox.get('migrated_base_questions');
    if (migrated is Map) {
      // Replace base categories with migrated questions for migrated installations
      migrated.forEach((categoryKey, categoryData) {
        if (categoryData is Map) {
          final categoryName = categoryKey.toString();
          final questions = categoryData['questions'];
          final intro = categoryData['intro'] ?? [];

          if (questions is List) {
            _baseCategories[categoryName] = {
              'name': categoryName,
              'intro': List.from(intro),
              'questions': List.from(questions),
            };
          }
        }
      });
    }
  }

  void _loadAddedQuestions() {
    final added = _myBox.get('added_questions', defaultValue: {});
    if (added is Map) {
      _addedQuestions.clear();
      added.forEach((key, value) {
        if (value is List) {
          _addedQuestions[key.toString()] = List.from(value);
        }
      });

      // Update base categories with added questions
      for (final entry in _addedQuestions.entries) {
        final category = entry.key;
        final addedQuestions = entry.value;
        if (_baseCategories.containsKey(category)) {
          final existing =
              List.from(_baseCategories[category]['questions'] ?? []);
          // Only add if not already present (avoid duplicates)
          for (final question in addedQuestions) {
            if (!existing.contains(question)) {
              existing.add(question);
            }
          }
          _baseCategories[category]['questions'] = existing;
        } else {
          _baseCategories[category] = {
            'name': category,
            'intro': [],
            'questions': List.from(addedQuestions),
          };
        }
      }
    }
  }

  int get vintage {
    return _vintage;
  }

  set vintage(int v) {
    _vintage = v;
    updateDB(VINTAGE, _vintage);
  }

  Future<List> loadQuestions(String csv) async {
    // load csv file
    final data = await rootBundle.loadString(csv);
    List<List<dynamic>> rows =
        const CsvToListConverter(shouldParseNumbers: false).convert(data);
    List _questions = jsonDecode(jsonEncode(rows));
    _questions.shuffle();
    return jsonDecode(jsonEncode(_questions));
  }

  Future<void> addQuestions(String category, String questionsCsv) async {
    try {
      // Parse CSV data
      final data = const CsvToListConverter(shouldParseNumbers: false)
          .convert(questionsCsv);
      final newQuestions = jsonDecode(jsonEncode(data)) as List;

      // Shuffle new questions for randomization
      newQuestions.shuffle();

      // Update added questions map
      final existingAdded = List.from(_addedQuestions[category] ?? []);
      existingAdded.addAll(newQuestions);
      _addedQuestions[category] = existingAdded;

      // Update base categories and get the full question list
      late final List<dynamic> fullQuestionList;
      if (_baseCategories.containsKey(category)) {
        // Add to existing category
        final existingCategory = _baseCategories[category];
        final existingQuestions =
            List.from(existingCategory['questions'] ?? []);
        existingQuestions.addAll(newQuestions);
        _baseCategories[category]['questions'] = existingQuestions;
        fullQuestionList = existingQuestions;
      } else {
        // Create new category
        _baseCategories[category] = {
          'name': category,
          'intro': [], // No intro for dynamically added categories
          'questions': newQuestions,
        };
        fullQuestionList = newQuestions;
      }

      // Save added questions to Hive
      await _myBox.put('added_questions', _addedQuestions);

      // Update all existing users' personalized questions for this category
      final userManager = UserManager.instance;
      await userManager.addNewQuestionsToCategory(category, fullQuestionList);
    } catch (e) {
      print('Error adding questions to category $category: $e');
    }
  }

  // Legacy methods for backwards compatibility - no longer used
  void createDB() async {
    // Not needed anymore - data is stored per user
  }

  void loadDB() async {
    // Not needed anymore - data is stored per user
  }

  void updateDB(String key, dynamic value) {
    _myBox.put(key, value);
  }

  List nextQuestion(String category) {
    final categoryProgress = _getUserCategoryProgress(category);
    if (categoryProgress == null) return List.empty();

    final personalizedQuestions = _getPersonalizedQuestions(category);
    if (personalizedQuestions.isEmpty) return List.empty();

    int _index = categoryProgress['index'];
    int _limit = categoryProgress['limit'];

    // Check if we've reached the limit or end of questions
    int effectiveLimit = (_limit == -1) ? personalizedQuestions.length : _limit;
    if (_index >= effectiveLimit) {
      return List.empty();
    }

    List q = [
      ...personalizedQuestions[_index]
    ]; // create a copy of next question
    var first = q[0]; // keep the question
    q.removeAt(0); // remove question
    q.shuffle(); // shuffle answers
    q.insert(0, first); // insert question
    return q;
  }

  void updateScore(String category, bool result) async {
    final categoryProgress = _getUserCategoryProgress(category);
    if (categoryProgress == null) return;

    final updatedProgress = Map<String, dynamic>.from(categoryProgress);

    // Get category-specific scoring
    final scoring = Questions.getCategoryScoring(category);
    final CORRECTANSWER = scoring['correct']!;
    final WRONGANSWER = scoring['wrong']!;

    if (result) {
      updatedProgress['score'] =
          (updatedProgress['score'] ?? 0) + CORRECTANSWER;
      updatedProgress['history'] =
          List<int>.from(updatedProgress['history'] ?? [])..add(1);
    } else {
      updatedProgress['score'] = (updatedProgress['score'] ?? 0) + WRONGANSWER;
      updatedProgress['history'] =
          List<int>.from(updatedProgress['history'] ?? [])..add(0);
    }

    await _updateUserCategoryProgress(category, updatedProgress);
  }

  bool checkAnswer(String category, String answer) {
    final categoryProgress = _getUserCategoryProgress(category);
    if (categoryProgress == null) return false;

    final personalizedQuestions = _getPersonalizedQuestions(category);
    if (personalizedQuestions.isEmpty) return false;

    int _index = categoryProgress['index'];
    if (answer == personalizedQuestions[_index][1]) {
      updateScore(category, true);
      return true;
    } else {
      updateScore(category, false);
      return false;
    }
  }

  void completeQuestion(String category, String answer, List presentedOptions,
      {bool clueUsed = false,
      int? removedOptionIndex,
      bool isSkipped = false}) async {
    final categoryProgress = _getUserCategoryProgress(category);
    if (categoryProgress == null) return;

    final personalizedQuestions = _getPersonalizedQuestions(category);
    if (personalizedQuestions.isEmpty) return;

    int _index = categoryProgress['index'];
    bool? isCorrect;
    if (!isSkipped) {
      isCorrect = answer == personalizedQuestions[_index][1];
      User().updateScore(isCorrect, category: category);
      giveOutRewards(category);
    } else {
      // For skipped questions, don't update score and don't give rewards
      isCorrect = null; // null indicates skipped
    }

    // Store completed question with user answer
    Map<String, dynamic> completedQuestion = {
      'question': personalizedQuestions[_index][0], // question text
      'correct_answer': personalizedQuestions[_index][1], // correct answer
      'user_answer': answer, // user's selected answer (empty for skipped)
      'is_correct': isCorrect,
      'options': presentedOptions, // options in the order presented to user
      'question_index': _index, // original question index in personalized list
      'clue_used': clueUsed, // whether clue was used for this question
      'removed_option_index':
          removedOptionIndex, // which option was removed by clue (0, 1, or 2)
      'is_skipped': isSkipped, // whether the question was skipped
    };

    // Performance optimization: Compress data and cleanup old questions
    final compressedQuestion = _compressCompletedQuestion(completedQuestion);
    final updatedProgress = Map<String, dynamic>.from(categoryProgress);
    updatedProgress['completed_questions'] =
        List.from(updatedProgress['completed_questions'] ?? [])
          ..add(compressedQuestion);

    // Performance optimization: Cleanup old questions to manage memory
    _cleanupOldCompletedQuestionsForProgress(updatedProgress);

    // Increment index
    updatedProgress['index'] = (updatedProgress['index'] ?? 0) + 1;

    await _updateUserCategoryProgress(category, updatedProgress);
  }

  StreamController<String> rewardsStreamController =
      StreamController<String>.broadcast();
  void giveOutRewards(String category) {
    // if 3 questions on a row are answered wrong, give 1 without negative mark
    if (User.continuousWrong(3)) {
      User.setNoNegativeMark(1);
      rewardsStreamController.add(Malayalam.noNegativeForThisQuestion);
    }
  }

  bool avaiableToBuy(String category, int count) {
    final categoryProgress = _getUserCategoryProgress(category);
    if (categoryProgress == null) return false;

    final personalizedQuestions = _getPersonalizedQuestions(category);

    int _limit = categoryProgress['limit'];
    int _total = personalizedQuestions.length;
    if ((_limit + count) <= _total) {
      return true;
    }

    return false;
  }

  void raiseAvailableLimit(String category, int count) {
    final categoryProgress = _getUserCategoryProgress(category);
    if (categoryProgress == null) return;

    final updatedProgress = Map<String, dynamic>.from(categoryProgress);
    updatedProgress['limit'] = (updatedProgress['limit'] ?? 0) + count;

    _updateUserCategoryProgress(category, updatedProgress);
  }

  bool freeCategory(String category) {
    final categoryProgress = _getUserCategoryProgress(category);
    return categoryProgress?['limit'] == -1;
  }

  // Get all completed questions for a category in reverse order (newest first)
  List<Map<String, dynamic>> getCompletedQuestions(String category) {
    final categoryProgress = _getUserCategoryProgress(category);
    if (categoryProgress == null) return [];

    List<Map<String, dynamic>> completed =
        (categoryProgress['completed_questions'] as List<dynamic>? ?? [])
            .map((item) =>
                Map<String, dynamic>.from(item as Map<dynamic, dynamic>))
            .toList();
    return completed.reversed.toList();
  }

  // Check if there are any completed questions for review
  bool hasCompletedQuestions(String category) {
    final categoryProgress = _getUserCategoryProgress(category);
    return (categoryProgress?['completed_questions'] as List<dynamic>? ?? [])
        .isNotEmpty;
  }

  // Get completed question at specific index for review (optimized)
  // Index 0 = oldest question, Index N = newest question (chronological order)
  Map<String, dynamic>? getCompletedQuestionAt(String category, int index) {
    final categoryProgress = _getUserCategoryProgress(category);
    if (categoryProgress == null) return null;

    List<dynamic> completed =
        categoryProgress['completed_questions'] as List<dynamic>? ?? [];
    if (index < 0 || index >= completed.length) {
      return null;
    }
    // Return in chronological order (oldest first) - direct access
    final item = completed[index];

    // Handle compressed data
    Map<String, dynamic> questionData;
    if (item is Map<String, dynamic>) {
      questionData = item;
    } else if (item is Map<dynamic, dynamic>) {
      questionData = Map<String, dynamic>.from(item);
    } else {
      return null;
    }

    // Performance optimization: Decompress if needed (check for compressed keys)
    if (questionData.containsKey('q')) {
      return _decompressCompletedQuestion(questionData);
    }

    return questionData;
  }

  // Get total number of completed questions
  int getCompletedQuestionsCount(String category) {
    final categoryProgress = _getUserCategoryProgress(category);
    return (categoryProgress?['completed_questions'] as List<dynamic>? ?? [])
        .length;
  }

  // Performance optimization: Get multiple completed questions at once
  List<Map<String, dynamic>> getCompletedQuestionsRange(
      String category, int startIndex, int count) {
    final categoryProgress = _getUserCategoryProgress(category);
    if (categoryProgress == null) return [];

    List<dynamic> completed =
        categoryProgress['completed_questions'] as List<dynamic>? ?? [];
    if (startIndex < 0 || startIndex >= completed.length) {
      return [];
    }

    final endIndex = (startIndex + count).clamp(0, completed.length);
    final range = completed.sublist(startIndex, endIndex);

    return range.map((item) {
      Map<String, dynamic> questionData;
      if (item is Map<String, dynamic>) {
        questionData = item;
      } else if (item is Map<dynamic, dynamic>) {
        questionData = Map<String, dynamic>.from(item);
      } else {
        return <String, dynamic>{};
      }

      // Performance optimization: Decompress if needed
      if (questionData.containsKey('q')) {
        return _decompressCompletedQuestion(questionData);
      }

      return questionData;
    }).toList();
  }

  // Performance optimization: Archive old completed questions to manage memory
  static const int MAX_COMPLETED_QUESTIONS =
      100; // Keep only last 100 questions
  void _cleanupOldCompletedQuestionsForProgress(Map<String, dynamic> progress) {
    List<dynamic> completed = progress['completed_questions'] as List<dynamic>;
    if (completed.length > MAX_COMPLETED_QUESTIONS) {
      // Keep only the most recent questions
      final keepCount = MAX_COMPLETED_QUESTIONS;
      final newCompleted = completed.sublist(completed.length - keepCount);
      progress['completed_questions'] = newCompleted;
    }
  }

  // Performance optimization: Compress question data for storage
  Map<String, dynamic> _compressCompletedQuestion(
      Map<String, dynamic> question) {
    return {
      'q': question['question'], // Shortened keys to save space
      'ca': question['correct_answer'],
      'ua': question['user_answer'],
      'ic': question['is_correct'],
      'o': question['options'],
      'qi': question['question_index'],
      'cu': question['clue_used'], // clue used
      'roi': question['removed_option_index'], // removed option index
      'is': question['is_skipped'] ?? false, // is skipped
    };
  }

  Map<String, dynamic> _decompressCompletedQuestion(
      Map<String, dynamic> compressed) {
    return {
      'question': compressed['q'],
      'correct_answer': compressed['ca'],
      'user_answer': compressed['ua'],
      'is_correct': compressed['ic'],
      'options': compressed['o'],
      'question_index': compressed['qi'],
      'clue_used': compressed['cu'] ?? false,
      'removed_option_index': compressed['roi'],
      'is_skipped': compressed['is'] ?? false,
    };
  }

  double getCategoryProgress(String category) {
    final categoryProgress = _getUserCategoryProgress(category);
    if (categoryProgress == null) return 0.0;

    final personalizedQuestions = _getPersonalizedQuestions(category);
    if (personalizedQuestions.isEmpty) return 0.0;

    final index = categoryProgress['index'] as int? ?? 0;
    final limit = categoryProgress['limit'] as int? ?? 0;

    // Determine effective total (questions available to user)
    final effectiveTotal = (limit == -1) ? personalizedQuestions.length : limit;

    if (effectiveTotal <= 0) {
      return 0.0;
    }

    // If all available questions are completed, return exactly 1.0
    if (index >= effectiveTotal) {
      return 1.0;
    }

    // Divide progress into 100 equal steps
    final questionsPerStep = effectiveTotal / 100.0;
    final currentStep = (index / questionsPerStep).floor();
    final progress = (currentStep / 100.0).clamp(0.0, 1.0);

    return progress;
  }

  void dispose() {
    if (!rewardsStreamController.isClosed) {
      rewardsStreamController.close();
    }
  }
}
