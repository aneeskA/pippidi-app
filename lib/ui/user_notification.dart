import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'package:pippidi/util/responsive_text.dart';

class UserNotification extends StatelessWidget {
  final String text;
  final Widget icon;
  const UserNotification({
    super.key,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 14.sp),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.sp),
            color: Colors.green,
          ),
          child: Row(
            children: [
              icon,
              SizedBox(
                width: 2.h,
              ),
              Expanded(
                child: Text(
                  text,
                  style: ResponsiveText.bodyStyle(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
