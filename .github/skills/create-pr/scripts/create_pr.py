import argparse
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

SEVERITIES = ("LOW", "MEDIUM", "HIGH")


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


def load_review(report_path: str | Path) -> PullRequestContent:
    try:
        report = Path(report_path).read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        raise ReviewFormatError(f"Cannot read review: {error}") from error
    return parse_review(report)


def create_pull_request(content: PullRequestContent) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["gh", "pr", "create", "--base", "main", "--title", content.title, "--body", content.body],
        capture_output=True,
        text=True,
        check=False,
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Create a GitHub pull request from a structured REVIEW.md file.")
    parser.add_argument("review_path", help="Path to the REVIEW.md file")
    args = parser.parse_args()
    try:
        content = load_review(args.review_path)
        result = create_pull_request(content)
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
