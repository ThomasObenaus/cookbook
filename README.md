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

## Continuous Integration

[Flutter CI](.github/workflows/flutter-ci.yml) runs on pull requests, pushes to
any branch, and manual dispatch. A branch with an open pull request can trigger
both a push run and a pull-request run.

The `Android Checks` job uses Ubuntu 24.04, Flutter 3.47.5, and Temurin JDK
25.0.3. It resolves dependencies with `--enforce-lockfile`, checks formatting
without changing files, runs strict analysis and tests with coverage, and builds
a debug APK. Unlike `make build`, CI fails on formatting differences.

Coverage and successful debug APKs are available from the workflow run's
Artifacts section for seven days. Coverage is uploaded when available even if
a later check fails. No release signing keys or publishing credentials are used.

The user has verified a successful hosted run and configured `Android Checks`
as a required check before merging. Adding the workflow alone does not enforce
merge protection; that is configured separately in GitHub's repository settings.

## Dependency Updates

[Dependabot configuration](.github/dependabot.yml) checks Pub packages and GitHub
Actions weekly on Mondays, with up to five open version-update PRs per ecosystem.
Merge this configuration into the repository's default branch to activate it,
then inspect the update jobs in GitHub's Dependency graph / Dependabot view.
The first hosted Dependabot check has not yet been verified.

Review release notes, compatibility, licenses, and security advisories before
merging update PRs. Require `Android Checks` to pass; no auto-merge is configured.
Keep GitHub Actions pinned to commit hashes when reviewing action updates.
Flutter, Java, and Android SDK version upgrades remain manual coordinated changes.

Scheduled version updates do not replace security review. Check the repository's
security settings for Dependabot alerts and security updates where supported;
their availability and advisory coverage vary by ecosystem. These settings have
not been changed or verified by this setup.
