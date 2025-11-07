# RevenueCat Setup Guide

This guide will help you set up RevenueCat for in-app purchases and subscriptions in your Flutter app.

## 📋 Prerequisites

- RevenueCat account ([Sign up](https://app.revenuecat.com/signup))
- App Store Connect account (for iOS)
- Google Play Console account (for Android)
- Firebase project (completed previous setup)

## 1. Create RevenueCat Account

### Step 1: Sign Up

1. Go to [RevenueCat Signup](https://app.revenuecat.com/signup)
2. Create an account with your email
3. Verify your email address

### Step 2: Create Your App

1. In RevenueCat dashboard, click **"New App"**
2. Enter your app name
3. Select the platforms you want to support (iOS, Android, or both)
4. Click **"Create"**

## 2. Configure Products

### Step 2.1: Create Products

1. Go to **Products** in the left sidebar
2. Click **"New Product"**
3. Choose product type:
   - **Consumable**: One-time purchases (like question packs)
   - **Non-Consumable**: Permanent purchases
   - **Subscription**: Recurring payments

### Step 2.2: Configure Product Details

For each product, set:

**Basic Info:**
- Product ID (must match store product IDs)
- Display name
- Description

**Pricing:**
- Price
- Currency

**Example Products for Language App:**
- `question_pack_25`: 25 questions - $0.99
- `question_pack_100`: 100 questions - $0.99
- `premium_subscription`: Monthly premium - $4.99

## 3. App Store Setup

### iOS Setup (App Store Connect)

#### Step 3.1: Create In-App Purchase Products

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Select your app
3. Go to **Features** → **In-App Purchases**
4. Click **"+"** to create new products

For each product:
1. Select type (Consumable, Non-Consumable, Auto-Renewable Subscription)
2. Enter Product ID (must match RevenueCat)
3. Enter details (name, description, pricing)
4. Set up screenshots and review details
5. Submit for review

#### Step 3.2: Connect RevenueCat to App Store

1. In RevenueCat → **App Settings** → **iOS**
2. Enter your:
   - Bundle ID
   - App Store Connect Shared Secret
   - App Store Connect Issuer ID
   - App Store Connect Private Key

### Android Setup (Google Play Console)

#### Step 3.3: Create In-App Products

1. Go to [Google Play Console](https://play.google.com/console/)
2. Select your app
3. Go to **Monetize** → **Products** → **In-app products**
4. Click **"Create product"**

For each product:
1. Enter Product ID (must match RevenueCat)
2. Set up pricing and details
3. Add translations
4. Publish the products

#### Step 3.4: Connect RevenueCat to Google Play

1. In RevenueCat → **App Settings** → **Android**
2. Enter your:
   - Package name
   - Service Account credentials (JSON file)

## 4. Get API Keys

### Step 4.1: Public API Keys

1. In RevenueCat → **API Keys**
2. Copy the **Public** API key for each platform:
   - iOS Public Key
   - Android Public Key

### Step 4.2: Update Environment Variables

Add to your `.env` file:

```bash
# RevenueCat API Keys
REVENUECAT_IOS_API_KEY=appl_your_ios_api_key_here
REVENUECAT_ANDROID_API_KEY=goog_your_android_api_key_here
```

## 5. Configure Entitlements

### Step 5.1: Create Entitlements

Entitlements define what users get with purchases:

1. Go to **Entitlements** in RevenueCat
2. Click **"New Entitlement"**
3. Examples:
   - `premium`: Premium features access
   - `questions`: Access to question packs

### Step 5.2: Link Products to Entitlements

1. Edit each product
2. Add entitlements that this product grants

## 6. Testing Purchases

### Step 6.1: Sandbox Testing (iOS)

1. Create sandbox tester accounts in App Store Connect
2. Test purchases won't be charged
3. Use these accounts to test in-app purchases

### Step 6.2: Internal Testing (Android)

1. Set up internal test track in Google Play Console
2. Add tester emails
3. Upload test APK and test purchases

### Step 6.3: RevenueCat Sandbox

RevenueCat provides sandbox mode for testing:

1. In RevenueCat → **App Settings** → **Sandbox**
2. Enable sandbox mode for testing

## 7. Integration Code

Your app is already configured to use RevenueCat. The main integration is in `lib/main.dart`:

```dart
// RevenueCat is initialized here with environment variables
await Purchases.configure(PurchasesConfiguration(apiKey));
```

### Checking Entitlements

```dart
// Example: Check if user has premium access
CustomerInfo customerInfo = await Purchases.getCustomerInfo();
bool hasPremium = customerInfo.entitlements.active.containsKey('premium');
```

### Making Purchases

```dart
// Example: Purchase a product
Purchases.purchaseProduct('question_pack_25');
```

### Restoring Purchases

```dart
// Restore purchases (important for iOS)
Purchases.restorePurchases();
```

## 8. Analytics & Webhooks

### Step 8.1: Set Up Webhooks

1. Go to **Integrations** in RevenueCat
2. Connect to your analytics service (Firebase, Mixpanel, etc.)
3. Set up webhooks for real-time purchase events

### Step 8.2: Monitor Revenue

1. Go to **Analytics** in RevenueCat dashboard
2. View revenue metrics, conversion rates, etc.
3. Set up alerts for important events

## 9. Going Live

### Before Launch

1. **Test thoroughly** in sandbox mode
2. **Update products** to production pricing
3. **Review store submissions** carefully
4. **Set up proper analytics** tracking

### Launch Checklist

- [ ] All products created in app stores
- [ ] Products approved by app stores
- [ ] API keys updated in production app
- [ ] Environment variables configured
- [ ] Testing completed on all platforms
- [ ] Analytics/webhooks configured
- [ ] Privacy policy updated for purchases

### After Launch

1. Monitor RevenueCat analytics
2. Watch for refund/dispute rates
3. Handle customer support issues
4. Optimize pricing based on data

## Troubleshooting

### Common Issues

**Purchases not working:**
- Check API keys are correct
- Verify products are approved in app stores
- Ensure bundle/package names match

**Sandbox purchases not appearing:**
- Check that sandbox mode is enabled
- Verify tester accounts are set up correctly

**Entitlements not granting:**
- Check product-to-entitlement mappings
- Verify purchase flow completes successfully

### Support

- [RevenueCat Documentation](https://docs.revenuecat.com/)
- [RevenueCat Community](https://community.revenuecat.com/)
- [Flutter Purchases Documentation](https://docs.revenuecat.com/docs/flutter)

## Next Steps

Once RevenueCat is configured, you can proceed to [Building for App Stores](./building-for-stores.md) to prepare your app for submission.
