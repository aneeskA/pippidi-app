# Firebase Setup Guide

This guide will help you set up Firebase for your Flutter app. Follow these steps to create a Firebase project and configure all required services.

## 📋 Prerequisites

- Google account
- Flutter project (this template)
- Firebase CLI (optional, for advanced features)

## 1. Create Firebase Project

### Step 1: Go to Firebase Console

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Click **"Create a project"** or **"Add project"**
3. Enter your project name (e.g., `my-language-app`)
4. Choose whether to enable Google Analytics (recommended: **Yes**)
5. Select your Google Analytics account or create a new one
6. Click **"Create project"**

### Step 2: Wait for Project Creation

Firebase will take a few moments to create your project. Once ready, click **"Continue"**.

## 2. Enable Required Services

### Authentication

1. In your Firebase project, go to **Authentication** in the left sidebar
2. Click **"Get started"**
3. Go to the **Sign-in method** tab
4. Enable **Anonymous** authentication (required for this app)
5. Optionally enable other providers (Google, Email/Password, etc.)

### Firestore Database

1. Go to **Firestore Database** in the left sidebar
2. Click **"Create database"**
3. Choose **"Start in test mode"** (you can change security rules later)
4. Select a location for your database (choose the closest to your users)
5. Click **"Done"**

### Storage (Optional)

If your app needs file uploads:

1. Go to **Storage** in the left sidebar
2. Click **"Get started"**
3. Choose **"Start in test mode"**
4. Select the same location as your Firestore database
5. Click **"Done"**

### Cloud Messaging (Push Notifications)

1. Go to **Cloud Messaging** in the left sidebar
2. This should be enabled by default for new projects

## 3. Register Your Apps

### Web App (Optional)

1. Click the **Web icon** (`</>`) to add a web app
2. Enter an app nickname (e.g., "My Language App Web")
3. Check **"Also set up Firebase Hosting"** if you plan to deploy to web
4. Click **"Register app"**
5. Copy the config object - you'll need this for your `.env` file

### Android App

1. Click the **Android icon** to add an Android app
2. Enter your Android package name (from `android/app/build.gradle`):
   ```
   com.yourcompany.yourapp
   ```
3. Enter an app nickname (e.g., "My Language App Android")
4. Enter or generate a debug signing certificate (optional for now)
5. Click **"Register app"**
6. Download `google-services.json`
7. Place it in `android/app/google-services.json` (replace the template)
8. Click **"Next"** and follow the remaining setup steps

### iOS App

1. Click the **iOS icon** to add an iOS app
2. Enter your iOS bundle ID (from Xcode or `ios/Runner.xcodeproj`):
   ```
   com.yourcompany.yourapp
   ```
3. Enter an app nickname (e.g., "My Language App iOS")
4. Enter your Apple Developer Team ID (from developer.apple.com)
5. Click **"Register app"**
6. Download `GoogleService-Info.plist`
7. Place it in `ios/Runner/GoogleService-Info.plist` (replace the template)
8. Click **"Next"** and follow the remaining setup steps

## 4. Configure Environment Variables

After registering your apps, you'll have the necessary API keys. Update your `.env` file:

### Get API Keys from Firebase Console

1. Go to **Project Settings** (gear icon → Project settings)
2. Scroll down to **"Your apps"** section
3. Click on each app to see its configuration

### Update .env File

```bash
# Firebase Configuration
FIREBASE_PROJECT_ID=your_project_id_here
FIREBASE_MESSAGING_SENDER_ID=your_sender_id_here
FIREBASE_AUTH_DOMAIN=your_project_id.firebaseapp.com
FIREBASE_DATABASE_URL=https://your_project_id.firebaseio.com
FIREBASE_STORAGE_BUCKET=your_project_id.appspot.com
FIREBASE_MEASUREMENT_ID=G-XXXXXXXXXX

# Platform-specific API Keys
FIREBASE_WEB_API_KEY=your_web_api_key_here
FIREBASE_WEB_APP_ID=your_web_app_id_here
FIREBASE_ANDROID_API_KEY=your_android_api_key_here
FIREBASE_ANDROID_APP_ID=your_android_app_id_here
FIREBASE_IOS_API_KEY=your_ios_api_key_here
FIREBASE_IOS_APP_ID=your_ios_app_id_here
FIREBASE_IOS_CLIENT_ID=your_ios_client_id_here
FIREBASE_IOS_BUNDLE_ID=com.yourcompany.yourapp
```

## 5. Security Rules (Important!)

### Firestore Security Rules

Go to **Firestore Database** → **Rules** and update the default rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to authenticated users
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Allow anonymous read access for certain collections (customize as needed)
    match /public/{document=**} {
      allow read: if true;
      allow write: if false;
    }
  }
}
```

### Storage Security Rules (if using Storage)

Go to **Storage** → **Rules**:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 6. Test Your Setup

### Run the App

```bash
flutter run
```

The app should now connect to your Firebase project. Check the console for any connection errors.

### Verify Services

1. **Authentication**: Try creating an anonymous user
2. **Firestore**: Check if data is being read/written
3. **Analytics**: Events should appear in Firebase console
4. **Crashlytics**: Force a test crash to verify error reporting

## 7. Additional Configuration

### Push Notifications (iOS)

For iOS push notifications, you'll need:

1. Apple Developer account
2. APNs certificates or keys
3. Upload them to Firebase Console → Cloud Messaging → iOS app configuration

### App Check (Security)

To enable Firebase App Check:

1. Go to **App Check** in Firebase Console
2. Enable for each platform
3. Follow the setup instructions for each platform

## Troubleshooting

### Common Issues

**App won't connect to Firebase:**
- Check that `google-services.json` and `GoogleService-Info.plist` are in the correct locations
- Verify API keys in `.env` match your Firebase project
- Check package name/bundle ID matches what you registered

**Permission denied errors:**
- Check Firestore/Storage security rules
- Ensure users are authenticated before accessing data

**Analytics not working:**
- Verify Measurement ID is correct in `.env`
- Check that analytics is enabled in the app

### Getting Help

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.google.com/docs/flutter/setup)
- [Firebase Community Forums](https://firebase.google.com/community)

## Next Steps

Once Firebase is set up, proceed to [RevenueCat Setup](./revenuecat-setup.md) to configure in-app purchases.
