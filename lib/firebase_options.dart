// Template Firebase Options for open-source app
// This file has been sanitized for open-source distribution
// Replace with your own Firebase configuration
//
// To generate this file for your Firebase project:
// 1. Install FlutterFire CLI: dart pub global activate flutterfire_cli
// 2. Run: flutterfire configure
//
// This template uses environment variables from .env file
// Make sure to set up your .env file with Firebase configuration values

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_WEB_API_KEY'] ?? 'your_web_api_key_here',
    appId: dotenv.env['FIREBASE_WEB_APP_ID'] ?? 'your_web_app_id_here',
    messagingSenderId:
        dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ??
        'your_messaging_sender_id_here',
    projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? 'your_project_id_here',
    authDomain:
        dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? 'your_project_id.firebaseapp.com',
    databaseURL:
        dotenv.env['FIREBASE_DATABASE_URL'] ??
        'https://your_project_id-default-rtdb.firebaseio.com',
    storageBucket:
        dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'your_project_id.appspot.com',
    measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? 'G-XXXXXXXXXX',
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey:
        dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? 'your_android_api_key_here',
    appId: dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? 'your_android_app_id_here',
    messagingSenderId:
        dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ??
        'your_messaging_sender_id_here',
    projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? 'your_project_id_here',
    databaseURL:
        dotenv.env['FIREBASE_DATABASE_URL'] ??
        'https://your_project_id-default-rtdb.firebaseio.com',
    storageBucket:
        dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'your_project_id.appspot.com',
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_IOS_API_KEY'] ?? 'your_ios_api_key_here',
    appId: dotenv.env['FIREBASE_IOS_APP_ID'] ?? 'your_ios_app_id_here',
    messagingSenderId:
        dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ??
        'your_messaging_sender_id_here',
    projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? 'your_project_id_here',
    databaseURL:
        dotenv.env['FIREBASE_DATABASE_URL'] ??
        'https://your_project_id-default-rtdb.firebaseio.com',
    storageBucket:
        dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'your_project_id.appspot.com',
    iosClientId:
        dotenv.env['FIREBASE_IOS_CLIENT_ID'] ?? 'your_ios_client_id_here',
    iosBundleId:
        dotenv.env['FIREBASE_IOS_BUNDLE_ID'] ?? 'com.yourcompany.yourapp',
  );

  static FirebaseOptions get macos => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_IOS_API_KEY'] ?? 'your_ios_api_key_here',
    appId: dotenv.env['FIREBASE_IOS_APP_ID'] ?? 'your_ios_app_id_here',
    messagingSenderId:
        dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ??
        'your_messaging_sender_id_here',
    projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? 'your_project_id_here',
    databaseURL:
        dotenv.env['FIREBASE_DATABASE_URL'] ??
        'https://your_project_id-default-rtdb.firebaseio.com',
    storageBucket:
        dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'your_project_id.appspot.com',
    iosClientId:
        dotenv.env['FIREBASE_IOS_CLIENT_ID'] ?? 'your_ios_client_id_here',
    iosBundleId:
        dotenv.env['FIREBASE_IOS_BUNDLE_ID'] ?? 'com.yourcompany.yourapp',
  );
}
