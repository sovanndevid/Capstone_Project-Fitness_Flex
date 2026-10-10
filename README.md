# FitnessFlex

**Flutter capstone application · mobile fitness experience**

FitnessFlex is a university capstone project exploring fitness-oriented mobile experiences through Flutter. The repository contains a multi-screen application, workout-related interfaces, navigation, Firebase initialisation and supporting application layers.

> **Project status:** Academic project. The repository is provided as a code portfolio; do not assume that every dependency or experimental feature is production-ready.

## Tech stack

- **Client:** Flutter / Dart
- **Application structure:** `lib/core`, `lib/data`, `lib/features`, `lib/navigation`, `lib/screens`, `lib/widgets`
- **Firebase services:** Firebase Core, Authentication and Cloud Firestore appear in `pubspec.yaml`; application start-up handles Firebase initialisation and optional anonymous sign-in
- **Additional dependencies:** Provider, Shared Preferences, image picking, charts, camera and ML Kit pose detection are configured in `pubspec.yaml` (presence does not establish feature completeness)

## Inspect the project

| Area | Location |
| --- | --- |
| Flutter app | `fitness_flex_app/` |
| Application entry point | `fitness_flex_app/lib/main.dart` |
| Navigation configuration | `fitness_flex_app/lib/navigation/` |
| Screens | `fitness_flex_app/lib/screens/` |
| Packages and assets | `fitness_flex_app/pubspec.yaml` |

## Local setup

1. Install the Flutter SDK with a compatible Dart version and configure a simulator or device.
2. Open `fitness_flex_app/` in the terminal.
3. Run `flutter pub get`.
4. Review `lib/firebase_options.dart` and configure your **own** Firebase project for relevant services. Firebase Authentication settings and any required Firestore rules must match your testing environment.
5. Run `flutter run` on a supported simulator or device.

Build setup may require platform-specific SDKs, permissions and additional configuration. These steps describe a starting point and have not been verified end-to-end on this machine.

## Development approach

The entry point initialises Firebase before launching the application and uses a central router to select the initial page and generate routes. The project uses Flutter widgets to build screens and shared UI components.

## Contributors and scope

FitnessFlex was developed as a **university group capstone**. Public descriptions should avoid assigning individual features to one developer without the agreed contribution record. Please open an issue if the repository needs additional attribution, screenshots or reproducible setup details.

## Portfolio

[Read the project case study](https://sovanndevid.xyz/projects/fitnessflex.html)

**Security:** Never commit private credentials, tokens, service accounts, user data or production secrets. Verify Firebase security rules and permissions before using real accounts or datasets.
