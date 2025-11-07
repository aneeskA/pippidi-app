import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'package:pippidi/data/user.dart';
import 'package:pippidi/util/my_border_style.dart';
import 'package:pippidi/util/responsive_text.dart';

class BadgesTable extends StatelessWidget {
  final String id;
  final String name;
  final String description;
  final int iconValue;
  const BadgesTable(
      {super.key,
      required this.name,
      required this.description,
      required this.iconValue,
      required this.id});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.start, children: [
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.sp),
          border: MyBorderStyle.standardBorder(),
        ),
        child: Padding(
          padding: EdgeInsets.all(8.sp),
          child: Row(children: [
            Expanded(
              flex: 1,
              child: Container(
                height: 7.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      User.isBadgeWon(id) ? Colors.green : Colors.transparent,
                  border: MyBorderStyle.standardBorder(),
                ),
                child: Icon(
                  IconData(iconValue, fontFamily: 'MaterialIcons'),
                  color: User.isBadgeWon(id)
                      ? Colors.white
                      : Colors.deepPurple.shade400,
                ),
              ),
            ),
            Expanded(
                flex: 5,
                child: Padding(
                  padding: EdgeInsets.only(left: 12.sp, right: 12.sp),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: ResponsiveText.bodyStyle(context),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              description,
                              style: ResponsiveText.bodySmallStyle(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
          ]),
        ),
      ),
      SizedBox(
        height: 1.h,
      ),
    ]);
  }
}
