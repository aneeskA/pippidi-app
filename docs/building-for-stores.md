# Building for App Stores

This guide covers building and submitting your Flutter app to the Apple App Store and Google Play Store.

## 📋 Prerequisites

- Firebase project configured
- RevenueCat configured
- App Store Connect account
- Google Play Console account
- Signing certificates/keys set up

## Android Build Guide

### 1. Generate Signing Key

#### Option 1: Use keytool (Recommended)

```bash
# Generate a keystore
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# You'll be prompted for:
# - Keystore password
# - Key alias (use "upload")
# - Key password (same as keystore password)
# - Your name, organization, etc.
```

#### Option 2: Use Android Studio

1. Open Android Studio
2. Go to **Build** → **Generate Signed Bundle/APK**
3. Create new keystore
4. Fill in details

### 2. Configure Key Properties

Create `android/key.properties` file:

```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=upload
storeFile=../upload-keystore.jks
```

**Security Note:** Never commit this file to version control!

### 3. Update Build Configuration

Your `android/app/build.gradle` already has conditional signing config. Make sure:

1. `key.properties` file exists
2. Keystore file is in the correct location
3. Passwords are correct

### 4. Build Release Bundle

```bash
# Build Android App Bundle (recommended)
flutter build appbundle --release

# Or build APK (if required)
flutter build apk --release
```

### 5. Test Release Build

```bash
# Install release build for testing
flutter build apk --release
flutter install
```

### 6. Submit to Google Play

#### Step 6.1: Create Play Store Listing

1. Go to [Google Play Console](https://play.google.com/console/)
2. Create new app or select existing
3. Fill in store listing:
   - App name and description
   - Screenshots (at least 2 per type)
   - Feature graphic
   - Privacy policy URL
   - App category

#### Step 6.2: Upload Bundle

1. Go to **Release** → **Production** (or Internal/Beta testing first)
2. Click **"Create new release"**
3. Upload your `.aab` file
4. Fill in release notes
5. Review and submit

#### Step 6.3: Set Up Pricing & Distribution

1. Set app pricing (free or paid)
2. Choose countries for distribution
3. Set content rating
4. Add contact details

## iOS Build Guide

### 1. Set Up Apple Developer Account

#### Create App ID

1. Go to [Apple Developer](https://developer.apple.com/)
2. Go to **Certificates, Identifiers & Profiles**
3. Create new **App ID**:
   - Select **App** type
   - Enter description
   - Enter bundle ID (must match Xcode project)
   - Enable required capabilities (Push Notifications, etc.)

#### Create Provisioning Profile

1. Create **Development** provisioning profile
2. Create **Distribution** provisioning profile
3. Download and install profiles

### 2. Configure Xcode Project

#### Bundle Identifier

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target
3. Go to **General** tab
4. Update **Bundle Identifier** to match your App ID

#### Team & Signing

1. Select your development team
2. Enable **Automatically manage signing**
3. For release builds, select appropriate provisioning profile

#### Capabilities

Enable required capabilities:
- **Push Notifications**
- **Associated Domains** (for deep linking)
- **Background Modes** (for push notifications)

### 3. Configure Build Settings

#### Version & Build Numbers

1. Update **Version** (marketing version, e.g., 1.0.0)
2. Update **Build** (technical version, increment for each build)

#### Deployment Target

Set minimum iOS version (recommended: 12.0+)

### 4. Build & Archive

#### Using Xcode

1. Open `ios/Runner.xcworkspace`
2. Select **Generic iOS Device** (not simulator)
3. Go to **Product** → **Archive**
4. Wait for archiving to complete

#### Using Flutter CLI

```bash
# Build iOS release
flutter build ios --release --no-tree-shake-icons

# Then archive in Xcode
```

### 5. Submit to App Store

#### Step 5.1: Create App Store Connect App

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Click **"+"** to create new app
3. Fill in app information:
   - Name
   - Bundle ID (must match Xcode)
   - SKU
   - User access

#### Step 5.2: Upload Build

1. In Xcode Organizer, select your archive
2. Click **"Distribute App"**
3. Select **"App Store Connect"**
4. Choose **"Upload"**
5. Sign in with your Apple ID

#### Step 5.3: Configure App Store Listing

1. In App Store Connect, go to your app
2. Fill in app information:
   - Description
   - Screenshots (multiple sizes required)
   - App icons
   - Keywords
   - Support URL
   - Marketing URL (optional)
   - Privacy Policy URL

#### Step 5.4: Pricing & Availability

1. Set price tier
2. Choose availability by country
3. Set app rating
4. Configure in-app purchases

#### Step 5.5: Submit for Review

1. Create new version
2. Select build to submit
3. Add version details and screenshots
4. Submit for Apple review

## Deep Linking Setup

### Android App Links

#### 1. Digital Asset Links

Create `assetlinks.json` file:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.yourcompany.yourapp",
    "sha256_cert_fingerprints": [
      "YOUR_SHA256_FINGERPRINT"
    ]
  }
}]
```

#### 2. Get SHA256 Fingerprint

```bash
# For debug keystore
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# For release keystore
keytool -list -v -keystore upload-keystore.jks -alias upload
```

#### 3. Host assetlinks.json

Upload to: `https://yourdomain.com/.well-known/assetlinks.json`

