# App Store Testing Distribution

Guide for distributing AlPHA to testers via Google Play and Apple TestFlight without making the app publicly available.

## Google Play — Internal Testing

The fastest way to get the app on Android devices. Not visible on the Play Store.

### Prerequisites
- Google Play Developer account ($25 one-time fee) — [sign up](https://play.google.com/console/signup)
- Android SDK installed (see `docs/android-device-testing.md`)
- A signing key for release builds

### 1. Create a Signing Key

```bash
keytool -genkey -v \
  -keystore ~/alpha-release-key.jks \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -alias alpha
```

Store the keystore file and passwords securely. **Do not commit the keystore to git.**

### 2. Configure Signing in the Project

Create `android/key.properties` (gitignored):
```properties
storePassword=<your-password>
keyPassword=<your-password>
keyAlias=alpha
storeFile=/Users/<you>/alpha-release-key.jks
```

Update `android/app/build.gradle` to reference it (see [Flutter docs](https://docs.flutter.dev/deployment/android#sign-the-app)).

### 3. Build a Signed App Bundle

```bash
flutter build appbundle
# Output: build/app/outputs/bundle/release/app-release.aab
```

### 4. Upload to Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Create a new app (name, default language, app type)
3. Navigate to **Testing > Internal testing**
4. Create a new release, upload the `.aab` file
5. Under **Testers**, create an email list and add tester emails
6. Save and roll out the release

### 5. Testers Install

1. Testers receive an opt-in link (or you share the link from the Play Console)
2. They open the link on their Android device
3. They install via the Play Store (shows as an internal test)

### Limits
- Up to **100 testers** by email address
- No app review required
- Updates are available to testers within minutes of upload
- Testers must have a Google account matching the email you added

### Updating
```bash
# Bump version in pubspec.yaml, then:
flutter build appbundle
# Upload the new .aab to the Internal testing track in Play Console
```

---

## Apple — TestFlight

The standard way to distribute iOS/macOS test builds to testers.

### Prerequisites
- Apple Developer Program membership ($99/year) — [enroll](https://developer.apple.com/programs/enroll/)
- Xcode installed on macOS
- An App Store Connect app record

### 1. Configure Xcode Signing

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the Runner target > **Signing & Capabilities**
3. Set your Team (Apple Developer account)
4. Set a unique Bundle Identifier (e.g. `com.devdull.alpha`)

### 2. Build and Archive

```bash
flutter build ipa
# Output: build/ios/ipa/alpha.ipa
```

Or archive via Xcode: **Product > Archive**.

### 3. Upload to App Store Connect

**Option A — Command line:**
```bash
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/alpha.ipa \
  --apiKey <key-id> \
  --apiIssuer <issuer-id>
```

**Option B — Xcode Organizer:**
1. After archiving, click **Distribute App**
2. Choose **App Store Connect**
3. Upload

### 4. Set Up TestFlight

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app > **TestFlight** tab
3. The uploaded build appears after processing (5–15 minutes)

**Internal testers** (up to 100):
- Add via **App Store Connect Users** (must have an App Store Connect role)
- No Apple review required
- Builds available immediately after processing

**External testers** (up to 10,000):
- Create a test group, add testers by email
- Requires a light Apple review (usually < 24 hours for the first build)
- Subsequent builds to the same group often auto-approve

### 5. Testers Install

1. Testers receive an email invitation
2. They install the **TestFlight** app from the App Store
3. They accept the invitation and install AlPHA from TestFlight

### Limits
- Internal: **100 testers**, no review
- External: **10,000 testers**, light review
- Builds expire after **90 days**
- Each build must have a unique version+build number

### Updating
```bash
# Bump version in pubspec.yaml, then:
flutter build ipa
# Upload and the new build appears in TestFlight
```

---

## Comparison

| | Google Play Internal | Apple TestFlight (Internal) | Apple TestFlight (External) |
|---|---|---|---|
| **Cost** | $25 one-time | $99/year | $99/year |
| **Max testers** | 100 | 100 | 10,000 |
| **Review required** | No | No | Light review |
| **Install method** | Play Store link | TestFlight app | TestFlight app |
| **Update speed** | Minutes | Minutes | Minutes (after first review) |
| **Build expiry** | None | 90 days | 90 days |

---

## Quick Alternative: Direct APK Sideload (Android Only)

For testing on your own device without the Play Store:

```bash
flutter build apk
adb install build/app/outputs/flutter-apk/app-release.apk
```

Or share the `.apk` file directly (email, cloud storage, etc.). The recipient must enable "Install from unknown sources" on their device.

See `docs/android-device-testing.md` for full USB setup instructions.
