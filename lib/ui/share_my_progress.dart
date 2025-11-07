import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pippidi/ui/button_dialog.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../data/user.dart';
import 'badge_only.dart';
import '../util/responsive_text.dart';
import 'package:pippidi/util/constants.dart';

class ShareMyProgress extends StatelessWidget {
  ShareMyProgress({super.key});

  final GlobalKey globalKey = GlobalKey();
  final List badges = User().sortedBadgeProgress;

  Future<void> captureWidget() async {
    final RenderRepaintBoundary boundary =
        globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
    var debugNeedsPaint = false;
    if (kDebugMode) debugNeedsPaint = boundary.debugNeedsPaint;
    if (debugNeedsPaint) {
      await Future.delayed(const Duration(milliseconds: 20));
      return captureWidget();
    }

    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();
    Directory tempDir = await getTemporaryDirectory();
    File imgFile = new File('${tempDir.path}/share.png');
    imgFile.writeAsBytes(pngBytes);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.deepPurple,
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        RepaintBoundary(
          key: globalKey,
          child: Container(
            color: Colors.deepPurple,
            child: Padding(
              padding: EdgeInsets.all(3.sp),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 8.sp),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Malayalam.appName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveText.bodySize(context),
                          ),
                        ),
                        Text(
                          User().score.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveText.bodySize(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10.sp,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BadgeOnly(
                        percent: badges[0][2],
                        codePoint: badges[0][3],
                      ),
                      SizedBox(
                        width: 1.sp,
                      ),
                      BadgeOnly(
                        percent: badges[1][2],
                        codePoint: badges[1][3],
                      ),
                      SizedBox(
                        width: 1.sp,
                      ),
                      BadgeOnly(
                        percent: badges[2][2],
                        codePoint: badges[2][3],
                      ),
                      SizedBox(
                        width: 1.sp,
                      ),
                      BadgeOnly(
                        percent: badges[3][2],
                        codePoint: badges[3][3],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 1.h,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BadgeOnly(
                        percent: badges[4][2],
                        codePoint: badges[4][3],
                      ),
                      SizedBox(
                        width: 1.sp,
                      ),
                      BadgeOnly(
                        percent: badges[5][2],
                        codePoint: badges[5][3],
                      ),
                      SizedBox(
                        width: 1.sp,
                      ),
                      BadgeOnly(
                        percent: badges[6][2],
                        codePoint: badges[6][3],
                      ),
                      SizedBox(
                        width: 1.sp,
                      ),
                      BadgeOnly(
                        percent: badges[7][2],
                        codePoint: badges[7][3],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 1.h,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BadgeOnly(
                        percent: badges[8][2],
                        codePoint: badges[8][3],
                      ),
                      SizedBox(
                        width: 1.sp,
                      ),
                      BadgeOnly(
                        percent: badges[9][2],
                        codePoint: badges[9][3],
                      ),
                      SizedBox(
                        width: 1.sp,
                      ),
                      BadgeOnly(
                        percent: badges[10][2],
                        codePoint: badges[10][3],
                      ),
                      SizedBox(
                        width: 1.sp,
                      ),
                      BadgeOnly(
                        percent: badges[11][2],
                        codePoint: badges[11][3],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 1.h,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BadgeOnly(
                        percent: badges[12][2],
                        codePoint: badges[12][3],
                      ),
                      SizedBox(
                        width: 1.sp,
                      ),
                      BadgeOnly(
                        percent: badges[13][2],
                        codePoint: badges[13][3],
                      ),
                      SizedBox(
                        width: 1.sp,
                      ),
                      BadgeOnly(
                        percent: badges[14][2],
                        codePoint: badges[14][3],
                      ),
                      SizedBox(
                        width: 1.sp,
                      ),
                      BadgeOnly(
                        percent: badges[15][2],
                        codePoint: badges[15][3],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 5.sp,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          Malayalam.shareFooter,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveText.bodySmallSize(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: 5.sp,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            DialogButton(
              name: Malayalam.shareButtonHaveIt,
              callback: () async {
                await captureWidget();
                Navigator.pop(context);
                Directory tempDir = await getTemporaryDirectory();
                Share.shareXFiles(
                  [XFile("${tempDir.path}/share.png")],
                  subject: Malayalam.downloadUrl,
                );
              },
            ),
          ],
        )
      ]),
    );
  }
}
