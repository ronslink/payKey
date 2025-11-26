# Android Studio Setup Guide for Flutter Development

This guide will help you set up Android Studio for Flutter mobile development on your Windows 11 system.

## Prerequisites

Before starting, ensure you have:
- Windows 11 (which you already have)
- Administrative privileges on your machine
- Stable internet connection

## Step 1: Install Android Studio

### Download and Install
1. **Download Android Studio**
   - Go to [developer.android.com/studio](https://developer.android.com/studio)
   - Click "Download Android Studio"
   - Accept the license agreement
   - Download the installer for Windows

2. **Install Android Studio**
   - Run the downloaded installer (`android-studio-*-windows.exe`)
   - Follow the installation wizard
   - Choose "Standard" installation type (recommended)
   - Accept all default settings
   - Wait for installation to complete

### Initial Setup
1. **Launch Android Studio**
   - The first launch may take a few minutes
   - Android Studio will download additional components

2. **Complete Setup Wizard**
   - Choose "Standard" setup type
   - Select UI theme (Dark theme recommended for development)
   - Verify Android SDK components are installed
   - Click "Finish"

## Step 2: Install Flutter SDK

### Download Flutter
1. **Download Flutter SDK**
   - Go to [flutter.dev/docs/get-started/install/windows](https://flutter.dev/docs/get-started/install/windows)
   - Download the latest stable Flutter SDK
   - Extract to `C:\flutter` (recommended location)

2. **Add Flutter to PATH**
   - Open System Environment Variables
   - Add `C:\flutter\bin` to PATH variable
   - Click OK to save changes

3. **Verify Flutter Installation**
   ```powershell
   flutter doctor
   ```

## Step 3: Configure Android Studio for Flutter

### Install Flutter Plugin
1. **Open Android Studio**
2. **Go to Plugins**
   - File → Settings (Ctrl+Alt+S)
   - Navigate to "Plugins" tab
3. **Install Flutter Plugin**
   - Search for "Flutter" in marketplace
   - Click "Install" (will also install Dart plugin)
   - Restart Android Studio when prompted

### Install Additional Useful Plugins
- **Flutter Widget Snippets** - Provides useful code snippets
- **Awesome Flutter Snippets** - Additional development shortcuts
- **Dart** - Language support (usually auto-installed with Flutter)

## Step 4: Configure Android SDK

### SDK Setup
1. **Open SDK Manager**
   - Android Studio → Tools → SDK Manager
   - Or click SDK Manager icon in toolbar

2. **Install Required SDK Components**
   - **SDK Platforms**: Check "Android 14.0 (API 34)" (recommended)
   - **SDK Tools**: 
     - ✅ Android SDK Build-Tools
     - ✅ Android SDK Command-line Tools
     - ✅ Android Emulator
     - ✅ Android SDK Platform-Tools

3. **Accept Licenses and Install**
   - Click "Apply" to install selected components
   - Accept any license agreements
   - Wait for download and installation to complete

## Step 5: Set Up Android Emulator

### Create Virtual Device
1. **Open AVD Manager**
   - Android Studio → Tools → AVD Manager
   - Or click AVD Manager icon

2. **Create New Virtual Device**
   - Click "Create Virtual Device"
   - Choose a device (e.g., "Pixel 6" or "Nexus 5")
   - Select system image (API 34 recommended)
   - Name your emulator (e.g., "Pixel_6_API_34")

3. **Configure Emulator Settings**
   - **AVD Name**: Give it a descriptive name
   - **Startup Orientation**: Portrait (recommended for testing)
   - **Camera**: Enable both front and back cameras for testing

4. **Launch Emulator**
   - Click the "Play" button (▶️) next to your created device
   - Wait for emulator to boot up (first launch takes 5-10 minutes)

## Step 6: Connect Flutter with Android Studio

### Configure Flutter Doctor
Run the following command in PowerShell to check everything is properly configured:

```powershell
flutter doctor -v
```

This command will show you:
- ✅ Flutter installation status
- ✅ Android toolchain status
- ✅ Connected devices status
- ⚠️ Any missing dependencies

### Common Flutter Doctor Issues and Solutions

#### Issue: "Android license status unknown"
**Solution:**
```powershell
flutter doctor --android-licenses
```
Accept all license agreements when prompted.

#### Issue: "Android SDK not found"
**Solution:**
1. Set ANDROID_HOME environment variable:
   - Variable name: `ANDROID_HOME`
   - Variable value: `C:\Users\[YourUsername]\AppData\Local\Android\Sdk`
2. Add to PATH: `%ANDROID_HOME%\platform-tools`

## Step 7: Test Your Setup

### Create Test Flutter Project
1. **Open Android Studio**
2. **Create New Flutter Project**
   - File → New → New Flutter Project
   - Select "Flutter Application"
   - Name it "test_app"
   - Set Flutter SDK path: `C:\flutter`
   - Click "Finish"

3. **Run the App**
   - Select your created emulator from device dropdown
   - Click the "Run" button (green play icon)
   - Flutter app should compile and launch on emulator

### Verify Development Environment
1. **Test Hot Reload**
   - Make a small change in `main.dart`
   - Save the file (Ctrl+S)
   - App should update automatically

2. **Test Debugging**
   - Set breakpoints in your code
   - Start debugging (Shift+F9)
   - Verify debugging works properly

## Step 8: Optimize Android Studio for Flutter

### Configure Editor Settings
1. **Code Style**
   - File → Settings → Editor → Code Style
   - Enable auto-formatting on save
   - Configure Dart code style preferences

2. **Enable Useful Features**
   - **Code Analysis**: Enable real-time code analysis
   - **Auto-save**: Enable auto-save for better development experience
   - **Code Folding**: Enable for better code navigation

### Configure Performance
1. **Increase Memory Allocation**
   - Help → Change Memory Settings
   - Increase maximum heap size to 4GB or higher

2. **Enable Power Save Mode** (Optional)
   - File → Power Save Mode
   - Disables some features to conserve battery/performance

## Step 9: Connect Physical Android Device (Optional)

### Enable Developer Options
1. **Enable USB Debugging**
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
   - Developer Options will appear in Settings

2. **Enable USB Debugging**
   - Settings → Developer Options
   - Enable "USB Debugging"
   - Connect device via USB cable

3. **Verify Device Connection**
   ```powershell
   flutter devices
   ```
   Your connected device should appear in the list.

## Troubleshooting Common Issues

### Issue: Flutter Doctor Shows Warnings
- Run `flutter doctor --android-licenses` to fix license issues
- Ensure ANDROID_HOME environment variable is set correctly

### Issue: Emulator Won't Start
- Check if Hyper-V is enabled (required for Android emulator)
- Enable Virtualization in BIOS settings
- Allocate more RAM to emulator (4GB+ recommended)

### Issue: "flutter" Command Not Recognized
- Verify Flutter SDK is in PATH environment variable
- Restart command prompt/PowerShell after PATH changes
- Run `where flutter` to verify command location

### Issue: Build Errors
- Run `flutter clean` then `flutter pub get`
- Ensure Android SDK is properly installed
- Check for sufficient disk space (5GB+ required)

## Next Steps

After successful setup:
1. **Explore Your Flutter Project**: The existing mobile project in your workspace
2. **Learn Flutter Development**: Check Flutter documentation and tutorials
3. **Use Version Control**: Integrate with Git for your mobile development
4. **Set up CI/CD**: Consider setting up automated builds and testing

## Development Tips

### Useful Flutter Commands
```powershell
flutter pub get          # Get dependencies
flutter clean            # Clean build cache
flutter run -d chrome    # Run in Chrome browser
flutter build apk        # Build Android APK
flutter build appbundle  # Build Android App Bundle
```

### Android Studio Shortcuts
- **Ctrl+Shift+P**: Command palette
- **Ctrl+/**: Comment/uncomment line
- **Ctrl+D**: Duplicate line
- **Ctrl+Shift+F**: Find in files
- **Ctrl+Shift+R**: Replace in files

## Support Resources

- [Flutter Official Documentation](https://flutter.dev/docs)
- [Android Studio User Guide](https://developer.android.com/studio/intro)
- [Flutter Doctor Documentation](https://flutter.dev/docs/get-started/install/windows#run-flutter-doctor)
- [Flutter Community](https://flutter.dev/community)

---

**Setup Complete!** You now have a fully configured Android Studio environment for Flutter development. Run `flutter doctor` to verify everything is working correctly and start building amazing mobile applications!