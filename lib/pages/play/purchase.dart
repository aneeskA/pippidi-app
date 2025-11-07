import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pippidi/data/questions.dart';
import 'package:pippidi/util/responsive_text.dart';
import 'package:pippidi/util/constants.dart';
import 'package:pippidi/ui/mybutton.dart';
import 'package:pippidi/ui/badges_list.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:sizer/sizer.dart';

class PurchaseUI extends StatefulWidget {
  final String category;
  final Function goToNextQuestion;
  final List badges;
  final List? nextQuestion; // For showing answers on button flip
  const PurchaseUI({
    super.key,
    required this.category,
    required this.goToNextQuestion,
    required this.badges,
    this.nextQuestion,
  });

  @override
  State<PurchaseUI> createState() => _PurchaseUIState();
}

class _PurchaseUIState extends State<PurchaseUI> with TickerProviderStateMixin {
  // Flip animation for button transitions
  AnimationController? _flipController;
  Animation<double>? _flipAnimation;
  bool _isFlipping = false;

  @override
  void initState() {
    super.initState();

    // Initialize flip controller
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController!, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _flipController?.dispose();
    super.dispose();
  }

  void _triggerFlipAnimation() {
    if (_isFlipping) return;

    setState(() {
      _isFlipping = true;
    });

    _flipController?.forward(from: 0.0).then((_) {
      // Small delay to ensure animation has fully settled before resetting state
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          setState(() {
            _isFlipping = false;
          });
        }
      });
    });
  }

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
              Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 7.sp),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width - 80,
                      height: 6.h,
                      child: ListView.separated(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.badges.length,
                        itemBuilder: (context, index) {
                          return BadgesList(
                            percent: widget.badges[index][2],
                            caption: widget.badges[index][1],
                            iconValue: widget.badges[index][3],
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) {
                          return SizedBox(
                            width: 8.sp,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(5.sp),
                    child: AutoSizeText(
                      Malayalam.gameFinished,
                      textAlign: TextAlign.center,
                      style: ResponsiveText.questionStyle(context),
                      maxLines: 4,
                      minFontSize: ResponsiveText.superscriptSize(context)
                          .roundToDouble(),
                      maxFontSize:
                          ResponsiveText.questionSize(context).roundToDouble(),
                      stepGranularity: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 6.h,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final buttonHeight = constraints.maxHeight / 3;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (Questions().avaiableToBuy(widget.category, 25))
                    SizedBox(
                      height: buttonHeight,
                      child: Stack(
                        children: [
                          Container(color: Colors.deepPurple),
                          AnimatedBuilder(
                            animation:
                                _flipAnimation ?? AlwaysStoppedAnimation(0.0),
                            builder: (context, child) {
                              // Apply horizontal shake transformation
                              double flipValue = _flipAnimation?.value ?? 0.0;
                              // Create shake effect: multiple oscillations with decreasing amplitude
                              double shakeFrequency = 6.0; // Number of shakes
                              double shakeAmplitude = 15.0 *
                                  (1.0 -
                                      flipValue); // Amplitude decreases over time
                              double shakeOffset =
                                  sin(flipValue * 3.14159 * shakeFrequency) *
                                      shakeAmplitude;

                              // Smooth transition between front and back content
                              // Front content (0-30%): full opacity, (30-70%): fading out
                              // Back content (30-70%): fading in, (70-100%): full opacity

                              double frontOpacity;
                              double backOpacity;

                              if (flipValue < 0.3) {
                                // First 30%: Show front at full opacity
                                frontOpacity = 1.0;
                                backOpacity = 0.0;
                              } else if (flipValue < 0.7) {
                                // Transition 30-70%: Fade between front and back (40% of animation)
                                double transitionProgress =
                                    (flipValue - 0.3) / 0.4; // 0 to 1
                                frontOpacity = 1.0 - transitionProgress;
                                backOpacity = transitionProgress;
                              } else {
                                // Last 30%: Show back at full opacity
                                frontOpacity = 0.0;
                                backOpacity = 1.0;
                              }

                              String frontText = Malayalam.buyQuestions(25);
                              Color frontColor = Colors.deepPurple.shade900;

                              String backText = widget.nextQuestion != null &&
                                      widget.nextQuestion!.length > 2
                                  ? widget.nextQuestion![2] // Second option
                                  : Malayalam.buyQuestions(25);
                              Color backColor =
                                  Colors.green.shade700; // Green for answer

                              return Stack(
                                children: [
                                  // Front side
                                  Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..setEntry(3, 2, 0.002)
                                      ..translate(
                                          shakeOffset, 0.0), // Horizontal shake
                                    child: Opacity(
                                      opacity: frontOpacity,
                                      child: MyButton(
                                        text: frontText,
                                        myColor: frontColor,
                                        callBack: () =>
                                            widget.goToNextQuestion(),
                                      ),
                                    ),
                                  ),
                                  // Back side
                                  Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..setEntry(3, 2, 0.002)
                                      ..translate(
                                          shakeOffset, 0.0), // Horizontal shake
                                    child: IgnorePointer(
                                      ignoring: backOpacity < 0.1,
                                      child: Opacity(
                                        opacity: backOpacity,
                                        child: MyButton(
                                          text: backText,
                                          myColor: backColor,
                                          callBack: null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  if (Questions().avaiableToBuy(widget.category, 100))
                    SizedBox(
                      height: buttonHeight,
                      child: Stack(
                        children: [
                          Container(color: Colors.deepPurple),
                          AnimatedBuilder(
                            animation:
                                _flipAnimation ?? AlwaysStoppedAnimation(0.0),
                            builder: (context, child) {
                              // Apply horizontal shake transformation
                              double flipValue = _flipAnimation?.value ?? 0.0;
                              // Create shake effect: multiple oscillations with decreasing amplitude
                              double shakeFrequency = 6.0; // Number of shakes
                              double shakeAmplitude = 15.0 *
                                  (1.0 -
                                      flipValue); // Amplitude decreases over time
                              double shakeOffset =
                                  sin(flipValue * 3.14159 * shakeFrequency) *
                                      shakeAmplitude;

                              // Smooth transition between front and back content
                              // Front content (0-30%): full opacity, (30-70%): fading out
                              // Back content (30-70%): fading in, (70-100%): full opacity

                              double frontOpacity;
                              double backOpacity;

                              if (flipValue < 0.3) {
                                // First 30%: Show front at full opacity
                                frontOpacity = 1.0;
                                backOpacity = 0.0;
                              } else if (flipValue < 0.7) {
                                // Transition 30-70%: Fade between front and back (40% of animation)
                                double transitionProgress =
                                    (flipValue - 0.3) / 0.4; // 0 to 1
                                frontOpacity = 1.0 - transitionProgress;
                                backOpacity = transitionProgress;
                              } else {
                                // Last 30%: Show back at full opacity
                                frontOpacity = 0.0;
                                backOpacity = 1.0;
                              }

                              String frontText = Malayalam.buyQuestions(100);
                              Color frontColor = Colors.deepPurple.shade900;

                              String backText = widget.nextQuestion != null &&
                                      widget.nextQuestion!.length > 3
                                  ? widget.nextQuestion![3] // Third option
                                  : Malayalam.buyQuestions(100);
                              Color backColor =
                                  Colors.green.shade700; // Green for answer

                              return Stack(
                                children: [
                                  // Front side
                                  Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..setEntry(3, 2, 0.002)
                                      ..translate(
                                          shakeOffset, 0.0), // Horizontal shake
                                    child: Opacity(
                                      opacity: frontOpacity,
                                      child: MyButton(
                                        text: frontText,
                                        myColor: frontColor,
                                        callBack: () =>
                                            widget.goToNextQuestion(),
                                      ),
                                    ),
                                  ),
                                  // Back side
                                  Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..setEntry(3, 2, 0.002)
                                      ..translate(
                                          shakeOffset, 0.0), // Horizontal shake
                                    child: IgnorePointer(
                                      ignoring: backOpacity < 0.1,
                                      child: Opacity(
                                        opacity: backOpacity,
                                        child: MyButton(
                                          text: backText,
                                          myColor: backColor,
                                          callBack: null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  if (Questions().avaiableToBuy(widget.category, 5))
                    SizedBox(
                      height: buttonHeight,
                      child: Stack(
                        children: [
                          Container(color: Colors.deepPurple),
                          AnimatedBuilder(
                            animation:
                                _flipAnimation ?? AlwaysStoppedAnimation(0.0),
                            builder: (context, child) {
                              // Apply horizontal shake transformation
                              double flipValue = _flipAnimation?.value ?? 0.0;
                              // Create shake effect: multiple oscillations with decreasing amplitude
                              double shakeFrequency = 6.0; // Number of shakes
                              double shakeAmplitude = 15.0 *
                                  (1.0 -
                                      flipValue); // Amplitude decreases over time
                              double shakeOffset =
                                  sin(flipValue * 3.14159 * shakeFrequency) *
                                      shakeAmplitude;

                              // Smooth transition between front and back content
                              // Front content (0-30%): full opacity, (30-70%): fading out
                              // Back content (30-70%): fading in, (70-100%): full opacity

                              double frontOpacity;
                              double backOpacity;

                              if (flipValue < 0.3) {
                                // First 30%: Show front at full opacity
                                frontOpacity = 1.0;
                                backOpacity = 0.0;
                              } else if (flipValue < 0.7) {
                                // Transition 30-70%: Fade between front and back (40% of animation)
                                double transitionProgress =
                                    (flipValue - 0.3) / 0.4; // 0 to 1
                                frontOpacity = 1.0 - transitionProgress;
                                backOpacity = transitionProgress;
                              } else {
                                // Last 30%: Show back at full opacity
                                frontOpacity = 0.0;
                                backOpacity = 1.0;
                              }

                              String frontText = Malayalam.later;
                              Color frontColor = Colors.deepPurple.shade900;

                              String backText = widget.nextQuestion != null &&
                                      widget.nextQuestion!.length > 1
                                  ? widget.nextQuestion![
                                      1] // First option (typically correct)
                                  : Malayalam.later;
                              Color backColor =
                                  Colors.green.shade700; // Green for answer

                              return Stack(
                                children: [
                                  // Front side
                                  Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..setEntry(3, 2, 0.002)
                                      ..translate(
                                          shakeOffset, 0.0), // Horizontal shake
                                    child: Opacity(
                                      opacity: frontOpacity,
                                      child: MyButton(
                                        text: frontText,
                                        myColor: frontColor,
                                        callBack: _isFlipping
                                            ? null
                                            : () {
                                                _triggerFlipAnimation();
                                                // Wait for flip animation to complete before transitioning
                                                Future.delayed(
                                                    const Duration(
                                                        milliseconds: 400), () {
                                                  if (mounted) {
                                                    Questions()
                                                        .raiseAvailableLimit(
                                                            widget.category, 5);
                                                    widget.goToNextQuestion();
                                                  }
                                                });
                                              },
                                      ),
                                    ),
                                  ),
                                  // Back side
                                  Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..setEntry(3, 2, 0.002)
                                      ..translate(
                                          shakeOffset, 0.0), // Horizontal shake
                                    child: IgnorePointer(
                                      ignoring: backOpacity < 0.1,
                                      child: Opacity(
                                        opacity: backOpacity,
                                        child: MyButton(
                                          text: backText,
                                          myColor: backColor,
                                          callBack: null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
