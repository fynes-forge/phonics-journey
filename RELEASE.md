# Release Guide — Phonics Journey

This document covers everything needed to produce signed, production-ready
builds for Android and iOS, including keystore management, CI/CD secrets,
and store submission checklists.

---

## Table of Contents

- [Android Release](#android-release)
  - [Creating a Keystore](#creating-a-keystore)
  - [Storing Keystore Safely](#storing-keystore-safely)
  - [key.properties](#keyproperties)
  - [Building the Release APK/AAB](#building-the-release-apkaab)
  - [CI/CD Secrets](#cicd-secrets)
- [iOS Release](#ios-release)
  - [Prerequisites](#prerequisites-ios)
  - [Certificates & Provisioning Profiles](#certificates--provisioning-profiles)
  - [Building for App Store](#building-for-app-store)
- [Versioning](#versioning)
- [Play Store Checklist](#play-store-checklist)
- [App Store Checklist](#app-store-checklist)
- [Emergency: Key Rotation](#emergency-key-rotation)

---

## Android Release

### Creating a Keystore

Run this **once** and store the output permanently:

```bash
keytool -genkey -v \
  -keystore phonics-journey.jks \
  -alias phonics-journey \
  -keyalg RSA \
  -keysize 4096 \
  -validity 10000 \
  -storetype JKS
```

You will be prompted for:
- **Store password** — use a strong, unique password (≥ 20 chars)
- **Key password** — can be same as store password, or different
- **Distinguished name fields** — name, organisation, location, country

> ⚠️ **CRITICAL**: If you lose the keystore or its passwords, you **cannot**
> update your app on the Play Store. Google cannot help you recover it.
> The only option is to publish under a new package name.

### Storing Keystore Safely

**Never commit the keystore to version control.**

```bash
# Ensure .gitignore blocks all keystore files
echo "*.jks" >> .gitignore
echo "*.keystore" >> .gitignore
echo "android/key.properties" >> .gitignore
```

Recommended storage strategy:
1. **Primary copy** — encrypted password manager (1Password, Bitwarden, etc.)
   Store the `.jks` file as a secure note/attachment.
2. **Backup copy** — encrypted external drive stored off-site.
3. **Base64 copy** — for CI/CD (see below).

To create a Base64 string for CI:
```bash
base64 -i phonics-journey.jks | pbcopy   # macOS
base64 -w 0 phonics-journey.jks          # Linux
```

### key.properties

Create `android/key.properties` (this file must NOT be committed):

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=phonics-journey
storeFile=phonics-journey.jks
```

The `android/app/build.gradle` reads this file automatically.

### Building the Release APK/AAB

```bash
# Ensure key.properties is in place (android/key.properties)
# Ensure keystore file is at android/app/phonics-journey.jks

# Build release APK (sideloading / direct distribution)
flutter build apk --release

# Build App Bundle (Google Play Store)
flutter build appbundle --release

# Output locations:
# APK: build/app/outputs/flutter-apk/app-release.apk
# AAB: build/app/outputs/bundle/release/app-release.aab
```

### CI/CD Secrets

Add these secrets in GitHub → Settings → Secrets and Variables → Actions:

| Secret Name | Value |
|-------------|-------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded `.jks` file |
| `ANDROID_KEY_ALIAS` | `phonics-journey` |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_STORE_PASSWORD` | Store password |

The CI workflow (`main.yml`) decodes the keystore on-the-fly and deletes
it immediately after the build. It never persists between runs.

```yaml
# How the CI uses the secrets (already in main.yml):
- name: Decode keystore
  run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 --decode > android/app/phonics-journey.jks

- name: Clean up (always runs)
  if: always()
  run: rm -f android/app/phonics-journey.jks android/key.properties
```

---

## iOS Release

### Prerequisites (iOS)

- Mac running macOS 13+
- Xcode 15+
- Apple Developer account ($99/year)
- App ID registered at [developer.apple.com](https://developer.apple.com)

### Certificates & Provisioning Profiles

1. **Create an App ID** in the Apple Developer portal:
   - Bundle ID: `com.yourname.phonicsjourney`
   - Enable: No special capabilities needed (offline app)

2. **Create a Distribution Certificate**:
   ```bash
   # In Xcode: Preferences → Accounts → Manage Certificates → +
   # Select: Apple Distribution
   ```

3. **Create a Provisioning Profile**:
   - Type: App Store Distribution
   - App ID: `com.yourname.phonicsjourney`
   - Certificate: the one you just created
   - Download and double-click to install

4. **Update `ios/Runner.xcodeproj`**:
   Open in Xcode, select Runner target → Signing & Capabilities:
   - Team: your team
   - Bundle Identifier: `com.yourname.phonicsjourney`
   - Provisioning Profile: your App Store profile

### Building for App Store

```bash
# Build iOS release
flutter build ios --release

# Open in Xcode for archiving
open ios/Runner.xcworkspace

# In Xcode:
# Product → Archive → Distribute App → App Store Connect → Upload
```

Or with Fastlane (recommended for CI):
```bash
gem install fastlane
cd ios
fastlane init
fastlane deliver
```

### iOS Privacy Manifest

Since iOS 17, a `PrivacyInfo.xcprivacy` file is required. Create it at
`ios/Runner/PrivacyInfo.xcprivacy`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrivacyCollectedDataTypes</key>
  <array/>
  <!-- No data collected — fully offline app -->
  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array>
        <string>C617.1</string>
      </array>
    </dict>
  </array>
  <key>NSPrivacyTracking</key>
  <false/>
</dict>
</plist>
```

---

## Versioning

Version numbers follow `MAJOR.MINOR.PATCH`:
- `MAJOR` — breaking changes to data format (requires migration)
- `MINOR` — new levels, features, or design changes
- `PATCH` — bug fixes, audio improvements

Update in `pubspec.yaml`:
```yaml
version: 1.2.0+5   # versionName+versionCode
```

The build number (`+5`) must be incremented for every Play Store / App Store
upload, even for the same version name.

```bash
# Quick version bump script
flutter pub run cider bump patch     # requires 'cider' package
```

---

## Play Store Checklist

Before submitting to Google Play:

- [ ] `applicationId` is correct in `android/app/build.gradle`
- [ ] `versionCode` is incremented from the last upload
- [ ] Release APK/AAB is signed with the release keystore
- [ ] App icon: `ic_launcher` at all densities (use Flutter Launcher Icons)
- [ ] Feature graphic: 1024×500 px
- [ ] Screenshots: phone (min 2), tablet optional
- [ ] Short description: ≤ 80 chars
- [ ] Full description: ≤ 4000 chars — mention offline/privacy focus
- [ ] Content rating: complete IARC questionnaire (Parental Guidance / 3+)
- [ ] Privacy policy URL (required — even for offline apps)
  - Use a simple GitHub Pages or Google Sites page
  - State clearly: no data collected, offline only
- [ ] Target audience: Children → must comply with Families Policy
  - No ads ✅ (already none)
  - No data collection ✅ (already none)
  - No external links without parental gate ✅

---

## App Store Checklist

Before submitting to Apple App Store:

- [ ] Bundle ID matches provisioning profile
- [ ] Build number incremented
- [ ] App icons: all required sizes (use Flutter Launcher Icons)
- [ ] Screenshots for 6.5" and 5.5" iPhone sizes (minimum)
- [ ] Privacy policy URL
- [ ] Age Rating: 4+ (no objectionable content)
- [ ] `NSMicrophoneUsageDescription` in `Info.plist`:
  ```xml
  <key>NSMicrophoneUsageDescription</key>
  <string>Used by parents to record custom phoneme sounds for their child.</string>
  ```
- [ ] `PrivacyInfo.xcprivacy` present (see above)
- [ ] Review notes: explain the parental gate and offline-only design

---

## Emergency: Key Rotation

**Android:** You cannot rotate the Play Store signing key on your own.
Google Play App Signing can be enrolled to let Google re-sign your app,
which provides some protection. Enroll when first uploading:
Play Console → Setup → App signing → Opt in.

**iOS:** Apple certificates can be revoked and re-created. A new distribution
certificate requires a new provisioning profile but does not affect your App Store listing.

**If keystore is lost:**
1. You cannot update the existing app on the Play Store.
2. Publish a new app with a new `applicationId`.
3. Provide a migration guide for existing users.
4. Consider enrolling in Google Play App Signing next time to avoid this.

---

## Lottie / Asset Licensing

Before release, verify all assets are appropriately licensed:

- **Andika font**: SIL Open Font Licence 1.1 — ✅ free for commercial use
- **Lottie animations**: Check the specific LottieFiles licence
  (many are free but attribution may be required)
- **SFX**: Ensure all audio is licensed for commercial distribution
  (Freesound.org, Zapsplat, etc. — check per-asset licence)
- **Custom recorded audio**: Parental recordings are user-generated, no licence needed
