import 'package:flutter/material.dart';
import 'package:pippidi/data/user.dart';
import 'package:sizer/sizer.dart';
import 'package:pippidi/util/constants.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:pippidi/util/responsive_text.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:pippidi/util/my_border_style.dart';

import 'dart:ui' as ui;

import 'dart:typed_data';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Generic friend addition service
class FriendAdditionService {
  static void addFriend(String userId,
      {VoidCallback? onProgress, VoidCallback? onComplete}) {
    final myID = User().id;

    // Don't add yourself
    if (userId == myID) {
      User()
          .friendAddtionUpdateController
          .add("$myID വിശദാംശം ചേർത്തിട്ടുണ്ട്!");
      onComplete?.call();
      return;
    }

    onProgress?.call();

    try {
      User().addFriend(userId);
      onComplete?.call();
    } catch (e) {
      // Handle error if needed
      onComplete?.call();
    }
  }

  static void showAddFriendModal(BuildContext context,
      {String? prefillUserId, Function? onProgress}) {
    final updateFriendList = () {}; // Default empty callback

    try {
      // Add a small delay to ensure context is fully ready
      Future.delayed(const Duration(milliseconds: 100), () {
        if (context.mounted) {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.deepPurple.shade400,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(14.sp)),
            ),
            isScrollControlled: true,
            useSafeArea: true,
            builder: (context) => SafeArea(
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(16.sp),
                  child: prefillUserId != null
                      ? AddFriendWithUserId(
                          userId: prefillUserId,
                          callback: updateFriendList,
                          progress: onProgress ?? () {})
                      : AddFriend(
                          callback: updateFriendList,
                          progress: onProgress ?? () {}),
                ),
              ),
            ),
          );
        }
      });
    } catch (e) {
      // Handle any exceptions that might occur when showing the modal
      print('Error in FriendAdditionService.showAddFriendModal: $e');
      // Fallback: try to show a simple snackbar instead
      try {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unable to open friend addition dialog')),
          );
        }
      } catch (fallbackError) {
        print('Fallback error handling also failed: $fallbackError');
      }
    }
  }
}

class AddFriend extends StatefulWidget {
  final Function callback;
  final Function progress;

  const AddFriend({super.key, required this.callback, required this.progress});

  @override
  _AddFriendState createState() => _AddFriendState();
}

class AddFriendWithUserId extends StatefulWidget {
  final String userId;
  final Function callback;
  final Function progress;

  const AddFriendWithUserId({
    super.key,
    required this.userId,
    required this.callback,
    required this.progress,
  });

  @override
  _AddFriendWithUserIdState createState() => _AddFriendWithUserIdState();
}

class _AddFriendState extends State<AddFriend> with TickerProviderStateMixin {
  final _textFieldController = TextEditingController();
  final myID = User().id;
  final myName = User().name;
  final ScreenshotController _screenshotController = ScreenshotController();

