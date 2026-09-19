# Flutter Android Development Setup Plan

Prepared: 2026-09-19

## Goal and Scope

Develop an Android app primarily in VS Code on Linux using Flutter and Dart.
Use Android Studio for Android SDK and virtual-device management, and for native
Android debugging when needed. It does not need to stay open during normal Flutter
development.

This document is a plan only. No SDKs, extensions, emulator images, project
scaffolding, or CI workflows have been installed or created.

Initial observation: `flutter`, `dart`, `java`, `adb`, and `sdkmanager` were not
found on the current terminal's PATH. They could still exist elsewhere. Linux
distribution, CPU architecture, available memory, virtualization support, and
installed VS Code extensions still need to be checked before installation.

## 1. Host and SDK Setup

- [ ] Confirm the Linux distribution, CPU architecture, free disk space, and RAM.
- [ ] Check current Flutter and Android installation locations before adding new ones.
- [ ] Install Git and the host dependencies listed in Flutter's Linux installation
      guide, including download/archive tools. Use distribution-specific packages.
- [ ] Install the current stable Flutter SDK in a user-writable location, such as
      `~/development/flutter`. Do not run Flutter as root.
- [ ] Add the Flutter SDK's `bin` directory to the shell PATH and restart VS Code
      so its terminal and extensions inherit the updated environment.
- [ ] Use the Dart SDK bundled with Flutter, not a separately versioned Dart install.
- [ ] Install stable Android Studio and complete its setup wizard.
- [ ] Start with Android Studio's bundled JDK. Confirm the actual Java location
      with `flutter doctor -v`; ensure it is compatible with the project's Android
      Gradle Plugin and Gradle wrapper. Do not independently upgrade these components.
- [ ] In SDK Manager, install Android SDK Platform-Tools, Command-line Tools,
      Build-Tools, Android Emulator, and the SDK platform required by the selected
      Flutter version/project. Install compatible NDK and CMake versions as required
      by Flutter's setup guidance and native plugins.
- [ ] Record the Android SDK location, typically `~/Android/Sdk`. Configure
      `ANDROID_HOME` and PATH entries for `platform-tools`, `emulator`, and
      `cmdline-tools/latest/bin` using the actual installed paths. Use
      `flutter config --android-sdk /actual/sdk/path` if auto-detection fails.
- [ ] Review Android SDK licenses interactively with
      `flutter doctor --android-licenses`.

Verification commands after installation:

```bash
flutter --version
dart --version
flutter doctor -v
adb version
```

Success: Flutter and the Android toolchain are usable. Warnings about unused
targets such as Linux desktop or web do not block Android development. A separate
system Gradle installation is unnecessary; use the project's Gradle wrapper.

### Reproducible Versions

Choose an exact stable Flutter version during installation and record it for both
local development and CI. Dart follows that Flutter version. Keep the generated
Gradle wrapper and Android build configuration under version control.

FVM (Flutter Version Management) is optional, useful when working on projects that
need different Flutter versions. If adopted, commit its project version
configuration, configure VS Code to use that SDK, and use the same pinned version
in CI. Do not mix SDKs inadvertently. Avoid automatic SDK upgrades in CI.

## 2. VS Code Extensions and Settings

| Priority                         | Extension      | Marketplace ID                   | Purpose                                                          |
| -------------------------------- | -------------- | -------------------------------- | ---------------------------------------------------------------- |
| Required                         | Flutter        | `Dart-Code.flutter`              | Run/debug, device selection, hot reload, Flutter tooling         |
| Required, installed with Flutter | Dart           | `Dart-Code.dart-code`            | Analyzer diagnostics, completion, formatting, refactoring, tests |
| Recommended                      | YAML           | `redhat.vscode-yaml`             | Edit package, analyzer, and CI configuration                     |
| Recommended                      | Error Lens     | `usernamehw.errorlens`           | Make existing diagnostics more visible; not a separate linter    |
| Recommended                      | markdownlint   | `DavidAnson.vscode-markdownlint` | Check project documentation                                      |
| Optional                         | GitHub Actions | `GitHub.vscode-github-actions`   | Workflow assistance if GitHub Actions is selected                |
| Optional                         | GitLens        | `eamodio.gitlens`                | Additional Git history and review tools                          |

