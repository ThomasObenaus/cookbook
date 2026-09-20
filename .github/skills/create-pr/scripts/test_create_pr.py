import subprocess
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch

from create_pr import PullRequestContent, ReviewFormatError, create_pull_request, load_review, parse_review


def review(
    title: str = "Prepare API",
    summary: str = "Adds the API preparation workflow.",
    why: str = "Make releases repeatable.",
    low: str = "None.",
    medium: str = "None.",
    high: str = "None.",
) -> str:
    return f"""# Change Review

## Findings

### LOW

{low}

### MEDIUM

{medium}

### HIGH

{high}

## Review Limitations

CI was not run.

## Title

{title}

## summary

{summary}

### Why

{why}
"""


class ParseReviewTests(unittest.TestCase):
    def test_builds_title_and_ordered_body(self):
        content = parse_review(review(low="- Low detail.", high="- High detail."))
        self.assertEqual(content.title, "Prepare API")
        self.assertEqual(
            content.body,
            "## summary\n\nAdds the API preparation workflow.\n\n"
            "### Why\n\nMake releases repeatable.\n\n"
            "## Findings\n\n### LOW\n\n- Low detail.\n\n"
            "### MEDIUM\n\nNone.\n\n### HIGH\n\n- High detail.",
        )
        self.assertNotIn("Review Limitations", content.body)

    def test_ignores_heading_examples_in_fenced_code(self):
        text = review(summary="Adds validation.\n\n```markdown\n## Title\nFake\n```")
        self.assertEqual(parse_review(text).title, "Prepare API")

    def test_rejects_missing_duplicate_empty_and_misnested_sections(self):
        invalid_reports = (
            review().replace("## Title\n\nPrepare API\n\n", ""),
            review() + "\n## Title\n\nDuplicate\n",
            review(title=""),
            review().replace("### Why", "## Why"),
            review().replace("### LOW", "### EXTRA\n\nNone.\n\n### LOW"),
            review().replace("### LOW\n\nNone.\n\n### MEDIUM", "### MEDIUM\n\nNone.\n\n### LOW"),
            review(summary=""),
            review(why=""),
            review(low=""),
        )
        for invalid in invalid_reports:
            with self.subTest(invalid=invalid):
                with self.assertRaises(ReviewFormatError):
                    parse_review(invalid)

    def test_rejects_multiline_title_and_unclosed_fence(self):
        with self.assertRaisesRegex(ReviewFormatError, "exactly one non-empty line"):
            parse_review(review(title="First line\nSecond line"))
        with self.assertRaisesRegex(ReviewFormatError, "Unclosed fenced"):
            parse_review(review() + "\n```\n")

    def test_loads_utf8_file_and_reports_read_errors(self):
        with TemporaryDirectory() as directory:
            report_path = Path(directory) / "REVIEW.md"
            report_path.write_text(review(title="Unicode title"), encoding="utf-8")
            self.assertEqual(load_review(report_path).title, "Unicode title")
            report_path.write_bytes(b"\xff")
            with self.assertRaisesRegex(ReviewFormatError, "Cannot read review"):
                load_review(report_path)
            with self.assertRaisesRegex(ReviewFormatError, "Cannot read review"):
                load_review(Path(directory) / "missing.md")


class CreatePullRequestTests(unittest.TestCase):
    @patch("create_pr.subprocess.run")
    def test_passes_title_and_body_as_literal_arguments(self, run):
        content = PullRequestContent("Fix 'quotes'; $(command)", "## summary\n\nBody `text`")
        run.return_value = subprocess.CompletedProcess([], 0, "https://github.com/example/repo/pull/1\n", "")

        result = create_pull_request(content)

        self.assertEqual(result.returncode, 0)
        run.assert_called_once_with(
            [
                "gh",
                "pr",
                "create",
                "--base",
                "main",
                "--title",
                "Fix 'quotes'; $(command)",
                "--body",
                "## summary\n\nBody `text`",
            ],
            capture_output=True,
            text=True,
            check=False,
        )


if __name__ == "__main__":
    unittest.main()
