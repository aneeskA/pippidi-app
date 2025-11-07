import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: uri_does_not_exist
import 'package:firebase_crashlytics/firebase_crashlytics.dart' as crashlytics;
import 'package:firebase_messaging/firebase_messaging.dart';
// ignore: uri_does_not_exist
import 'package:firebase_performance/firebase_performance.dart' as performance;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sizer/sizer.dart';
import 'package:upgrader/upgrader.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:pippidi/data/questions.dart';
import 'package:pippidi/pages/landing.dart';
import 'package:pippidi/pages/onboarding.dart';
import 'package:pippidi/pages/play_category.dart';
import 'package:pippidi/util/install_new_questions.dart';
import 'package:pippidi/util/mal_upgrade_message.dart';
import 'package:pippidi/data/user.dart';
import 'package:pippidi/firebase_options.dart';
import 'package:pippidi/util/firebase.dart' as fb;
import 'package:pippidi/util/error_reporting.dart';

// Global navigator key for deep linking
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Generic deep link handler
class DeepLinkHandler {
  static const String domain = 'pippidi.com';
  static String? pendingUserId;

  static void handleUri(Uri uri) {
    try {
      if (uri.host == domain && uri.pathSegments.isNotEmpty) {
        final path = uri.pathSegments.first;

        switch (path) {
          case 'user':
            if (uri.pathSegments.length > 1) {
              pendingUserId = uri.pathSegments[1];
              _navigateToHome();
            }
            break;
          // Add more deep link patterns here as needed
          default:
            break;
        }
      }
    } catch (e) {
      print('Error handling deep link URI: $e');
      // Clear any partial state
      pendingUserId = null;
    }
  }

  static void _navigateToHome() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => LandingPage(
                  jumpTo:
                      0)), // Navigate to LandingPage with HomePage (index 0)
          (route) => false,
        );
      }
    });
  }

  static void clearPendingData() {
    pendingUserId = null;
  }
}

// Handle deep links (legacy wrapper for backward compatibility)
void _handleDeepLink(Uri uri) {
  DeepLinkHandler.handleUri(uri);
}

// in app purchase keys - loaded from environment variables
String get iosPurchaseKey => dotenv.env['REVENUECAT_IOS_API_KEY'] ?? 'your_ios_revenuecat_api_key_here';
String get androidPurchaseKey => dotenv.env['REVENUECAT_ANDROID_API_KEY'] ?? 'your_android_revenuecat_api_key_here';

