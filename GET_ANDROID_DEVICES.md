# How to Get Android Devices for Flutter Development

## Method 1: Create Android Emulator (Recommended)

### Step 1: Open AVD Manager
```powershell
# Option A: From Android Studio
# Tools → AVD Manager

# Option B: Command Line
cd C:\Users\[YourUsername]\AppData\Local\Android\Sdk\emulator
emulator -list-avds
```

### Step 2: Create New Virtual Device
1. **Open Android Studio**
2. **Launch AVD Manager**: Tools → AVD Manager
3. **Click "Create Virtual Device"**
4. **Choose Device Category**:
   - **Phone**: Select "Pixel 6", "Nexus 5", or "Pixel 7"
   - **Tablet**: For tablet testing
   - **TV/Automotive/Wear**: For other platforms

### Step 3: Select System Image
1. **Choose API Level**:
   - **Recommended**: API 34 (Android 14.0)
   - **Also Good**: API 33 (Android 13.0)
2. **Download System Image**: Click "Download" if not already installed
3. **Select Image**: Choose the downloaded image

### Step 4: Configure AVD Settings
```
AVD Name: Pixel_6_API_34
Startup Orientation: Portrait
Camera: Enable both Front and Back
RAM: 2GB or 4GB (recommended 4GB)
VM Heap: 512MB
Internal Storage: 6GB (minimum)
SD Card: 1GB
```

### Step 5: Start Emulator
```powershell
# Option A: From Android Studio AVD Manager
# Click the "Play" button (▶️) next to your device

# Option B: Command Line
emulator -avd Pixel_6_API_34
```

## Method 2: Use Physical Android Device

### Step 1: Enable Developer Options
1. **Go to Settings** on your Android device
2. **About Phone** → Tap "Build Number" 7 times
3. **Developer Options** will appear in Settings menu

### Step 2: Enable USB Debugging
1. **Settings** → **Developer Options**
2. **Enable "USB Debugging"**
3. **Enable "Install via USB"** (if available)

### Step 3: Connect Device
1. **Connect via USB Cable**
2. **Allow USB Debugging** when prompted on device
3. **Trust the Computer** when prompted

### Step 4: Verify Connection
```powershell
adb devices
```
You should see your device listed (e.g., `HT7B1234567    device`)

## Quick Commands to Check Devices

### List All Devices
```powershell
flutter devices
```
Shows all connected Flutter-compatible devices

### List Android Devices Only
```powershell
adb devices
```
Shows all Android devices (includes non-Flutter devices)

### List Available Emulators
```powershell
emulator -list-avds
```

## Common Device Names and IDs

### Example Flutter Device Output:
```
2 connected devices:

Pixel_6_API_34 (mobile) • emulator-5554 • Android 14.0 (API 34)
GT-I9505 (mobile)       • HT7B1234567  • Android 9.0 (API 28)
Chrome (web)            • chrome       • Web Browser
Edge (web)              • edge         • Web Browser
```

### Example ADB Device Output:
```
List of devices attached
emulator-5554   device
HT7B1234567    device
```

## Running Commands by Device Type

### Run on Specific Emulator
```powershell
flutter run -d emulator-5554
```

### Run on Specific Physical Device
```powershell
flutter run -d HT7B1234567
```

### Run on Any Android Device
```powershell
flutter run -d android
```

## Troubleshooting Device Issues

### No Devices Found
```powershell
# Check if devices are actually connected
adb devices

# Check Flutter devices
flutter devices

# Restart ADB server
adb kill-server
adb start-server
```

### Emulator Won't Start
```powershell
# Check if Hyper-V is enabled (Windows)
# Enable in: Windows Features → Hyper-V

# Or enable Windows Hypervisor Platform
# Windows Features → Windows Hypervisor Platform
```

### Device Not Recognized
```powershell
# Update Android SDK platform-tools
sdkmanager --update "platform-tools"

# Or reinstall USB drivers
# Device Manager → Right-click device → Update driver
```

## Create Multiple Test Devices

### Test Different Screen Sizes
```
Device 1: Pixel 6 (1080x2400) - Standard
Device 2: Nexus 5 (1080x1920) - Compact
Device 3: Pixel 7 (1080x2400) - Large
Device 4: Nexus 7 Tablet (1200x1920) - Tablet
```

### Test Different API Levels
```
Device 1: API 34 (Android 14) - Latest
Device 2: API 30 (Android 11) - Common
Device 3: API 28 (Android 9.0) - Minimum
```

## Quick Device Setup Script

```powershell
# Create this as setup_devices.ps1
Write-Host "Creating Android Emulator..."

# List available AVDs
emulator -list-avds

# If no AVDs exist, guide user to create one
Write-Host "If no AVDs listed:"
Write-Host "1. Open Android Studio"
Write-Host "2. Tools → AVD Manager"
Write-Host "3. Create Virtual Device → Phone → Pixel 6 → API 34"
Write-Host "4. Click Finish"

# Check device connections
Write-Host "`nChecking connected devices..."
adb devices

Write-Host "`nFlutter devices:"
flutter devices
```

## Summary

**To get devices for Flutter development:**

1. **For Emulators**: Use Android Studio AVD Manager → Create Virtual Device → Start Emulator
2. **For Physical**: Enable Developer Options → USB Debugging → Connect via USB
3. **To List**: Run `flutter devices` or `adb devices`
4. **To Run**: Use `flutter run -d [device-id]` with the device ID from the list

**Most Common Command**: `flutter run -d emulator-5554` (for emulator)