import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:animated_icon_button/animated_icon_button.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sizer/sizer.dart';

import 'package:pippidi/pages/play.dart';
import 'package:pippidi/util/constants.dart';
import 'package:pippidi/data/questions.dart';
import 'package:pippidi/util/install_new_questions.dart';
import 'package:pippidi/ui/titlebar.dart';
import 'package:pippidi/ui/category_card.dart';
import 'package:pippidi/util/responsive_text.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class Categories extends StatefulWidget {
  final int jumpTo;
  final String category;
  const Categories({
    super.key,
    this.jumpTo = 0,
    this.category = "",
  });

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories>
    with
        AfterLayoutMixin<Categories>,
        SingleTickerProviderStateMixin,
        RouteAware,
        WidgetsBindingObserver {
  late AnimationController _controller;
  late int _jumpToOnce;
  late String _categoryOnce;

  void downloadButtonListener() {
    if (_controller.isCompleted) {
      _controller.repeat();
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, // the SingleTickerProviderStateMixin
      duration: Duration(seconds: 1),
    );

    // Copy incoming deep-link/navigation params so we can reset after using once
    _jumpToOnce = widget.jumpTo;
    _categoryOnce = widget.category;

    checkForNewQuestions(false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when returning to this page (e.g., from Play page)
    // Force rebuild to update progress bars
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    // Also listen for app lifecycle changes (when app comes back to foreground)
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  @override
  void activate() {
    // Called when this State object is reinserted into the tree
    // This happens when returning from a pushed route
    super.activate();
    if (mounted) {
      setState(() {});
    }
  }

  void checkForNewQuestions(bool userclicked) async {
    _controller.addListener(downloadButtonListener);
    _controller.forward();
    bool installed = await InstallQuestions().Do();
    if (!_controller.isAnimating) {
      return;
    }

    if (installed) {
      if (mounted) {
        // Force update progress bars after installing new questions
        setState(() {});
      }
    } else if (userclicked) {
      if (mounted) {
        BotToast.showSimpleNotification(
            align: Alignment(0, 0.75),
            title: Malayalam.allUpToDate,
            titleStyle: ResponsiveText.bodyStyle(context),
            backgroundColor: Colors.green,
            closeIcon: const Icon(
              Icons.done,
              color: Colors.white,
            ),
            duration: Duration(seconds: 3));
      }
    }

    _controller.stop();
    _controller.removeListener(downloadButtonListener);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 20.sp, left: 20.sp),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const TitleBar(),
                Visibility(
                  visible: false,
                  child: AnimatedIconButton(
                    animationController: _controller,
                    icons: [
                      AnimatedIconItem(
                        icon: Icon(
                          Icons.refresh_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          checkForNewQuestions(true);
                        },
                      ),
                    ],
                  ),
                )
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CategoryCard(
                            categoryName: Malayalam.kadamkatha,
                            assetPath: "assets/rubiks-cube.json",
                            progress: Questions()
                                .getCategoryProgress(Questions.KADAMKATHA),
                            onTap: () async {
                              await Navigator.push(context,
                                  MaterialPageRoute(builder: (newcontext) {
                                return Play(category: Questions.KADAMKATHA);
                              }));
                              // Force update when returning from Play page
                              if (mounted) {
                                setState(() {});
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          width: 1.h,
                        ),
                        Expanded(
                          child: CategoryCard(
                            categoryName: Malayalam.kusruthy,
                            assetPath: "assets/running-pigeon.json",
                            progress: Questions()
                                .getCategoryProgress(Questions.KUSRUTHY),
                            onTap: () async {
                              await Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return Play(category: Questions.KUSRUTHY);
                              }));
                              // Force update when returning from Play page
                              if (mounted) {
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 1.h,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: CategoryCard(
                            categoryName: Malayalam.charithram,
                            assetPath: "assets/dirigible.json",
                            progress: Questions()
                                .getCategoryProgress(Questions.CHARITHRAM),
                            onTap: () async {
                              await Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return Play(category: Questions.CHARITHRAM);
                              }));
                              // Force update when returning from Play page
                              if (mounted) {
                                setState(() {});
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          width: 1.h,
                        ),
                        Expanded(
                          child: CategoryCard(
                            categoryName: Malayalam.aanukalikam,
                            assetPath: "assets/aanukalikam.json",
                            progress: Questions()
                                .getCategoryProgress(Questions.AANUKALIKAM),
                            onTap: () async {
                              await Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return Play(category: Questions.AANUKALIKAM);
                              }));
                              // Force update when returning from Play page
                              if (mounted) {
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 1.h,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: CategoryCard(
                            categoryName: Malayalam.cinema,
                            assetPath: "assets/cinema.json",
                            progress: Questions()
                                .getCategoryProgress(Questions.CINEMA),
                            onTap: () async {
                              await Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return Play(category: Questions.CINEMA);
                              }));
                              // Force update when returning from Play page
                              if (mounted) {
                                setState(() {});
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          width: 1.h,
                        ),
                        Expanded(
                          child: CategoryCard(
                            categoryName: Malayalam.letter,
                            assetPath: "assets/strategy.json",
                            progress: Questions()
                                .getCategoryProgress(Questions.LETTER),
                            onTap: () async {
                              await Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return Play(category: Questions.LETTER);
                              }));
                              // Force update when returning from Play page
                              if (mounted) {
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) {
    if (_jumpToOnce != 0 && _categoryOnce != "") {
      if (Questions().isCategoryValid(_categoryOnce)) {
        final String categoryToOpen = _categoryOnce;
        // Reset values so this logic is only applied once
        setState(() {
          _jumpToOnce = 0;
          _categoryOnce = "";
        });
        Future.delayed(Duration(milliseconds: 500), () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return Play(category: categoryToOpen);
          }));
        });
      }
    }
  }
}
