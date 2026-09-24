# cookbook

Cookbook is an Android application built with Flutter. Any future backend lives
in a separate repository.

Display name: **Cookbook**. Android application ID: `com.thomaso.cookbook`.

## Shopping List

Recipe details include **Add to shopping list**. The **Shopping list** tab keeps
ingredient quantities, units, and notes. Entries can be completed by tapping
their checkbox or text, then reviewed in the collapsed **Completed** section.
Both active and completed entries can be reordered, edited, and removed, while
**Clear shopping list** removes all entries after confirmation.

The meal planner can add every ingredient from the displayed week's planned
meals in one operation. Repeated recipes and additions remain separate entries;
quantities are not merged or scaled. The list is saved on the device and needs
no account or network; it is not synchronized or backed up by this feature.

## Project Layout

- `lib/`: Dart application code; entry point is `lib/main.dart`.
- `android/`: Android configuration and native Kotlin integration.
- `test/`: Unit and widget tests.
- `integration_test/`: Smoke tests that run inside the app on Android.
- `pubspec.yaml` and `pubspec.lock`: Dependencies and their resolved versions.

## Make Targets

Run these from the repository root with GNU Make and Flutter/Dart on PATH:

| Command                 | Action                                                                           |
| ----------------------- | -------------------------------------------------------------------------------- |
| `make start-emulator`   | Resolve dependencies, then start `Pixel_8_API_36`                                |
| `make devices`          | List connected devices                                                           |
| `make lint`             | Format Dart code, then run `make analyze`                                        |
| `make test`             | Run unit and widget tests                                                        |
| `make analyze`          | Run strict static analysis, including lint rules                                 |
| `make build`            | Run `test`, then `lint` (including `analyze`), then build a debug APK            |
| `make release`          | Check formatting, analyze, and test; build a signed release AAB                  |
| `make integration-test` | Run Android integration tests on the specified device (default: `emulator-5554`) |

`make lint` modifies files when formatting is needed. Build steps run in order
and stop on failure, including when `make build` or `make release` is invoked
with `-j`. `make release` checks formatting without changing files and does not
increment versions or upload to Google Play. Device integration tests and key
backups remain separate steps.
`make start-emulator` uses `flutter pub get`, which reuses compatible locked
versions rather than upgrading all dependencies. Override the emulator with
`make start-emulator EMULATOR=another_avd_name`. Run `make` to list the targets.

To run Cookbook on a physical Android phone, follow the
[phone connection guide](docs/connect-to-mobile.md) for USB debugging setup,
device selection, and installing and launching the debug app with VS Code's F5.

For Google Play registration, private upload-key storage, signing, and versioning,
see the [release setup guide](docs/release-setup.md). Release builds require local
signing credentials; debug builds and CI do not. Local signed release compilation
has been verified; Play setup and internal-track testing remain pending.
