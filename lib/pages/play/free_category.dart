import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';
import 'package:pippidi/ui/badges_list.dart';
import 'package:pippidi/util/constants.dart';
import 'package:pippidi/util/responsive_text.dart';
import 'package:pippidi/data/user.dart';
import 'package:pippidi/util/fcm_sync.dart';

class FreeCategoryUI extends StatefulWidget {
  final String category;
  final List badges;
  const FreeCategoryUI({
    super.key,
    required this.category,
    required this.badges,
  });

  @override
  State<FreeCategoryUI> createState() => _FreeCategoryUIState();
}

class _FreeCategoryUIState extends State<FreeCategoryUI> {
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      if (mounted) {
        setState(() {
          _notificationsEnabled =
              settings.authorizationStatus == AuthorizationStatus.authorized;
        });
      }
    });
    if (!User().firstTime) {
      Future.delayed(Duration(seconds: 3), () async {
        FirebaseMessaging messaging = FirebaseMessaging.instance;
        final settings = await messaging.getNotificationSettings();
        if (settings.authorizationStatus != AuthorizationStatus.authorized) {
          await messaging.requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            // provisional: false (default for full)
            sound: true,
          );
          await syncFCMToken(); // Re-sync for full access
        }
      });
    }
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: Column(
            children: [
              SizedBox(
                height: 1.h,
              ),
              Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 7.sp),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width - 32.sp,
                      height: 6.h,
                      child: ListView.separated(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.badges.length,
                        itemBuilder: (context, index) {
                          return BadgesList(
                            percent: widget.badges[index][2],
                            caption: widget.badges[index][1],
                            iconValue: widget.badges[index][3],
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) {
                          return SizedBox(
                            width: 8.sp,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Align(
                  alignment: FractionalOffset.bottomCenter,
                  child: Text(
                    Malayalam.gameFinished,
                    style: ResponsiveText.h1Style(context),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Align(
            alignment: FractionalOffset.topCenter,
            child: Padding(
              padding: EdgeInsets.only(right: 10.sp, left: 10.sp, top: 10.sp),
              child: _notificationsEnabled
                  ? Text(
                      Malayalam.freeQuestionsInfo,
                      textAlign: TextAlign.justify,
                      style: ResponsiveText.bodyStyle(context),
                    )
                  : GestureDetector(
                      onTap: _openAppSettings,
                      child: Text(
                        Malayalam.freeQuestionsInfoPrompt,
                        textAlign: TextAlign.justify,
                        style: ResponsiveText.bodyStyle(context),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