#### 4. Android Manifest

Your `android/app/src/main/AndroidManifest.xml` should have:

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https"
          android:host="yourdomain.com"
          android:pathPrefix="/user" />
</intent-filter>
```

### iOS Universal Links

#### 1. Associated Domains

In Xcode:
1. Go to **Signing & Capabilities**
2. Add **Associated Domains**
3. Add: `applinks:yourdomain.com`

#### 2. Apple App Site Association (AASA)

Create `apple-app-site-association` file:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.yourcompany.yourapp",
        "paths": ["/user/*"]
      }
    ]
  }
}
```

#### 3. Host AASA File

Upload to: `https://yourdomain.com/.well-known/apple-app-site-association`

## Testing App Store Builds

### Internal Testing

#### iOS TestFlight

1. Upload build to TestFlight
2. Add internal testers
3. Test deep linking and purchases

#### Android Internal Testing

1. Upload to Play Console Internal track
2. Add tester emails
3. Test app functionality

### Beta Testing

#### iOS

1. Submit to TestFlight Beta
2. Share public link for external testers

#### Android

1. Use Open/Beta/Alpha testing tracks
2. Share testing links with users

## Common Build Issues

### Android Issues

**Build fails with signing error:**
- Check `key.properties` passwords
- Verify keystore file location
- Ensure alias name is correct

**Play Store rejection:**
- Check content rating
- Verify privacy policy
- Ensure screenshots meet guidelines

**App Links not working:**
- Verify `assetlinks.json` is accessible
- Check SHA256 fingerprint matches
- Test with `adb` commands

### iOS Issues

**Archive fails:**
- Check bundle identifier matches App ID
- Verify provisioning profile is valid
- Ensure certificates are not expired

**App Store rejection:**
- Check app icons meet size requirements
- Verify screenshots are correct size
- Ensure privacy policy is linked

**Universal Links not working:**
- Verify AASA file is accessible
- Check team ID in AASA file
- Test with `xcrun simctl openurl`

## Performance Optimization

### Android

```bash
# Build with performance optimizations
flutter build appbundle --release --target-platform android-arm,android-arm64 --split-per-abi
```

### iOS

```bash
# Build optimized iOS app
flutter build ios --release --no-tree-shake-icons
```

## Continuous Integration (Optional)

### Fastlane for iOS

```ruby
# Gemfile
gem 'fastlane'

# Fastfile
lane :beta do
  build_app(
    scheme: "Runner",
    export_method: "app-store"
  )
  upload_to_testflight
end
```

### Fastlane for Android

```ruby
lane :beta do
  gradle(task: "bundleRelease")
  upload_to_play_store(
    track: 'internal',
    apk: 'build/app/outputs/bundle/release/app-release.aab'
  )
end
```

## Pre-Launch Checklist

### Before Submitting

- [ ] All Firebase services configured
- [ ] RevenueCat products set up and approved
- [ ] Deep linking configured and tested
- [ ] Privacy policy published
- [ ] App icons and screenshots ready
- [ ] Version numbers updated
- [ ] Signing certificates valid
- [ ] Test builds working on devices

### Store-Specific Requirements

**App Store:**
- [ ] App Review Guidelines compliance
- [ ] TestFlight testing completed
- [ ] In-app purchases configured
- [ ] Export compliance (if applicable)

**Play Store:**
- [ ] Content rating completed
- [ ] Target audience selected
- [ ] Pricing and distribution set
- [ ] Store listing translations (if applicable)

## Post-Launch

### Monitoring

1. **Crash reporting** via Firebase Crashlytics
2. **Analytics** via Firebase Analytics
3. **Revenue tracking** via RevenueCat
4. **User feedback** and reviews

### Updates

1. Plan regular updates with bug fixes and features
2. Monitor crash reports and fix issues
3. Update dependencies for security
4. Add new content and features

## Support Resources

- [Flutter Deployment Docs](https://flutter.dev/docs/deployment)
- [App Store Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Google Play Policies](https://play.google.com/about/developer-content-policy/)
- [Firebase App Distribution](https://firebase.google.com/products/app-distribution)
