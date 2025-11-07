import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/scheduler.dart';
import 'package:sizer/sizer.dart';
import 'package:pippidi/util/responsive_text.dart';
import 'package:pippidi/ui/mybutton.dart';
import 'package:pippidi/util/constants.dart';

class ContentCard extends StatefulWidget {
  final String color; // Red, Yellow, Blue
  final Color altColor;
  final String title;
  final String subtitle;
  final VoidCallback? onGetStarted;

  const ContentCard(
      {super.key,
      required this.color,
      this.title = "",
      required this.subtitle,
      required this.altColor,
      this.onGetStarted});

  @override
  _ContentCardState createState() => _ContentCardState();
}

class _ContentCardState extends State<ContentCard> {
  late Ticker _ticker;

  @override
  void initState() {
    _ticker = Ticker((d) {
      setState(() {});
    })
      ..start();
    super.initState();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        var time = DateTime.now().millisecondsSinceEpoch / 2000;
        var scaleX = 1.2 + sin(time) * .05;
        var scaleY = 1.2 + cos(time) * .07;
        var offsetY = 20 + cos(time) * 20;
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        return Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: <Widget>[
            Transform.translate(
              offset: Offset(-(scaleX - 1) / 2 * width,
                  -(scaleY - 1) / 2 * height + offsetY),
              child: Transform(
                transform: Matrix4.diagonal3Values(scaleX, scaleY, 1),
                child: Image.asset('assets/gooey/Bg-${widget.color}.png',
                    fit: BoxFit.cover),
              ),
            ),
            Container(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.only(top: 9.h, bottom: 3.h),
                child: Column(
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5.w),
                        child: Image.asset(
                          'assets/gooey/Illustration-${widget.color}.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(
                        height: 2.h,
                        child: Image.asset(
                            'assets/gooey/Slider-${widget.color}.png')),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5.w),
                        child: _buildBottomContent(),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        );
      },
    );
  }

  Widget _buildBottomContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Center(
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              style: ResponsiveText.h1Style(context),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: ResponsiveText.bodyStyle(context),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 9.w),
              child: SizedBox(
                width: double.infinity,
                height: 6.h,
                child: MyButton(
                  text: Malayalam.getStarted,
                  myColor: widget.altColor,
                  callBack: widget.onGetStarted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
