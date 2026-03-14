# Child Connect

Child Connect is a Flutter-based adoption awareness and support platform designed to connect children, families, mentors, and support services in one mobile-first experience.

The project focuses on making child support and adoption workflows more structured, accessible, and user-friendly through a clean app experience and secure backend integration.

## Features

- User authentication flow with session handling
- Child discovery and profile cards
- Adoption guidance and adoption form flow
- Mentor support and mentor chat screens
- Contact and mission screens
- Programs and resources listing
- In-app chatbot assistance
- Cross-platform Flutter app (Android, iOS, Web support structure present)
- Branded launcher icon support for Android and iOS

## Tech Stack

- Flutter (Dart)
- Supabase (`supabase_flutter`)
- Environment config via `flutter_dotenv`
- Shared local state with `shared_preferences`
- Networking with `http`
- Media picking with `image_picker`
- External links with `url_launcher`
- Typography with `google_fonts`

## Project Structure

Main folders:

- `lib/`
	- `main.dart` - App entry point
	- `screens/` - UI screens and flows
	- `services/` - Business logic and integrations
	- `utils/` - Theme, app constants, shared helpers
	- `widgets/` - Reusable UI components
- `test/` - Widget and unit tests
- `android/` - Android native project
- `ios/` - iOS native project
- `web/` - Web host files
- `sql/` - SQL scripts (Supabase setup)
- `Assets/` - Project media assets and logo

## Prerequisites

Before running locally, ensure you have:

- Flutter SDK installed and added to PATH
- Dart SDK (bundled with Flutter)
- Android Studio / Xcode (for mobile builds)
- A configured Supabase project

## Environment Variables

Create a `.env` file in the project root with:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

The app loads these values during startup and will fail fast if they are missing.

## Getting Started

1. Install dependencies:

```bash
flutter pub get
```

2. Run the app:

```bash
flutter run
```

## Quality Checks

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Create debug APK:

```bash
flutter build apk --debug
```

## Build Commands

Android release build:

```bash
flutter build apk --release
```

iOS release build (macOS only):

```bash
flutter build ios --release
```

## Launcher Icon

Launcher icons are configured via `flutter_launcher_icons` in `pubspec.yaml`.

To regenerate icons:

```bash
dart run flutter_launcher_icons
```

Current configured source image:

- `Assets/logo.jpeg`

## Backend Setup Notes

- Supabase is required for auth and backend data operations.
- SQL setup script is available in `sql/supabase_free_tier_setup.sql`.

## Version

Current app version from `pubspec.yaml`:

- `2.0.0+1`

## License

This project is distributed under the license defined in the root `LICENSE` file.
