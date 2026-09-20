import argparse
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

DIFF_COMMAND = ("git", "--no-pager", "diff", "main...HEAD")


@dataclass(frozen=True)
class DiffCapture:
    path: Path | None
    returncode: int
    stderr: bytes
    byte_count: int = 0
    line_count: int = 0


def capture_diff(output_directory: Path | None = None) -> DiffCapture:
    output = tempfile.NamedTemporaryFile(
        prefix="copilot-branch-diff-",
        suffix=".patch",
        dir=output_directory,
        delete=False,
    )
    output_path = Path(output.name)
    try:
        with output:
            completed = subprocess.run(
                DIFF_COMMAND,
                stdout=output,
                stderr=subprocess.PIPE,
                check=False,
            )
    except OSError:
        output_path.unlink(missing_ok=True)
        raise

    if completed.returncode != 0:
        output_path.unlink(missing_ok=True)
        return DiffCapture(None, completed.returncode, completed.stderr)

    byte_count = output_path.stat().st_size
    if byte_count == 0:
        output_path.unlink()
        return DiffCapture(None, 0, completed.stderr)

    with output_path.open("rb") as diff_file:
        line_count = sum(1 for _ in diff_file)
    return DiffCapture(output_path, 0, completed.stderr, byte_count, line_count)


def main() -> int:
    parser = argparse.ArgumentParser(description="Capture the committed main...HEAD diff without terminal truncation.")
    parser.parse_args()
    try:
        capture = capture_diff()
    except OSError as error:
        print(f"FAIL: cannot capture branch diff: {error}", file=sys.stderr)
        return 1

    if capture.returncode != 0:
        message = capture.stderr.decode("utf-8", errors="replace").rstrip()
        print(message or f"git diff failed with exit code {capture.returncode}.", file=sys.stderr)
        return capture.returncode
    if capture.path is None:
        print("EMPTY_DIFF")
        return 0

    print(f"DIFF_PATH={capture.path}")
    print(f"DIFF_BYTES={capture.byte_count}")
    print(f"DIFF_LINES={capture.line_count}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
