# cookbook

Cookbook is an Android application built with Flutter. Any future backend lives
in a separate repository.

## Project Layout

- `lib/`: Dart application code; entry point is `lib/main.dart`.
- `android/`: Android configuration and native Kotlin integration.
- `test/`: Unit and widget tests.
- `pubspec.yaml` and `pubspec.lock`: Dependencies and their resolved versions.

The starter currently contains Flutter's counter example, not cookbook features.
Display name: **Cookbook**. Android application ID: `com.thomaso.cookbook`.

## Development

Use Flutter **3.47.5 stable** with its bundled Dart SDK. Open this repository root
in VS Code. See [the setup plan](FLUTTER_SETUP_PLAN.md) for Android prerequisites.

```bash
flutter pub get
flutter emulators --launch Pixel_8_API_36
flutter devices
```

Select the running Android device in VS Code and press F5, or use
`flutter run -d DEVICE_ID` with the ID reported by `flutter devices`.

## Checks

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos --fatal-warnings
flutter test
flutter build apk --debug
```

Keep `pubspec.lock` in version control. Add feature packages only when needed and
review their maintenance, licenses, permissions, and platform requirements.
Release signing is not configured; the generated release configuration still
uses the debug signing key and must not be used for publication.
