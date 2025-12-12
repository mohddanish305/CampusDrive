# CampusDrive Setup Guide

## 1. Firebase Setup (Authentication)
1. Go to [Firebase Console](https://console.firebase.google.com/).
2. Create a new project named "CampusDrive".
3. Add an Android app with package name `com.example.campusdrive` (or check `android/app/build.gradle`).
4. Download `google-services.json` and place it in `android/app/`.
5. Enable **Authentication** in Firebase Console:
   - Enable **Email/Password**.
   - Enable **Google Sign-In**.
6. For Google Sign-In, you must add your SHA-1 fingerprint to Firebase Project Settings (run `cd android && ./gradlew signingReport` to find it).

## 2. Supabase Setup (Cloud Sync)
1. Go to [Supabase](https://supabase.com/).
2. Create a new project.
3. Go to **Storage** and create a bucket named `documents`.
4. Set RLS policies for `documents`:
   - Allow ALL operations for authenticated users (or public for testing).
5. Get your **URL** and **Anon Key** from Project Settings > API.
6. Update `lib/main.dart` (uncomment Supabase init) or `lib/services/supabase_service.dart` with these keys.

## 3. Local Storage
- The app uses `path_provider` to store files in the app's document directory.
- Metadata is stored in a local SQLite database (`campusdrive.db`).

## 4. Running the App
1. Ensure `google-services.json` is in place.
2. Run `flutter pub get`.
3. Run `flutter run`.

## 5. Troubleshooting
- **Build Failures**: Ensure your Flutter SDK is up to date (`flutter upgrade`).
- **Auth Errors**: Check if `google-services.json` is correct and SHA-1 is added for Google Sign-In.
- **Sync Errors**: Check Supabase RLS policies and ensure keys are correct.
