# TestFlight Beta Testing Setup for PayKey iOS App

## Overview

TestFlight is Apple's official beta testing platform that allows you to distribute your app to up to 10,000 external testers before releasing on the App Store.

## Prerequisites

Before you can use TestFlight, you need:

1. ✅ Apple Developer Program membership ($99/year)
2. ✅ App Store Connect account set up
3. ✅ Completed iOS app configuration (done ✅)
4. ✅ Build uploaded to App Store Connect

## Steps to Set Up TestFlight

### 1. Build and Upload to App Store Connect

```bash
cd mobile

# Get dependencies
flutter pub get

# Build iOS release
flutter build ios --release

# Open Xcode to archive and upload
open ios/Runner.xcworkspace
```

In Xcode:
1. Select **Product** → **Archive**
2. After archiving, click **Distribute App**
3. Select **App Store Connect**
4. Upload to App Store Connect

### 2. Configure App in App Store Connect

1. Go to https://appstoreconnect.apple.com
2. Select your app "PayKey"
3. Navigate to **TestFlight** tab
4. Under **Builds**, you should see your uploaded build

### 3. Create Internal Testing Group

Internal testers are team members with App Store Connect access:

1. Go to **TestFlight** → **Internal Testing**
2. Click **+** next to Builds
3. Select your build
4. Enable the build for testing

### 4. Create External Testing Group

External testers can be anyone with an Apple ID:

1. Go to **TestFlight** → **External Testing**
2. Click **+** to create a new group
3. Add tester emails (up to 10,000 total)
4. Provide:
   - **Beta App Description**: What to test
   - **Feedback URL**: Where testers submit issues
   - **Privacy Policy URL**: Link to your privacy policy
5. Submit for Apple Beta Review (typically 1-2 days)

### 5. Required App Store Metadata

Before TestFlight works, complete these in App Store Connect:

| Field | Required |
|-------|----------|
| App Name | ✅ |
| App Description | ✅ |
| Keywords | ✅ |
| Support URL | ✅ |
| Privacy Policy URL | ✅ |
| App Icon (1024x1024) | ✅ |
| Screenshots | ✅ (at least one) |
| Build | ✅ (uploaded) |

### 6. Screenshots Required

Provide screenshots for:
- 6.5" Super Retina display (1284×2778 px)
- 5.5" display (1242×2208 px)

Include these in your App Store listing:
1. Home screen / Dashboard
2. Workers list
3. Payroll run
4. Payslip view
5. Settings

## Testing with TestFlight

### For Testers:
1. Install TestFlight app from App Store
2. Accept invitation via email or link
3. Install beta app
4. Test and provide feedback

### For Developers:
1. Monitor crash reports in App Store Connect
2. Collect tester feedback
3. Fix issues and upload new builds
4. Push updated builds to TestFlight

## Going from TestFlight to App Store

1. Complete all metadata in App Store Connect
2. Go to **Pricing and Availability**
3. Set release date and countries
4. Click **Submit for Review**
5. Apple review typically takes 24-48 hours
6. Once approved, release manually or automatically

## Timeline

| Phase | Duration |
|-------|----------|
| Build upload | 10-30 min |
| Apple processing | 1-2 hours |
| Internal testing | Immediate |
| External Beta Review | 1-2 business days |
| App Store Review | 24-48 hours |

## Total: 2-5 days from build to release
