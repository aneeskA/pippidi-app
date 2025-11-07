import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class MyBorderStyle {
  /// Standard border used throughout the app
  static Border standardBorder() {
    return Border.all(
      color: Colors.deepPurple.shade400,
      width: 7.sp,
    );
  }

  /// Thick border variant for special emphasis
  static Border thickBorder() {
    return Border.all(
      color: Colors.deepPurple.shade400,
      width: 10.sp,
    );
  }

  /// Custom border with configurable width
  static Border customBorder({double? width, Color? color}) {
    final stdBorder = standardBorder();
    return Border.all(
      color: color ?? stdBorder.top.color,
      width: width?.sp ?? stdBorder.top.width,
    );
  }

  static double badgeBorderSize() {
    return 7.sp;
  }

  static double ButtonBorderSize() {
    return 7.sp;
  }

  static BorderSide standardBorderSide() {
    return BorderSide(
      color: Colors.deepPurple.shade400,
      width: 7.sp,
    );
  }
}
