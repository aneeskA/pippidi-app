import 'dart:async';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:badges/badges.dart' as MyBadge;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sizer/sizer.dart';
import 'package:pippidi/data/user.dart';
import 'package:pippidi/data/questions.dart';
import 'package:pippidi/ui/badges_list.dart';
import 'package:pippidi/ui/mybutton.dart';
import 'package:pippidi/util/responsive_text.dart';

class QuizUI extends StatefulWidget {
  final List badges;
  final List question;
  final String category; // Add category for hint scoring
  final bool Function(String) checkAnswer;
  final void Function(String, {bool clueUsed, int? removedOptionIndex})
      onAnswerSelected;
  final void Function()? onClueUsed; // Callback for when clue is used
  final void Function()? onSkipUsed; // Callback for when skip is used
  final void Function()? onSkipEarned; // Callback for when skip is earned

  // Review mode parameters
  final bool isReviewMode;
  final String? userSelectedAnswer;
  final bool? wasAnswerCorrect;
  final String? correctAnswer;
  final bool? clueUsed;
  final int? removedOptionIndex;

  const QuizUI({
    super.key,
    required this.badges,
    required this.question,
    required this.category, // Add required category parameter
    required this.checkAnswer,
    required this.onAnswerSelected,
    this.onClueUsed,
    this.onSkipUsed,
    this.onSkipEarned,
    this.isReviewMode = false,
    this.userSelectedAnswer,
    this.wasAnswerCorrect,
    this.correctAnswer,
    this.clueUsed,
    this.removedOptionIndex,
  });

  @override
  State<QuizUI> createState() => _QuizUIState();
}

class _QuizUIState extends State<QuizUI> with TickerProviderStateMixin {
  int? selectedIndex;
  bool? isCorrect;
  int? correctIndex;
  bool isProcessing = false;

  // Clue functionality
  Timer? _clueTimer;
  bool _showClueButton = false;
  bool _clueUsed = false;

  // Skip functionality
  bool _showSkipButton = false;
  bool _skipUsed = false;
  bool _showSkipInLower = false;
  AnimationController? _skipController;
  late Animation<double> _skipAnimation;
  AnimationController? _clueGrowController;
  Animation<double>? _clueGrowAnimation;
  AnimationController? _clueShrinkController;
  Animation<double>? _clueShrinkAnimation;
  AnimationController? _clueStackMoveController;
  Animation<double>? _clueStackMoveAnimation;

  // Button shrink animations for clue
  AnimationController? _buttonShrinkController;
  Animation<double>? _buttonShrinkAnimation;
  int? _shrinkingButtonIndex;
  List<bool> _shrunkButtons = [
    false,
    false,
    false
  ]; // Track buttons that have been shrunk

