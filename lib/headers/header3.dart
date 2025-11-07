import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sizer/sizer.dart';

import 'package:pippidi/util/constants.dart';
import 'package:pippidi/util/responsive_text.dart';
import 'package:pippidi/util/my_border_style.dart';

class Header3 extends StatelessWidget {
  const Header3({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.sp),
          border: MyBorderStyle.standardBorder()),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 8.sp),
              child: Container(
                  child: Lottie.asset(
                "assets/cards3.json",
              )),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 8.sp),
              child: Text(
                Malayalam.greeting3,
                textAlign: TextAlign.center,
                style: ResponsiveText.bodyStyle(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
