import 'package:flutter/material.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:pippidi/util/responsive_text.dart';
import 'package:sizer/sizer.dart';

import 'package:pippidi/util/my_border_style.dart';

class BadgesList extends StatefulWidget {
  final String caption;
  final double percent;
  final int iconValue;
  const BadgesList(
      {super.key,
      required this.caption,
      required this.percent,
      required this.iconValue});

  @override
  State<BadgesList> createState() => _BadgesListState();
}

class _BadgesListState extends State<BadgesList>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _currentPercent = 0.0;

  @override
  void initState() {
    super.initState();
    _currentPercent = widget.percent;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: _currentPercent,
      end: _currentPercent,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(BadgesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percent != widget.percent) {
      // Animate from current percent to new percent
      _animation = Tween<double>(
        begin: _currentPercent,
        end: widget.percent,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));

      _animationController.forward(from: 0.0).then((_) {
        setState(() {
          _currentPercent = widget.percent;
        });
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return JustTheTooltip(
      isModal: true,
      elevation: 0,
      margin: EdgeInsets.all(30.sp),
      backgroundColor: Colors.deepPurple.shade400,
      content: Padding(
        padding: EdgeInsets.all(10.sp),
        child: Text(
          widget.caption,
          style: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveText.bodySize(context),
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: Listener(
          onPointerDown: (_) => setState(() => _isPressed = true),
          onPointerUp: (_) => setState(() => _isPressed = false),
          onPointerCancel: (_) => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: ClipOval(
              child: SizedBox(
                width: 6.h,
                height: 6.h,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_currentPercent == 1.0)
                      Container(
                        width: 6.h,
                        height: 6.h,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                      ),
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return CircularPercentIndicator(
                          radius: 3.h,
                          lineWidth: MyBorderStyle.badgeBorderSize(),
                          center: Icon(
                            IconData(widget.iconValue,
                                fontFamily: 'MaterialIcons'),
                            color: Colors.white,
                          ),
                          progressColor: Colors.white,
                          backgroundColor: Colors.deepPurple.shade400,
                          percent: _animation.value.clamp(0.0, 1.0),
                          fillColor: Colors.transparent,
                          animation: false, // We handle animation manually
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
