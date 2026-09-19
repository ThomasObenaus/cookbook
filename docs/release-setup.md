# Google Play and Release Signing

The release build uses a dedicated upload key, never the debug key. Debug builds,
F5, and existing CI jobs do not require release credentials. No publishing job
or automatic upload is configured.

## 1. Check Your Play Console Account

1. Sign in to [Google Play Console](https://play.google.com/console/) with the
   intended owner account. Check whether a developer account already exists.
2. If not, follow the registration flow, select the correct personal or
   organization account type, review the fee, and complete Google's identity
   verification. Enter identity and payment information only on Google's site.
3. Check for an existing Cookbook app before creating a new entry. For a new
   app, use the display name **Cookbook**, choose its language and **App**, and
   make the free/paid choice deliberately. Review declarations before accepting.
4. Keep the existing application ID **com.thomaso.cookbook**. Its availability
   has not been verified; the package ID cannot be changed after first upload.
5. Start with **Internal testing**, not production. When prompted during the
   first release setup, enroll in **Play App Signing** and let Google generate
   the app signing key for a new app. Your local key is the separate upload key.

If the app already exists, check its registered upload certificate before using
a new key. Do not replace an existing signing identity accidentally.

New personal accounts created after November 13, 2023 currently need a closed
test with at least 12 continuously opted-in testers for 14 days before applying
for production access. Internal testing does not satisfy this requirement.
Follow the current Console dashboard for verification, target API, privacy,
Data safety, content rating, and testing requirements. The starter counter is
not a finished product to submit for production.

## 2. Create a Private Upload Key

Use a terminal directly, not chat, for passwords and certificate identity prompts.
Choose a strong unique password and save it in a password manager. Do not put
passwords in command arguments, shell history, screenshots, or repository files.

On this Linux setup, run:

```bash
umask 077
mkdir -p "$HOME/.config/cookbook"
chmod 700 "$HOME/.config/cookbook"
```

If `upload-keystore.jks` already exists there, stop and investigate; do not
overwrite it. Otherwise run this once:

```bash
"$HOME/development/android-studio/jbr/bin/keytool" -genkeypair -v \
  -keystore "$HOME/.config/cookbook/upload-keystore.jks" \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Answer the interactive prompts yourself. When asked for the key password,
press Enter to reuse the keystore password, or save the separate password too.
Then restrict the resulting file:

```bash
chmod 600 "$HOME/.config/cookbook/upload-keystore.jks"
```

## 3. Configure Local Signing

Create `~/.config/cookbook/key.properties` locally in an editor outside this
repository. Fill in the following values yourself; do not send them through chat:

```properties
storeFile=/absolute/path/to/.config/cookbook/upload-keystore.jks
storePassword=YOUR_KEYSTORE_PASSWORD
keyAlias=upload
keyPassword=YOUR_KEY_PASSWORD
```

Use the actual absolute path, not `~` or `$HOME`. Java properties files interpret
backslashes as escapes; correctly escape any backslashes in password values.
Keep this file private from the moment it is created (`umask 077` in the terminal
used to create it), and verify permissions:

```bash
chmod 600 "$HOME/.config/cookbook/key.properties"
stat -c '%a %n' "$HOME/.config/cookbook" "$HOME/.config/cookbook/key.properties" \
  "$HOME/.config/cookbook/upload-keystore.jks"
```

Expect directory mode `700` and file modes `600`. Passwords in this properties
file are plaintext: filesystem permissions are not encryption. Use full-disk
encryption where available and keep encrypted backups in a separate secure
location. Store passwords in a password manager, and verify a backup can be
restored without replacing the working key.

Gradle reads this properties file by default. `COOKBOOK_SIGNING_PROPERTIES` can
override its path; the variable contains only a file path, not the passwords.
Missing properties or a missing keystore block release preparation. No secrets
are needed in GitHub for the current debug and integration workflows. Any future
release automation must use an approved protected environment and temporary
credential files, never untrusted PR jobs, artifacts, or caches.

## 4. Version Each Upload

The source of truth is [pubspec.yaml](../pubspec.yaml), currently `1.0.0+1`:

- `1.0.0` is the user-facing Android `versionName`.
- `1` is the Android `versionCode` used to order builds.
- Each new uploaded build must use a greater build number than previous uploads
  across all tracks. For example, a second internal build can be `1.0.0+2`.
- Promoting the same existing artifact between tracks does not require rebuilding.
- Check Play's existing uploads before assuming build number 1 is available.

Flutter supports `--build-name` and `--build-number` overrides, but record any
overrides with the release. Do not reset build numbers when changing versions.

## 5. Build and Verify Before Upload

After creating the key and properties, run from the repository root:

```bash
make test
make lint
flutter build appbundle --release
```

The usual output is `build/app/outputs/bundle/release/app-release.aab`. Verify
its signature and compare its signer certificate with your upload certificate
before uploading to the internal track. An AAB is not directly installable
like an APK. Preserve the artifact, source revision, toolchain versions, and
version/build number. Signing does not establish Play policy compliance.

## References

- [Flutter Android releases](https://docs.flutter.dev/deployment/android)
- [Play Console registration](https://support.google.com/googleplay/android-developer/answer/6112435)
- [Play App Signing](https://support.google.com/googleplay/android-developer/answer/7384423)
- [Personal-account testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465)
