import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

SEVERITIES = ("LOW", "MEDIUM", "HIGH")
REVIEW_PATH = Path("REVIEW.md")


class ReviewFormatError(ValueError):
    pass


@dataclass(frozen=True)
class Heading:
    level: int
    title: str
    line: int


@dataclass(frozen=True)
class PullRequestContent:
    title: str
    body: str


def _parse_headings(lines: list[str]) -> list[Heading]:
    headings = []
    fence = None
    for index, line in enumerate(lines):
        marker = re.match(r"^ {0,3}(`{3,}|~{3,})", line)
        if fence is not None:
            if marker and marker[1][0] == fence[0] and len(marker[1]) >= len(fence) and line.strip() == marker[1]:
                fence = None
            continue
        if marker:
            fence = marker[1]
            continue
        match = re.fullmatch(r"(#{1,6}) (.+?)\s*", line)
        if match:
            headings.append(Heading(len(match[1]), match[2], index))
    if fence is not None:
        raise ReviewFormatError("Unclosed fenced code block.")
    return headings


def _single_heading(headings: list[Heading], level: int, title: str) -> Heading:
    matches = [heading for heading in headings if (heading.level, heading.title) == (level, title)]
    if len(matches) != 1:
        raise ReviewFormatError(f"Expected exactly one {'#' * level} {title} heading; found {len(matches)}.")
    return matches[0]


def _section_end(headings: list[Heading], heading: Heading) -> int:
    return next(
        (candidate.line for candidate in headings if candidate.line > heading.line and candidate.level <= heading.level),
        sys.maxsize,
    )


def _section_text(lines: list[str], start: int, end: int, label: str) -> str:
    text = "\n".join(lines[start:end]).strip()
    if not text:
        raise ReviewFormatError(f"{label} must not be empty.")
    return text


def parse_review(report: str) -> PullRequestContent:
    lines = report.splitlines()
    headings = _parse_headings(lines)
    title_heading = _single_heading(headings, 2, "Title")
    summary_heading = _single_heading(headings, 2, "summary")
    why_heading = _single_heading(headings, 3, "Why")
    findings_heading = _single_heading(headings, 2, "Findings")
    severity_headings = [_single_heading(headings, 3, severity) for severity in SEVERITIES]

    title_end = _section_end(headings, title_heading)
    title_lines = [line.strip() for line in lines[title_heading.line + 1 : title_end] if line.strip()]
    if len(title_lines) != 1:
        raise ReviewFormatError("## Title must contain exactly one non-empty line.")

    summary_end = _section_end(headings, summary_heading)
    summary_children = [heading.title for heading in headings if summary_heading.line < heading.line < summary_end and heading.level == 3]
    if summary_children != ["Why"]:
        raise ReviewFormatError("## summary must contain exactly one ### Why subsection.")
    summary = _section_text(lines, summary_heading.line + 1, why_heading.line, "## summary")
    why = _section_text(lines, why_heading.line + 1, summary_end, "### Why")

    findings_end = _section_end(headings, findings_heading)
    findings_children = [
        heading.title for heading in headings if findings_heading.line < heading.line < findings_end and heading.level == 3
    ]
    if findings_children != list(SEVERITIES):
        raise ReviewFormatError("## Findings must contain ### LOW, ### MEDIUM, and ### HIGH in that order.")

    body_parts = ["## summary", summary, "### Why", why, "## Findings"]
    for severity, heading in zip(SEVERITIES, severity_headings, strict=True):
        content = _section_text(lines, heading.line + 1, _section_end(headings, heading), f"### {severity}")
        body_parts.extend((f"### {severity}", content))

    return PullRequestContent(title=title_lines[0], body="\n\n".join(body_parts))


def load_review() -> PullRequestContent:
    try:
        report = REVIEW_PATH.read_text(encoding="utf-8")
    except FileNotFoundError as error:
        raise ReviewFormatError("REVIEW.md is missing from the repository root.") from error
    except (OSError, UnicodeError) as error:
        raise ReviewFormatError(f"Cannot read repository-root REVIEW.md: {error}") from error
    return parse_review(report)


def create_pull_request(content: PullRequestContent) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["gh", "pr", "create", "--base", "main", "--title", content.title, "--body", content.body],
        capture_output=True,
        text=True,
        check=False,
    )


def sync_pull_request(content: PullRequestContent) -> subprocess.CompletedProcess[str]:
    view_result = subprocess.run(
        ["gh", "pr", "view", "--json", "body,url,baseRefName,state,number"],
        capture_output=True,
        text=True,
        check=False,
    )
    if view_result.returncode != 0:
        return create_pull_request(content)

    try:
        pull_request = json.loads(view_result.stdout)
        body = pull_request["body"]
        url = pull_request["url"]
        base_ref_name = pull_request["baseRefName"]
        state = pull_request["state"]
        number = pull_request["number"]
        if not all(isinstance(value, str) for value in (body, url, base_ref_name, state)) or type(number) is not int or number < 1:
            raise TypeError
    except (json.JSONDecodeError, KeyError, TypeError) as error:
        raise ReviewFormatError("Cannot parse the current pull request returned by GitHub CLI.") from error

    if base_ref_name != "main" or state != "OPEN":
        return create_pull_request(content)
    if body == content.body:
        return subprocess.CompletedProcess(view_result.args, 0, f"{url}\n", "")

    edit_result = subprocess.run(
        [
            "gh",
            "api",
            "--method",
            "PATCH",
            f"repos/{{owner}}/{{repo}}/pulls/{number}",
            "--raw-field",
            f"body={content.body}",
            "--silent",
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    if edit_result.returncode == 0:
        return subprocess.CompletedProcess(edit_result.args, 0, f"{url}\n", edit_result.stderr)
    return edit_result


def main() -> int:
    parser = argparse.ArgumentParser(description="Create or synchronize a GitHub pull request from repository-root REVIEW.md.")
    parser.parse_args()
    try:
        content = load_review()
        result = sync_pull_request(content)
    except ReviewFormatError as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1
    except FileNotFoundError:
        print("FAIL: GitHub CLI executable 'gh' was not found.", file=sys.stderr)
        return 1

    if result.stdout:
        print(result.stdout, end="" if result.stdout.endswith("\n") else "\n")
    if result.stderr:
        print(result.stderr, end="" if result.stderr.endswith("\n") else "\n", file=sys.stderr)
    return result.returncode


if __name__ == "__main__":
    sys.exit(main())
