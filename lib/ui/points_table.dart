import 'package:badges/badges.dart' as MyBadge;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import 'package:pippidi/data/user.dart';
import 'package:pippidi/util/responsive_text.dart';
import 'package:pippidi/util/my_border_style.dart';

class PointsTable extends StatelessWidget {
  final int index;
  final int score;
  final String username;
  final String id;
  final int badgeCount;
  PointsTable({
    super.key,
    required this.index,
    required this.id,
    required this.username,
    required this.badgeCount,
    required this.score,
  });

  final NumberFormat formatter = NumberFormat('#,##,###');

  @override
  Widget build(BuildContext context) {
    final bool me = User().id == id;
    return Padding(
      padding: EdgeInsets.only(bottom: 10.sp),
      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        Container(
          height: 7.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.sp),
            border: MyBorderStyle.standardBorder(),
            color: me ? Colors.deepPurple.shade700 : Colors.deepPurple,
          ),
          child: Row(children: [
            Expanded(
                flex: 4,
                child: Padding(
                  padding: EdgeInsets.only(left: 14.sp),
                  child: Text(
                    username,
                    overflow: TextOverflow.ellipsis,
                    style: ResponsiveText.bodyStyle(context),
                  ),
                )),
            Expanded(
                flex: 1,
                child: Center(
                  child: MyBadge.Badge(
                    badgeAnimation: MyBadge.BadgeAnimation.scale(
                      toAnimate: false,
                    ),
                    badgeStyle: MyBadge.BadgeStyle(
                      badgeColor: Colors.green,
                    ),
                    badgeContent: Text(
                      badgeCount.toString(),
                      style: ResponsiveText.superscriptStyle(context),
                    ),
                    child: Icon(
                      Icons.workspace_premium_outlined,
                      color: Colors.white,
                    ),
                  ),
                )),
            Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.only(right: 14.sp),
                  child: Text(
                    formatter.format(score),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: ResponsiveText.pointStyle(context),
                  ),
                )),
          ]),
        ),
      ]),
    );
  }
}
