import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../util/responsive_text.dart';
import 'package:pippidi/util/constants.dart';

class TitleBar extends StatefulWidget {
  const TitleBar({super.key});

  @override
  State<TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends State<TitleBar> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 7.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            // ignore: prefer_const_literals_to_create_immutables
            children: [
              Text(
                Malayalam.appName,
                style: ResponsiveText.h1Style(context),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 1.h,
        ),
      ],
    );
  }
}
