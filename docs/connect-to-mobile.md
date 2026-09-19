# Connect an Android Phone and Run Cookbook from VS Code

## 1. Enable Developer Options

1. On the phone, open **Settings > About phone**.
2. Find **Build number**, sometimes under **Software information**.
3. Tap **Build number** seven times.
4. Enter the phone's PIN on the phone if requested.
5. Confirm that Developer options are enabled.

Do not enable **OEM unlocking** or unlock the bootloader. Neither is needed.

## 2. Enable USB Debugging and Connect

1. Open **Settings > Developer options**, sometimes under **System > Advanced**.
2. Enable **USB debugging** and confirm the warning.
3. Connect the phone to the computer with a data-capable USB cable.
4. Keep the phone unlocked during initial setup.
5. If needed, open the phone's USB notification and select
   **File transfer / Android Auto** instead of charging only.
6. When **Allow USB debugging?** appears, approve the connection to this computer.
   Select **Always allow from this computer** only for a trusted computer.

If no authorization prompt appears yet, run the ADB check in the next section
and check the phone screen again.

## 3. Verify the Connection

In VS Code's terminal, run:

```bash
adb devices -l
make devices
```

## 4. Open the Flutter Project in VS Code

1. Open `lib/main.dart`.
2. Click the device selector in VS Code's bottom status bar and select the phone,
   for example **Armor 10 5G**.
   ![alt text](status-bar-phone-selector.png)
   Alternatively, use the Command Palette command
   **Flutter: Select Device**.

## 5. Build, Install, and Launch with F5

1. Keep the phone connected and unlocked.
2. Press **F5**, or choose **Run > Start Debugging**.
3. If prompted to choose a debugger, select **Dart & Flutter**.
4. Wait for the build to finish. The first Android build can take several minutes
   and may download dependencies.
5. Accept any phone-side prompt that explicitly permits this USB app installation.
6. Confirm that **Cookbook** opens on the phone.

F5 builds a debug APK, installs it via ADB, launches the app, and attaches the
debugger. You do not need to copy an APK to the phone or run `adb install`
manually. The usual build output is
`build/app/outputs/flutter-apk/app-debug.apk`.

The installed app uses the Android application ID `com.thomaso.cookbook`.
It is a development build signed with a debug key, not a Play-ready release.
