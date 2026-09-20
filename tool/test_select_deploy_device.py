import io
import json
import subprocess
import unittest
from unittest.mock import patch

from select_deploy_device import AndroidDevice, discover_android_devices, select_device


class DiscoverAndroidDevicesTest(unittest.TestCase):
    @patch("select_deploy_device.subprocess.run")
    def test_returns_only_supported_android_devices(self, run) -> None:
        run.return_value = subprocess.CompletedProcess(
            args=["flutter", "devices", "--machine"],
            returncode=0,
            stdout=json.dumps(
                [
                    {
                        "name": "Armor 10 5G",
                        "id": "5000AF1001008153",
                        "isSupported": True,
                        "targetPlatform": "android-arm64",
                        "emulator": False,
                        "sdk": "Android 10 (API 29)",
                    },
                    {
                        "name": "Linux",
                        "id": "linux",
                        "isSupported": True,
                        "targetPlatform": "linux-x64",
                    },
                    {
                        "name": "Unsupported Android",
                        "id": "unsupported",
                        "isSupported": False,
                        "targetPlatform": "android-arm64",
                    },
                ]
            ),
            stderr="",
        )

        devices = discover_android_devices("flutter")

        self.assertEqual(
            devices,
            [
                AndroidDevice(
                    name="Armor 10 5G",
                    device_id="5000AF1001008153",
                    sdk="Android 10 (API 29)",
                    emulator=False,
                )
            ],
        )
        run.assert_called_once_with(
            ["flutter", "devices", "--machine"],
            capture_output=True,
            check=False,
            text=True,
        )

    @patch("select_deploy_device.subprocess.run")
    def test_splits_a_flutter_command_with_a_wrapper(self, run) -> None:
        run.return_value = subprocess.CompletedProcess(
            args=["env", "flutter", "devices", "--machine"],
            returncode=0,
            stdout="[]",
            stderr="",
        )

        discover_android_devices("env flutter")

        run.assert_called_once_with(
            ["env", "flutter", "devices", "--machine"],
            capture_output=True,
            check=False,
            text=True,
        )

    @patch(
        "select_deploy_device.subprocess.run",
        side_effect=FileNotFoundError("missing executable"),
    )
    def test_converts_command_launch_failures(self, run) -> None:
        with self.assertRaisesRegex(RuntimeError, "Could not run the Flutter command"):
            discover_android_devices("missing-flutter")


class SelectDeviceTest(unittest.TestCase):
    def test_prompts_until_a_listed_device_is_selected(self) -> None:
        devices = [
            AndroidDevice("Armor 10 5G", "phone-id", "Android 10", False),
            AndroidDevice("Pixel 8", "emulator-id", "Android 16", True),
        ]
        output = io.StringIO()

        selected = select_device(devices, io.StringIO("invalid\n3\n2\n"), output)

        self.assertEqual(selected, devices[1])
        self.assertIn("1. Armor 10 5G", output.getvalue())
        self.assertIn("2. Pixel 8", output.getvalue())
        self.assertEqual(output.getvalue().count("Enter one of the listed numbers."), 2)

    def test_rejects_an_empty_device_list(self) -> None:
        with self.assertRaisesRegex(RuntimeError, "No supported Android devices are available"):
            select_device([], io.StringIO(), io.StringIO())


if __name__ == "__main__":
    unittest.main()