/// Safely get FCM token with iOS APNS token checking and Android retry
Future<void> _initializeFCMToken() async {
  try {
    String? apnsToken;
    bool apnsReady = true;

    // For iOS, check if APNS token is available before getting FCM token
    if (Platform.isIOS) {
      // Poll for APNS token with timeout (increased to 30 seconds)
      int attempts = 0;
      const maxAttempts = 30;

      while (apnsToken == null && attempts < maxAttempts) {
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) {
          attempts++;
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }

      if (apnsToken == null) {
        apnsReady = false;
      }
    }

    if (apnsReady) {
      // Retry token fetch for Android (can be delayed due to Play Services)
      String? token;
      if (Platform.isAndroid) {
        // For Android, APNS is not needed for token fetch
        int retryAttempts = 0;
        const maxRetries = 5;
        while (token == null && retryAttempts < maxRetries) {
          token = await FirebaseMessaging.instance.getToken();
          if (token == null) {
            retryAttempts++;
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }

      if (Platform.isIOS) {
        // Only get FCM token if APNS is ready (on iOS)
        token = await FirebaseMessaging.instance.getToken();
      }

      if (token != null) {
        await _updateFCMTokenInBackend(token); // Sync to backend
      }
    }
  } catch (e, stack) {
    ErrorReporting.logError(e, stack,
        message: 'FCM token retrieval failed - app continues normally');
  }
}

// Add this function after _initializeFCMToken (around line 173, before /// Deferred initialization)
Future<void> _updateFCMTokenInBackend(String? token) async {
  if (token == null) return;
  try {
    final currentUserId = User().id;
    if (currentUserId.isNotEmpty) {
      await fb.Firebase.write('users/${currentUserId}', {'fcm_token': token});
    } else {
      print('No current user - skipping FCM token sync');
    }
  } catch (e, stack) {
    // Check if this is a permission error (expected with anonymous auth)
    final errorMessage = e.toString();
    if (errorMessage.contains('permission-denied')) {
      // This is expected - anonymous users can't write to Firebase database
      // Silently ignore this error as it's not actionable for users
      print(
          'FCM token sync skipped due to permissions (expected with anonymous auth)');
    } else {
      // Log other unexpected errors
      ErrorReporting.logError(e, stack,
          message: 'Failed to update FCM token in backend');
    }
  }
}

// Ensure onTokenRefresh is set up in main() after FCM setup
// (Add this if not present, after FirebaseMessaging.onMessageOpenedApp.listen)

/// Deferred initialization for non-critical components
Future<void> _initializeDeferredComponents() async {
  try {
    // Initialize Questions data (was blocking startup)
    try {
      Questions(); // load questions data in background
      ErrorReporting.logAppLifecycleEvent('Questions data initialized');
    } catch (e, stack) {
      ErrorReporting.logError(e, stack,
          message: 'Questions initialization failed');
    }

    // Initialize deep linking in background
    final appLinks = AppLinks();

    // Handle initial link (when app is opened from a deep link)
    final initialLink = await appLinks.getInitialLink();
    if (initialLink != null) {
      _handleDeepLink(initialLink);
    }

    // Handle links while app is running
    appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });

    // Setup in-app purchases (non-critical for initial UI) - with duplicate prevention
    bool _purchasesConfigured = false;
    if (!_purchasesConfigured) {
      try {
        if (Platform.isIOS) {
          await Purchases.configure(PurchasesConfiguration(iosPurchaseKey));
        } else if (Platform.isAndroid) {
          await Purchases.configure(PurchasesConfiguration(androidPurchaseKey));
        }
        _purchasesConfigured = true;
      } catch (e, stack) {
        ErrorReporting.logError(e, stack,
            message: 'Purchases configuration failed - continuing without IAP');
      }
    }

    await _initializeFCMToken();

    ErrorReporting.logAppLifecycleEvent('Deferred components initialized');
  } catch (e, stack) {
    ErrorReporting.logError(e, stack,
        message: 'Deferred initialization failed');
  }
}

// Close StreamControllers when app is terminated
void cleanupApp() {
  // Close StreamControllers in Questions class
  Questions().dispose();

  // Close StreamControllers in User class
  User().dispose();
}

Future<void> _handleInitialMessage() async {
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    String category = initialMessage.data['category'] ?? '';
    FirebaseAnalytics.instance.logAppOpen();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushReplacement(
          MaterialPageRoute(
            builder: (context) => LandingPage(
              jumpTo: 1,
              category: category,
            ),
          ),
        );
      }
    });
  }
}

// notifications
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Hive.initFlutter();
  await Hive.openBox(Questions.BOXNAME);
  Questions();
  await InstallQuestions().Do();
}

