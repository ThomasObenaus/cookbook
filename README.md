# cookbook

Cookbook is an Android application built with Flutter. Any future backend lives
in a separate repository.

Display name: **Cookbook**. Android application ID: `com.thomaso.cookbook`.

## Project Layout

- `lib/`: Dart application code; entry point is `lib/main.dart`.
- `android/`: Android configuration and native Kotlin integration.
- `test/`: Unit and widget tests.
- `pubspec.yaml` and `pubspec.lock`: Dependencies and their resolved versions.

## Make Targets

Run these from the repository root with GNU Make and Flutter/Dart on PATH:

| Command               | Action                                                                |
| --------------------- | --------------------------------------------------------------------- |
| `make start-emulator` | Resolve dependencies, then start `Pixel_8_API_36`                     |
| `make devices`        | List connected devices                                                |
| `make lint`           | Format `lib/` and `test/`, then run `make analyze`                    |
| `make test`           | Run unit and widget tests                                             |
| `make analyze`        | Run strict static analysis, including lint rules                      |
| `make build`          | Run `test`, then `lint` (including `analyze`), then build a debug APK |

`make lint` modifies files when formatting is needed. Build steps run in order
and stop on failure, including when `make build` is invoked with `-j`.
`make start-emulator` uses `flutter pub get`, which reuses compatible locked
versions rather than upgrading all dependencies. Override the emulator with
`make start-emulator EMULATOR=another_avd_name`. Run `make` to list the targets.
