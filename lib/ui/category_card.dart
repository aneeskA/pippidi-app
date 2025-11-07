import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sizer/sizer.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:pippidi/util/responsive_text.dart';

class CategoryCard extends StatefulWidget {
  final String categoryName;
  final String assetPath;
  final double progress; // 0.0 to 1.0
  final VoidCallback onTap;

  const CategoryCard({
    Key? key,
    required this.categoryName,
    required this.assetPath,
    required this.progress,
    required this.onTap,
  }) : super(key: key);

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void didUpdateWidget(CategoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.sp),
      ),
      child: Stack(
        children: [
          // Main card content (no border - handled by CustomPaint)
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14.sp),
            child: InkWell(
              key: UniqueKey(),
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(14.sp),
              child: Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox.expand(
                      child: FittedBox(
                        child: Lottie.asset(widget.assetPath),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: AutoSizeText(
                        widget.categoryName,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                        style: ResponsiveText.bodyStyle(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Progress indicator overlay
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return IgnorePointer(
                child: CustomPaint(
                  painter: UnifiedBorderPainter(
                    progress: _progressAnimation.value,
                    borderRadius: 14.sp,
                    borderWidth: 7.sp,
                    borderColor: Colors.deepPurple.shade400,
                    progressColor: Colors.white60,
                  ),
                  child: Container(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class UnifiedBorderPainter extends CustomPainter {
  final double progress;
  final double borderRadius;
  final double borderWidth;
  final Color borderColor;
  final Color progressColor;

  UnifiedBorderPainter({
    required this.progress,
    required this.borderRadius,
    required this.borderWidth,
    required this.borderColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create a proper outline path for the rounded rectangle border
    final Path fullBorderPath = Path();

    final double left = 0;
    final double top = 0;
    final double right = size.width;
    final double bottom = size.height;
    final double radius = borderRadius;

    // Start from top-left corner and create clockwise outline
    fullBorderPath.moveTo(left + radius, top);

    // Top side
    fullBorderPath.lineTo(right - radius, top);

    // Top-right corner
    fullBorderPath.arcToPoint(
      Offset(right, top + radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // Right side
    fullBorderPath.lineTo(right, bottom - radius);

    // Bottom-right corner
    fullBorderPath.arcToPoint(
      Offset(right - radius, bottom),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // Bottom side
    fullBorderPath.lineTo(left + radius, bottom);

    // Bottom-left corner
    fullBorderPath.arcToPoint(
      Offset(left, bottom - radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // Left side
    fullBorderPath.lineTo(left, top + radius);

    // Top-left corner
    fullBorderPath.arcToPoint(
      Offset(left + radius, top),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // Close the path to form a complete contour
    fullBorderPath.close();

    // Draw the full border (purple)
    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    canvas.drawPath(fullBorderPath, borderPaint);

    // Draw the progress border (white) - only if progress > 0
    if (progress > 0) {
      // Calculate total perimeter for progress calculation
      final straightWidth = right - left - 2 * radius;
      final straightHeight = bottom - top - 2 * radius;
      final totalPerimeter =
          2 * (straightWidth + straightHeight) + 2 * 3.14159 * radius;
      final progressLength = totalPerimeter * progress;

      // Manually draw progress by calculating segment lengths
      final progressPath = Path();
      double currentLength = 0;

      // Top side
      final topLength = straightWidth;
      if (progressLength > currentLength) {
        final remainingProgress = progressLength - currentLength;
        final drawLength = remainingProgress.clamp(0, topLength);
        final endX = left + radius + drawLength;
        progressPath.moveTo(left + radius, top);
        progressPath.lineTo(endX, top);
        if (progressLength <= currentLength + topLength) {
          // Progress ends in this segment
          final progressPaint = Paint()
            ..color = progressColor
            ..strokeWidth = borderWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.butt;
          canvas.drawPath(progressPath, progressPaint);
          return;
        }
      }
      currentLength += topLength;

      // Top-right corner (quarter circle)
      final cornerArcLength = 3.14159 * radius / 2; // π*r/2
      if (progressLength > currentLength) {
        final remainingProgress = progressLength - currentLength;
        final arcProgress = remainingProgress.clamp(0, cornerArcLength);
        final arcAngle =
            (arcProgress / cornerArcLength) * (3.14159 / 2); // 90 degrees

        progressPath.arcToPoint(
          Offset(right - radius + radius * cos(3.14159 / 2 - arcAngle),
              top + radius - radius * sin(3.14159 / 2 - arcAngle)),
          radius: Radius.circular(radius),
          clockwise: true,
        );

        if (progressLength <= currentLength + cornerArcLength) {
          final progressPaint = Paint()
            ..color = progressColor
            ..strokeWidth = borderWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.butt;
          canvas.drawPath(progressPath, progressPaint);
          return;
        }
      }
      currentLength += cornerArcLength;

      // Right side
      final rightLength = straightHeight;
      if (progressLength > currentLength) {
        final remainingProgress = progressLength - currentLength;
        final drawLength = remainingProgress.clamp(0, rightLength);
        final endY = top + radius + drawLength;
        progressPath.lineTo(right, endY);
        if (progressLength <= currentLength + rightLength) {
          final progressPaint = Paint()
            ..color = progressColor
            ..strokeWidth = borderWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.butt;
          canvas.drawPath(progressPath, progressPaint);
          return;
        }
      }
      currentLength += rightLength;

      // Bottom-right corner
      if (progressLength > currentLength) {
        final remainingProgress = progressLength - currentLength;
        final arcProgress = remainingProgress.clamp(0, cornerArcLength);
        final arcAngle = (arcProgress / cornerArcLength) * (3.14159 / 2);

        progressPath.arcToPoint(
          Offset(right - radius + radius * cos(arcAngle),
              bottom - radius + radius * sin(arcAngle)),
          radius: Radius.circular(radius),
          clockwise: true,
        );

        if (progressLength <= currentLength + cornerArcLength) {
          final progressPaint = Paint()
            ..color = progressColor
            ..strokeWidth = borderWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.butt;
          canvas.drawPath(progressPath, progressPaint);
          return;
        }
      }
      currentLength += cornerArcLength;

      // Bottom side
      if (progressLength > currentLength) {
        final remainingProgress = progressLength - currentLength;
        final drawLength = remainingProgress.clamp(0, straightWidth);
        final endX = right - radius - drawLength;
        progressPath.lineTo(endX, bottom);
        if (progressLength <= currentLength + straightWidth) {
          final progressPaint = Paint()
            ..color = progressColor
            ..strokeWidth = borderWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.butt;
          canvas.drawPath(progressPath, progressPaint);
          return;
        }
      }
      currentLength += straightWidth;

      // Bottom-left corner
      if (progressLength > currentLength) {
        final remainingProgress = progressLength - currentLength;
        final arcProgress = remainingProgress.clamp(0, cornerArcLength);
        final arcAngle = (arcProgress / cornerArcLength) * (3.14159 / 2);

        progressPath.arcToPoint(
          Offset(left + radius - radius * cos(3.14159 / 2 - arcAngle),
              bottom - radius + radius * sin(3.14159 / 2 - arcAngle)),
          radius: Radius.circular(radius),
          clockwise: true,
        );

        if (progressLength <= currentLength + cornerArcLength) {
          final progressPaint = Paint()
            ..color = progressColor
            ..strokeWidth = borderWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.butt;
          canvas.drawPath(progressPath, progressPaint);
          return;
        }
      }
      currentLength += cornerArcLength;

      // Left side
      if (progressLength > currentLength) {
        final remainingProgress = progressLength - currentLength;
        final drawLength = remainingProgress.clamp(0, straightHeight);
        final endY = bottom - radius - drawLength;
        progressPath.lineTo(left, endY);
        if (progressLength <= currentLength + straightHeight) {
          final progressPaint = Paint()
            ..color = progressColor
            ..strokeWidth = borderWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.butt;
          canvas.drawPath(progressPath, progressPaint);
          return;
        }
      }
      currentLength += straightHeight;

      // Top-left corner (final segment)
      if (progressLength > currentLength) {
        final remainingProgress = progressLength - currentLength;
        final arcProgress = remainingProgress.clamp(0, cornerArcLength);
        final arcAngle = (arcProgress / cornerArcLength) * (3.14159 / 2);

        progressPath.arcToPoint(
          Offset(left + radius + radius * cos(3.14159 - arcAngle),
              top + radius - radius * sin(3.14159 - arcAngle)),
          radius: Radius.circular(radius),
          clockwise: true,
        );
      }

      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = borderWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;

      canvas.drawPath(progressPath, progressPaint);
    }
  }

  @override
  bool shouldRepaint(UnifiedBorderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.progressColor != progressColor;
  }
}
