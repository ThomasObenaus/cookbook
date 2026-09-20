import subprocess
import unittest
from contextlib import redirect_stderr
from io import StringIO
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import call, patch

from create_pr import PullRequestContent, ReviewFormatError, create_pull_request, load_review, parse_review, sync_pull_request


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
            with self.subTest(invalid=invalid), self.assertRaises(ReviewFormatError):
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
            with patch("create_pr.REVIEW_PATH", report_path):
                self.assertEqual(load_review().title, "Unicode title")
                report_path.write_bytes(b"\xff")
                with self.assertRaisesRegex(ReviewFormatError, "Cannot read repository-root REVIEW.md"):
                    load_review()

    def test_missing_root_review_stops_with_explicit_error(self):
        with TemporaryDirectory() as directory:
            missing_path = Path(directory) / "REVIEW.md"
            with (
                patch("create_pr.REVIEW_PATH", missing_path),
                self.assertRaisesRegex(ReviewFormatError, "REVIEW.md is missing from the repository root"),
            ):
                load_review()


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

    @patch("create_pr.create_pull_request")
    @patch("create_pr.load_review")
    def test_missing_review_does_not_call_github(self, load, create):
        load.side_effect = ReviewFormatError("REVIEW.md is missing from the repository root.")
        stderr = StringIO()

        with patch("create_pr.sys.argv", ["create_pr.py"]), redirect_stderr(stderr):
            self.assertEqual(__import__("create_pr").main(), 1)

        self.assertIn("FAIL: REVIEW.md is missing from the repository root.", stderr.getvalue())
        create.assert_not_called()

    @patch("create_pr.create_pull_request")
    def test_rejects_review_path_argument(self, create):
        stderr = StringIO()

        with (
            patch("create_pr.sys.argv", ["create_pr.py", "other/REVIEW.md"]),
            redirect_stderr(stderr),
            self.assertRaisesRegex(SystemExit, "2"),
        ):
            __import__("create_pr").main()

        self.assertIn("unrecognized arguments: other/REVIEW.md", stderr.getvalue())
        create.assert_not_called()


class SyncPullRequestTests(unittest.TestCase):
    @patch("create_pr.subprocess.run")
    def test_creates_pull_request_when_current_branch_has_none(self, run):
        content = PullRequestContent("Prepare API", "## summary\n\nNew body")
        run.side_effect = (
            subprocess.CompletedProcess([], 1, "", "no pull requests found"),
            subprocess.CompletedProcess([], 0, "https://github.com/example/repo/pull/1\n", ""),
        )

        result = sync_pull_request(content)

        self.assertEqual(result.returncode, 0)
        self.assertEqual(
            run.call_args_list,
            [
                call(
                    ["gh", "pr", "view", "--json", "body,url,baseRefName,state,number"],
                    capture_output=True,
                    text=True,
                    check=False,
                ),
                call(
                    [
                        "gh",
                        "pr",
                        "create",
                        "--base",
                        "main",
                        "--title",
                        "Prepare API",
                        "--body",
                        "## summary\n\nNew body",
                    ],
                    capture_output=True,
                    text=True,
                    check=False,
                ),
            ],
        )

    @patch("create_pr.subprocess.run")
    def test_stops_when_pull_request_lookup_fails(self, run):
        content = PullRequestContent("Prepare API", "## summary\n\nNew body")
        lookup_failure = subprocess.CompletedProcess([], 1, "", "HTTP 401: Bad credentials")
        run.return_value = lookup_failure

        result = sync_pull_request(content)

        self.assertIs(result, lookup_failure)
        run.assert_called_once_with(
            ["gh", "pr", "view", "--json", "body,url,baseRefName,state,number"],
            capture_output=True,
            text=True,
            check=False,
        )

    @patch("create_pr.subprocess.run")
    def test_leaves_matching_existing_body_unchanged(self, run):
        content = PullRequestContent("Prepare API", "## summary\n\nCurrent body")
        run.return_value = subprocess.CompletedProcess(
            [],
            0,
            '{"body":"## summary\\n\\nCurrent body","url":"https://github.com/example/repo/pull/1","baseRefName":"main","state":"OPEN","number":1}',
            "",
        )

        result = sync_pull_request(content)

        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "https://github.com/example/repo/pull/1\n")
        self.assertEqual(run.call_count, 1)

    @patch("create_pr.subprocess.run")
    def test_updates_existing_body_when_review_differs(self, run):
        content = PullRequestContent("Prepare API", "## summary\n\nUpdated body")
        url = "https://github.com/example/repo/pull/1"
        run.side_effect = (
            subprocess.CompletedProcess(
                [],
                0,
                f'{{"body":"Old body","url":"{url}","baseRefName":"main","state":"OPEN","number":1}}',
                "",
            ),
            subprocess.CompletedProcess([], 0, "", ""),
        )

        result = sync_pull_request(content)

        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, f"{url}\n")
        self.assertEqual(
            run.call_args_list[1],
            call(
                [
                    "gh",
                    "api",
                    "--method",
                    "PATCH",
                    "repos/{owner}/{repo}/pulls/1",
                    "--raw-field",
                    f"body={content.body}",
                    "--silent",
                ],
                capture_output=True,
                text=True,
                check=False,
            ),
        )


if __name__ == "__main__":
    unittest.main()
