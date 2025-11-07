import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:pippidi/util/my_border_style.dart';
import 'package:sizer/sizer.dart';

import 'package:pippidi/util/responsive_text.dart';

class MyButton extends StatefulWidget {
  final String text;
  final Color myColor;
  final void Function()? callBack;
  final bool isLoading;
  final IconData? icon;
  final Color? borderColor;
  final String? feedbackType;

  const MyButton({
    super.key,
    required this.text,
    required this.myColor,
    required this.callBack,
    this.isLoading = false,
    this.icon,
    this.borderColor,
    this.feedbackType,
  });

  @override
  State<MyButton> createState() => _MyButtonState();
}

class _MyButtonState extends State<MyButton> with TickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _colorController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // Handle initial feedbackType if present
    if (widget.feedbackType != null) {
      Color targetColor =
          widget.feedbackType == 'correct' ? Colors.green : Colors.red;
      _colorAnimation =
          ColorTween(begin: widget.myColor, end: targetColor).animate(
        CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
      );
      _colorController.forward(from: 0.0);
    } else {
      _colorAnimation = AlwaysStoppedAnimation(widget.myColor);
    }

    _colorController.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant MyButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.feedbackType != oldWidget.feedbackType &&
        widget.feedbackType != null) {
      Color targetColor =
          widget.feedbackType == 'correct' ? Colors.green : Colors.red;
      _colorAnimation =
          ColorTween(begin: widget.myColor, end: targetColor).animate(
        CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
      );
      _colorController.forward(from: 0.0);
    } else if (widget.feedbackType == null && oldWidget.feedbackType != null) {
      // Reset to original color when feedbackType is cleared
      _colorAnimation = AlwaysStoppedAnimation(widget.myColor);
    }
  }

  @override
  void dispose() {
    _colorController.dispose();
    super.dispose();
  }

  void _handlePointerDown(_) {
    if (!mounted) return;
    setState(() => _isPressed = true);
  }

  void _handlePointerUp(_) {
    if (!mounted) return;
    setState(() => _isPressed = false);
  }

  void _handlePointerCancel(_) {
    if (!mounted) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        scale: _isPressed ? 0.97 : 1.0,
        child: Padding(
          padding: EdgeInsets.only(bottom: 5.sp, right: 20.sp, left: 20.sp),
          child: OutlinedButton(
            onPressed: widget.callBack,
            style: OutlinedButton.styleFrom(
              backgroundColor: _colorAnimation.value,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.sp),
              ),
              side: BorderSide(
                color: widget.borderColor ?? Colors.deepPurple.shade400,
                width: MyBorderStyle.ButtonBorderSize(),
              ),
              overlayColor: Colors.white.withValues(alpha: 0.10),
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null)
                        Icon(
                          widget.icon,
                          color: Colors.white,
                          size: ResponsiveText.buttonSize(context),
                        ),
                      if (widget.icon != null) SizedBox(width: 5.sp),
                      Expanded(
                        child: AutoSizeText(
                          widget.text,
                          style: ResponsiveText.buttonStyle(context),
                          maxLines: 1,
                          minFontSize: ResponsiveText.superscriptSize(context)
                              .roundToDouble(),
                          maxFontSize: ResponsiveText.buttonSize(context)
                              .roundToDouble(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  if (widget.isLoading)
                    Container(
                      width: 20.sp,
                      height: 20.sp,
                      child: const CircularProgressIndicator(
                        color: Colors.green,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
