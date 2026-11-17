# Expense Tracker App — Flutter + SQLite

An offline-first personal finance mobile app for the BBS-UTech Mobile App Development semester project. Default currency: PKR. UI theme: light blue and white.

## Included
- Flutter/Dart application source (`lib/`)
- SQLite database service (`sqflite`)
- Transaction model
- Splash screen and dashboard
- Add, list, edit and delete transactions
- Income/expense filtering and category selection
- Analytics and financial charts (`fl_chart`)
- Calendar view, search/reports, settings/profile

## Requirements
- Install the Flutter SDK (stable) and Android Studio / Android SDK.
- Install the Flutter and Dart extensions in VS Code. Extensions alone are not the Flutter SDK.

## First-time setup
1. Extract this ZIP.
2. Open the `expense_tracker_app` folder in VS Code.
3. Open Terminal in that folder and run:

   ```bash
   flutter doctor
   flutter create --platforms=android .
   flutter pub get
   flutter analyze
   flutter run
   ```

4. Select an Android emulator or connect an Android phone with USB debugging enabled.

## Build an APK
After the app launches successfully, run:

```bash
flutter build apk --release
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`.

## Important project notes
- Records are stored locally on the device in SQLite; no internet connection is required for core features.
- This is a single-device project; login, cloud sync, bank integration and automatic backup are not included.
- Categories are currently provided as built-in defaults. The category management screen is basic; persistent custom-category CRUD is not yet implemented.
- The source package was not compiled or device-tested in the preparation environment because the Flutter SDK is unavailable there. Run `flutter analyze` and test all screens/CRUD on your Android device before academic submission.
