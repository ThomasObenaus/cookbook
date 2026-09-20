import subprocess
import sys
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory

from validate_review import validate_review


def report(
    finding: str = "None.",
    summary: str = "Changes the behavior.",
    why: str = "Fixes a regression.",
    limitations: str = "Tests not run.",
) -> str:
    return f"""# Change Review

## LOW

{finding}

## MEDIUM

None.

## HIGH

None.

## Review Limitations

{limitations}

## summary

{summary}

### Why

{why}
"""


class ValidateReviewTests(unittest.TestCase):
    def setUp(self):
        temporary = TemporaryDirectory(prefix="validate-review-test-")
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name)
        self.report_path = self.directory / "REVIEW.md"
        (self.directory / "source file.dart").write_text("first\nsecond\n", encoding="utf-8")

    def check(self, text: str):
        self.report_path.write_bytes(text.encode("utf-8"))
        return validate_review(self.report_path)

    def assert_error(self, text: str, fragment: str):
        result = self.check(text)
        self.assertTrue(any(fragment in error for error in result.errors), result.errors)

    def test_empty_categories_and_exact_word_limits(self):
        result = self.check(report(summary=" ".join(["word"] * 50), why=" ".join(["word"] * 30)))
        self.assertEqual(result.errors, [])
        self.assertEqual(result.summary_words, 50)
        self.assertEqual(result.why_words, 30)

    def test_encoded_paths_angle_destinations_ranges_and_crlf(self):
        text = report(finding="- **Defect**: See [source](source%20file.dart#L2) and [range](<source file.dart#L1-L2>).")
        result = self.check(text.replace("\n", "\r\n"))
        self.assertEqual(result.errors, [])
        self.assertEqual(result.checked_links, 2)

    def test_missing_reordered_duplicate_and_extra_headings(self):
        for invalid in (
            report().replace("## LOW", "## HIGH"),
            report().replace("## MEDIUM", ""),
            report().replace("## summary", "## HIGH\n\n## summary"),
            report() + "\n## Afterword\n",
            report().replace("### Why", "## Why"),
            report().replace("## LOW", "## MEDIUM", 1).replace("## MEDIUM\n\nNone.\n\n## HIGH", "## LOW\n\nNone.\n\n## HIGH"),
        ):
            with self.subTest(invalid=invalid):
                self.assert_error(invalid, "Expected headings")

    def test_missing_or_overlong_summary_and_why(self):
        for invalid in (
            report(summary=""),
            report(why=""),
            report(summary=" ".join(["word"] * 51)),
            report(why=" ".join(["word"] * 31)),
        ):
            with self.subTest(invalid=invalid):
                self.assert_error(invalid, "must contain")

    def test_missing_targets_directories_and_invalid_line_anchors(self):
        (self.directory / "empty.dart").write_text("", encoding="utf-8")
        for target in (
            "missing.dart#L1",
            ".#L1",
            "empty.dart#L1",
            "source%20file.dart#L0",
            "source%20file.dart#L3",
            "source%20file.dart#L2-L1",
            "source%20file.dart#section",
        ):
            with self.subTest(target=target):
                self.assert_error(report(finding=f"- **Defect**: See [source]({target})."), "invalid link")

    def test_valid_line_link_required_for_each_finding(self):
        result = self.check(report(finding="- **First**: See [source](source%20file.dart#L1).\n- **Second**: Missing link."))
        self.assertEqual(sum("each finding" in error for error in result.errors), 1)
        for target in ("https://example.com/#L1", "source%20file.dart"):
            with self.subTest(target=target):
                self.assert_error(report(finding=f"- **Defect**: See [source]({target})."), "each finding")

    def test_fenced_examples_and_external_urls_ignored(self):
        result = self.check(report(limitations="```markdown\n## HIGH\n[missing](missing.dart#L1)\n```\n[docs](https://example.com)"))
        self.assertEqual(result.errors, [])
        self.assertEqual(result.checked_links, 0)

    def test_malformed_links_alongside_valid_links(self):
        self.assert_error(
            report(finding="- **Defect**: [valid](source%20file.dart#L1) and [bad](unencoded space.dart#L1)."),
            "malformed or unsupported",
        )

    def test_reference_links_and_unclosed_fences(self):
        self.assert_error(report(limitations="[source][ref]\n[ref]: source%20file.dart#L1"), "reference-style")
        self.assert_error(report() + "\n```\n", "Unclosed fenced code block.")

    def test_symlinks_outside_report_tree(self):
        with TemporaryDirectory() as external:
            source = Path(external) / "source.dart"
            source.write_text("first\n", encoding="utf-8")
            (self.directory / "linked.dart").symlink_to(source)
            self.assert_error(report(finding="- **Defect**: See [source](linked.dart#L1)."), "outside the report directory")

    def test_unreadable_report(self):
        self.assertTrue(validate_review(self.report_path).errors[0].startswith("Cannot read report:"))

    def test_invalid_utf8_and_percent_encoding(self):
        self.report_path.write_bytes(b"\xff")
        self.assertTrue(validate_review(self.report_path).errors[0].startswith("Cannot read report:"))
        for target in ("bad%ZZ.dart#L1", "bad%FF.dart#L1"):
            with self.subTest(target=target):
                self.assert_error(report(finding=f"- **Defect**: See [source]({target})."), "invalid link")

    def test_last_line_without_newline(self):
        (self.directory / "source file.dart").write_text("first\nsecond", encoding="utf-8")
        result = self.check(report(finding="- **Defect**: See [source](source%20file.dart#L2)."))
        self.assertEqual(result.errors, [])
        self.assert_error(report(finding="- **Defect**: See [source](source%20file.dart#L3)."), "invalid link")

    def test_cli_defaults_explicit_path_and_failures(self):
        script = Path(__file__).with_name("validate_review.py")
        self.check(report())
        for arguments, expected_code in (
            ([], 0),
            ([str(self.report_path)], 0),
            (["missing.md"], 1),
            (["one.md", "two.md"], 2),
            (["--help"], 0),
        ):
            with self.subTest(arguments=arguments):
                completed = subprocess.run(
                    [sys.executable, "-B", str(script), *arguments],
                    cwd=self.directory,
                    capture_output=True,
                    text=True,
                    check=False,
                )
                self.assertEqual(completed.returncode, expected_code, completed.stderr)
                if expected_code == 1:
                    self.assertIn("FAIL: Cannot read report:", completed.stderr)
                elif expected_code == 0 and arguments != ["--help"]:
                    self.assertIn("PASS: headings and severity order", completed.stdout)
        self.check(report(summary=""))
        completed = subprocess.run(
            [sys.executable, "-B", str(script)],
            cwd=self.directory,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(completed.returncode, 1)
        self.assertIn("summary must contain", completed.stderr)


if __name__ == "__main__":
    unittest.main()
