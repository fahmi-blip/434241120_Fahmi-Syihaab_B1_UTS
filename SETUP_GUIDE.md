# 🔧 Flutter Project - Setup & Running Guide

## ✅ ERROR FIXES APPLIED

### Issue 1: Java Version Incompatibility ✓ FIXED
**Problem**: Java 25.0.2 not fully supported by Gradle 8.14
**Solution**: Use Java 24.0.1

### Issue 2: Gradle Configuration ✓ FIXED  
**Changes made**:
- Updated `android/gradle.properties` with native access flags
- Removed deprecated `android.enableBuildCache`
- Fixed NDK version to 27.0.12077973 in `android/app/build.gradle.kts`

---

## 📱 HOW TO RUN THE APP

### Option 1: Using Script (Easiest)
```powershell
# Run this first (from project root)
.\set_java_env.ps1

# Then run flutter
flutter run
```

### Option 2: Manual Java Setup
```powershell
$env:JAVA_HOME = "C:\Program Files\Java\jdk-24"
flutter run
```

### Option 3: Using Emulator
```powershell
# Set Java first
$env:JAVA_HOME = "C:\Program Files\Java\jdk-24"

# List available emulators
flutter emulators

# Launch emulator and run app
flutter run -d emulator-5554
```

---

## 🔌 WIRELESS CONNECTION (Phone)

### Prerequisites
✓ Phone connected via USB (already verified: TOAY4D65MV59ZHRS)
✓ USB Debugging enabled (Settings > Developer Options)
✓ Phone & PC on same WiFi network

### Steps:

**Step 1: Enable Wireless ADB**
```powershell
# Set Java first
$env:JAVA_HOME = "C:\Program Files\Java\jdk-24"

# Connect via USB
adb devices

# Enable TCP/IP mode
adb tcpip 5555

# Disconnect USB cable
```

**Step 2: Connect via WiFi**
```powershell
# Find phone IP address
adb shell ip addr show wlan0

# Connect (replace <IP> with actual IP)
adb connect <IP>:5555

# Example:
# adb connect 192.168.1.100:5555

# Verify connection
adb devices
```

**Step 3: Run Flutter
```powershell
flutter run
```

---

## 🐛 TROUBLESHOOTING

### If gradle still fails:
```bash
# Clean everything
flutter clean
cd android
./gradlew clean
cd ..

# Run again with verbose
flutter run -v
```

### If wireless connection drops:
```bash
# Reconnect
adb connect <IP>:5555

# Or go back to USB
adb usb
```

### If ADB not recognized:
```powershell
# Restart adb service
adb kill-server
adb start-server
adb devices
```

---

## 📋 CONFIGURED PATHS

| Item | Path |
|------|------|
| Flutter SDK | `C:\Users\ACER\develop\flutter` |
| Android SDK | `C:\Android\sdk` |
| Java (for build) | `C:\Program Files\Java\jdk-24` ✓ |
| NDK | `27.0.12077973` ✓ |
| Phone Connected | TOAY4D65MV59ZHRS (Oppo) ✓ |

---

## 📝 CHANGES MADE TO PROJECT

### Files Modified:
1. **android/gradle.properties** - Added JVM args for Java 24 compatibility
2. **android/app/build.gradle.kts** - Set NDK version to 27.0.12077973
3. **android/local.properties** - Fixed NDK path
4. **set_java_env.ps1** - Script to set Java environment

---

**Last Updated**: May 23, 2026
**Status**: ✓ Ready to run
