import argparse
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from urllib.parse import unquote

EXPECTED_SECTIONS = ("LOW", "MEDIUM", "HIGH", "Review Limitations", "summary")


@dataclass
class ValidationResult:
    errors: list[str] = field(default_factory=list)
    summary_words: int = 0
    why_words: int = 0
    checked_links: int = 0


def validate_review(report_path: str | Path = "REVIEW.md") -> ValidationResult:
    result = ValidationResult()
    report_path = Path(report_path)
    try:
        report = report_path.read_text(encoding="utf-8")
        root = report_path.absolute().parent.resolve(strict=True)
    except (OSError, ValueError, RuntimeError) as error:
        result.errors.append(f"Cannot read report: {error}")
        return result

    lines = report.split("\n")
    headings: list[tuple[int, str, int]] = []
    visible_lines: list[str] = []
    fence = None
    for index, line in enumerate(lines):
        marker = re.match(r"^ {0,3}(`{3,}|~{3,})", line)
        if fence is not None:
            if marker and marker[1][0] == fence[0] and len(marker[1]) >= len(fence) and line.strip() == marker[1]:
                fence = None
            visible_lines.append("")
            continue
        if marker:
            fence = marker[1]
            visible_lines.append("")
            continue
        heading = re.fullmatch(r"(#{1,6}) (.+?)\s*", line)
        if heading:
            headings.append((len(heading[1]), heading[2], index))
        visible_lines.append(line)
    if fence is not None:
        result.errors.append("Unclosed fenced code block.")

    expected_headings = [(1, "Change Review")]
    expected_headings.extend((2, title) for title in EXPECTED_SECTIONS)
    expected_headings.append((3, "Why"))
    if [(level, title) for level, title, _ in headings] != expected_headings:
        result.errors.append(
            "Expected headings: # Change Review; ## LOW; ## MEDIUM; ## HIGH; ## Review Limitations; ## summary; ### Why, in that order."
        )

    summary_index = next(
        (index for level, title, index in headings if (level, title) == (2, "summary")),
        None,
    )
    why_index = next(
        (index for level, title, index in headings if (level, title) == (3, "Why")),
        None,
    )
    if summary_index is not None and why_index is not None and summary_index < why_index:
        result.summary_words = len("\n".join(lines[summary_index + 1 : why_index]).split())
    if why_index is not None:
        result.why_words = len("\n".join(lines[why_index + 1 :]).split())
    if not 1 <= result.summary_words <= 50:
        result.errors.append(f"summary must contain 1-50 words; found {result.summary_words}.")
    if not 1 <= result.why_words <= 30:
        result.errors.append(f"Why must contain 1-30 words; found {result.why_words}.")

    location_lines: set[int] = set()
    for index, line in enumerate(visible_lines):
        if re.search(r"\[[^\]\n]+\]\[[^\]\n]*\]", line):
            result.errors.append(f"Line {index + 1}: use inline links, not reference-style links.")
        links = list(re.finditer(r"(?<!!)\[[^\]\n]+\]\((<[^>\n]+>|[^\s()]+)\)", line))
        link_starts = list(re.finditer(r"(?<!!)\[[^\]\n]+\]\(", line))
        if len(links) != len(link_starts):
            result.errors.append(
                f"Line {index + 1}: malformed or unsupported inline link; use a plain or angle-bracket destination without a title."
            )
        for match in links:
            target = re.sub(r"^<|>$", "", match[1])
            if re.match(r"(?:https?:|mailto:|//)", target, re.IGNORECASE):
                continue
            file_part, separator, anchor = target.partition("#")
            try:
                if re.search(r"%(?![0-9a-fA-F]{2})", file_part):
                    raise ValueError("invalid percent-encoded path")
                decoded_path = unquote(file_part, errors="strict")
                if not decoded_path or Path(decoded_path).is_absolute() or re.match(r"[a-z][a-z\d+.-]*:", decoded_path, re.IGNORECASE):
                    raise ValueError("expected a relative file path")
                resolved_path = (root / decoded_path).resolve(strict=True)
                if not resolved_path.is_relative_to(root):
                    raise ValueError("linked file is outside the report directory")
                if not resolved_path.is_file():
                    raise ValueError("target is not a file")
                if separator:
                    location = re.fullmatch(r"L([1-9][0-9]*)(?:-L([1-9][0-9]*))?", anchor)
                    if not location:
                        raise ValueError("expected #L<number> or #L<start>-L<end>")
                    content = resolved_path.read_text(encoding="utf-8")
                    line_count = len(content.split("\n")) - int(content.endswith("\n")) if content else 0
                    start = int(location[1])
                    end = int(location[2] or location[1])
                    if start > end or end > line_count:
                        raise ValueError(f"line range exceeds {line_count} lines or is reversed")
                    location_lines.add(index)
                result.checked_links += 1
            except (OSError, ValueError, RuntimeError) as error:
                result.errors.append(f"Line {index + 1}: invalid link {target}: {error}")

    for severity in EXPECTED_SECTIONS[:3]:
        heading_index = next(
            (index for index, (level, title, _) in enumerate(headings) if (level, title) == (2, severity)),
            None,
        )
        if heading_index is None:
            continue
        start = headings[heading_index][2] + 1
        end = headings[heading_index + 1][2] if heading_index + 1 < len(headings) else len(lines)
        if "\n".join(visible_lines[start:end]).strip() == "None.":
            continue
        finding_starts = [index for index in range(start, end) if re.match(r"^- \*\*[^*]+\*\*:", visible_lines[index])]
        if not finding_starts:
            result.errors.append(f"{severity}: expected findings in '- **Title**: description' format or 'None.'.")
        else:
            finding_started = False
            for index in range(start, end):
                line = visible_lines[index]
                if index in finding_starts:
                    finding_started = True
                elif line.strip() and not (finding_started and line.startswith(("  ", "\t"))):
                    result.errors.append(
                        f"Line {index + 1}: unexpected content in {severity}; use '- **Title**: description' or indent a continuation."
                    )
        for finding_index, finding_start in enumerate(finding_starts):
            finding_end = finding_starts[finding_index + 1] if finding_index + 1 < len(finding_starts) else end
            if not any(finding_start <= index < finding_end for index in location_lines):
                result.errors.append(f"Line {finding_start + 1}: each finding needs a valid local file link with a line anchor.")

    return result


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate a generated review report without modifying files.")
    parser.add_argument("report_path", nargs="?", default="REVIEW.md", help="Report path (default: REVIEW.md)")
    args = parser.parse_args()
    result = validate_review(args.report_path)
    if result.errors:
        for error in result.errors:
            print(f"FAIL: {error}", file=sys.stderr)
        return 1
    print(
        f"PASS: headings and severity order; summary {result.summary_words}/50 words; "
        f"Why {result.why_words}/30 words; {result.checked_links} local links checked."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