  bool _isScanning = false;

  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _textController;
  late Animation<double> _textAnimation;
  late AnimationController _cameraController;
  late Animation<double> _cameraAnimation;
  late AnimationController _galleryController;
  late Animation<double> _galleryAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _textController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _textAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _cameraController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _cameraAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _cameraController, curve: Curves.easeOut),
    );
    _galleryController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _galleryAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _galleryController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    _cameraController.dispose();
    _galleryController.dispose();
    super.dispose();
  }

  void _handleDetectedCode(String code) {
    final _code = code.split('/');
    if (_code.length < 2) {
      Fluttertoast.showToast(msg: Malayalam.noQRCode);
      return;
    }
    if (mounted) {
      setState(() {
        _textFieldController.text = _code.last;
      });
    }
    Future.delayed(const Duration(milliseconds: 200), () {
      Navigator.pop(context);
      final text = _textFieldController.text;
      if (text.isEmpty) return;
      if (text == myID) {
        User()
            .friendAddtionUpdateController
            .add("$myName വിശദാംശം ചേർത്തിട്ടുണ്ട്!");
        return;
      }
      widget.progress();
      User().addFriend(text);
    });
  }

  Future<Uint8List?> generateQrImage(String data) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Colors.white,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.white,
      ),
      gapless: false,
    );

    double pad = 14.sp;
    const padding = 20.0;
    double qrHeight = 1200.0;
    double innerPadding = 14.sp;
    double wide = qrHeight;
    double fixed = 0.0;
    late TextPainter headingPainter;
    late TextPainter subheadingPainter;
    late TextPainter bottomPainter;
    const int maxIterations = 5;
    for (int i = 0; i < maxIterations; i++) {
      headingPainter = TextPainter(
        text: TextSpan(
          text: Malayalam.appName,
          style: ResponsiveText.h1Style(context).copyWith(
            fontSize: ResponsiveText.h1Size(context) * 3,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      headingPainter.layout(maxWidth: wide);

      subheadingPainter = TextPainter(
        text: TextSpan(
          text: Malayalam.appDescription,
          style: ResponsiveText.bodyStyle(context).copyWith(
            fontSize: ResponsiveText.h1Size(context) * 2,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      subheadingPainter.layout(maxWidth: wide);

      final text = Malayalam().shareImageAndText(data);
      bottomPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: ResponsiveText.bodyStyle(context).copyWith(
            fontSize: ResponsiveText.h1Size(context) * 2,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      bottomPainter.layout(maxWidth: wide);

      fixed = headingPainter.height +
          padding +
          subheadingPainter.height +
          padding * 2 +
          padding +
          bottomPainter.height +
          padding;
      fixed += 2 * innerPadding;

      double newWide = fixed + qrHeight;
      if ((newWide - wide).abs() < 1.0) {
        break;
      }
      wide = newWide;
    }

    double totalHeight = fixed + qrHeight;
    double contentWidth = wide;
    double contentHeight = totalHeight;
    double side = max(contentWidth + 2 * pad, contentHeight + 2 * pad);

    final picRecorder = ui.PictureRecorder();
    final canvas = Canvas(
        picRecorder, Rect.fromPoints(const Offset(0, 0), Offset(side, side)));

    final bgPaint = Paint()..color = Colors.deepPurple;
    canvas.drawRect(Rect.fromLTWH(0, 0, side, side), bgPaint);

    double xTrans = (side - contentWidth) / 2;
    double yTrans = (side - contentHeight) / 2;
    canvas.translate(xTrans, yTrans);

    double yOffset = padding;

    // Paint heading
    headingPainter.paint(
        canvas, Offset((wide - headingPainter.width) / 2, yOffset));
    yOffset += headingPainter.height + padding;

    // Paint subheading
    subheadingPainter.paint(
        canvas, Offset((wide - subheadingPainter.width) / 2, yOffset));
    yOffset += subheadingPainter.height + padding * 2;

    // Paint QR
    double borderedQrSize = qrHeight + 2 * innerPadding;
    double borderX = (wide - borderedQrSize) / 2;
    double qrPaintX = borderX + innerPadding;
    double borderY = yOffset;
    var borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = MyBorderStyle.thickBorder().top.width;
    var borderRect =
        Rect.fromLTWH(borderX, borderY, borderedQrSize, borderedQrSize);
    var rrect = RRect.fromRectAndRadius(borderRect, Radius.circular(14.sp));
    canvas.drawRRect(rrect, borderPaint);
    canvas.save();
    canvas.translate(qrPaintX, yOffset + innerPadding);
    painter.paint(canvas, Size(qrHeight, qrHeight));
    canvas.restore();
    yOffset += borderedQrSize + padding;

    // Paint bottom text
    bottomPainter.paint(
        canvas, Offset((wide - bottomPainter.width) / 2, yOffset));

    final pic = picRecorder.endRecording();
    final img = await pic.toImage(side.toInt(), side.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _pickFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
          source: ImageSource.gallery, requestFullMetadata: false);
      if (image != null) {
        final controller = MobileScannerController();
        final BarcodeCapture? barcodeCapture =
            await controller.analyzeImage(image.path);
        controller.dispose();
        String? code;
        if (barcodeCapture != null && barcodeCapture.barcodes.isNotEmpty) {
          code = barcodeCapture.barcodes.first.rawValue;
        }
        if (code != null) {
          _handleDetectedCode(code);
        } else {
          Fluttertoast.showToast(msg: Malayalam.noQRCode);
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: Malayalam.galleryPermissionError);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(14.sp),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: AutoSizeText(
                  Malayalam.enterCode,
                  style: TextStyle(
                    fontSize: ResponsiveText.h2Size(context),
                    color: Colors.white,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: AutoSizeText(
                  Malayalam.scanQRInfo,
                  style: TextStyle(
                    fontSize: ResponsiveText.bodySmallSize(context),
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 10.sp),
              TextField(
                controller: _textFieldController,
                onSubmitted: (String value) {
                  String input = value.trim();
                  if (input.isEmpty) {
                    Fluttertoast.showToast(msg: Malayalam.noQRCode);
                    return;
                  }
                  // Remove leading '@' if present
                  if (input.startsWith('@')) {
                    input = input.substring(1).trim();
                  }
                  // Extract user ID from URL if it looks like one
                  String userId = input;
                  if (input.contains('/user/')) {
                    // Find the part after the last '/'
                    int lastSlash = input.lastIndexOf('/');
                    if (lastSlash != -1 && lastSlash < input.length - 1) {
                      userId = input.substring(lastSlash + 1);
                    }
                  }
                  // Validate extracted ID (basic check: not empty and reasonable length)
                  if (userId.isEmpty || userId.length < 5) {
                    Fluttertoast.showToast(msg: Malayalam.noQRCode);
                    return;
                  }
                  if (userId == myID) {
                    User()
                        .friendAddtionUpdateController
                        .add("$myName വിശദാംശം ചേർത്തിട്ടുണ്ട്!");
                    _textFieldController.clear();
                    return;
                  }
                  widget.progress();
                  User().addFriend(userId);
                  if (mounted) {
                    Navigator.pop(context);
                  }
                  _textFieldController.clear();
                },
                style: TextStyle(
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.sp),
                    borderSide: BorderSide(
                      color: Colors.deepPurple.shade300,
                      width: 7.sp,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.sp),
                    borderSide: BorderSide(
                      color: Colors.deepPurple.shade300,
                      width: 7.sp,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.sp),
                    borderSide: BorderSide(
                      color: Colors.deepPurple.shade300,
                      width: 7.sp,
                    ),
                  ),
                  hintText: Malayalam.friendCodeHint,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 15.sp,
                    vertical: 12.sp,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isScanning)
                        Padding(
                          padding: EdgeInsets.only(left: 8.sp),
                          child: SizedBox(
                            width: 20.sp,
                            height: 20.sp,
                            child: CircularProgressIndicator(
                              strokeWidth: 5.sp,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      ScaleTransition(
                        scale: _galleryAnimation,
                        child: IconButton(
                          icon: Icon(Icons.photo_library, color: Colors.white),
                          onPressed: () async {
                            await _galleryController.forward();
                            await _galleryController.reverse();
                            if (mounted) {
                              setState(() {
                                _isScanning = true;
                              });
                            }
                            await _pickFromGallery();
                            if (mounted) {
                              setState(() {
                                _isScanning = false;
                              });
                            }
                          },
                        ),
                      ),
                      ScaleTransition(
                        scale: _cameraAnimation,
                        child: IconButton(
                          icon: Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: () async {
                            await _cameraController.forward();
                            await _cameraController.reverse();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QRScannerScreen(
                                  onDetected: (String code) {
                                    _handleDetectedCode(code);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 15.sp),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: AutoSizeText(
                      Malayalam.shareQR,
                      style: TextStyle(
                        fontSize: ResponsiveText.h2Size(context),
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      minFontSize: 12,
                      stepGranularity: 2,
                      textAlign: TextAlign.left,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _animation,
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_outward_outlined,
                            color: Colors.white,
                          ),
                          iconSize: ResponsiveText.h1Size(context),
                          onPressed: () async {
                            await _controller.forward();
                            await _controller.reverse();
                            final imageBytes = await generateQrImage(
                                Malayalam().shareLink(myID));
                            if (imageBytes != null) {
                              final directory = await getTemporaryDirectory();
                              final imagePath = '${directory.path}/qr.png';
                              await File(imagePath).writeAsBytes(imageBytes);
                              await Share.shareXFiles([XFile(imagePath)],
                                  subject: Malayalam().shareImageAndText(
                                      Malayalam().shareLink(myID)));
                            }
                          },
                        ),
                      ),
                      ScaleTransition(
                        scale: _textAnimation,
                        child: IconButton(
                          icon: Icon(
                            Icons.link,
                            color: Colors.white,
                          ),
                          iconSize: ResponsiveText.h1Size(context),
                          onPressed: () async {
                            await _textController.forward();
                            await _textController.reverse();
                            await Share.share(
                              Malayalam().shareLink(myID),
                              subject: Malayalam()
                                  .shareCodeOnly(Malayalam().shareLink(myID)),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  border: MyBorderStyle.customBorder(
                    color: Colors.deepPurple.shade300,
                  ),
                  borderRadius: BorderRadius.circular(14.sp),
                ),
                child: Screenshot(
                  controller: _screenshotController,
                  child: QrImageView(
                    data: Malayalam().shareLink(myID),
                    version: QrVersions.auto,
                    gapless: false,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.white,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddFriendWithUserIdState extends State<AddFriendWithUserId> {
  final GlobalKey<_AddFriendState> _addFriendKey = GlobalKey<_AddFriendState>();
  bool _friendAdded = false;

  @override
  void initState() {
    super.initState();

    // Automatically add the friend after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoAddFriend();
    });
  }

  void _autoAddFriend() {
    // Wait for the AddFriend widget to be built
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && !_friendAdded) {
        _friendAdded = true;

        // Access the AddFriend state directly using the GlobalKey
        final addFriendState = _addFriendKey.currentState;
        if (addFriendState != null) {
          addFriendState._textFieldController.text = widget.userId;

          // Use the generic service to add friend
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              final text = addFriendState._textFieldController.text;
              if (text.isNotEmpty) {
                // First dismiss the modal like in normal flow
                if (context.mounted) {
                  Navigator.pop(context);
                }

                // Then add the friend
                FriendAdditionService.addFriend(
                  text,
                  onProgress: () => addFriendState.widget.progress(),
                  onComplete: () {
                    // Handle completion if needed
                  },
                );
              }
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AddFriend(
      key: _addFriendKey,
      callback: widget.callback,
      progress: widget.progress,
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  final Function(String) onDetected;

  const QRScannerScreen({super.key, required this.onDetected});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _hasDetected = false;
  late MobileScannerController controller;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MobileScanner(
        controller: controller,
        onDetect: (BarcodeCapture capture) {
          if (_hasDetected) return;
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final String? code = barcode.rawValue;
            if (code != null) {
              _hasDetected = true;
              widget.onDetected(code);
              Navigator.of(context).pop();
              return;
            }
          }
        },
      ),
    );
  }
}
