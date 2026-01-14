# Social Authentication Configuration Guide

Since your app uses Firebase, the easiest way to configure Social Login is through the **Firebase Console**.

## 1. Google Sign-In Setup

### A. Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/).
2. Select your project.
3. Navigate to **Authentication** > **Sign-in method**.
4. Click **Add new provider** > **Google**.
5. Toggle **Enable**.
6. Set the **Project support email**.
7. Click **Save**.

### B. Android Configuration
1. In Firebase Console, go to **Project Settings** (gear icon) > **General**.
2. Scroll to your **Android app**.
3. You must add your **SHA-1 fingerprint**.
   - Run this command in your project terminal to get the debug SHA-1:
     ```bash
     cd android
     ./gradlew signingReport
     ```
   - Copy the `SHA1` from the `debug` variant.
   - Paste it into the Firebase Console "Add fingerprint" field.
4. Download the updated `google-services.json`.
5. Replace the existing file at `mobile/android/app/google-services.json`.

### C. iOS Configuration
1. In Firebase Console, go to **Project Settings** > **General**.
2. Scroll to your **iOS app**.
3. Ensure your **Bundle ID** matches (`com.paykey.mobile` or similar).
4. Download the `GoogleService-Info.plist`.
5. Replace the existing file at `mobile/ios/Runner/GoogleService-Info.plist`.
   - **Important**: Open Xcode (`mobile/ios/Runner.xcworkspace`) and ensure the file is properly added to the "Runner" target.
6. Copy the `REVERSED_CLIENT_ID` from the `GoogleService-Info.plist`.
7. In Xcode:
   - Go to **Runner** (Project) > **Targets** > **Runner** > **Info** tab.
   - Expand **URL Types**.
   - Click `+`.
   - Paste the `REVERSED_CLIENT_ID` into the **URL Schemes** field.

---

## 2. Apple Sign-In Setup

### A. Apple Developer Portal
1. Go to [Apple Developer Account](https://developer.apple.com/account/).
2. Go to **Certificates, Identifiers & Profiles** > **Identifiers**.
3. Select your App ID.
4. Check **Sign In with Apple**.
5. Save.

### B. Xcode
1. Open `mobile/ios/Runner.xcworkspace`.
2. Select **Runner** target > **Signing & Capabilities**.
3. Click `+ Capability`.
4. Add **Sign In with Apple**.

### C. Firebase Console (Optional but recommended)
1. Go to **Authentication** > **Sign-in method**.
2. Enable **Apple**.
3. Leave configuration blank if only using it on iOS devices (Firebase handles it automatically via the SDK).

---

## 3. Backend Verification (Important)
For the backend to verify tokens:
1. We will need the **Client IDs** generated above.
2. Google: Look in `google-services.json` for `client_id` (under `oauth_client`).
3. Apple: Uses the Bundle ID.

*I will handle the backend implementation to dynamically verify these.*
