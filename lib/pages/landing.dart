import 'package:flutter/material.dart';

import 'package:pippidi/pages/home.dart';
import 'package:pippidi/pages/play.dart';
import 'package:pippidi/pages/play_category.dart';
import 'package:pippidi/pages/user_account.dart';
import 'package:pippidi/util/constants.dart';
import 'package:sizer/sizer.dart';
import 'package:pippidi/main.dart' as main;
import 'package:pippidi/data/questions.dart';
import 'package:pippidi/ui/add_friend.dart';

class LandingPage extends StatefulWidget {
  final int jumpTo;
  final String category;
  const LandingPage({
    super.key,
    this.jumpTo = 0,
    this.category = "",
  });

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int _index = 0;
  late List<Widget> _pages;
  bool _deepLinkHandled = false;
  String _initialCategory = "";

  @override
  void initState() {
    super.initState();
    _index = widget.jumpTo;
    _initialCategory = widget.category;
    _pages = [
      const HomePage(),
      const Categories(),
      const UserAccount(),
    ];

    // Handle one-time deep link/category auto navigation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Handle user deep link first
      final userId = main.DeepLinkHandler.pendingUserId;
      if (userId != null) {
        main.DeepLinkHandler.clearPendingData();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showAddFriendModal(userId);
          }
        });
      }
      // Handle category deep link
      else if (!_deepLinkHandled &&
          _index == 1 &&
          _initialCategory.isNotEmpty) {
        if (Questions().isCategoryValid(_initialCategory)) {
          final String categoryToOpen = _initialCategory;
          _deepLinkHandled = true;
          _initialCategory = "";
          Future.delayed(const Duration(milliseconds: 500), () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return Play(category: categoryToOpen);
            }));
          });
        }
      }
    });
  }

  void _showAddFriendModal(String userId) {
    FriendAdditionService.showAddFriendModal(
      context,
      prefillUserId: userId,
      onProgress: () {
        // Handle progress if needed
      },
    );
  }

  void _navigateBottomBar(int index) {
    setState(() {
      _index = index;
    });
  }

  Widget _buildCustomNavButton(
      int index, IconData outlinedIcon, IconData filledIcon, String text) {
    bool isSelected = _index == index;
    return GestureDetector(
      onTap: () => _navigateBottomBar(index),
      behavior: HitTestBehavior.opaque, // Ensures the entire area is clickable
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16.sp, // Increased from 10.sp for larger touch area
          vertical: 16.sp, // Adjusted for better proportions
        ),
        margin: EdgeInsets.symmetric(
            horizontal: 4.sp), // Add some spacing between buttons
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Icon(
                isSelected ? filledIcon : outlinedIcon,
                key: ValueKey<bool>(isSelected),
                color: Colors.white,
                size:
                    20.sp, // Slightly larger icon for better touch interaction
              ),
            ),
            SizedBox(height: 4.sp),
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp, // Slightly smaller text to fit better
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.95,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            ),
          );
        },
        child: Container(
          key: ValueKey<int>(_index),
          child: _pages[_index],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.deepPurple.withOpacity(0.6),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.sp, vertical: 15.sp),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCustomNavButton(
                  0, Icons.home_outlined, Icons.home, Malayalam.home),
              _buildCustomNavButton(1, Icons.play_arrow_outlined,
                  Icons.play_arrow, Malayalam.play),
              _buildCustomNavButton(
                  2, Icons.person_outline, Icons.person, Malayalam.profile),
            ],
          ),
        ),
      ),
    );
  }
}
