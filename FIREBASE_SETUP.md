# Firebase Go-Live Setup

This project is already wired for `firebase_core`, `firebase_auth`, and `cloud_firestore`.

## What is already done

- Firebase packages are installed in `pubspec.yaml`
- Android Google Services Gradle plugin is enabled
- Placeholder Firebase options exist in `lib/firebase_options.dart`

## What you must do next

### 1. Create your Firebase project

In Firebase Console:

1. Create or open your Firebase project
2. Enable:
   - Authentication
   - Cloud Firestore

### 2. Register your app platforms

Use these current platform identifiers unless you plan to change them:

- Android package name: `com.example.feesify`
- iOS bundle ID: `com.example.feesify`

If you want different identifiers, change them in the native project first, then download matching Firebase config files.

### 3. Add Android Firebase config

Download `google-services.json` from Firebase Console and place it here:

- `android/app/google-services.json`

### 4. Add iOS Firebase config

Download `GoogleService-Info.plist` from Firebase Console and place it here:

- `ios/Runner/GoogleService-Info.plist`

Then open `ios/Runner.xcodeproj` or `ios/Runner.xcworkspace` in Xcode and make sure the plist is added to the `Runner` target.

### 5. Replace placeholder Firebase options

Update these placeholder values in:

- `lib/firebase_options.dart`

Replace:

- `apiKey`
- `appId`
- `messagingSenderId`
- `projectId`
- `authDomain` for web
- `storageBucket`
- `iosBundleId` if needed

You can either:

- copy values manually from Firebase Console, or
- regenerate this file using FlutterFire CLI if you use that workflow later

### 6. Firestore Rules

Paste the contents of:

- `firestore.rules`

into:

- Firebase Console
- `Build` > `Firestore Database` > `Rules`

Then click `Publish`.

### 7. Enable Firebase Authentication methods

In Firebase Console:

- go to `Authentication` > `Sign-in method`
- enable `Email/Password`

### 8. Create Firestore database

In Firebase Console:

- go to `Firestore Database`
- create the database
- start in production mode if you are using the provided rules

## Recommended verification

After adding the real config:

1. Run `flutter pub get`
2. Run `flutter analyze`
3. Run the app
4. Test:
   - principal registration
   - admin login
   - school approval
   - bursar creation
   - payment entry
   - reports export

## Important reminder

This project will not connect to live Firebase until:

- `lib/firebase_options.dart` is updated with real values
- `android/app/google-services.json` is added
- `ios/Runner/GoogleService-Info.plist` is added
