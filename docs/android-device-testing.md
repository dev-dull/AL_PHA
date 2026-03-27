# Testing on Android (Pixel 8 Pro)

Quick reference for deploying AlPHA to a physical Pixel 8 Pro over USB.

## One-Time Setup

### 1. Install Android SDK

The Android SDK is required to build and deploy to Android devices.

**Option A — Android Studio (recommended):**
```bash
# Download from https://developer.android.com/studio
# On first launch, it installs the Android SDK automatically.
# Default SDK location: ~/Library/Android/sdk
```

**Option B — Command-line only:**
```bash
brew install --cask android-commandlinetools
# Then install SDK components:
sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.1"
```

After installation, tell Flutter where the SDK is:
```bash
flutter config --android-sdk ~/Library/Android/sdk
# Accept licenses:
flutter doctor --android-licenses
```

### 2. Install ADB (Android Debug Bridge)

If you used Android Studio, ADB is included. Otherwise:
```bash
brew install android-platform-tools
```

Verify:
```bash
adb version
```

### 3. Enable Developer Options on the Pixel 8 Pro

1. Open **Settings > About phone**
2. Tap **Build number** 7 times (you'll see a toast counting down)
3. Go back to **Settings > System > Developer options**
4. Enable **USB debugging**

### 4. Java 17

Required for Android builds:
```bash
brew install openjdk@17
# Add to PATH if needed:
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
```

## Connecting the Device

1. Connect the Pixel 8 Pro to the Mac via **USB-C cable**
2. On the phone, tap **Allow USB debugging** when prompted (check "Always allow from this computer")
3. Verify the connection:

```bash
adb devices
# Should show something like:
# 28291FDH300XXX  device
```

4. Verify Flutter sees it:

```bash
flutter devices
# Should list "Pixel 8 Pro" as a connected device
```

## Building and Running

### Debug build (hot reload enabled):
```bash
flutter run -d <device-id>
# or just:
flutter run
# Flutter will prompt you to select a device if multiple are connected
```

### Release build (for realistic performance testing):
```bash
flutter run --release -d <device-id>
```

### Build APK without installing:
```bash
flutter build apk
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Install APK manually:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Wireless Debugging (no cable)

After the first USB connection, you can switch to wireless:

1. Connect via USB first
2. Enable wireless debugging:
```bash
adb tcpip 5555
```
3. Find the phone's IP (Settings > Network & internet > Wi-Fi > connected network > IP address)
4. Connect wirelessly:
```bash
adb connect <phone-ip>:5555
```
5. Unplug the USB cable — `flutter devices` should still show the phone

To go back to USB mode:
```bash
adb usb
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `flutter devices` shows no Android device | Run `adb devices` to check USB connection. Re-plug cable and re-approve USB debugging. |
| `Unable to locate Android SDK` | Run `flutter config --android-sdk <path>` |
| License errors | Run `flutter doctor --android-licenses` and accept all |
| Build fails with Java errors | Ensure Java 17 is installed and `JAVA_HOME` is set |
| `adb: command not found` | `brew install android-platform-tools` |
| Device shows as "unauthorized" | Re-approve USB debugging on the phone |
| Slow first build | Normal — Gradle downloads dependencies on first Android build. Subsequent builds are faster. |

## Quick Reference

```bash
# Check everything is working:
flutter doctor

# List devices:
flutter devices

# Run on phone:
flutter run -d <device-id>

# Build APK:
flutter build apk

# View device logs:
flutter logs -d <device-id>
```
