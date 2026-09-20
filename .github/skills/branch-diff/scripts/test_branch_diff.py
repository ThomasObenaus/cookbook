import subprocess
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch

from branch_diff import DIFF_COMMAND, capture_diff


class CaptureDiffTests(unittest.TestCase):
    @patch("branch_diff.subprocess.run")
    def test_uses_vscode_output_directory_by_default(self, run):
        def write_diff(command, *, stdout, stderr, check):
            stdout.write(b"diff content\n")
            return subprocess.CompletedProcess(command, 0, b"", b"")

        run.side_effect = write_diff
        with TemporaryDirectory() as directory:
            output_directory = Path(directory) / ".config" / "Code" / "copilot-terminal-output"
            with patch("branch_diff.DEFAULT_OUTPUT_DIRECTORY", output_directory):
                capture = capture_diff()

            self.assertEqual(capture.path.parent, output_directory)
            self.assertTrue(output_directory.is_dir())

    @patch("branch_diff.subprocess.run")
    def test_preserves_complete_large_diff(self, run):
        payload = b"diff --git a/start b/start\n" + (b"+changed content\n" * 5000) + b"diff --git a/end b/end\n"

        def write_diff(command, *, stdout, stderr, check):
            stdout.write(payload)
            return subprocess.CompletedProcess(command, 0, b"", b"")

        run.side_effect = write_diff
        with TemporaryDirectory() as directory:
            capture = capture_diff(Path(directory))

            self.assertIsNotNone(capture.path)
            self.assertEqual(capture.path.read_bytes(), payload)
            self.assertEqual(capture.byte_count, len(payload))
            self.assertEqual(capture.line_count, payload.count(b"\n"))

        self.assertEqual(run.call_args.args, (DIFF_COMMAND,))
        self.assertIs(run.call_args.kwargs["stderr"], subprocess.PIPE)
        self.assertFalse(run.call_args.kwargs["check"])

    @patch("branch_diff.subprocess.run")
    def test_removes_empty_capture(self, run):
        run.return_value = subprocess.CompletedProcess(DIFF_COMMAND, 0, b"", b"")
        with TemporaryDirectory() as directory:
            capture = capture_diff(Path(directory))

            self.assertIsNone(capture.path)
            self.assertEqual(list(Path(directory).iterdir()), [])

    @patch("branch_diff.subprocess.run")
    def test_removes_partial_capture_after_git_failure(self, run):
        def fail_diff(command, *, stdout, stderr, check):
            stdout.write(b"partial diff")
            return subprocess.CompletedProcess(command, 128, b"", b"fatal: bad revision\n")

        run.side_effect = fail_diff
        with TemporaryDirectory() as directory:
            capture = capture_diff(Path(directory))

            self.assertEqual(capture.returncode, 128)
            self.assertEqual(capture.stderr, b"fatal: bad revision\n")
            self.assertIsNone(capture.path)
            self.assertEqual(list(Path(directory).iterdir()), [])


if __name__ == "__main__":
    unittest.main()
