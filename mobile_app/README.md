# jPrime Conference Companion App

A Flutter mobile app for the jPrime conference — schedule, venue map, QR scanner, notifications, and more.

## Prerequisites

- **Flutter SDK** `>=3.11.3` — [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Firebase project** configured (google-services.json / GoogleService-Info.plist already included)

### Android / Windows

| Tool | Version |
|------|---------|
| Android Studio | Latest stable |
| Android SDK | API 34+ |
| Java JDK | 17 |

### macOS / iOS

| Tool | Version |
|------|---------|
| Xcode | 15+ |
| CocoaPods | Latest (`sudo gem install cocoapods`) |
| iOS deployment target | 16.0 |

## Getting Started

```bash
# 1. Clone the repo
git clone https://github.com/Zenlingo/jprime_hackathon.git
cd jprime_hackathon/mobile_app

# 2. Install dependencies
flutter pub get

# 3. Verify your environment
flutter doctor
```

## Running the App

### Android

```bash
# List available devices/emulators
flutter devices

# Run on a connected Android device or emulator
flutter run
```

Or open the project in **Android Studio**, select a device, and press **Run**.

### iOS (macOS only)

```bash
# Install iOS dependencies
cd ios && pod install && cd ..

# Run on a connected iPhone or simulator
flutter run
```

Or open `ios/Runner.xcworkspace` in **Xcode**, select a simulator/device, and press **Run**.

### Windows

```bash
flutter run -d windows
```

### macOS

```bash
flutter run -d macos
```

## Building Release Versions

### Android APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS (requires Apple Developer account)

```bash
flutter build ipa --release
# Output: build/ios/ipa/*.ipa
```

## Project Structure

```
lib/           → Dart source code
assets/        → Images and venue assets
android/       → Android platform project
ios/           → iOS platform project
tool/          → Helper scripts
```

## Troubleshooting

- **`flutter doctor` shows issues** — follow the suggested fixes for your platform.
- **iOS pod errors** — run `cd ios && pod install --repo-update && cd ..`
- **Android build fails** — ensure `JAVA_HOME` points to JDK 17 and Android SDK is up to date.
- **Firebase errors** — verify `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` exist.
