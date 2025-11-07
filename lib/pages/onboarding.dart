import 'package:flutter/material.dart';
import 'package:pippidi/onboarding/user_name.dart';
import 'package:pippidi/welcome/gooey_carousel.dart';
import 'package:pippidi/welcome/content_card.dart';
import 'package:pippidi/util/constants.dart';

class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({super.key});

  @override
  State<OnBoardingPage> createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {
  void _goToUserName() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => UserName()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GooeyCarousel(
        children: <Widget>[
          ContentCard(
            color: 'Red',
            altColor: const Color.fromARGB(31, 73, 72, 72),
            title: Malayalam.appName,
            subtitle: Malayalam.appDescription,
            onGetStarted: _goToUserName,
          ),
          ContentCard(
            color: 'Yellow',
            altColor: const Color.fromARGB(31, 73, 72, 72),
            title: Malayalam.onboardingKadankathaTitle,
            subtitle: Malayalam.onboardingKadankathaDescription,
            onGetStarted: _goToUserName,
          ),
          ContentCard(
            color: 'Blue',
            altColor: const Color.fromARGB(31, 92, 90, 90),
            title: Malayalam.onboardingBattleTitle,
            subtitle: Malayalam.onboardingBattleDescription,
            onGetStarted: _goToUserName,
          ),
        ],
      ),
    );
  }
}
