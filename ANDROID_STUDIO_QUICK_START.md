# Android Studio Setup - Quick Start Checklist

## Immediate Actions (Next 30 minutes)

### ✅ Step 1: Download and Install (10-15 minutes)
- [ ] Download Android Studio from https://developer.android.com/studio
- [ ] Run installer with default settings
- [ ] Complete initial setup wizard

### ✅ Step 2: Install Flutter SDK (5 minutes)
- [ ] Download Flutter SDK from https://flutter.dev/docs/get-started/install/windows
- [ ] Extract to `C:\flutter`
- [ ] Add `C:\flutter\bin` to PATH environment variable
- [ ] Restart terminal and verify: `flutter --version`

### ✅ Step 3: Configure Android Studio (10 minutes)
- [ ] Launch Android Studio
- [ ] Install Flutter plugin (File → Settings → Plugins → search "Flutter")
- [ ] Restart Android Studio when prompted
- [ ] Complete SDK setup through Android Studio's setup wizard

### ✅ Step 4: Verify Setup (2 minutes)
Open PowerShell and run:
```powershell
flutter doctor
```
Fix any warnings by following the suggestions in the output.

## For Your Existing Flutter Project

Since you have a Flutter project in `mobile/`, here's how to open it:

### Option 1: Open in Android Studio
1. Launch Android Studio
2. File → Open → Select `d:\payKey\mobile` folder
3. Android Studio will automatically detect it's a Flutter project
4. Click "Get dependencies" when prompted

### Option 2: Command Line
```powershell
cd d:\payKey\mobile
flutter pub get
flutter run
```

## Current Project Status
I can see you have:
- ✅ Flutter mobile project in `mobile/` directory
- ✅ Backend API in `backend/` directory (currently running)
- ⚠️ Some Flutter analysis issues mentioned in your markdown files

## Next Steps After Setup
1. **Test the Setup**: Run `flutter doctor` to ensure everything is working
2. **Open Your Project**: Load the `mobile` folder in Android Studio
3. **Fix Analysis Issues**: Use the Flutter analysis tools to resolve any linting issues
4. **Connect Device**: Either use Android emulator or connect physical device for testing

## Quick Commands Reference
```powershell
flutter doctor          # Check setup status
flutter pub get         # Get dependencies
flutter clean           # Clean build cache
flutter run            # Run app on connected device
flutter analyze        # Check code quality
```

**Ready to start? Follow the checklist above and you'll have Android Studio running with your Flutter project in under 30 minutes!**