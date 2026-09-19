# Flutter Android Development Setup Plan

Prepared: 2026-09-19

## Goal and Scope

Develop an Android app primarily in VS Code on Linux using Flutter and Dart.
Use Android Studio for Android SDK and virtual-device management, and for native
Android debugging when needed. It does not need to stay open during normal Flutter
development.

Section 1 host and SDK setup is complete and Flutter Doctor passes the Android
toolchain check. Flutter, Android, and Java environment settings are persistent
in Bash. The user confirms shell setup and VS Code restart are complete.
The user confirms clicking Finish in Android Studio's first-launch wizard.
Section 2 editor configuration is ready; the user confirms F5 launch, breakpoints,
variable inspection, and hot reload work. The user also confirms the SDK version,
completion, diagnostics, Testing UI, and Inspector widget selection work.
Section 3 emulator setup is verified: Pixel_8_API_36 boots successfully
and is detected by ADB and Flutter. Physical-device checks remain pending.
Section 4's Android-only Flutter starter now exists at the repository
root. The GitHub Actions CI workflow is implemented and locally validated;
the user confirms a successful hosted run and working required-check enforcement
for `Android Checks`.
Release setup is deferred.

Host checks confirmed Ubuntu 24.04.5 LTS on x86_64, 31 GiB RAM, and 236 GiB free
disk space before installation. The Android Emulator confirms KVM is installed
and usable. No previous Flutter or Android installation was found in the common
locations checked. All SDK downloads passed their published SHA-256 checks.

## 1. Host and SDK Setup

- [x] Confirm the Linux distribution, CPU architecture, free disk space, and RAM.
- [x] Check current Flutter and Android installation locations before adding new ones.
- [x] Install Git and the host dependencies listed in Flutter's Linux installation
      guide, including download/archive tools. Use distribution-specific packages.
- [x] Install the current stable Flutter SDK in a user-writable location, such as
      `~/development/flutter`. Do not run Flutter as root.
- [x] Add the Flutter SDK's `bin` directory to Bash PATH in `~/.bashrc`.
- [x] Restart VS Code and verify tools in a new terminal so its terminal and
      extensions inherit the updated environment.
- [x] Use the Dart SDK bundled with Flutter, not a separately versioned Dart install.
- [x] Install stable Android Studio in `~/development/android-studio`.
- [x] Complete Android Studio's first-launch wizard, reusing `~/Android/Sdk`
      (user confirmed clicking Finish).
- [x] Start with Android Studio's bundled JDK. Confirm the actual Java location
      with `flutter doctor -v`; ensure it is compatible with the project's Android
      Gradle Plugin and Gradle wrapper. Do not independently upgrade these components.
- [x] In SDK Manager, install Android SDK Platform-Tools, Command-line Tools,
      Build-Tools, Android Emulator, and the SDK platform required by the selected
      Flutter version/project. Install compatible NDK and CMake versions as required
      by Flutter's setup guidance and native plugins.
- [x] Record `~/Android/Sdk` and configure Flutter to use this Android SDK.
- [x] Persist `ANDROID_HOME`, the bundled `JAVA_HOME`, and PATH entries for Java,
      `platform-tools`, `emulator`, and `cmdline-tools/latest/bin` in `~/.bashrc`.
      Verified after sourcing the configuration; existing terminals need reloading.
- [x] Review Android SDK licenses interactively with
      `flutter doctor --android-licenses`.

### Installed Versions and Validation

| Component                 | Installed version / location                                 |
| ------------------------- | ------------------------------------------------------------ |
| Flutter                   | 3.47.5 stable, `~/development/flutter`                       |
| Dart                      | 3.13.4, bundled with Flutter                                 |
| Android Studio            | Quail 4 Patch 1 (2026.1.4.8), `~/development/android-studio` |
| Java                      | Bundled OpenJDK 25.0.3, `~/development/android-studio/jbr`   |
| Android SDK               | `~/Android/Sdk`                                              |
| Command-line tools        | 22.0, `cmdline-tools/latest`                                 |
| Platform / Build-Tools    | Android API 36 (revision 2) / 36.0.0                         |
| Platform-Tools / Emulator | 37.0.1 / 37.1.11                                             |
| NDK / CMake               | 28.2.13676358 / 3.22.1                                       |

