import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pippidi/data/user.dart';
import 'package:pippidi/data/user_manager.dart';
import 'package:pippidi/data/user_data.dart';
import 'package:pippidi/ui/badges_table.dart';
import 'package:pippidi/util/my_border_style.dart';
import 'package:pippidi/util/responsive_text.dart';
import 'package:pippidi/util/constants.dart';
import 'package:pippidi/util/user_id_generator.dart';
import 'package:transliteration/transliteration.dart';
import 'package:transliteration/response/transliteration_response.dart';
import 'package:sizer/sizer.dart';

import '../ui/titlebar.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:pippidi/util/firebase.dart';
import 'package:pippidi/ui/button_dialog.dart';

// Cached profile picture widget to prevent flickering during animations
class CachedProfilePicture extends StatefulWidget {
  final UserData user;
  final double size;

  const CachedProfilePicture({
    super.key,
    required this.user,
    required this.size,
  });

  @override
  State<CachedProfilePicture> createState() => _CachedProfilePictureState();
}

class _CachedProfilePictureState extends State<CachedProfilePicture> {
  MemoryImage? _cachedImage;
  String? _lastImageKey;

  @override
  void didUpdateWidget(CachedProfilePicture oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update cached image if user or image data changed
    final currentKey = widget.user.profilePicKey;
    if (_lastImageKey != currentKey) {
      _lastImageKey = currentKey;
      final bytes = widget.user.profilePicBytes;
      _cachedImage = bytes != null ? MemoryImage(bytes) : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize cache on first build
    if (_cachedImage == null && _lastImageKey == null) {
      _lastImageKey = widget.user.profilePicKey;
      final bytes = widget.user.profilePicBytes;
      _cachedImage = bytes != null ? MemoryImage(bytes) : null;
    }

    return Container(
      key: ValueKey(widget.user.profilePicKey),
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _cachedImage == null ? Colors.white : null,
        border: MyBorderStyle.standardBorder(),
        image: _cachedImage != null
            ? DecorationImage(
                image: _cachedImage!,
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: _cachedImage == null
          ? Center(
              child: Icon(
                Icons.person_outline_outlined,
                color: Colors.deepPurple,
                size: widget.size * 0.5,
              ),
            )
          : null,
    );
  }
}

class UserAccount extends StatefulWidget {
  const UserAccount({super.key});

  @override
  State<UserAccount> createState() => _UserAccountState();
}

class _UserAccountState extends State<UserAccount>
    with TickerProviderStateMixin {
  String username = User().name;
  String profilepic = User().profilepic;
  final _badges = User().badgeList;
  late AnimationController _cameraController;
  late Animation<double> _cameraAnimation;
  late AnimationController _editController;
  late Animation<double> _editAnimation;
  late AnimationController _dropdownController;
  bool _showUserList = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cameraController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _cameraAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _cameraController, curve: Curves.easeOut),
    );
    _editController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _editAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _editController, curve: Curves.easeOut),
    );
    _dropdownController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Pre-load all user profile pictures when widget initializes
    _preloadUserProfilePictures();
  }

  void _preloadUserProfilePictures() {
    final allUsers = UserManager.instance.users;
    final currentUserId = UserManager.instance.currentUser?.userId;

    // Pre-load all user profile pictures
    for (var entry in allUsers.entries) {
      if (entry.value.userId != currentUserId) {
        // Access profilePicBytes to ensure it's cached
        entry.value.profilePicBytes;
      }
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _editController.dispose();
    _dropdownController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Padding(
        padding: EdgeInsets.only(right: 20.sp, left: 20.sp),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              TitleBar(),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14.sp),
                          border: MyBorderStyle.standardBorder(),
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 12.sp,
                            bottom: 12.sp,
                            left: 12.sp,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: GestureDetector(
                                  onTap: () async {
                                    await _cameraController.forward();
                                    await _cameraController.reverse();
                                    final ImagePicker _picker = ImagePicker();
                                    try {
                                      final XFile? photo =
                                          await _picker.pickImage(
                                              source: ImageSource.camera,
                                              requestFullMetadata: false);
                                      if (photo != null) {
                                        // Store image directly in Hive as base64
                                        User().profilepic = photo.path;
                                        // Clear the profile picture cache to force refresh
                                        User().clearProfilePicCache();
                                        setState(() {
                                          // Refresh the UI - profilepic getter now returns base64 string
                                          profilepic = User().profilepic;
                                        });
                                      }
                                    } catch (e) {
                                      Fluttertoast.showToast(
                                          msg: Malayalam.cameraPermissionError,
                                          toastLength: Toast.LENGTH_LONG,
                                          gravity: ToastGravity.BOTTOM,
                                          timeInSecForIosWeb: 1,
                                          backgroundColor: Colors.green,
                                          textColor: Colors.white,
                                          fontSize:
                                              ResponsiveText.bodySize(context));
                                    }
                                  },
                                  child: Container(
                                    height: 15.h,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: User().profilePicBytes == null
                                          ? Colors.white
                                          : null,
                                      border: MyBorderStyle.standardBorder(),
                                      image: (User().profilePicBytes != null)
                                          ? DecorationImage(
                                              image: MemoryImage(
                                                  User().profilePicBytes!),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: (User().profilePicBytes ==
                                                  null)
                                              ? Icon(
                                                  Icons.person_outline_outlined,
                                                  color: Colors.deepPurple,
                                                  size: 40.sp,
                                                )
                                              : null,
                                        ),
                                        Positioned(
                                          bottom: 15.sp,
                                          right: 0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.deepPurple.shade900,
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.all(10.sp),
                                              child: FittedBox(
                                                fit: BoxFit.contain,
                                                child: ScaleTransition(
                                                  scale: _cameraAnimation,
                                                  child: Icon(
                                                    Icons.photo_camera,
                                                    color: Colors.white,
                                                    size: 15.sp,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: 12.sp,
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: GestureDetector(
                                                    onTap: () async {
                                                      await _editController
                                                          .forward();
                                                      await _editController
                                                          .reverse();
                                                      _showEditNameModal(
                                                          context);
                                                    },
                                                    child: Text(
                                                      username,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign: TextAlign.left,
                                                      style: ResponsiveText
                                                          .h2Style(context),
                                                    ),
                                                  ),
                                                ),
                                                ScaleTransition(
                                                  scale: _editAnimation,
                                                  child: GestureDetector(
                                                    onTap: () async {
                                                      await _editController
                                                          .forward();
                                                      await _editController
                                                          .reverse();
                                                      _showEditNameModal(
                                                          context);
                                                    },
                                                    child: Padding(
                                                      padding: EdgeInsets.only(
                                                        bottom: 5.sp,
                                                        left: 5.sp,
                                                      ),
                                                      child: Icon(
                                                          Icons.edit_note,
                                                          color: Colors.white,
                                                          size: 16.sp),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  EdgeInsets.only(right: 7.sp),
                                              child: Text(
                                                User().score.toString() +
                                                    Malayalam.points +
                                                    " (" +
                                                    User().correct.toString() +
                                                    Malayalam.correct +
                                                    " " +
                                                    User().wrong.toString() +
                                                    Malayalam.wrong +
                                                    ")",
                                                textAlign: TextAlign.left,
                                                style: ResponsiveText.bodyStyle(
                                                    context),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: AutoSizeText(
                                              User().badges.length.toString() +
                                                  Malayalam.medal,
                                              textAlign: TextAlign.left,
                                              style: ResponsiveText.bodyStyle(
                                                  context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(
                        height: 1.h,
                      ),
                      // Switch User Section
                      Material(
                        color: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.sp),
                          side: MyBorderStyle.standardBorderSide(),
                        ),
                        child: Column(
                          children: [
                            // Switch User Header
                            InkWell(
                              borderRadius: BorderRadius.circular(14.sp),
                              onTap: () {
                                setState(() {
                                  _showUserList = !_showUserList;
                                  if (_showUserList) {
                                    _dropdownController.forward();
                                  } else {
                                    _dropdownController.reverse();
                                  }
                                });
                              },
                              child: Padding(
                                padding: EdgeInsets.all(12.sp),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      Malayalam.switchUser,
                                      style: ResponsiveText.bodyStyle(context)
                                          .copyWith(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    RotationTransition(
                                      turns: Tween<double>(
                                        begin: 0.0,
                                        end: 0.5,
                                      ).animate(_dropdownController),
                                      child: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.white,
                                        size: 20.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // User list with smooth animation (inside the container)
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              child: ClipRect(
                                child: SizedBox(
                                  height: _showUserList ? null : 0,
                                  child: _buildUserList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(
                        height: 2.h,
                      ),
                      Row(
                        children: [
                          Text(
                            Malayalam.suggestions,
                            style: ResponsiveText.h2Style(context),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 1.h,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.sp),
                                side: MyBorderStyle.standardBorderSide(),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14.sp),
                                onTap: () async {
                                  await Clipboard.setData(ClipboardData(
                                      text: Malayalam.suggestionEmail));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          Malayalam().suggestionPromptCopy(
                                              Malayalam.suggestionEmail),
                                          style:
                                              ResponsiveText.bodyStyle(context),
                                        ),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(12.sp),
                                  child: Text(
                                    Malayalam.suggestionPrompt,
                                    style: ResponsiveText.bodyStyle(context)
                                        .copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 1.h,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            Malayalam.acheivements,
                            style: ResponsiveText.h2Style(context),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 1.h,
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        child: ListView.separated(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          scrollDirection: Axis.vertical,
                          itemCount: _badges.length,
                          itemBuilder: (context, index) {
                            return BadgesTable(
                              id: _badges[index]["key"],
                              name: _badges[index]["name"],
                              description: _badges[index]["description"],
                              iconValue: _badges[index]["badgeIconCode"],
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) {
                            return SizedBox(
                              width: 10.w,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditNameModal(BuildContext context) {
    final TextEditingController _editController =
        TextEditingController(text: username);
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
          child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: EdgeInsets.all(16.sp),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 10.sp),
                  TypeAheadField<String>(
                    controller: _editController,
                    builder: (context, controller, focusNode) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: ResponsiveText.h2Style(context),
                        maxLength: Malayalam.maxUsernameLength,
                        inputFormatters: [Malayalam.malayalamInputFormatter],
                        decoration: InputDecoration(
                          labelText: Malayalam.newName,
                          labelStyle: ResponsiveText.bodyStyle(context),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.deepPurple.shade300,
                              width: 7.sp,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.deepPurple.shade300,
                              width: 7.sp,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.deepPurple.shade300,
                              width: 7.sp,
                            ),
                          ),
                        ),
                      );
                    },
                    suggestionsCallback: (pattern) async {
                      if (pattern.isEmpty) return <String>[''];
                      TransliterationResponse? response =
                          await Transliteration.transliterate(
                              pattern, Languages.MALAYALAM);
                      var results =
                          response?.transliterationSuggestions ?? <String>[''];

                      // Filter out non-Malayalam suggestions
                      results = results
                          .where((suggestion) =>
                              suggestion.isNotEmpty &&
                              Malayalam.isValidMalayalamName(suggestion))
                          .toList();

                      // If no valid Malayalam suggestions, return empty
                      if (results.isEmpty) {
                        return <String>[''];
                      }

                      return results;
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(title: Text(suggestion));
                    },
                    onSelected: (suggestion) {
                      if (suggestion.isEmpty) {
                        return;
                      }

                      // Validate that the suggestion contains only Malayalam characters
                      if (!Malayalam.isValidMalayalamName(suggestion)) {
                        // Invalid characters detected - reject this selection
                        return;
                      }

                      _editController.text = suggestion;
                    },
                  ),
                  SizedBox(height: 16.sp),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      DialogButton(
                        name: Malayalam.save,
                        callback: () {
                          String newName = _editController.text.trim();
                          if (newName.isNotEmpty && newName != username) {
                            setState(() {
                              username = newName;
                            });
                            User().name = newName;
                            Firebase.write('users/${User().id}', {
                              'name': newName,
                              'modifiedAt': DateTime.now().toIso8601String()
                            });
                          }
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20.sp),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    final allUsers = UserManager.instance.users;
    final currentUserId = UserManager.instance.currentUser?.userId;
    // If no current user, don't show any user rows to avoid duplication
    if (currentUserId == null) {
      return Padding(
        padding: EdgeInsets.only(left: 15.sp),
        child: Column(children: []),
      );
    }

    // Create list of user rows (excluding current user since it's shown at the top)
    List<Widget> userRows = [];
    for (var entry in allUsers.entries) {
      if (entry.value.userId != currentUserId) {
        userRows.add(_buildUserRow(entry.value));
      }
    }

    // Add the template user for creating new user at the end if limit not reached
    if (UserManager.instance.canCreateUser()) {
      final createNewUserRow = Container(
        margin: EdgeInsets.only(top: 10.sp),
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.sp),
            side: MyBorderStyle.standardBorderSide(),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14.sp),
            onTap: () => _showCreateNewUserModal(context),
            child: Padding(
              padding: EdgeInsets.only(
                top: 12.sp,
                bottom: 12.sp,
                left: 12.sp,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 12.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: MyBorderStyle.standardBorder(),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add,
                          color: Colors.deepPurple,
                          size: 30.sp,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.only(left: 12.sp),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  Malayalam.createNewUser,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                  style:
                                      ResponsiveText.h2Style(context).copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "0 ${Malayalam.points} (0 ${Malayalam.correct} 0 ${Malayalam.wrong})",
                                  textAlign: TextAlign.left,
                                  style: ResponsiveText.bodyStyle(context)
                                      .copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "0 ${Malayalam.medal}",
                                textAlign: TextAlign.left,
                                style:
                                    ResponsiveText.bodyStyle(context).copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      userRows.add(createNewUserRow);
    }

    // Add bottom padding after the last user row
    userRows.add(SizedBox(height: 10.sp));

    return Padding(
      padding: EdgeInsets.only(left: 10.sp, right: 10.sp),
      child: Column(children: userRows),
    );
  }

  Widget _buildUserRow(UserData user) {
    return Container(
      margin: EdgeInsets.only(top: 10.sp),
      child: Material(
        color: Colors.deepPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.sp),
          side: MyBorderStyle.standardBorderSide(),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14.sp),
          onTap: () => _switchToUser(user.userId),
          child: Padding(
            padding: EdgeInsets.only(
              top: 12.sp,
              bottom: 12.sp,
              left: 12.sp,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: CachedProfilePicture(
                    user: user,
                    size: 12.h,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.only(left: 12.sp),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.name,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.left,
                                style: ResponsiveText.h2Style(context),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${user.score} ${Malayalam.points} (${user.correct} ${Malayalam.correct} ${user.wrong} ${Malayalam.wrong})",
                                textAlign: TextAlign.left,
                                style: ResponsiveText.bodyStyle(context),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              "${user.badges.length} ${Malayalam.medal}",
                              textAlign: TextAlign.left,
                              style: ResponsiveText.bodyStyle(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _switchToUser(String userId) async {
    // Scroll to top simultaneously with collapse
    if (mounted && _scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    // Close the user list
    setState(() {
      _showUserList = false;
      _dropdownController.reverse();
    });

    // Switch to the selected user
    await UserManager.instance.switchToUser(userId);

    // Update local state to reflect the new user
    setState(() {
      username = User().name;
      profilepic = User().profilepic;
    });

    // Re-preload user profile pictures in case they changed
    _preloadUserProfilePictures();

    // Show a brief success animation/feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${Malayalam.switchedTo} ${User().name}',
          style: ResponsiveText.bodyStyle(context),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showCreateNewUserModal(BuildContext context) {
    final TextEditingController _nameController = TextEditingController();
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
          child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: EdgeInsets.all(16.sp),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 10.sp),
                  TypeAheadField<String>(
                    controller: _nameController,
                    builder: (context, controller, focusNode) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: ResponsiveText.h2Style(context),
                        maxLength: Malayalam.maxUsernameLength,
                        inputFormatters: [Malayalam.malayalamInputFormatter],
                        decoration: InputDecoration(
                          labelText: Malayalam.newName,
                          labelStyle: ResponsiveText.bodyStyle(context),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.deepPurple.shade300,
                              width: 7.sp,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.deepPurple.shade300,
                              width: 7.sp,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.deepPurple.shade300,
                              width: 7.sp,
                            ),
                          ),
                        ),
                      );
                    },
                    suggestionsCallback: (pattern) async {
                      if (pattern.isEmpty) return <String>[''];
                      TransliterationResponse? response =
                          await Transliteration.transliterate(
                              pattern, Languages.MALAYALAM);
                      var results =
                          response?.transliterationSuggestions ?? <String>[''];

                      // Filter out non-Malayalam suggestions
                      results = results
                          .where((suggestion) =>
                              suggestion.isNotEmpty &&
                              Malayalam.isValidMalayalamName(suggestion))
                          .toList();

                      // If no valid Malayalam suggestions, return empty
                      if (results.isEmpty) {
                        return <String>[''];
                      }

                      return results;
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(title: Text(suggestion));
                    },
                    onSelected: (suggestion) {
                      if (suggestion.isEmpty) {
                        return;
                      }

                      // Validate that the suggestion contains only Malayalam characters
                      if (!Malayalam.isValidMalayalamName(suggestion)) {
                        // Invalid characters detected - reject this selection
                        return;
                      }

                      _nameController.text = suggestion;
                    },
                  ),
                  SizedBox(height: 16.sp),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      DialogButton(
                        name: Malayalam.save,
                        callback: () async {
                          String newName = _nameController.text.trim();
                          if (newName.isNotEmpty) {
                            try {
                              // Generate unique user ID
                              final userId = generateUserId();

                              // Create new user (already onboarded since added through user management)
                              await UserManager.instance.createUser(
                                userId: userId,
                                name: newName,
                                firstTime:
                                    false, // Explicitly mark as already onboarded
                              );

                              // Write to Firebase (similar to onboarding)
                              final nowIso = DateTime.now().toIso8601String();
                              await Firebase.write('users/${userId}', {
                                'name': newName,
                                'score': 0,
                                'badge': 0,
                                'createdAt': nowIso,
                                'modifiedAt': nowIso,
                              });

                              // Switch to the newly created user
                              await UserManager.instance.switchToUser(userId);

                              // Update local state with post-frame callback to ensure in-memory propagation
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    username = User().name;
                                    profilepic = User().profilepic;
                                  });
                                }
                              });

                              // Close the modal
                              if (mounted) Navigator.pop(context);

                              // Scroll to top simultaneously with collapse
                              if (mounted && _scrollController.hasClients) {
                                _scrollController.animateTo(
                                  0.0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              }

                              // Collapse the user list dropdown
                              setState(() {
                                _showUserList = false;
                                _dropdownController.reverse();
                              });

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${Malayalam.switchedTo} $newName',
                                    style: ResponsiveText.bodyStyle(context),
                                  ),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              // Show error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error creating user: ${e.toString()}',
                                    style: ResponsiveText.bodyStyle(context),
                                  ),
                                  duration: const Duration(seconds: 3),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20.sp),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
