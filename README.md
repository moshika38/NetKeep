# NetKeep

A Flutter-based network traffic monitoring application that helps you track and manage your device's network usage in real-time.

## Features

- 📊 **Real-time Traffic Monitoring** - Track network traffic statistics using native Android APIs
- 🔔 **Background Service** - Continuous monitoring even when the app is in the background
- 🎨 **Modern UI** - Clean, dark-themed interface built with Material Design
- 📱 **Android Support** - Optimized for Android devices
- 🛡️ **Permission Management** - Secure handling of required permissions
- 💾 **Local Storage** - Persistent settings using SharedPreferences
- 📈 **Ad Integration** - Google Mobile Ads support

## Project Structure

```
netkeep/
├── lib/
│   ├── main.dart              # App entry point
│   ├── presentation/          # UI screens and widgets
│   ├── services/              # Business logic and services
│   ├── utils/                 # Utilities and helpers
│   └── widgets/               # Reusable UI components
├── packages/
│   └── netkeep_traffic_stats/ # Native traffic stats plugin
├── pages/
│   ├── privacy/               # Privacy policy page
│   └── terms/                 # Terms of service page
├── assets/                    # App assets and icons
└── android/                   # Android platform configuration
```

## Prerequisites

- Flutter SDK >= 3.12.2
- Dart SDK >= 3.12.2
- Android Studio / VS Code with Flutter extensions
- Android device or emulator (API level 21+)

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/moshika38/NetKeep
   cd netkeep
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**
   
   Create a `.env` file in the root directory with your configuration:
   ```env
      ADMOB_APP_ID=
      ADMOB_BANNER_ID=
      ADMOB_INTERSTITIAL_ID=
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Dependencies

### Development
- `flutter_test` - Testing framework
- `flutter_lints` - Code analysis rules

## Building for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

## Permissions Required

The app requires the following Android permissions:
- `PACKAGE_USAGE_STATS` - To access network traffic statistics
- `FOREGROUND_SERVICE` - To run background monitoring service
- Other runtime permissions as needed
 
## License

This project is proprietary software. All rights reserved.

## Support

For issues and feature requests, please contact the development team.
