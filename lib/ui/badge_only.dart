import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:sizer/sizer.dart';

class BadgeOnly extends StatelessWidget {
  final double percent;
  final int codePoint;
  const BadgeOnly({
    super.key,
    required this.percent,
    required this.codePoint,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: CircularPercentIndicator(
        radius: 20.sp,
        lineWidth: 7.sp,
        center: Icon(
          IconData(codePoint, fontFamily: 'MaterialIcons'),
          color: Colors.white,
        ),
        progressColor: Colors.white,
        backgroundColor: Colors.deepPurple.shade400,
        percent: percent,
        fillColor: percent >= 1.0 ? Colors.green : Colors.transparent,
        animateFromLastPercent: true,
        animation: true,
      ),
    );
  }
}
