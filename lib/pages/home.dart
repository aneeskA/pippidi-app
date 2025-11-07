import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:sizer/sizer.dart';

import 'package:pippidi/headers/header1.dart';
import 'package:pippidi/headers/header2.dart';
import 'package:pippidi/headers/header3.dart';
import 'package:pippidi/util/firebase.dart';
import 'package:pippidi/ui/points_table.dart';
import 'package:pippidi/data/user.dart';
import 'package:pippidi/ui/add_friend.dart';
import 'package:pippidi/ui/titlebar.dart';
import 'package:pippidi/util/responsive_text.dart';
import 'package:pippidi/util/constants.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:pippidi/util/fcm_sync.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final PageController _controller = PageController();
  late Timer _timer;
  int _currentPage = 0;
  int direction = 1;
  int totalPages = 3;
  // static final _id = User().id; // kept for possible future share usage
  List _currentOrder = User().leaderboard;
  final GlobalKey<AnimatedListState> _key = GlobalKey();
  StreamSubscription? friendDataStream;
  StreamSubscription? friendAddUpdateStream;
  bool _isSearching = false;
  late AnimationController _addFriendController;
  late Animation<double> _addFriendAnimation;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      _currentPage = (_currentPage + direction * 1) % totalPages;
      if (_currentPage == (totalPages - 1) || (_currentPage == 0)) {
        direction *= -1;
      }

      _controller.animateToPage(
        _currentPage,
        duration: const Duration(seconds: 1),
        curve: Curves.easeIn,
      );
    });

    // wait for updates from firebase
    Firebase().activateListeners();

    friendDataUpdates();
    friendAdditionStatusUpdates();

    if (!User().firstTime) {
      Future.delayed(const Duration(seconds: 3), () async {
        FirebaseMessaging messaging = FirebaseMessaging.instance;
        final settings = await messaging.getNotificationSettings();
        if (settings.authorizationStatus != AuthorizationStatus.authorized) {
          await messaging.requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            sound: true,
          );
          await syncFCMToken(); // Re-sync for full access
        }
        // Optional: Log status if needed
      });
    }

    // Load initial leaderboard data asynchronously after the frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final currentLeaderboard = await Firebase().currentLeaderBoard();
        // Populate global leaderboard data
        for (final leader in currentLeaderboard) {
          final int index = leader[4] as int; // index from database
          final Map<String, dynamic> data = {
            'name': leader[0],
            'score': leader[1],
            'id': leader[2],
            'badge': leader[3],
            'index': index,
          };
          User().updateLeader(index, data);
        }
        // Trigger UI update with the new leaderboard data
        User().friendListRefreshController.add(true);
      } catch (error) {
        print('Error loading initial leaderboard: $error');
      }
    });

    _addFriendController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _addFriendAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _addFriendController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    Firebase().deactivateListeners();
    friendDataStream?.cancel();
    friendAddUpdateStream?.cancel();
    _addFriendController.dispose();
    super.dispose();
  }

  void friendDataUpdates() {
    friendDataStream = User().friendListRefreshController.stream.listen((data) {
      updateFriendList();
    });
  }

  void friendAdditionStatusUpdates() {
    friendAddUpdateStream =
        User().friendAddtionUpdateController.stream.listen((data) {
      Fluttertoast.showToast(
        msg: data,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 5,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: ResponsiveText.bodySize(context),
      );

      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  void _onTapAddFriend(BuildContext context) {
    FriendAdditionService.showAddFriendModal(
      context,
      onProgress: callbackFriendAddInProgress,
    );
  }

  void callbackFriendAddInProgress() {
    if (mounted) {
      setState(() {
        _isSearching = true;
      });
    }
  }

  void _addItemToList(int index, List element) {
    _currentOrder.insert(index, element);
    if (_key.currentState != null) {
      _key.currentState!
          .insertItem(index, duration: const Duration(milliseconds: 500));
    }
  }

  void _removeItemFromList(int index) {
    String id = _currentOrder[index][2];
    String username = _currentOrder[index][0];
    int score = _currentOrder[index][1];
    int badgeCount = _currentOrder[index][3];
    if (_key.currentState != null) {
      _key.currentState!.removeItem(
        index,
        (context, animation) {
          return SizeTransition(
            sizeFactor: animation,
            child: PointsTable(
              index: index,
              id: id,
              username: username,
              badgeCount: badgeCount,
              score: score,
            ),
          );
        },
        duration: const Duration(milliseconds: 500),
      );
    }

    _currentOrder.removeAt(index);
  }

  void updateFriendList() {
    if (!mounted) return; // Prevent updates if widget is disposed

    List targetOrder = User().leaderboard; // desired end state
    if (targetOrder.length < _currentOrder.length) {
      int extra = -1; // find the exta item's index
      for (int i = 0; i < targetOrder.length; i++) {
        if (targetOrder[i][2] != _currentOrder[i][2]) {
          extra = i;
          break;
        }
      }

      if (extra == -1) {
        extra = _currentOrder.length - 1;
      }

      _removeItemFromList(extra);
      return;
    }

    if (targetOrder.length > _currentOrder.length) {
      int extra = -1; // find the exta item's index
      for (int i = 0; i < _currentOrder.length; i++) {
        if (targetOrder[i][2] != _currentOrder[i][2]) {
          extra = i;
          break;
        }
      }

      if (extra == -1) {
        extra = targetOrder.length - 1;
      }

      _addItemToList(extra, targetOrder[extra]);
      return;
    }

    if (targetOrder.length == _currentOrder.length) {
      for (int i = 0; i < _currentOrder.length; i++) {
        if (_currentOrder[i][2] != targetOrder[i][2] ||
            _currentOrder[i][1] != targetOrder[i][1] ||
            _currentOrder[i][0] != targetOrder[i][0] ||
            _currentOrder[i][3] != targetOrder[i][3]) {
          // check id, score, name, badge
          _removeItemFromList(i);
          _addItemToList(i, targetOrder[i]);
        }
      }

      return;
    }
  }

  void deleteFriend(String id) {
    User().deleteFriend = id;
    if (mounted) {
      updateFriendList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple, // Add the proper background color
      body: Padding(
        padding: EdgeInsets.only(right: 20.sp, left: 20.sp),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const TitleBar(),
              SizedBox(
                height: 20.h,
                child: Stack(
                  children: [
                    PageView(
                      controller: _controller,
                      children: const [
                        Header1(),
                        Header2(),
                        Header3(),
                      ],
                    ),
                    Container(
                        alignment: Alignment(0, 0.8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SmoothPageIndicator(
                              controller: _controller,
                              count: 3,
                              effect: WormEffect(
                                activeDotColor: Colors.white,
                                dotHeight: 8,
                                dotWidth: 8,
                                dotColor: Colors.deepPurple.shade200,
                              ),
                            ),
                          ],
                        )),
                  ],
                ),
              ),
              SizedBox(
                height: 7.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Malayalam.pointsTable,
                      style: ResponsiveText.h2Style(context),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        RepaintBoundary(
                          child: ScaleTransition(
                            scale: _addFriendAnimation,
                            child: IconButton(
                              icon: Icon(Icons.person_add),
                              color: Colors.white,
                              iconSize: ResponsiveText.h1Size(context),
                              onPressed: _isSearching
                                  ? null
                                  : () async {
                                      await _addFriendController.forward();
                                      await _addFriendController.reverse();
                                      _onTapAddFriend(context);
                                    },
                            ),
                          )
                              .animate(
                                  onPlay: (controller) =>
                                      controller.loop(count: 2, reverse: true))
                              .shimmer(
                                delay: 400.ms,
                                duration: 1800.ms,
                                color: Colors.deepPurple.shade900,
                              ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Expanded(
                  child: Container(
                alignment: Alignment.centerLeft,
                child: AnimatedList(
                  key: _key,
                  scrollDirection: Axis.vertical,
                  initialItemCount: _currentOrder.length,
                  itemBuilder: (context, index, animation) {
                    return SizeTransition(
                      key: UniqueKey(),
                      sizeFactor: animation,
                      child: PointsTable(
                        index: index,
                        id: _currentOrder[index][2],
                        username: _currentOrder[index][0],
                        badgeCount: _currentOrder[index][3],
                        score: _currentOrder[index][1],
                      ),
                    );
                  },
                ),
              ))
            ],
          ),
        ),
      ),
    );
  }
}