Install through the Extensions view, verifying each publisher and avoiding
duplicate Flutter/Dart tooling. Git support and the testing UI are already built
into VS Code. Flutter DevTools is available through Flutter tooling; no separate
DevTools extension is required. AI assistance is optional, not a pipeline dependency.

During implementation:

- [ ] Open the Flutter project root, not just its Android subdirectory.
- [ ] Set the Dart extension as the formatter for Dart files and enable
      format-on-save for Dart.
- [ ] Confirm the extension and terminal select the same Flutter SDK.
- [ ] Add team extension recommendations and portable workspace settings to the
      repository. Keep machine-specific absolute SDK paths in user settings.
- [ ] Start with the default F5 launch behavior; add launch configurations only
      when flavors or environment arguments require them.
- [ ] Verify completion, diagnostics, a Dart breakpoint, hot reload, the testing
      UI, and Flutter Inspector.

Do not use ESLint or Prettier to lint/format Dart. Kotlin and Java extensions are
not required for ordinary Flutter development; use Android Studio when working
deeply on native Android code.

## 3. Emulator and Physical Devices

### Recommended Emulator

Use Google's official **Android Emulator**, installed through SDK Manager, with
an **Android Virtual Device (AVD)** created in Android Studio's Device Manager.
An AVD is the device configuration and OS image, not a separate emulator product.
Genymotion and consumer Android emulators are unnecessary for this setup.

Initial AVD recommendation:

| Setting         | Recommendation                                                                                          |
| --------------- | ------------------------------------------------------------------------------------------------------- |
| Device profile  | A standard Pixel phone profile, such as Pixel 8                                                         |
| Android version | A stable image compatible with the app, preferably matching its target API; record the exact API chosen |
| Image           | Google APIs image for general development; Google Play image when Play Store behavior is needed         |
| CPU image       | `x86_64` on an Intel/AMD Linux host; verify host/tool availability before choosing another architecture |
| Graphics        | Automatic acceleration initially                                                                        |
| Memory          | Start with profile defaults and adjust to host capacity                                                 |

- [ ] Enable CPU virtualization in BIOS/UEFI where necessary.
- [ ] Configure Linux KVM and user access to `/dev/kvm` using the distribution's
      instructions. Group changes may require signing out and back in. Do not run
      the emulator as root or make `/dev/kvm` world-writable.
- [ ] Verify acceleration with `emulator -accel-check` after PATH setup.
- [ ] Create and boot the AVD, then confirm Flutter detects it.
- [ ] Select the device from VS Code's status bar and launch the app with F5.

```bash
emulator -accel-check
flutter emulators
flutter devices
adb devices
```

A host with 16 GB RAM and ample SSD space is a practical starting point, not a
guaranteed minimum; 32 GB is more comfortable for several tools/devices. Reserve
tens of GB for SDKs, images, and build caches. If hardware acceleration is
unavailable or memory is limited, use a physical phone instead.

### Device Coverage

- [ ] Keep at least one real Android phone for release and performance testing.
      Enable Developer options and USB debugging, authorize this computer, and
      configure Linux USB/udev permissions if required.
- [ ] Add a device/image at the app's minimum supported API before release.
- [ ] Test the latest stable Android version, small screens, large text, rotation,
      and a tablet/foldable size if those form factors are supported.
- [ ] Check permission denial, offline behavior, background/resume behavior, and
      notifications where applicable.

The emulator API, compile SDK, target SDK, and minimum SDK are different settings.
Use Flutter's compatible build defaults initially, then choose minimum support
and target API based on plugin requirements and current Play policy.

## 4. Project Baseline and Dependency Management

- [ ] Agree on the app name, repository layout, and permanent Android application
      ID before scaffolding. Do not overwrite existing repository content.
- [ ] Create an Android-targeted Flutter app through VS Code or the Flutter CLI.
- [ ] Keep the app's `pubspec.lock` in Git for reproducible dependency resolution.
- [ ] Keep generated build output, SDK caches, local SDK paths, credentials, and
      signing material out of Git; review the generated ignore rules.