Flutter is configured with explicit Android SDK, Android Studio, and JDK paths.
The installed Flutter template uses Gradle 9.3.1 and AGP 9.1.0. The starter app
has been created and the user's subsequent `make build` completed successfully.

Verified: Flutter/Dart versions, Android toolchain in `flutter doctor -v`, all
Android SDK licenses accepted, `adb version`, installed SDK packages, and
`emulator -accel-check`. Remaining Doctor errors concern unused Linux desktop
dependencies, not Android. The API 36 system image and AVD are recorded in section 3.

The user confirms shell setup and VS Code restart are complete. Flutter, Android,
and Java settings were added to `~/.bashrc` by the assistant; zsh setup was left
to the user. Bash syntax, tool resolution, Java, ADB, and KVM acceleration were
verified after sourcing the configuration. The equivalent settings are:

```bash
export JAVA_HOME="$HOME/development/android-studio/jbr"
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$HOME/development/flutter/bin:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
```

Launch the installed IDE with `~/development/android-studio/bin/studio` when
needed. SDK downloads remain in `~/development/.downloads`.

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

Editor configuration:

- [x] Set the Dart extension as the formatter for Dart files and enable
      format-on-save for Dart.
- [x] Configure the extension to use the terminal's Flutter SDK in user settings.
- [x] Add team extension recommendations and portable workspace settings to the
      repository. Keep machine-specific absolute SDK paths in user settings.

Pending app-dependent editor checks are collected in section 11 at the end.

### Editor Setup Status

All listed extensions were already installed; no new installations were needed:
Flutter and Dart 3.142.0, YAML 1.24.0, Error Lens 3.28.0, markdownlint 0.62.1,
GitHub Actions 0.32.3, and GitLens 19.2.0. Installation does not by itself verify
extension activation or enabled status in a Flutter workspace.

- `.vscode/settings.json` selects `Dart-Code.dart-code` as the Dart formatter
  and enables format-on-save only for Dart, leaving other languages unchanged.
- `.vscode/extensions.json` recommends the required and recommended extensions.
  Optional GitHub Actions and GitLens remain optional and are already installed.
- VS Code user settings set `dart.flutterSdkPath` to
  `/home/winnietom/development/flutter`, matching terminal Flutter 3.47.5.
- Configuration JSON checks passed, and VS Code reported no errors in the settings
  or extension recommendations. No custom launch configuration was added.

The user resolved Dart-only workspace detection by opening the Flutter project
root and reloading VS Code, then confirmed F5 launch, a breakpoint, variable
inspection, and hot reload with state preserved. VS Code's test integration now
discovers and runs the widget test, and the live Flutter Inspector widget tree
was retrieved through tooling. The user subsequently confirmed manual Testing UI
and Inspector widget selection, completion, diagnostics, and Flutter SDK 3.47.5.
DevTools memory, network, and performance checks remain pending.

Do not use ESLint or Prettier to lint/format Dart. Kotlin and Java extensions are
not required for ordinary Flutter development; use Android Studio when working
deeply on native Android code.

## 3. Emulator and Physical Devices

### Recommended Emulator

Use Google's official **Android Emulator**, installed through SDK Manager, with
an **Android Virtual Device (AVD)** created in Android Studio's Device Manager
or with the SDK's `avdmanager` CLI.
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

- [x] Confirm CPU virtualization is enabled; no BIOS/UEFI change was needed.
- [x] Confirm Linux KVM and user access to `/dev/kvm` using the distribution's
      instructions. Group changes may require signing out and back in. Do not run
      the emulator as root or make `/dev/kvm` world-writable.
