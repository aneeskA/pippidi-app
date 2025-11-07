import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sizer/sizer.dart';
import '../util/responsive_text.dart';

class Intro extends StatelessWidget {
  final String lottie;
  final String heading;
  final String caption;
  final Color color;
  const Intro({
    super.key,
    required this.lottie,
    required this.heading,
    required this.caption,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.sp),
          child: Column(children: [
            Expanded(
                flex: 2,
                child: Container(
                  alignment: Alignment.bottomCenter,
                  child: Lottie.asset(
                    lottie,
                  ),
                )),
            Expanded(
                flex: 1,
                child: Container(
                  child: Column(
                    children: [
                      Text(
                        heading,
                        style: ResponsiveText.h1Style(context),
                      ),
                      SizedBox(
                        height: 2.h,
                      ),
                      Text(
                        caption,
                        textAlign: TextAlign.center,
                        style: ResponsiveText.bodyStyle(context),
                      )
                    ],
                  ),
                )),
          ]),
        ),
      ),
    );
  }
}
