# Flutter Run Commands - Android

## Quick Answer: How to run `flutter run android`

### Step-by-Step Commands:

```powershell
# 1. Navigate to your Flutter project
cd d:\payKey\mobile

# 2. Check available devices
flutter devices

# 3. Run on Android device
flutter run -d android
```

## Detailed Commands:

### Option 1: Basic Run (Auto-detects Android device)
```powershell
cd d:\payKey\mobile
flutter run
```

### Option 2: Specify Android Target
```powershell
cd d:\payKey\mobile
flutter run -d android
```

### Option 3: Run on Specific Device ID
```powershell
flutter devices                    # List all devices first
flutter run -d [device-id]         # Use actual device ID
```

### Option 4: Run with Additional Options
```powershell
# Debug mode with hot reload (default)
flutter run -d android

# Release mode (faster, optimized)
flutter run -d android --release

# Profile mode
flutter run -d android --profile

# Production build
flutter run -d android --release --obfuscate --split-debug-info=build/debug-info/
```

## Prerequisites Commands:

### 1. Check Flutter Setup
```powershell
flutter doctor
```

### 2. Install Dependencies
```powershell
cd d:\payKey\mobile
flutter pub get
```

### 3. Accept Android Licenses
```powershell
flutter doctor --android-licenses
```

## Common Device Scenarios:

### Running on Android Emulator:
```powershell
# Start emulator first (from Android Studio AVD Manager)
# Then run:
flutter run -d emulator-5554
```

### Running on Physical Device:
```powershell
# Ensure USB debugging enabled on device
flutter run -d [device-serial-number]
```

### If No Devices Detected:
```powershell
# Check what's wrong
flutter doctor -v

# Or list all connected devices
adb devices
```

## Quick Commands Reference:

```powershell
# Navigate to project
cd d:\payKey\mobile

# Essential commands (run in order):
flutter doctor                    # Check setup
flutter devices                   # List devices
flutter pub get                   # Get dependencies  
flutter run -d android           # Run on Android
```

## Troubleshooting:

### "No connected devices" error:
1. Start Android emulator: Tools → AVD Manager → Play button
2. OR connect physical device with USB debugging enabled
3. Run `flutter devices` to verify connection

### "Android SDK not found" error:
```powershell
flutter doctor --android-licenses
```

### Build errors:
```powershell
flutter clean
flutter pub get
flutter run -d android
```

## Your Project Structure:
- **Flutter project location**: `d:\payKey\mobile`
- **Backend API**: Running on `d:\payKey\backend` (already active)
- **Dependencies**: Need to run `flutter pub get` in mobile directory

**The core command you need: `cd d:\payKey\mobile && flutter run -d android`**