- [x] Verify acceleration with `emulator -accel-check` after PATH setup.
- [x] Create and boot the AVD, then confirm Flutter detects it.

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

### Emulator Setup Status

Created `Pixel_8_API_36` with `avdmanager`, using the Pixel 8 hardware profile and
`system-images;android-36;google_apis;x86_64` (Android 16, API 36). Graphics are
automatic; the running emulator selected the NVIDIA GeForce GTX 1650. KVM is
usable without elevated privileges.

Verified: `flutter emulators` lists the AVD, ADB reports `emulator-5554` as
`device`, `sys.boot_completed` returns `1`, and `flutter devices` lists it as an
Android API 36 emulator. The device serial may change on subsequent launches.
AVD creation reported a missing image `devices.xml`; this did not prevent
creation, boot, or device discovery.

The emulator was left running. After closing it, launch it again with:

```bash
flutter emulators --launch Pixel_8_API_36
```

The user confirms selecting the emulator and launching the starter with F5 works.
App-dependent device coverage is collected in section 11.
Physical-phone setup below is not yet verified.

### Device Coverage

- [ ] Keep at least one real Android phone for release and performance testing.
      Enable Developer options and USB debugging, authorize this computer, and
      configure Linux USB/udev permissions if required.

The emulator API, compile SDK, target SDK, and minimum SDK are different settings.
Use Flutter's compatible build defaults initially, then choose minimum support
and target API based on plugin requirements and current Play policy.

## 4. Project Baseline and Dependency Management

- [x] Agree on the app name, repository layout, and permanent Android application
      ID before scaffolding. Do not overwrite existing repository content.
- [x] Create an Android-targeted Flutter app through VS Code or the Flutter CLI.
- [x] Start with Flutter's standard project layout. Select state management,
      routing, storage, and HTTP packages only when application requirements justify them.
- [ ] Review plugin maintenance, licenses, supported Android APIs, native
      dependencies, permissions, and security before adoption of future plugins.

### Project Setup Status

- Dart project name: `cookbook`; display name: **Cookbook**.
- Android application ID and namespace: `com.thomaso.cookbook`.
- Standard `lib/`, `android/`, and `test/` folders live at the repository root.
  Any future backend will use a separate repository.
- Generated with Flutter 3.47.5, targeting Android only, with Kotlin native
  integration. The counter starter is retained for development-tool verification.
- Existing license, setup plan, and VS Code settings were preserved. The README
  now documents the project layout and development commands.
- Only template dependencies are present: Flutter, `cupertino_icons` (resolved
  1.0.9), `flutter_test`, and `flutter_lints` (6.0.0). No feature plugins were
  adopted, so the future-plugin review remains pending.
- Dependency resolution, static analysis, the starter widget test, and formatting
  checks passed. The user confirms debugger and hot-reload checks passed;
  VS Code test integration also discovered and passed the starter widget test.
- `flutter pub outdated` reports current direct dependencies and newer versions
  of four transitive dependencies. The generated lockfile was retained without
  upgrades or overrides; this report is not a security audit.
- Generated ignore rules exclude build output, Dart caches, Android local SDK
  paths, and Android signing keys/properties. The generated project and lockfile
  are tracked in Git; no files were staged or committed by the assistant.
- The first debug APK build was interrupted, but the user's subsequent
  `make build` completed with exit code 0, verifying tests, formatting, analysis,
  and debug APK compilation. The JDK native-access warning did not block it.
  A subsequent `flutter test --coverage` passed and produced `coverage/lcov.info`:
  24/26 lines (92.3%) covered in `lib/main.dart`. Only the `main()` entry point
  was uncovered; the widget test constructs `MyApp` directly. No coverage
  threshold is enforced, and this measures only the starter example.

Post-scaffolding repository and dependency tasks are collected in section 11.

## 5. Formatting, Linting, and Static Analysis

The following is reference guidance; app-dependent execution is tracked in
section 11.

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

Pending testing and debugging tasks are collected in section 11.

## 7. Configuration, Security, and Observability