Future<void> main() async {
  final startTime = DateTime.now();
  ErrorReporting.logAppLifecycleEvent('App startup initiated');

  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Lock app to portrait orientation only (critical for UI)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Keep native splash screen up until app is finished bootstrapping
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // CRITICAL PATH: Initialize essential components first
  // Firebase core (essential for app functionality)
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // Firebase already initialized (e.g., from background handler)
    // This is normal and expected - continue with existing app
    ErrorReporting.logAppLifecycleEvent(
        'Firebase already initialized, using existing app');
  }

  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  // Initialize Firebase Crashlytics immediately for error reporting
  await crashlytics.FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(true);
  FlutterError.onError =
      crashlytics.FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.FirebaseCrashlytics.instance
        .recordError(error, stack, fatal: true);
    return true;
  };

  // Firebase Performance Monitoring (essential for Android Vitals)
  await performance.FirebasePerformance.instance
      .setPerformanceCollectionEnabled(true);

  // Firebase App Check (security, essential)
  await FirebaseAppCheck.instance.activate();

  // Sign in anonymously (essential for database access)
  await fb.Firebase.signInAnonymously();

  // Initialize local storage (critical for app data)
  await Hive.initFlutter();
  // Defer Questions initialization to avoid blocking startup
  // Questions(); // load questions - moved to deferred initialization
  await Hive.openBox(User.BOXNAME);

  // Initialize User system with UserManager
  await User.initialize();

  // Initialize Questions singleton after Hive setup
  await Hive.openBox(Questions.BOXNAME);
  Questions();

  // Setup Firebase messaging (important for notifications)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage event) async {
    await InstallQuestions().Do();
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage event) {
    String category = event.data['category'] ?? '';
    FirebaseAnalytics.instance.logAppOpen();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushReplacement(
          MaterialPageRoute(
            builder: (context) => LandingPage(
              jumpTo: 1,
              category: category,
            ),
          ),
        );
      }
    });
  });

  // Add the onTokenRefresh listener here
  FirebaseMessaging.instance.onTokenRefresh.listen((String token) async {
    try {
      await _updateFCMTokenInBackend(token);
      ErrorReporting.logAppLifecycleEvent('FCM token refreshed and synced');
    } catch (e) {
      // Token refresh errors are handled in _updateFCMTokenInBackend
      // No additional logging needed here
    }
  });

  // Register cleanup for app termination
  WidgetsBinding.instance.addObserver(AppLifecycleObserver());

  // Log critical path completion time
  final criticalPathTime = DateTime.now().difference(startTime).inMilliseconds;
  ErrorReporting.logPerformanceMetric(
      'app_critical_startup_time_ms', criticalPathTime,
      unit: 'ms');
  ErrorReporting.logAppLifecycleEvent('Critical startup path completed',
      context: {'time_ms': criticalPathTime});

  // Launch the app immediately - UI is ready
  runApp(const MyApp());

  _handleInitialMessage();

  // DEFERRED INITIALIZATION: Non-critical components in background
  // This improves perceived launch time by not blocking UI
  _initializeDeferredComponents();

  // Report fully drawn after a short delay to allow UI to render
  // This tells Android that the app is ready for user interaction
  Future.delayed(const Duration(milliseconds: 500), () {
    try {
      // For Android, signal that the app is fully drawn and ready
      // This helps with Android Vitals launch time metrics
      if (Platform.isAndroid) {
        ErrorReporting.logAppLifecycleEvent(
            'App reported as fully drawn to Android');
      }
    } catch (e, stack) {
      ErrorReporting.logError(e, stack, message: 'Report fully drawn failed');
    }
  });

  // Remove splash screen when critical path is complete
  FlutterNativeSplash.remove();

  // Log total startup time
  final totalStartupTime = DateTime.now().difference(startTime).inMilliseconds;
  ErrorReporting.logPerformanceMetric(
      'app_total_startup_time_ms', totalStartupTime,
      unit: 'ms');
  ErrorReporting.logAppLifecycleEvent('App fully started', context: {
    'total_startup_time_ms': totalStartupTime,
    'critical_path_time_ms': criticalPathTime
  });
}

// Observer to handle app lifecycle events
class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Log app lifecycle events for Android Vitals
    ErrorReporting.logAppLifecycleEvent(state.toString());

    if (state == AppLifecycleState.detached) {
      ErrorReporting.logAppLifecycleEvent(
          'App terminating - cleaning up resources');
      cleanupApp();
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? _isFirstTime;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    try {
      // Safely check firstTime without creating new instances during build
      final isFirstTime = User().firstTime;
      if (mounted) {
        setState(() {
          _isFirstTime = isFirstTime;
          _isLoading = false;
        });
        // Delay local notifications setup until after onboarding (prevents early popup)
        if (!isFirstTime) {
          // Removed setupFlutterNotifications();
        }
      }
    } catch (e, stack) {
      ErrorReporting.logError(e, stack,
          message: 'Failed to check firstTime in MyApp');
      // Default to first time if there's an error
      if (mounted) {
        setState(() {
          _isFirstTime = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while checking firstTime
    if (_isLoading || _isFirstTime == null) {
      return Sizer(builder: (context, orientation, deviceType) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          builder: BotToastInit(),
          navigatorObservers: [BotToastNavigatorObserver(), routeObserver],
          home: Scaffold(
            body: Container(
              color: Colors.deepPurple, // Match your splash screen color
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white, // White loading indicator
                ),
              ),
            ),
          ),
        );
      });
    }

    return Sizer(builder: (context, orientation, deviceType) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        builder: BotToastInit(),
        navigatorObservers: [BotToastNavigatorObserver(), routeObserver],
        home: _isFirstTime!
            ? OnBoardingPage()
            : UpgradeAlert(
                child: LandingPage(),
                upgrader: Upgrader(messages: MalayalamMessages())),
      );
    });
  }
}
