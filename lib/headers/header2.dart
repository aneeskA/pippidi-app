import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sizer/sizer.dart';

import 'package:pippidi/util/constants.dart';
import 'package:pippidi/util/responsive_text.dart';
import 'package:pippidi/util/my_border_style.dart';

class Header2 extends StatelessWidget {
  const Header2({super.key});

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
            child: Container(
                child: Lottie.asset(
              "assets/cards2.json",
            )),
          ),
          Expanded(
            child: Text(
              Malayalam.greeting2,
              textAlign: TextAlign.center,
              style: ResponsiveText.bodyStyle(context),
            ),
          ),
        ],
      ),
    );
  }
}
