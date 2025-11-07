import 'dart:math';

import 'package:flutter/widgets.dart';

class SunAndMoon extends StatefulWidget {
  final bool? isDragComplete;
  final List<String> assetPaths;
  final int index;

  const SunAndMoon(
      {Key? key,
      this.isDragComplete = false,
      this.assetPaths = const ['assets/gooey/Sun-Yellow.png', 'assets/gooey/Sun-Red.png', 'assets/gooey/Moon-Crescent.png'],
      required this.index})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _SunAndMoonState();
}

class _SunAndMoonState extends State<SunAndMoon> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  int _rotationRadius = 300;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController.unbounded(vsync: this);
    _rotationAnimation = Tween<double>(begin: 1, end: 0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDragComplete = widget.isDragComplete ?? false;
    if (isDragComplete && widget.index != _currentIndex) {
      _currentIndex = widget.index;
      double nextAnimState = widget.index / 3;
      _animationController.animateTo(nextAnimState, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    }
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          _buildAssetWithDefaultAngle(0, 240),
          _buildAssetWithDefaultAngle(1, 30),
          _buildAssetWithDefaultAngle(2, 180),
        ],
      ),
    );
  }

  Widget _buildAssetWithDefaultAngle(int index, double degreeAngle) {
    double radianAngle = degreeAngle / 180 * pi;
    return AnimatedOpacity(
      opacity: index == _currentIndex % 3 ? 1 : 0,
      duration: const Duration(milliseconds: 300),
      child: RotationTransition(
        turns: _rotationAnimation,
        child: Transform.translate(
          offset: Offset(_rotationRadius * cos(radianAngle), _rotationRadius * sin(radianAngle)),
          child: Image.asset(
            widget.assetPaths.elementAt(index),
            width: 60,
            height: 60,
          ),
        ),
      ),
    );
  }
}