- [ ] Never treat `--dart-define`, bundled environment files, or obfuscation as
      secret storage. Privileged secrets belong on a backend, not in the app binary.
- [ ] Keep signing passwords and CI credentials out of Git and logs. Store local
      sensitive values securely and use the CI platform's protected secret store.
- [ ] Before production, select crash reporting such as Crashlytics or Sentry
      based on privacy requirements; analytics is a separate, optional decision.

App-specific configuration and verification tasks are collected in section 11.

## 8. Continuous Integration

Recommendation: use GitHub Actions if the repository is hosted on GitHub;
otherwise use the existing host's CI. Codemagic is a reasonable alternative for
a mobile-focused hosted pipeline. Neither CI hosting nor cloud services need to
be provisioned for initial local setup.

### Pull Request Gate

The pipeline is implemented in `.github/workflows/flutter-ci.yml`; hosted
verification and merge protection are tracked separately in section 11.

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

### CI Setup Status

- Added `Flutter CI` with the `Android Checks` job for pull requests, all branch
  pushes, and manual dispatch on Ubuntu 24.04. Push and pull-request events can
  both run for a branch with an open pull request.
- Pinned actions to immutable revisions and Flutter to 3.47.5; selected Temurin
  JDK 25.0.3 and explicit Android platform/build-tools/NDK/CMake versions matching
  the local setup. Flutter is configured to use that JDK and the runner's SDK.
- Enabled Gradle and Flutter/Pub caches, read-only repository permissions,
  cancellation of superseded runs, and a 30-minute job timeout. Checkout does
  not persist credentials; the workflow references no release secrets.
- Added locked dependency resolution, non-mutating formatting checks, strict
  analysis, coverage tests, and debug APK compilation. Coverage and successful
  APK artifacts are retained for seven days; available coverage is retained
  after a later failure. No coverage threshold is enforced.
- YAML checks, actionlint, pinned action input checks, and the local dependency,
  formatting, analysis, and coverage gates passed. The debug build previously
  passed locally. The user confirms the entire GitHub-hosted `Android Checks`
  job passed, including the debug APK build and artifact uploads.
- The first hosted SDK setup failed because the pinned Android action requested
  the obsolete `tools` package by default. Setting `packages: platform-tools`
  resolved that failure; the subsequent full job passed (user confirmed).
- No commit, push, or remote repository settings changes were made by the
  assistant. The user configured the required `Android Checks` status check
  through GitHub's ruleset or branch protection settings and confirms it works.
  Remote enforcement was user-verified, not independently inspected by the
  assistant. Emulator integration CI is deferred.

## 9. Release Pipeline

- [ ] Register the required Google Play developer account and review current
      verification, target API, testing, privacy, and Data safety requirements.
- [ ] Configure Play App Signing and a dedicated upload key. Back up the upload
      keystore securely and restrict access.
- [ ] Keep the keystore and signing properties outside version control. Inject
      them only into approved release jobs and clean temporary copies afterward.
- [ ] Require approval before production promotion. Use staged rollout and plan
      for stopping a rollout and shipping a higher-build-number fix.

App-specific signing, build, and release validation tasks are collected in
section 11; they are not prerequisites for the first example app.

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

## 11. Pending Steps Requiring an App

An example Flutter app now exists from section 4. Check off each step only after
it has been verified. Start with the example-app checks; feature-specific and
release tasks need a more developed app and apply only when relevant. Earlier
sections retain reference guidance and tasks that can be done before scaffolding.

### Example App and VS Code Verification

- [x] Open the Flutter project root, not just its Android subdirectory.
- [x] Confirm the active extension reports the configured Flutter SDK after
      opening a Flutter project (Flutter 3.47.5, user verified).
- [x] Start with the default F5 launch behavior; add launch configurations only
      when flavors or environment arguments require them.
- [x] Select the device from VS Code's status bar and launch the app with F5.
- [x] Verify completion, diagnostics, and the Testing UI (user verified).
- [x] Verify VS Code test discovery and execution through its test integration
      (one widget test passed, including a coverage run).