- [ ] Start with Flutter's standard project layout. Select state management,
      routing, storage, and HTTP packages only when application requirements justify them.
- [ ] Review plugin maintenance, licenses, supported Android APIs, native
      dependencies, permissions, and security before adoption.
- [ ] Review `flutter pub outdated` regularly; upgrade in a separate change and
      rerun tests. An outdated-package report is not a security vulnerability scan.
- [ ] Use a dependency update service such as Dependabot or Renovate if supported
      by the chosen repository host; include security/advisory review.

## 5. Formatting, Linting, and Static Analysis

Use the built-in Dart formatter and analyzer with **flutter_lints** as the initial
lint baseline. Flutter templates normally include this development dependency;
verify it rather than adding a second ruleset.

The analyzer configuration should include:

```yaml
include: package:flutter_lints/flutter.yaml
```

Configure the same rules locally and in CI. Consider stricter rules later when
they address real issues; do not start with multiple overlapping lint packages.
Run Android Lint as well when native code, manifests, or platform configuration
become a meaningful part of the project.

Run from the Flutter project root:

```bash
flutter pub get
dart format .
flutter analyze --fatal-infos --fatal-warnings
flutter test --coverage
```

For a non-mutating format gate in CI:

```bash
dart format --output=none --set-exit-if-changed .
```

Optional local pre-commit checks can run formatting and analysis. CI remains the
authoritative gate because local hooks can be skipped. Node.js tooling is not
required for the Flutter build pipeline.

## 6. Testing and Debugging

| Layer         | Tool                               | Initial coverage                                        |
| ------------- | ---------------------------------- | ------------------------------------------------------- |
| Unit          | `flutter_test` / Dart testing APIs | Validation and business logic                           |
| Widget        | `flutter_test`                     | Screen states, interaction, navigation, text scaling    |
| Integration   | Flutter SDK `integration_test`     | One critical end-to-end flow on Android                 |
| Manual/device | Real phone and emulator            | Permissions, accessibility, lifecycle, release behavior |

Unit and widget tests run without an Android emulator. Integration tests require
a configured target device. Add `integration_test` as a Flutter SDK development
dependency and create the tests before running this example; replace `DEVICE_ID`
with an ID from `flutter devices`:

```bash
flutter test integration_test -d DEVICE_ID
```

Use fakes/mocks to isolate ordinary tests from production services. Standard
`integration_test` cannot drive all native UI, such as Android permission dialogs;
consider Patrol only if automating those interactions becomes necessary.

- [ ] Confirm VS Code breakpoints, variable inspection, and hot reload work.
- [ ] Use Flutter Inspector for layout and DevTools for memory/network/performance.
- [ ] Measure performance on real hardware in profile mode, not debug mode.
- [ ] Track coverage for important logic; generating a report does not enforce
      a threshold. Set an explicit threshold later if useful.
- [ ] Add targeted golden/screenshot tests for stable visual requirements, using
      a consistent OS, fonts, and rendering environment.

## 7. Configuration, Security, and Observability

- [ ] Separate development and production API endpoints. Start with documented
      `--dart-define` values; add Android flavors when separate app IDs, service
      configurations, or side-by-side installations are needed.
- [ ] Never treat `--dart-define`, bundled environment files, or obfuscation as
      secret storage. Privileged secrets belong on a backend, not in the app binary.
- [ ] Keep signing passwords and CI credentials out of Git and logs. Store local
      sensitive values securely and use the CI platform's protected secret store.
- [ ] Use HTTPS and request only necessary Android permissions. If network access
      is needed, verify the release manifest includes the Internet permission.
- [ ] For local APIs, remember that emulator `localhost` refers to the emulator;
      the standard Android emulator reaches the host through `10.0.2.2`. Keep any
      development cleartext exceptions out of production configuration.
- [ ] Keep logs free of credentials and sensitive personal data.
- [ ] Before production, select crash reporting such as Crashlytics or Sentry
      based on privacy requirements; analytics is a separate, optional decision.
- [ ] Test accessibility with TalkBack and large text; check contrast and touch targets.

## 8. Continuous Integration

