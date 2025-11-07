import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:pippidi/data/user_manager.dart';
import 'package:pippidi/pages/landing.dart';
import 'package:pippidi/util/firebase.dart';
import 'package:transliteration/response/transliteration_response.dart';
import 'package:transliteration/transliteration.dart';
import 'package:sizer/sizer.dart';
import 'package:pippidi/util/constants.dart';
import 'package:pippidi/util/user_id_generator.dart';
import 'package:pippidi/util/fcm_sync.dart';

class UserName extends StatefulWidget {
  UserName({super.key});

  @override
  State<UserName> createState() => _UserNameState();
}

class _UserNameState extends State<UserName> with TickerProviderStateMixin {
  final _typeAheadController = TextEditingController();
  late AnimationController controller;
  late AnimationController pageLoadController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;
  int ANIMATION = 2;
  bool nameEntered = false;
  FocusNode? _inputFocusNode;
  bool _didAutofocus = false;

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: ANIMATION),
    )..addListener(() {
        setState(() {});
      });

    pageLoadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    final curved = CurvedAnimation(
      parent: pageLoadController,
      curve: Curves.easeOutCubic,
    );
    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero)
            .animate(curved);

    // Start the entry animation
    pageLoadController.forward();

    // After the entry animation completes, request focus on the input after 200ms
    pageLoadController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_didAutofocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!mounted || _didAutofocus) return;
          if (_inputFocusNode != null && _inputFocusNode!.canRequestFocus) {
            FocusScope.of(context).requestFocus(_inputFocusNode);
            _didAutofocus = true;
          }
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    pageLoadController.dispose();
    _typeAheadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.sp),
            child: Column(children: [
              Expanded(
                  flex: 1,
                  child: Container(
                    child: Column(
                      children: [
                        Container(
                          alignment: Alignment.bottomCenter,
                          child: Text(
                            "തുടങ്ങാം",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          height: 2.h,
                        ),
                        SlideTransition(
                          position: slideAnimation,
                          child: FadeTransition(
                            opacity: fadeAnimation,
                            child: Container(
                              alignment: Alignment.topLeft,
                              decoration: BoxDecoration(
                                  color: Colors.deepPurple[100],
                                  borderRadius: BorderRadius.circular(14.sp)),
                              child: Padding(
                                padding: EdgeInsets.all(16.sp),
                                child: TypeAheadField<String>(
                                  controller: _typeAheadController,
                                  builder: (context, controller, focusNode) {
                                    // Capture the focus node once; actual focus is requested after animation completes
                                    _inputFocusNode ??= focusNode;

                                    return TextFormField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      autocorrect: true,
                                      maxLength: Malayalam.maxUsernameLength,
                                      inputFormatters: [
                                        Malayalam.malayalamInputFormatter
                                      ],
                                      decoration: InputDecoration.collapsed(
                                        hintText: Malayalam.nameQuestion,
                                      ),
                                    );
                                  },
                                  suggestionsCallback: (pattern) async {
                                    if (pattern.isEmpty) {
                                      return <String>[""];
                                    }
                                    TransliterationResponse? _response =
                                        await Transliteration.transliterate(
                                            pattern, Languages.MALAYALAM);
                                    var results =
                                        _response?.transliterationSuggestions;
                                    results ??= <String>[""];

                                    // Filter out non-Malayalam suggestions
                                    results = results
                                        .where((suggestion) =>
                                            suggestion.isNotEmpty &&
                                            Malayalam.isValidMalayalamName(
                                                suggestion))
                                        .toList();

                                    // If no valid Malayalam suggestions, return empty to show "type to start"
                                    if (results.isEmpty) {
                                      return <String>[""];
                                    }

                                    return results;
                                  },
                                  itemBuilder: (context, suggestion) {
                                    if (suggestion.isEmpty) {
                                      return ListTile(
                                        title: Text(Malayalam.typeToStart),
                                        tileColor: Colors.deepPurple[200],
                                      );
                                    }
                                    return ListTile(
                                      title: Text(suggestion),
                                      tileColor: Colors.deepPurple[200],
                                    );
                                  },
                                  onSelected: (String suggestion) async {
                                    if (suggestion.isEmpty) {
                                      return;
                                    }

                                    // Validate that the suggestion contains only Malayalam characters
                                    if (!Malayalam.isValidMalayalamName(
                                        suggestion)) {
                                      // Invalid characters detected - reject this selection
                                      return;
                                    }
                                    _typeAheadController.text = suggestion;

                                    setState(() {
                                      nameEntered = true;
                                    });
                                    controller.repeat();

                                    // Create user id
                                    final id = generateUserId();

                                    // Create new user using UserManager
                                    final newUser =
                                        await UserManager.instance.createUser(
                                      userId: id,
                                      name: suggestion,
                                      firstTime:
                                          true, // Onboarding users start as not-yet-onboarded
                                    );

                                    // Mark as onboarding complete by directly updating the user data
                                    final updatedUser =
                                        newUser.copyWith(firstTime: false);
                                    await UserManager.instance
                                        .updateCurrentUser(updatedUser);

                                    await syncFCMToken();
                                    // Ensure user is signed in anonymously before writing to Firebase
                                    await Firebase.signInAnonymously();

                                    // Store data in firebase
                                    final nowIso =
                                        DateTime.now().toIso8601String();
                                    final data = <String, dynamic>{
                                      'name': suggestion,
                                      'score': 0,
                                      'badge': 0,
                                      'createdAt': nowIso,
                                      'modifiedAt': nowIso,
                                    };
                                    Firebase.write('users/${id}', data);

                                    // Show progress bar
                                    await Future.delayed(
                                        Duration(
                                            milliseconds:
                                                (ANIMATION * 1000 - 300)), () {
                                      Navigator.pushReplacement(context,
                                          MaterialPageRoute(
                                        builder: (context) {
                                          return LandingPage(
                                            jumpTo: 1,
                                            category: "KADAMKATHA",
                                          );
                                        },
                                      ));
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 1.h,
                        ),
                        if (nameEntered)
                          (LinearProgressIndicator(
                            value: controller.value,
                            color: Colors.white,
                            backgroundColor: Colors.deepPurple,
                          )),
                      ],
                    ),
                  )),
            ]),
          ),
        ),
      ),
    );
  }
}
