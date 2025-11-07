import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ResponsiveText {
  static const List<String> malayalamFallback = [
    'Noto Sans Malayalam',
    'NotoSansMalayalam',
    'Malayalam MN',
    'Kohinoor Malayalam'
  ];
  // Get responsive font size based on screen size
  static double getFontSize(BuildContext context, double baseFontSize) {
    return baseFontSize;
  }

  static double h1Size(BuildContext context) {
    return getFontSize(context, 22.sp);
  }

  static TextStyle h1Style(BuildContext context) {
    return TextStyle(
      fontSize: h1Size(context),
      fontWeight: FontWeight.w600,
      color: Colors.white,
      fontFamilyFallback: malayalamFallback,
    );
  }

  static double h2Size(BuildContext context) {
    return getFontSize(context, 18.sp);
  }

  static TextStyle h2Style(BuildContext context) {
    return TextStyle(
      fontSize: h2Size(context),
      fontWeight: FontWeight.w600,
      color: Colors.white,
      fontFamilyFallback: malayalamFallback,
    );
  }

  static double bodySize(BuildContext context) {
    return getFontSize(context, 17.sp);
  }

  static TextStyle bodyStyle(BuildContext context) {
    return TextStyle(
      fontSize: bodySize(context),
      fontWeight: FontWeight.w400,
      color: Colors.white,
      fontFamilyFallback: malayalamFallback,
    );
  }

  static double bodySmallSize(BuildContext context) {
    return getFontSize(context, 15.sp);
  }

  static TextStyle bodySmallStyle(BuildContext context) {
    return TextStyle(
      fontSize: bodySmallSize(context),
      fontWeight: FontWeight.w400,
      color: Colors.white,
      fontFamilyFallback: malayalamFallback,
    );
  }

  static double superscriptSize(BuildContext context) {
    return getFontSize(context, 12.sp);
  }

  static TextStyle superscriptStyle(BuildContext context) {
    return TextStyle(
      fontSize: superscriptSize(context),
      fontWeight: FontWeight.w400,
      color: Colors.white,
      fontFamilyFallback: malayalamFallback,
    );
  }

  static TextStyle bodyStyleBold(BuildContext context) {
    return TextStyle(
      fontSize: bodySize(context),
      fontWeight: FontWeight.bold,
      color: Colors.white,
      fontFamilyFallback: malayalamFallback,
    );
  }

  static double buttonSize(BuildContext context) {
    return getFontSize(context, 20.sp);
  }

  static TextStyle buttonStyle(BuildContext context) {
    return TextStyle(
      fontSize: buttonSize(context),
      fontWeight: FontWeight.w500,
      color: Colors.white,
      fontFamilyFallback: malayalamFallback,
    );
  }

  static double questionSize(BuildContext context) {
    return getFontSize(context, 22.sp);
  }

  static TextStyle questionStyle(BuildContext context) {
    return TextStyle(
      fontSize: questionSize(context),
      fontWeight: FontWeight.w500,
      color: Colors.white,
      fontFamilyFallback: malayalamFallback,
    );
  }

  static double pointSize(BuildContext context) {
    return getFontSize(context, 16.sp);
  }

  static TextStyle pointStyle(BuildContext context) {
    return TextStyle(
      fontSize: pointSize(context),
      fontWeight: FontWeight.w500,
      color: Colors.white,
      fontFamilyFallback: malayalamFallback,
    );
  }

  static double myPointSize(BuildContext context) {
    return getFontSize(context, 25.sp);
  }

  static TextStyle changeStyleColor(TextStyle style, Color newColor) {
    return style.copyWith(color: newColor);
  }
}