- [x] Confirm VS Code breakpoints, variable inspection, and hot reload work
      (user verified; hot reload preserves the counter state).
- [x] Connect to the IDE-launched app and retrieve its live Flutter Inspector
      widget tree; verified Cookbook's Scaffold, AppBar, counter, and button.
- [x] Open Flutter Inspector and select a widget to inspect its place in the
      widget tree (user verified).
- [ ] Use DevTools for memory/network/performance checks.

### Project Baseline and Quality Checks

- [x] Keep the app's `pubspec.lock` in Git for reproducible dependency resolution.
- [x] Keep generated build output, SDK caches, local SDK paths, credentials, and
      signing material out of Git; review the generated ignore rules.
- [x] Verify the template's `flutter_lints` dependency and analyzer configuration
      using section 5; avoid adding a second ruleset.
- [x] Run dependency resolution, formatting, static analysis, and widget/unit
      tests; verified during setup and by the user's successful `make build`.
- [x] Run `flutter test --coverage` and verify the generated coverage report
      (`coverage/lcov.info`, 24/26 lines covered in `lib/main.dart`).
- [x] Build a debug APK with `flutter build apk --debug` to verify Android
      project-level toolchain compatibility.
- [ ] Review `flutter pub outdated` regularly; upgrade in a separate change and
      rerun tests. An outdated-package report is not a security vulnerability scan.
- [ ] Use a dependency update service such as Dependabot or Renovate if supported
      by the chosen repository host; include security/advisory review.

### Feature and Device Validation

- [ ] Add a device/image at the app's minimum supported API before release.
- [ ] Test the latest stable Android version, small screens, large text, rotation,
      and a tablet/foldable size if those form factors are supported.
- [ ] Check permission denial, offline behavior, background/resume behavior, and
      notifications where applicable.
- [ ] Add `integration_test` and a critical end-to-end test, then run it on an
      Android device using section 6's guidance.
- [ ] Measure performance on real hardware in profile mode, not debug mode.
- [ ] Track coverage for important logic; generating a report does not enforce
      a threshold. Set an explicit threshold later if useful.
- [ ] Add targeted golden/screenshot tests for stable visual requirements, using
      a consistent OS, fonts, and rendering environment.
- [ ] Test accessibility with TalkBack and large text; check contrast and touch targets.

### App Configuration and Security

- [ ] Separate development and production API endpoints. Start with documented
      `--dart-define` values; add Android flavors when separate app IDs, service
      configurations, or side-by-side installations are needed.
- [ ] Use HTTPS and request only necessary Android permissions. If network access
      is needed, verify the release manifest includes the Internet permission.
- [ ] For local APIs, remember that emulator `localhost` refers to the emulator;
      the standard Android emulator reaches the host through `10.0.2.2`. Keep any
      development cleartext exceptions out of production configuration.
- [ ] Keep logs free of credentials and sensitive personal data.

### CI and Release Validation

- [x] Implement section 8's pull request gate and validate its workflow and local
      quality commands.
- [x] Push the workflow and verify a successful GitHub-hosted `Android Checks` run
      (user confirmed, including APK build and artifact uploads).
- [x] Require `Android Checks` before merging via a branch ruleset or protection
      (configured and verified by the user).
- [ ] Run an integration smoke test on important pull requests or a scheduled
      job using section 8's emulator and untrusted-contribution safeguards.
- [ ] Configure release signing explicitly; a template build that uses debug
      signing is not ready for Play distribution.
- [ ] Set a user-facing version and monotonically increasing Android build number.
- [ ] Run tests, then build with `flutter build appbundle --release` using the
      intended production configuration.
- [ ] Retain the AAB and, when applicable, obfuscation symbols/mapping files with
      the release's source revision and toolchain version.
- [ ] Test through Google Play's internal track on real hardware before promotion.
      An AAB cannot be installed directly like an APK.
