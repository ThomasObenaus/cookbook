#!/usr/bin/env bash
set -euo pipefail

device="${ANDROID_SERIAL:-emulator-5554}"
log_dir="build/integration-logs"
mkdir -p "$log_dir"

collect_logs() {
    timeout 20s adb -s "$device" logcat -d > "$log_dir/logcat.txt" 2>&1 || true
}
trap collect_logs EXIT

timeout 20s adb -s "$device" logcat -c
timeout --signal=TERM --kill-after=30s 15m make integration-test DEVICE="$device" 2>&1 | tee "$log_dir/test-output.txt"
