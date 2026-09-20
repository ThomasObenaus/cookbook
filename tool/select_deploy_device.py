import argparse
import json
import subprocess
import sys
from dataclasses import dataclass
from typing import TextIO


@dataclass(frozen=True)
class AndroidDevice:
    name: str
    device_id: str
    sdk: str
    emulator: bool


def discover_android_devices(flutter: str) -> list[AndroidDevice]:
    result = subprocess.run(
        [flutter, "devices", "--machine"],
        capture_output=True,
        check=False,
        text=True,
    )
    if result.returncode != 0:
        details = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(details or "Flutter device discovery failed.")

    try:
        values = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise RuntimeError("Flutter returned invalid device data.") from error

    if not isinstance(values, list):
        raise TypeError("Flutter returned invalid device data.")

    devices = []
    for value in values:
        if not isinstance(value, dict):
            continue
        platform = value.get("targetPlatform")
        name = value.get("name")
        device_id = value.get("id")
        if (
            value.get("isSupported") is not True
            or not isinstance(platform, str)
            or not platform.startswith("android-")
            or not isinstance(name, str)
            or not isinstance(device_id, str)
        ):
            continue

        sdk = value.get("sdk")
        devices.append(
            AndroidDevice(
                name=name,
                device_id=device_id,
                sdk=sdk if isinstance(sdk, str) else "Unknown Android version",
                emulator=value.get("emulator") is True,
            )
        )

    return devices


def select_device(
    devices: list[AndroidDevice],
    input_stream: TextIO,
    output_stream: TextIO,
) -> AndroidDevice:
    if not devices:
        raise RuntimeError("No supported Android devices are available.")

    print("Available Android devices:", file=output_stream)
    for index, device in enumerate(devices, start=1):
        kind = "emulator" if device.emulator else "physical"
        print(
            f"  {index}. {device.name} ({device.device_id}, {device.sdk}, {kind})",
            file=output_stream,
        )

    while True:
        print(
            f"Select a deploy target [1-{len(devices)}]: ",
            end="",
            file=output_stream,
            flush=True,
        )
        response = input_stream.readline()
        if response == "":
            raise RuntimeError("Device selection was cancelled.")

        try:
            selection = int(response.strip())
        except ValueError:
            selection = 0

        if 1 <= selection <= len(devices):
            return devices[selection - 1]

        print("Enter one of the listed numbers.", file=output_stream)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--flutter", default="flutter")
    arguments = parser.parse_args(argv)

    try:
        devices = discover_android_devices(arguments.flutter)
        selected_device = select_device(devices, sys.stdin, sys.stderr)
    except (RuntimeError, TypeError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    print(selected_device.device_id)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
