// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:collection';

import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sizer/sizer.dart';

import 'package:pippidi/data/questions.dart';
import 'package:pippidi/data/user.dart';
import 'package:pippidi/pages/play/free_category.dart';
import 'package:pippidi/pages/play/purchase.dart';
import 'package:pippidi/pages/play/quiz.dart';
import 'package:pippidi/ui/user_notification.dart';
import 'package:pippidi/util/firebase.dart';
import 'package:pippidi/util/my_border_style.dart';
import 'package:pippidi/util/responsive_text.dart';
import 'package:pippidi/util/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Play extends StatefulWidget {
  final String category;
  Play({super.key, required this.category});

  @override
  State<Play> createState() => _PlayState();
}

class _PlayState extends State<Play>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  Questions db = Questions();
  User user = User();
  List next = [];
  int score = 0;
  late int _currentPage;
  final int _ANIMATION_DELAY = 800;
  final int _QUIZ_ANIMATION_DELAY = 2000; // Match QuizUI animation duration
  bool _isProcessingAnswer = false; // Track if answer is being processed
  bool _isProfilePressed = false; // Track if profile picture is pressed
  FToast fToast = FToast();
  StreamSubscription? badgeStream;
  StreamSubscription? rewardsStream;
  late PageController _pageViewController;
  List _badgeProgress = User().badgeProgress;
  List _badgesCompletedWithLocation = [];
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  late AnimationController _backController;
  late Animation<double> _backAnimation;

  // Performance optimization: LRU cache for completed questions
  static const int CACHE_SIZE = 20; // Keep only 20 questions in memory
  final LinkedHashMap<String, Map<String, dynamic>> _questionCache =
      LinkedHashMap<String, Map<String, dynamic>>();

  // Performance optimization: Track visible page range for pre-loading
  int _visibleStartPage = 0;
  int _visibleEndPage = 0;
  static const int PRELOAD_BUFFER =
      3; // Pre-load 3 pages before/after visible range

  // Performance optimization: Batch updates to prevent multiple rebuilds
  Timer? _batchUpdateTimer;
  final List<VoidCallback> _pendingUpdates = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    next = db.nextQuestion(widget.category);
    score = user.score;

    // Start at the last page (current question page)
    _currentPage = db.getCompletedQuestionsCount(widget.category);
    _pageViewController = PageController(initialPage: _currentPage);

    // Performance optimization: Initialize visible page range
    _visibleStartPage =
        (_currentPage - PRELOAD_BUFFER).clamp(0, _totalPages - 1);
    _visibleEndPage = (_currentPage + PRELOAD_BUFFER).clamp(0, _totalPages - 1);

    listenToBadgeEvents();
    listenToRewardEvents();
    fToast.init(context);

    // Performance optimization: Pre-load visible pages on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadQuestions(_visibleStartPage, _visibleEndPage);
    });

    analytics.logSelectContent(
      contentType: widget.category,
      itemId: Questions().freeCategory(widget.category) ? "free" : "paid",
    );

    _backController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _backAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _backController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    badgeStream?.cancel();
    rewardsStream?.cancel();
    _batchUpdateTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    checkIfLeader();
    _backController.dispose();
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    // Prevent back navigation during answer processing
    if (_isProcessingAnswer) {
      return false; // Block the back button
    }
    return super.didPopRoute();
  }

  // Performance optimization: Cache management methods
  String _getCacheKey(String category, int index) {
    return '$category:$index';
  }

  Map<String, dynamic>? _getCachedQuestion(String category, int index) {
    final key = _getCacheKey(category, index);
    if (_questionCache.containsKey(key)) {
      // Move to end (most recently used)
      final value = _questionCache.remove(key);
      _questionCache[key] = value!;
      return value;
    }
    return null;
  }

  void _cacheQuestion(
      String category, int index, Map<String, dynamic> question) {
    final key = _getCacheKey(category, index);
    if (_questionCache.containsKey(key)) {
      _questionCache.remove(key);
    }

    _questionCache[key] = question;

    // Remove oldest entries if cache is full
    while (_questionCache.length > CACHE_SIZE) {
      _questionCache.remove(_questionCache.keys.first);
    }
  }

  // Performance optimization: Batch update mechanism
  void _scheduleBatchUpdate(VoidCallback update, {VoidCallback? onComplete}) {
    _pendingUpdates.add(update);
    _batchUpdateTimer?.cancel();
    _batchUpdateTimer = Timer(const Duration(milliseconds: 16), () {
      if (mounted) {
        setState(() {
          for (final update in _pendingUpdates) {
            update();
          }
          _pendingUpdates.clear();
        });
        // Execute completion callback after state update
        onComplete?.call();
      }
    });
  }

  // Performance optimization: Pre-load questions for better scrolling performance
  void _preloadQuestions(int startPage, int endPage) {
    final completedCount = db.getCompletedQuestionsCount(widget.category);

    if (completedCount == 0) return;

    // Calculate the range in chronological order (oldest first)
    // startPage = index in completed questions array (0 = oldest)
    final startIndex = startPage.clamp(0, completedCount - 1);
    final endIndex = endPage.clamp(0, completedCount - 1);
    final rangeSize = (endIndex - startIndex + 1).clamp(0, CACHE_SIZE);

    if (rangeSize <= 0) return;

    // Performance optimization: Load multiple questions at once
    final questions =
        db.getCompletedQuestionsRange(widget.category, startIndex, rangeSize);

    // Cache all loaded questions
    for (int i = 0; i < questions.length; i++) {
      final questionIndex = startIndex + i;
      final key = _getCacheKey(widget.category, questionIndex);
      if (!_questionCache.containsKey(key)) {
        _cacheQuestion(widget.category, questionIndex, questions[i]);
      }
    }
  }

  void listenToBadgeEvents() {
    badgeStream = User().badgeWonController.stream.listen((data) {
      // find the position of the completed badge, if any
      for (int i = 0; i < _badgeProgress.length; i++) {
        if (_badgeProgress[i][0] == data[0]) {
          _badgesCompletedWithLocation.add([i, ...data]);
          break;
        }
      }

      // Performance optimization: Use single delayed callback instead of multiple
      Future.delayed(Duration(milliseconds: _ANIMATION_DELAY), () {
        if (mounted) {
          // Show badge notification
          _showToastWithBotToast(
            data[1],
            Icon(Icons.workspace_premium_outlined, color: Colors.white),
            Duration(seconds: 3),
          );

          // Show negative mark notification if applicable
          if (User().noNegativeMark > 0) {
            _showToastWithBotToast(
              Malayalam.noNegativePointsFor(User().noNegativeMark),
              Icon(Icons.bolt_outlined, color: Colors.white),
              Duration(seconds: 5),
            );
          }
        }
      });
    });
  }

  void listenToRewardEvents() {
    rewardsStream = Questions().rewardsStreamController.stream.listen((data) {
      // Performance optimization: Use consistent delay timing
      Future.delayed(Duration(milliseconds: _ANIMATION_DELAY), () {
        if (mounted) {
          // Show reward notification
          _showToastWithBotToast(
            data,
            Icon(Icons.lock_open_outlined, color: Colors.white),
            Duration(seconds: 3),
          );
        }
      });
    });
  }

  void checkIfLeader() async {
    List currentLeaderboard = await Firebase().currentLeaderBoard();
    User().updateIfLeader(currentLeaderboard);
  }

  // Get total number of pages (1 for current question + completed questions for review)
  int get _totalPages {
    int completedCount = db.getCompletedQuestionsCount(widget.category);
    return 1 +
        completedCount; // Always 1 page for current question + review pages
  }

  // Handle page changes from scrolling with performance optimizations
  void _onPageChanged(int page) {
    _currentPage = page;

    // Performance optimization: Track visible page range for pre-loading
    _visibleStartPage = (page - PRELOAD_BUFFER).clamp(0, _totalPages - 1);
    _visibleEndPage = (page + PRELOAD_BUFFER).clamp(0, _totalPages - 1);

    // Performance optimization: Pre-load questions for smooth scrolling
    _preloadQuestions(_visibleStartPage, _visibleEndPage);
  }

  void goToNextQuestion() {
    // For purchase flow - update the question data and navigate to current position
    setState(() {
      next = db.nextQuestion(widget.category);
      score = user.score;
      _currentPage = db.getCompletedQuestionsCount(widget.category);
    });

    // Smooth scroll to the current question page - same animation as when answering questions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageViewController.hasClients) {
        _pageViewController.animateToPage(_currentPage,
            curve: Curves.fastLinearToSlowEaseIn,
            duration: Duration(milliseconds: _ANIMATION_DELAY));
      }
    });
  }

  // Build the content for each page (review pages + current question) with performance optimizations
  Widget _buildPageContent(int index) {
    int completedCount = db.getCompletedQuestionsCount(widget.category);

    // Pages 0 to (completedCount-1): Show review pages (chronological order: oldest first)
    if (index < completedCount) {
      // Performance optimization: Check cache first, then database
      // For oldest first: index 0 = oldest question, index N = newest question
      Map<String, dynamic>? completedQuestion =
          _getCachedQuestion(widget.category, index);

      if (completedQuestion == null) {
        // Load from database and cache it
        completedQuestion = db.getCompletedQuestionAt(widget.category, index);

        if (completedQuestion != null) {
          _cacheQuestion(widget.category, index, completedQuestion);
        }
      }

      if (completedQuestion != null) {
        // Convert the completed question format to the format expected by QuizUI
        List questionForReview = [
          completedQuestion['question'], // question text
          completedQuestion['options'][0], // option 1 (correct)
          completedQuestion['options'][1], // option 2
          completedQuestion['options'][2], // option 3
        ];

        return QuizUI(
          badges: _badgeProgress,
          question: questionForReview,
          category: widget.category,
          checkAnswer: (ans) => db.checkAnswer(widget.category, ans),
          onAnswerSelected: (ans,
                  {bool clueUsed = false, int? removedOptionIndex}) =>
              {}, // No-op for review mode
          onClueUsed: null, // No clue usage in review mode
          onSkipUsed: null, // No skip usage in review mode
          isReviewMode: true,
          userSelectedAnswer: completedQuestion['user_answer'],
          wasAnswerCorrect: completedQuestion['is_correct'],
          correctAnswer: completedQuestion['correct_answer'],
          clueUsed: completedQuestion['clue_used'] ?? false,
          removedOptionIndex: completedQuestion['removed_option_index'],
        );
      } else {
        // Show loading placeholder while question is being loaded
        return _buildLoadingPage();
      }
    }

    // Last page: Always show current question (if available) or end screen
    if (index == completedCount) {
      if (next.isNotEmpty) {
        return QuizUI(
          badges: _badgeProgress,
          question: next,
          category: widget.category,
          checkAnswer: (ans) => db.checkAnswer(widget.category, ans),
          onAnswerSelected: (ans,
                  {bool clueUsed = false, int? removedOptionIndex}) =>
              updateScore(ans,
                  clueUsed: clueUsed, removedOptionIndex: removedOptionIndex),
          onClueUsed: () => setState(() => score = User().score),
          onSkipUsed: () => setState(() {
            score = User().score;
            _badgeProgress = User().badgeProgress;
          }),
          isReviewMode: false,
        );
      } else {
        // No more questions available
        return (!Questions().freeCategory(widget.category))
            ? PurchaseUI(
                category: widget.category,
                goToNextQuestion: goToNextQuestion,
                badges: _badgeProgress)
            : FreeCategoryUI(category: widget.category, badges: _badgeProgress);
      }
    }

    // Fallback - should not reach here
    return Container();
  }

  // Performance optimization: Loading placeholder for better UX
  Widget _buildLoadingPage() {
    return Container(
      padding: EdgeInsets.all(20.sp),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 2.h),
            Text(
              Malayalam.loadingQuestion,
              style: TextStyle(
                fontSize: ResponsiveText.myPointSize(context) * 0.8,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void updateScore(String answer,
      {bool clueUsed = false, int? removedOptionIndex}) {
    // Prevent multiple answer submissions
    if (_isProcessingAnswer) return;

    setState(() {
      _isProcessingAnswer = true;
    });

    // Extract the options in the order they were presented to the user
    List<String> presentedOptions = [
      next[1], // option 1
      next[2], // option 2
      next[3], // option 3
    ];

    // Track skip count before completing question to detect if skip was earned
    final skipCountBefore = user.skipCount;

    // Handle skip vs regular answer
    bool isSkipped = answer.isEmpty;
    db.completeQuestion(widget.category, answer, presentedOptions,
        clueUsed: clueUsed,
        removedOptionIndex: removedOptionIndex,
        isSkipped: isSkipped);

    // Check if skip was earned and send notification
    final skipCountAfter = user.skipCount;
    final consecutiveAfter = user.consecutiveCorrectAnswers;
    if (skipCountAfter > skipCountBefore) {
      final message =
          Malayalam.skipEarnedMessage(consecutiveAfter, skipCountAfter);
      // Send notification with delay to match other notifications
      Future.delayed(Duration(milliseconds: _ANIMATION_DELAY), () {
        if (mounted) {
          _showToastWithBotToast(
            message,
            SvgPicture.asset(
              'assets/skip-icon.svg',
              color: Colors.white,
            ),
            Duration(seconds: 3),
          );
        }
      });
    }

    // Badge progress will be updated after page transition to allow smooth animation
    // from current position to new position (forward or backward)

    // Use same delay for both skips and regular answers (2 seconds for UI animation)
    final delayDuration = Duration(milliseconds: _QUIZ_ANIMATION_DELAY);
    Future.delayed(delayDuration, () {
      if (mounted) {
        // Performance optimization: Use batch updates with scroll callback to ensure proper timing
        _scheduleBatchUpdate(() {
          next = db.nextQuestion(widget.category);
          score = user.score;
          // Current question is now at the last page after completing a question
          _currentPage = db.getCompletedQuestionsCount(widget.category);

          // Performance optimization: Clear cache for the new question to ensure fresh data
          _questionCache.clear();
          _preloadQuestions(_visibleStartPage, _visibleEndPage);
        }, onComplete: () {
          // Ensure we're on the current question page after answering (executes after batch update)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _pageViewController.hasClients) {
              _pageViewController.animateToPage(_currentPage,
                  curve: Curves.fastLinearToSlowEaseIn,
                  duration: Duration(milliseconds: _ANIMATION_DELAY));
            }
          });
        });

        // Update badge progress after the page transition completes
        // This allows badges to animate smoothly from old position to new position
        Future.delayed(Duration(milliseconds: _ANIMATION_DELAY), () {
          if (mounted) {
            _scheduleBatchUpdate(() {
              _badgeProgress = User().badgeProgress;
              _badgesCompletedWithLocation.forEach((completed) {
                // insert won badges to show user progress
                _badgeProgress.insert(completed[0],
                    [completed[1], completed[2], 1.0, completed[3]]);
              });
            });
          }
        });
      }
    });

    // Reset processing flag after full animation cycle completes
    // For skips, use shorter delay since there's no quiz animation
    final resetDelayDuration = isSkipped
        ? Duration(milliseconds: _ANIMATION_DELAY + 200)
        : Duration(
            milliseconds: _QUIZ_ANIMATION_DELAY + _ANIMATION_DELAY + 200);
    Future.delayed(resetDelayDuration, () {
      if (mounted) {
        setState(() {
          _isProcessingAnswer = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Padding(
        padding: EdgeInsets.only(right: 20.sp, left: 20.sp),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 7.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ScaleTransition(
                      scale: _backAnimation,
                      child: IgnorePointer(
                        ignoring: _isProcessingAnswer,
                        child: GestureDetector(
                          onTap: _isProcessingAnswer
                              ? null
                              : () async {
                                  await _backController.forward();
                                  await _backController.reverse();
                                  Navigator.of(context).pop();
                                },
                          child: Opacity(
                            opacity: _isProcessingAnswer ? 0.3 : 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    ResponsiveText.myPointSize(context)),
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                size: ResponsiveText.myPointSize(context) / 1.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: Listener(
                            onPointerDown: (_) =>
                                setState(() => _isProfilePressed = true),
                            onPointerUp: (_) =>
                                setState(() => _isProfilePressed = false),
                            onPointerCancel: (_) =>
                                setState(() => _isProfilePressed = false),
                            child: AnimatedScale(
                              scale: _isProfilePressed ? 0.92 : 1.0,
                              duration: const Duration(milliseconds: 120),
                              curve: Curves.easeOut,
                              child: JustTheTooltip(
                                isModal: true,
                                elevation: 0,
                                margin: EdgeInsets.all(30.sp),
                                backgroundColor: Colors.deepPurple.shade400,
                                content: Padding(
                                  padding: EdgeInsets.all(10.sp),
                                  child: Text(
                                    User().name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          ResponsiveText.bodySize(context),
                                    ),
                                  ),
                                ),
                                child: Container(
                                  width: ResponsiveText.myPointSize(context),
                                  height: ResponsiveText.myPointSize(context),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: User().profilePicBytes == null
                                        ? Colors.white
                                        : null,
                                    border: MyBorderStyle.standardBorder(),
                                    image: (User().profilePicBytes != null)
                                        ? DecorationImage(
                                            image: MemoryImage(
                                                User().profilePicBytes!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: User().profilePicBytes == null
                                      ? FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            User().name.isNotEmpty
                                                ? User().name[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              color: Colors.deepPurple,
                                              fontSize:
                                                  ResponsiveText.myPointSize(
                                                      context),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.sp),
                        AnimatedFlipCounter(
                          duration:
                              Duration(milliseconds: _ANIMATION_DELAY ~/ 2),
                          value: score,
                          textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveText.myPointSize(context),
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 1.h,
              ),
              Expanded(
                child: PageView.builder(
                  scrollDirection: Axis.vertical,
                  controller: _pageViewController,
                  onPageChanged: _onPageChanged,
                  physics: _totalPages > 1
                      ? const PageScrollPhysics() // Allow scrolling when there are review pages
                      : const ClampingScrollPhysics(), // Allow internal scrolling when only FreeCategoryUI
                  itemCount: _totalPages,
                  itemBuilder: (context, index) {
                    return Container(
                      padding: EdgeInsets.only(bottom: 10.sp),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.sp),
                        border: MyBorderStyle.standardBorder(),
                      ),
                      child: _buildPageContent(index),
                    );
                  },
                ),
              ),
              SizedBox(
                height: 2.h,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Alternative toast implementation using BotToast for better positioning control
  // BotToast offers more flexible positioning with Alignment values instead of fixed positions

  /// Shows a toast notification using BotToast with dynamic positioning after badge list.
  ///
  /// This method calculates the position relative to the badge list bottom and uses
  /// alignment-based positioning for better cross-device compatibility.
  ///
  /// [text] The message to display in the toast
  /// [icon] The icon to show alongside the text
  /// [duration] How long the toast should be visible
  void _showToastWithBotToast(String text, Widget icon, Duration duration) {
    // Calculate badge list bottom position: Top bar (7.h) + spacing (1.h) + badge row (6.h) + gap (35.sp)
    final badgeRowEndY = 7.h + 1.h + 6.h + 20.sp;

    BotToast.showCustomNotification(
      duration: duration,
      toastBuilder: (cancelFunc) => Container(
        padding: EdgeInsets.only(top: badgeRowEndY, left: 25.sp, right: 25.sp),
        child: UserNotification(text: text, icon: icon),
      ),
      animationDuration: Duration(milliseconds: 300),
      animationReverseDuration: Duration(milliseconds: 200),
    );
  }
}
