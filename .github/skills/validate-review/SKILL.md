---
name: validate-review
description: "Use when validating a generated REVIEW.md report: check headings, LOW/MEDIUM/HIGH order, summary and Why word limits, and local file links with line numbers."
argument-hint: "Optional path to REVIEW.md"
---

# Validate Review

Use the reusable [validator](./scripts/validate_review.py), not custom inline scripts. Requires Python 3.10 or newer and only its standard library. No pip packages, virtual environment, or Node.js installation are needed.

## Procedure

1. From the repository root, run:

   ```sh
   python3 .github/skills/validate-review/scripts/validate_review.py
   ```

   The default report is `REVIEW.md`. For another report, append its quoted path as the sole argument. Links resolve relative to that report's directory.

2. Read the result. Exit 0 means all structural checks passed; exit 1 means validation failed and lists the problems; exit 2 means invalid command-line arguments. A missing report is a failure, not an empty review.
3. Report failures precisely. Only correct the report if the user's task authorizes edits, then rerun the same command. Do not edit reviewed source files or invent findings to satisfy validation.

## Contract

- Requires `# Change Review`, followed by `## LOW`, `## MEDIUM`, `## HIGH`, `## Review Limitations`, `## summary`, and `### Why`, in that order without additional headings. Fenced code does not count as headings or links.
- Counts whitespace-separated words: summary must contain 1-50 words, excluding Why; Why must contain 1-30 words. Keep both as plain prose.
- Findings use `- **Title**: description`; empty severity categories use `None.`. Each finding needs an inline local file link with a valid line anchor.
- Supports inline links such as `[file:42](lib/file.dart#L42)`, line ranges, percent-encoded filenames, and angle-bracket destinations for paths containing spaces. Use this report format, not reference-style links or titled link destinations.
- Checks local targets are files within the report directory tree, including symlink resolution. Anchors must be `#L<number>` or `#L<start>-L<end>` and within actual file lines. A trailing newline does not create an extra line.
- External HTTP(S) and mail links are not fetched and do not satisfy a finding's code-location requirement.
- Reads files only; no Git commands, network access, writes, or code execution from report content. It validates structure, not finding accuracy or whether a linked line supports a finding.
- Use the stable command above. Do not replace it with `python3 -c`, shell wrappers, or one-off validation scripts. Approval remains controlled by the editor's permissions; this skill does not bypass it.

## Testing the Validator

Run the bundled standard-library tests when changing the validator, not for every report:

```sh
python3 -B .github/skills/validate-review/scripts/test_validate_review.py
```

The tests use temporary fixtures outside the repository. `-B` prevents Python bytecode cache files from being created.