  List<bool> _visibleButtons = [true, true, true];

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _clueGrowController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _clueGrowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _clueGrowController!, curve: Curves.easeOut),
    );

    _clueShrinkController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _clueShrinkAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _clueShrinkController!, curve: Curves.easeIn),
    );

    _clueStackMoveController = AnimationController(
      duration: const Duration(
          milliseconds: 600), // Match button repositioning duration
      vsync: this,
    );
    _clueStackMoveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _clueStackMoveController!, curve: Curves.easeOut),
    );

    // Initialize button shrink controller
    _buttonShrinkController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _buttonShrinkAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _buttonShrinkController!, curve: Curves.easeIn),
    );

    // Initialize skip animation controller
    _skipController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _skipAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _skipController!, curve: Curves.easeOut),
    );

    if (widget.isReviewMode) {
      _initializeReviewMode();
      // Force a rebuild after initialization
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      // Start clue timer for quiz mode
      _startClueTimer();
      // Check if skip is available immediately
      _checkSkipAvailability();
    }
  }

  @override
  void didUpdateWidget(QuizUI oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset state when question changes or when switching between review mode and quiz mode
    if (oldWidget.question != widget.question ||
        oldWidget.isReviewMode != widget.isReviewMode) {
      selectedIndex = null;
      isCorrect = null;
      correctIndex = null;
      isProcessing = false;
      _showClueButton = false;
      _clueUsed = false;
      _showSkipButton = false;
      _skipUsed = false;
      _showSkipInLower = false;
      _shrinkingButtonIndex = null;
      _shrunkButtons = [false, false, false];
      _visibleButtons = [true, true, true];
      _clueStackMoveController?.reset();

      // Cancel existing timer and start new one for new question
      _clueTimer?.cancel();
      if (!widget.isReviewMode) {
        _startClueTimer();
      }

      if (widget.isReviewMode) {
        _initializeReviewMode();
      }
    }
  }

  @override
  void deactivate() {
    // Stop timer when widget becomes inactive (e.g., when navigating away)
    _clueTimer?.cancel();
    super.deactivate();
  }

  @override
  void dispose() {
    _clueTimer?.cancel();
    _clueGrowController?.dispose();
    _clueShrinkController?.dispose();
    _clueStackMoveController?.dispose();
    _buttonShrinkController?.dispose();
    _skipController?.dispose();
    super.dispose();
  }

  void _initializeReviewMode() {
    if (widget.userSelectedAnswer != null &&
        widget.userSelectedAnswer!.isNotEmpty) {
      // Find the index of the user's selected answer
      int userIndex = -1;
      for (int i = 1; i < widget.question.length; i++) {
        if (widget.question[i] == widget.userSelectedAnswer) {
          userIndex = i - 1; // Convert to 0-based index
          break;
        }
      }

      if (userIndex != -1) {
        selectedIndex = userIndex;
        isCorrect = widget.wasAnswerCorrect;
      }
    }

    // Always show the correct answer in review mode (for both answered and skipped questions)
    if (widget.correctAnswer != null) {
      for (int i = 1; i < widget.question.length; i++) {
        if (widget.question[i] == widget.correctAnswer) {
          correctIndex = i - 1; // Convert to 0-based index
          break;
        }
      }
    }

    // Initialize clue state for review mode
    if (widget.clueUsed == true && widget.removedOptionIndex != null) {
      _clueUsed = true;
      _removedOptionIndex = widget.removedOptionIndex;
      _visibleButtons[widget.removedOptionIndex!] = false;
    }
  }

  void _startClueTimer() {
    _clueTimer?.cancel();
    _clueTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_clueUsed && !_showClueButton && !isProcessing) {
        // Check if user has enough points for clue based on category
        final scoring = Questions.getCategoryScoring(widget.category);
        final hintCost = scoring['hint']!.abs();
        if (User().score >= hintCost) {
          setState(() {
            _showClueButton = true;
          });
          _clueGrowController?.forward();
        }
      }
    });
  }

  void _onCluePressed() {
    if (_clueUsed || isProcessing) return;

    setState(() {
      _clueUsed = true;
    });

    // Reduce hint cost from score based on category
    final scoring = Questions.getCategoryScoring(widget.category);
    final hintCost =
        scoring['hint']!.abs(); // Use absolute value since it's a deduction
    User user = User();
    user.score = user.score - hintCost;

    // Notify parent about score change
    widget.onClueUsed?.call();

    // Start button shrink animation immediately
    _startButtonShrink();
  }

  void _checkSkipAvailability() {
    if (User().skipCount > 0 && !_skipUsed) {
      setState(() {
        _showSkipButton = true;
      });
    }
  }

  void _onSkipPressed() async {
    if (_skipUsed || isProcessing || User().skipCount <= 0) return;

    // Find the correct answer index (same logic as _selectOption)
    int corrIndex;
    if (widget.checkAnswer(widget.question[1])) {
      corrIndex = 0;
    } else if (widget.checkAnswer(widget.question[2])) {
      corrIndex = 1;
    } else {
      corrIndex = 2;
    }

    // Start the scale animation like in user_account.dart
    await _skipController?.forward();
    await _skipController?.reverse();

    // Process skip immediately to prevent exploitation
    User().useSkip();
    widget.onSkipUsed?.call();
    widget.onAnswerSelected('',
        clueUsed: _clueUsed, removedOptionIndex: _removedOptionIndex);

    setState(() {
      selectedIndex = null; // No answer selected for skip
      isCorrect = null; // Not applicable for skip
      correctIndex = corrIndex; // Show correct answer with green border
      isProcessing = true;
      _showSkipButton = false; // Hide skip button immediately
      _skipUsed = true;
    });

    // Use same delay as regular answers (2 seconds for UI animation)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // UI updates handled by parent after answer processing
      }
    });
  }

  void _startButtonShrink() {
    // Find the correct answer index
    int correctAnswerIndex = -1;
    for (int i = 1; i < widget.question.length; i++) {
      if (widget.checkAnswer(widget.question[i])) {
        correctAnswerIndex = i - 1; // Convert to 0-based index
        break;
      }
    }

    if (correctAnswerIndex == -1) return;

    // Find wrong answer indices
    List<int> wrongIndices = [];
    for (int i = 0; i < 3; i++) {
      if (i != correctAnswerIndex) {
        wrongIndices.add(i);
      }
    }

    // Select a random wrong answer to remove
    final random = Random();
    int indexToRemove = wrongIndices[random.nextInt(wrongIndices.length)];
    _removedOptionIndex = indexToRemove; // Store for persistence

    // Set the shrinking button index and trigger position animation immediately
    setState(() {
      _shrinkingButtonIndex = indexToRemove;
    });

    // Start clue-skip stack move animation simultaneously with button repositioning
    _clueStackMoveController?.forward();

    // Add listener for completion
    _clueStackMoveController?.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _showSkipInLower = true;
        });
      }
    });

    // Start shrink animation - this will also trigger the fall animation simultaneously
    _buttonShrinkController?.forward().then((_) {
      if (mounted) {
        // Mark button as shrunk (but don't hide yet - let it finish falling)
        setState(() {
          _shrunkButtons[indexToRemove] = true; // Keep button scaled down
          // Keep _shrinkingButtonIndex set until fall animation completes
        });

        // Wait for fall animation to complete (1000ms) before hiding the button
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              _visibleButtons[indexToRemove] = false;
              _shrinkingButtonIndex = null; // Now safe to clear
            });

            // Start clue button shrink after button is hidden
            _clueShrinkController?.forward().then((_) {
              if (mounted) {
                setState(() {
                  _showClueButton = false;
                });
              }
            });
          }
        });
      }
    });
  }

  void _selectOption(int index, String ans) {
    if (widget.isReviewMode) return; // No interaction in review mode

    final correct = widget.checkAnswer(ans);
    int? corrIndex;
    if (!correct) {
      if (widget.checkAnswer(widget.question[1])) {
        corrIndex = 0;
      } else if (widget.checkAnswer(widget.question[2])) {
        corrIndex = 1;
      } else {
        corrIndex = 2;
      }
    }
    // Process answer immediately to prevent exploitation
    widget.onAnswerSelected(ans,
        clueUsed: _clueUsed, removedOptionIndex: _removedOptionIndex);

    setState(() {
      selectedIndex = index;
      isCorrect = correct;
      correctIndex = corrIndex;
      isProcessing = true;
    });

    // Keep the delay for UI animation only
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // UI updates handled by parent after answer processing
      }
    });
  }

  int? _removedOptionIndex; // Track which option was removed by clue

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              SizedBox(
                height: 1.h,
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    children: [
                      SizedBox(
                        width: constraints.maxWidth,
                        height: 6.h,
                        child: ListView.separated(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.badges.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(
                                  left: index == 0 ? 5.sp : 0.sp),
                              child: BadgesList(
                                percent: widget.badges[index][2],
                                caption: widget.badges[index][1],
                                iconValue: widget.badges[index][3],
                              ),
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) {
                            return SizedBox(
                              width: 8.sp,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              Expanded(
                child: AnimatedOpacity(
                  opacity: isProcessing && selectedIndex == null ? 0.5 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(5.sp),
                      child: AutoSizeText(
                        widget.question[0],
                        textAlign: TextAlign.center,
                        style: ResponsiveText.questionStyle(context),
                        maxLines: null,
                        minFontSize: ResponsiveText.superscriptSize(context)
                            .roundToDouble(),
                        maxFontSize: ResponsiveText.questionSize(context)
                            .roundToDouble(),
                        stepGranularity: 1,
                      ),
                    ),
                  ),
                ),
              ),
              // Restore original animated transform for stack movement
              AnimatedBuilder(
                animation:
                    _clueStackMoveAnimation ?? AlwaysStoppedAnimation(0.0),
                builder: (context, child) {
                  // Calculate the movement distance based on available height
                  // Move down to occupy the space of the eliminated button
                  final moveDistance = _clueStackMoveAnimation?.value ?? 0.0;
                  // Move down by approximately 9.h to position in the space left by the eliminated button
                  // This fills the gap created when one of the three buttons is removed
                  final translationY = moveDistance * 9.h;

                  return Transform.translate(
                    offset: Offset(0, translationY),
                    child: SizedBox(
                      height: 6.h,
                      child: Stack(
                        children: [
                          // Clue button
                          if (_showClueButton)
                            Positioned(
                              right: _showSkipButton ? 35.sp : 15.sp,
                              bottom: 5.sp,
                              child: AnimatedBuilder(
                                animation: Listenable.merge([
                                  _clueGrowAnimation,
                                  _clueShrinkAnimation,
                                ]),
                                builder: (context, child) {
                                  double opacity =
                                      _clueGrowAnimation?.value ?? 0.0;
                                  if (_clueShrinkController?.isAnimating ??
                                      false) {
                                    opacity =
                                        _clueShrinkAnimation?.value ?? 0.0;
                                  }
                                  return Opacity(
                                    opacity: opacity,
                                    child: SizedBox(
                                      width: _showSkipButton ? 20.sp : 30.sp,
                                      height: 30.sp,
                                      child: IconButton(
                                        onPressed:
                                            _clueUsed ? null : _onCluePressed,
                                        icon: Icon(
                                          _clueUsed
                                              ? Icons.lightbulb
                                              : Icons.lightbulb_outline,
                                          size: 24.sp,
                                          color: Colors.white,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(),
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          // Skip button in upper - hide visual and disable hits after switch
                          if (_showSkipButton && !_showSkipInLower)
                            Positioned(
                              right: 15.sp,
                              bottom: 5.sp,
                              child: IgnorePointer(
                                ignoring: _showSkipInLower,
                                child: SizedBox(
                                  width: 30.sp,
                                  height: 30.sp,
                                  child: IconButton(
                                    onPressed:
                                        _skipUsed ? null : _onSkipPressed,
                                    icon: ScaleTransition(
                                      scale: _skipAnimation,
                                      child: User().skipCount > 1
                                          ? MyBadge.Badge(
                                              badgeAnimation:
                                                  MyBadge.BadgeAnimation.scale(
                                                toAnimate: false,
                                              ),
                                              badgeStyle: MyBadge.BadgeStyle(
                                                badgeColor: Colors.green,
                                              ),
                                              badgeContent: Text(
                                                User().skipCount.toString(),
                                                style: ResponsiveText
                                                    .superscriptStyle(context),
                                              ),
                                              child: SvgPicture.asset(
                                                'assets/skip-icon.svg',
                                                width: 22.sp,
                                                height: 22.sp,
                                                color: Colors.white,
                                              ),
                                            )
                                          : SvgPicture.asset(
                                              'assets/skip-icon.svg',
                                              width: 22.sp,
                                              height: 22.sp,
                                              color: Colors.white,
                                            ),
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    splashColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final buttonHeight = constraints.maxHeight / 3;

              // Calculate positions for visible buttons (they should fall to fill gaps)
              int positionIndex = 0;
              final buttonPositions = <int, double>{};

              for (int i = 0; i < 3; i++) {
                // During animation, exclude the shrinking button from position calculation
                // so remaining buttons move up immediately to fill the gap
                if (_visibleButtons[i] && _shrinkingButtonIndex != i) {
                  buttonPositions[i] = positionIndex * buttonHeight;
                  positionIndex++;
                }
              }

              // Special handling for shrinking button - let it fall below visible area
              if (_shrinkingButtonIndex != null) {
                buttonPositions[_shrinkingButtonIndex!] =
                    -buttonHeight * 2; // Fall below the bottom
              }

              return Stack(
                children: [
                  // Button 1
                  AnimatedPositioned(
                    duration: _shrinkingButtonIndex == 0
                        ? const Duration(
                            milliseconds:
                                600) // Faster fall for discarded button
                        : const Duration(
                            milliseconds:
                                600), // Smooth slide for repositioning buttons
                    curve: _shrinkingButtonIndex == 0
                        ? Curves.easeIn // Accelerate the falling button
                        : Curves
                            .easeOut, // Match stack move curve for repositioning buttons
                    bottom: buttonPositions[0] ?? -buttonHeight,
                    left: 0,
                    right: 0,
                    height: buttonHeight,
                    child: AnimatedBuilder(
                      animation:
                          _buttonShrinkAnimation ?? AlwaysStoppedAnimation(1.0),
                      builder: (context, child) {
                        Widget button = MyButton(
                          text: widget.question[1],
                          myColor: Colors.deepPurple.shade900,
                          callBack: widget.isReviewMode ||
                                  isProcessing ||
                                  !_visibleButtons[0]
                              ? null
                              : () => _selectOption(0, widget.question[1]),
                          borderColor: (
                                  // Skipped questions: green border on correct answer
                                  (selectedIndex == null &&
                                          correctIndex == 0) ||
                                      // Wrong answers: green border on correct answer
                                      (selectedIndex != null &&
                                          isCorrect == false &&
                                          correctIndex == 0))
                              ? Colors.green
                              : null,
                          feedbackType: widget.isReviewMode
                              ? (selectedIndex == null
                                  ? null // No background color change for skipped questions
                                  : ((selectedIndex == 0)
                                      ? ((isCorrect == true)
                                          ? 'correct'
                                          : 'wrong')
                                      : null))
                              : ((selectedIndex == 0)
                                  ? (isCorrect! ? 'correct' : 'wrong')
                                  : null),
                        );

                        if (_shrinkingButtonIndex == 0) {
                          // Height animation for shrinking button
                          double heightFactor =
                              _buttonShrinkAnimation?.value ?? 1.0;
                          button = ClipRect(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              heightFactor: heightFactor,
                              child: AnimatedOpacity(
                                opacity: _visibleButtons[0] ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 250),
                                child: button,
                              ),
                            ),
                          );
                        } else {
                          // Scale animation for non-shrinking buttons
                          double shrinkScale = _shrunkButtons[0] ? 0.0 : 1.0;
                          button = Transform.scale(
                            scale: shrinkScale,
                            child: AnimatedOpacity(
                              opacity: _visibleButtons[0] ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 250),
                              child: button,
                            ),
                          );
                        }

                        return button;
                      },
                    ),
                  ),
                  // Button 2
                  AnimatedPositioned(
                    duration: _shrinkingButtonIndex == 1
                        ? const Duration(
                            milliseconds:
                                600) // Faster fall for discarded button
                        : const Duration(
                            milliseconds:
                                600), // Smooth slide for repositioning buttons
                    curve: _shrinkingButtonIndex == 1
                        ? Curves.easeIn // Accelerate the falling button
                        : Curves
                            .easeOut, // Match stack move curve for repositioning buttons
                    bottom: buttonPositions[1] ?? -buttonHeight,
                    left: 0,
                    right: 0,
                    height: buttonHeight,
                    child: AnimatedBuilder(
                      animation:
                          _buttonShrinkAnimation ?? AlwaysStoppedAnimation(1.0),
                      builder: (context, child) {
                        Widget button = MyButton(
                          text: widget.question[2],
                          myColor: Colors.deepPurple.shade900,
                          callBack: widget.isReviewMode ||
                                  isProcessing ||
                                  !_visibleButtons[1]
                              ? null
                              : () => _selectOption(1, widget.question[2]),
                          borderColor: (
                                  // Skipped questions: green border on correct answer
                                  (selectedIndex == null &&
                                          correctIndex == 1) ||
                                      // Wrong answers: green border on correct answer
                                      (selectedIndex != null &&
                                          isCorrect == false &&
                                          correctIndex == 1))
                              ? Colors.green
                              : null,
                          feedbackType: widget.isReviewMode
                              ? (selectedIndex == null
                                  ? null // No background color change for skipped questions
                                  : ((selectedIndex == 1)
                                      ? ((isCorrect == true)
                                          ? 'correct'
                                          : 'wrong')
                                      : null))
                              : ((selectedIndex == 1)
                                  ? (isCorrect! ? 'correct' : 'wrong')
                                  : null),
                        );

                        if (_shrinkingButtonIndex == 1) {
                          // Height animation for shrinking button
                          double heightFactor =
                              _buttonShrinkAnimation?.value ?? 1.0;
                          button = ClipRect(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              heightFactor: heightFactor,
                              child: AnimatedOpacity(
                                opacity: _visibleButtons[1] ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 250),
                                child: button,
                              ),
                            ),
                          );
                        } else {
                          // Scale animation for non-shrinking buttons
                          double shrinkScale = _shrunkButtons[1] ? 0.0 : 1.0;
                          button = Transform.scale(
                            scale: shrinkScale,
                            child: AnimatedOpacity(
                              opacity: _visibleButtons[1] ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 250),
                              child: button,
                            ),
                          );
                        }

                        return button;
                      },
                    ),
                  ),
                  // Button 3
                  AnimatedPositioned(
                    duration: _shrinkingButtonIndex == 2
                        ? const Duration(
                            milliseconds:
                                600) // Faster fall for discarded button
                        : const Duration(
                            milliseconds:
                                600), // Smooth slide for repositioning buttons
                    curve: _shrinkingButtonIndex == 2
                        ? Curves.easeIn // Accelerate the falling button
                        : Curves
                            .easeOut, // Match stack move curve for repositioning buttons
                    bottom: buttonPositions[2] ?? -buttonHeight,
                    left: 0,
                    right: 0,
                    height: buttonHeight,
                    child: AnimatedBuilder(
                      animation:
                          _buttonShrinkAnimation ?? AlwaysStoppedAnimation(1.0),
                      builder: (context, child) {
                        Widget button = MyButton(
                          text: widget.question[3],
                          myColor: Colors.deepPurple.shade900,
                          callBack: widget.isReviewMode ||
                                  isProcessing ||
                                  !_visibleButtons[2]
                              ? null
                              : () => _selectOption(2, widget.question[3]),
                          borderColor: (
                                  // Skipped questions: green border on correct answer
                                  (selectedIndex == null &&
                                          correctIndex == 2) ||
                                      // Wrong answers: green border on correct answer
                                      (selectedIndex != null &&
                                          isCorrect == false &&
                                          correctIndex == 2))
                              ? Colors.green
                              : null,
                          feedbackType: widget.isReviewMode
                              ? (selectedIndex == null
                                  ? null // No background color change for skipped questions
                                  : ((selectedIndex == 2)
                                      ? ((isCorrect == true)
                                          ? 'correct'
                                          : 'wrong')
                                      : null))
                              : ((selectedIndex == 2)
                                  ? (isCorrect! ? 'correct' : 'wrong')
                                  : null),
                        );

                        if (_shrinkingButtonIndex == 2) {
                          // Height animation for shrinking button
                          double heightFactor =
                              _buttonShrinkAnimation?.value ?? 1.0;
                          button = ClipRect(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              heightFactor: heightFactor,
                              child: AnimatedOpacity(
                                opacity: _visibleButtons[2] ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 250),
                                child: button,
                              ),
                            ),
                          );
                        } else {
                          // Scale animation for non-shrinking buttons
                          double shrinkScale = _shrunkButtons[2] ? 0.0 : 1.0;
                          button = Transform.scale(
                            scale: shrinkScale,
                            child: AnimatedOpacity(
                              opacity: _visibleButtons[2] ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 250),
                              child: button,
                            ),
                          );
                        }

                        return button;
                      },
                    ),
                  ),
                  // Remove old proxy, add new skip in lower
                  if (_showSkipInLower &&
                      _showSkipButton &&
                      !_skipUsed &&
                      !isProcessing)
                    Positioned(
                      top: 2.5.h,
                      right: 15.sp,
                      child: SizedBox(
                        width: 30.sp,
                        height: 30.sp,
                        child: IconButton(
                          onPressed: _skipUsed ? null : _onSkipPressed,
                          icon: ScaleTransition(
                            scale: _skipAnimation,
                            child: User().skipCount > 1
                                ? MyBadge.Badge(
                                    badgeAnimation:
                                        MyBadge.BadgeAnimation.scale(
                                      toAnimate: false,
                                    ),
                                    badgeStyle: MyBadge.BadgeStyle(
                                      badgeColor: Colors.green,
                                    ),
                                    badgeContent: Text(
                                      User().skipCount.toString(),
                                      style: ResponsiveText.superscriptStyle(
                                          context),
                                    ),
                                    child: SvgPicture.asset(
                                      'assets/skip-icon.svg',
                                      width: 22.sp,
                                      height: 22.sp,
                                      color: Colors.white,
                                    ),
                                  )
                                : SvgPicture.asset(
                                    'assets/skip-icon.svg',
                                    width: 22.sp,
                                    height: 22.sp,
                                    color: Colors.white,
                                  ),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          focusColor: Colors.transparent,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        )
      ],
    );
  }
}
