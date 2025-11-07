# Pippidi - Open Source Flutter App Template

An open-source Flutter app template for Malayalam language learning games with Firebase backend and RevenueCat in-app purchases. This template provides a complete, production-ready foundation that you can fork and customize for your own app.

## Showcase

1. [pippidi.com](https://pippidi.com)
2. [App Store](https://apps.apple.com/in/app/pippidi/id1663599178)
3. [Play Store](https://play.google.com/store/apps/details?id=com.aneeska.pippidi.android.app)

## ✨ Features

- 🎮 Interactive Malayalam language learning games
- 🔐 Firebase Authentication & Firestore database
- 💳 RevenueCat in-app purchases and subscriptions
- 📱 Cross-platform (iOS/Android/Web)
- 🔗 Deep linking support
- 🔔 Push notifications
- 📊 Firebase Analytics & Crashlytics
- 🎨 Modern Material Design UI
- 🌐 Multi-language support (English/Malayalam)

## 🚀 Quick Start

### Prerequisites

- Flutter SDK (3.0+)
- Firebase account
- RevenueCat account (for in-app purchases)
- Android Studio (for Android builds)
- Xcode (for iOS builds)

### 1. Clone & Setup

```bash
git clone https://github.com/aneeskA/pippidi-app.git
cd pippidi-app
flutter pub get
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your API keys (see setup guides below)
nano .env
```

### 3. Firebase Setup

Follow the [Firebase Setup Guide](./docs/firebase-setup.md) to:

- Create a Firebase project
- Enable required services (Auth, Firestore, etc.)
- Download configuration files
- Update environment variables

### 4. RevenueCat Setup

Follow the [RevenueCat Setup Guide](./docs/revenuecat-setup.md) to:

- Create a RevenueCat account
- Configure products and subscriptions
- Get API keys
- Update environment variables

### 5. Run the App

```bash
# For development
flutter run

# For release builds, see platform-specific guides below
```

## 📋 Setup Guides

### Firebase Configuration

📖 [Complete Firebase Setup](./docs/firebase-setup.md)

- Create Firebase project
- Configure Authentication, Firestore, Storage
- Set up push notifications
- Generate config files

### RevenueCat Configuration

📖 [Complete RevenueCat Setup](./docs/revenuecat-setup.md)

- Create RevenueCat account
- Configure products and subscriptions
- Set up app stores
- Generate API keys

### Building for App Stores

📖 [Android Build Guide](./docs/building-for-stores.md#android)
📖 [iOS Build Guide](./docs/building-for-stores.md#ios)

- Signing certificates and keystores
- App store submissions
- Release configurations

## 🔧 Configuration Files

### Environment Variables (.env)

Copy `.env.example` to `.env` and fill in your keys:

```bash
# Firebase
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_WEB_API_KEY=your_web_api_key
FIREBASE_ANDROID_API_KEY=your_android_api_key
FIREBASE_IOS_API_KEY=your_ios_api_key
# ... (see .env.example for all variables)

# RevenueCat
REVENUECAT_ANDROID_API_KEY=your_android_revenuecat_key
REVENUECAT_IOS_API_KEY=your_ios_revenuecat_key
```

### Firebase Config Files

Replace template files with your actual Firebase configuration:

- `android/app/google-services.json` - Android Firebase config
- `ios/Runner/GoogleService-Info.plist` - iOS Firebase config

### Build Configuration

For release builds, you'll need to set up signing:

**Android:**

- Create a keystore file
- Update `android/key.properties` with your signing credentials

**iOS:**

- Configure signing certificates in Xcode
- Update bundle identifiers if needed

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration (uses .env)
├── data/                     # Data models and services
├── pages/                    # App screens/pages
├── ui/                       # UI components and widgets
├── util/                     # Utilities and helpers
├── onboarding/               # Onboarding flow
├── questions/                # Game questions and logic
└── welcome/                  # Welcome screens

android/                      # Android-specific files
├── app/
│   ├── google-services.json  # Firebase config (template)
│   └── build.gradle         # Build configuration
└── key.properties           # Signing config (create for releases)

ios/                          # iOS-specific files
├── Runner/
│   └── GoogleService-Info.plist # Firebase config (template)
├── Podfile                  # CocoaPods dependencies
└── Runner.xcodeproj/        # Xcode project

docs/                        # Documentation
├── firebase-setup.md        # Firebase configuration guide
├── revenuecat-setup.md      # RevenueCat configuration guide
└── building-for-stores.md   # App store deployment guide
```

## 🧪 Testing

```bash
# Run tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart

# Analyze code
flutter analyze

# Format code
flutter format .
```

## 📦 Building for Production

### Android

```bash
# Create keystore (first time only)
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Build release bundle
flutter build appbundle --release
```

### iOS

```bash
# Build for iOS
flutter build ios --release

# Open in Xcode for archiving
open ios/Runner.xcworkspace
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow Flutter's [style guide](https://flutter.dev/docs/development/tools/formatting)
- Use `flutter format` before committing
- Run `flutter analyze` to check for issues
- Write tests for new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Backend powered by [Firebase](https://firebase.google.com/)
- In-app purchases via [RevenueCat](https://revenuecat.com/)

#### 🏗️ iOS Build Instructions

```bash
# Build iOS release
flutter build ios --release --no-tree-shake-icons

# Archive in Xcode:
# 1. Open ios/Runner.xcworkspace
# 2. Product → Archive
# 3. Upload to TestFlight
```

#### 🧪 iOS Testing

```bash
# Test Universal Links after TestFlight install:
# Open Safari → https://pippidi.com/user/TESTUSER
# Should open app directly (no Safari fallback)
```

### Android App Links

#### ✅ Configuration Complete

**Package Name:** `com.aneeska.pippidi.android.app`
**Domain:** `pippidi.com`
**Path Pattern:** `/user/*`

#### 📋 Android Files Configuration

**AndroidManifest.xml** (`android/app/src/main/AndroidManifest.xml`):

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https"
          android:host="pippidi.com"
          android:pathPrefix="/user" />
</intent-filter>
```

**assetlinks.json** (`https://pippidi.com/.well-known/assetlinks.json`):

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.aneeska.pippidi.android.app",
      "sha256_cert_fingerprints": [
        "C0:EC:FB:E6:CC:C4:25:C3:7D:B0:AC:4C:68:C1:9F:EE:0B:00:2A:F1:37:6A:36:67:62:B3:88:4D:EA:24:52:3E",
        "E0:C7:B4:2C:E9:EF:47:0A:31:00:82:2F:E4:67:7D:73:C2:B6:BF:B0:1C:90:8E:06:F4:3F:73:D1:5C:17:85:69"
      ]
    }
  }
]
```

**Key Properties** (`android/key.properties`):

```properties
storePassword=pippidi
keyPassword=pippidi
keyAlias=upload
storeFile=../../pippidi-upload-keystore.jks
```

#### 🛠️ Update Script

Run `./update_assetlinks.sh` when you change signing keys:

```bash
#!/bin/bash
# Auto-generates assetlinks.json with current keystore fingerprints
./update_assetlinks.sh
```

#### 🏗️ Android Build Instructions

```bash
# Build Android release bundle
flutter build appbundle --release --no-tree-shake-icons

# Build debug APK for testing
flutter build apk --debug
```

#### 🧪 Android Testing

```bash
# Install debug APK
flutter build apk --debug
# Install: build/app/outputs/flutter-apk/app-debug.apk

# Test App Links:
# Open Chrome → https://pippidi.com/user/TESTUSER
# Should open app directly
```

## Release

### iOS

```bash
$ flutter build ios --release --no-tree-shake-icons
# Then archive in Xcode and upload to TestFlight
```

### Android

```bash
$ flutter build appbundle --release --no-tree-shake-icons
# Upload to Play Store
```