Recommendation: use GitHub Actions if the repository is hosted on GitHub;
otherwise use the existing host's CI. Codemagic is a reasonable alternative for
a mobile-focused hosted pipeline. Neither CI hosting nor cloud services need to
be provisioned for initial local setup.

### Pull Request Gate

1. Check out the repository with minimal permissions.
2. Install the exact pinned Flutter SDK, compatible JDK, and required Android SDK
   components. Use reviewed actions pinned to immutable revisions where practical.
3. Restore dependency/build caches keyed by relevant SDK versions and lockfiles.
4. Run `flutter pub get --enforce-lockfile` once the application lockfile is committed.
5. Run `dart format --output=none --set-exit-if-changed .`.
6. Run `flutter analyze --fatal-infos --fatal-warnings`.
7. Run `flutter test --coverage` and retain the coverage report.
8. Run `flutter build apk --debug` to catch Android compilation/plugin failures.
9. Require these checks before merging.

Run an integration smoke test on important pull requests or a scheduled job using
a pinned emulator API/image and a runner with supported KVM access. Wait for boot
completion and upload relevant test logs on failure. Do not assume every hosted
runner supports accelerated emulators.

Untrusted pull requests must not receive release secrets. Do not execute
untrusted contribution code in a privileged release context. Start with separate
validation and release workflows.

## 9. Release Pipeline

- [ ] Register the required Google Play developer account and review current
      verification, target API, testing, privacy, and Data safety requirements.
- [ ] Configure Play App Signing and a dedicated upload key. Back up the upload
      keystore securely and restrict access.
- [ ] Configure release signing explicitly; a template build that uses debug
      signing is not ready for Play distribution.
- [ ] Keep the keystore and signing properties outside version control. Inject
      them only into approved release jobs and clean temporary copies afterward.
- [ ] Set a user-facing version and monotonically increasing Android build number.
- [ ] Run tests, then build with `flutter build appbundle --release` using the
      intended production configuration.
- [ ] Retain the AAB and, when applicable, obfuscation symbols/mapping files with
      the release's source revision and toolchain version.
- [ ] Test through Google Play's internal track on real hardware before promotion.
      An AAB cannot be installed directly like an APK.
- [ ] Require approval before production promotion. Use staged rollout and plan
      for stopping a rollout and shipping a higher-build-number fix.

Start with manual upload to the internal track. Add fastlane or a reviewed Play
publishing integration later if release frequency warrants it. Check CI artifact
retention, emulator execution costs, and store/account fees before enabling them.

## 10. Execution Order and Acceptance Checks

| Phase | Deliverable                     | Done when                                                         |
| ----- | ------------------------------- | ----------------------------------------------------------------- |
| 1     | Host, Flutter, Android SDK, JDK | `flutter doctor -v` confirms the Android toolchain works          |
| 2     | VS Code extensions and device   | F5 launches an app; breakpoint and hot reload work                |
| 3     | Project quality baseline        | Formatting, analysis, unit/widget tests, and debug APK build pass |
| 4     | Device validation               | Integration smoke test passes; real-device checks documented      |
| 5     | CI                              | A pull request runs and enforces the same quality gates           |
| 6     | Release readiness               | Correctly signed AAB is tested through the internal track         |

Implementation should begin with phases 1 and 2. CI and release setup should
follow a working local app, not block the first development session. Local iOS
builds would require macOS and Xcode and are outside this Linux/Android plan.

## References

- [Flutter installation](https://docs.flutter.dev/install)
- [Flutter in VS Code](https://docs.flutter.dev/tools/vs-code)
- [Android setup for Flutter](https://docs.flutter.dev/platform-integration/android/setup)
- [Android emulator acceleration](https://developer.android.com/studio/run/emulator-acceleration)
- [Flutter lints](https://pub.dev/packages/flutter_lints)
- [Dart static analysis](https://dart.dev/tools/analysis)
- [Flutter testing](https://docs.flutter.dev/testing/overview)
- [Flutter DevTools](https://docs.flutter.dev/tools/devtools)
- [Android releases and signing](https://docs.flutter.dev/deployment/android)
- [Flutter continuous delivery](https://docs.flutter.dev/deployment/cd)
