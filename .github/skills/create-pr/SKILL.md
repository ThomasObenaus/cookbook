---
name: create-pr
description: "Use when explicitly asked to create, open, or submit a GitHub pull request from a structured REVIEW.md file for the current branch's committed changes against main."
argument-hint: "Path to REVIEW.md"
user-invocable: true
disable-model-invocation: true
---

# Create GitHub Pull Request

Create one ready-for-review GitHub pull request from the current branch into `main`. Invoking this skill with a review file authorizes that external action.

## Inputs

- Review file path: Required path to a UTF-8 Markdown file.

If the path is missing or ambiguous, ask for it before running the command. Do not choose a review file implicitly.

The review must contain exactly one of each required heading:

```markdown
## Title

<one non-empty line>

## summary

<non-empty summary>
### Why
<non-empty rationale>

## Findings

### LOW

<findings or None.>
### MEDIUM
<findings or None.>
### HIGH
<findings or None.>
```

`Why` must be a subsection of `summary`. The severity subsections must appear under `Findings` in LOW, MEDIUM, HIGH order. Other sections, including review limitations, are not copied into the pull request.

## Preconditions

- Use the repository provided by the workspace or active file. If it is ambiguous, ask which repository to use.
- The current branch must contain the intended commits and already be published to a GitHub remote.
- Python 3.10 or newer must be available; no Python packages are required.
- GitHub CLI must be installed and authenticated with permission to create pull requests.
- Complete any required implementation, tests, and review before invoking this skill. The script reads but does not modify the supplied review file.

## Procedure

1. Substitute the quoted review path and run only this command from the repository:

   ```sh
   python3 -B .github/skills/create-pr/scripts/create_pr.py '<path-to-REVIEW.md>'
   ```

   Do not wrap, chain, redirect, or extend the command. Do not run discovery or setup commands first.

2. The script validates and extracts the report without invoking a shell:
   - PR title: the content under `## Title`.
   - PR body: `## summary`, then `### Why`, then `## Findings` with `### LOW`, `### MEDIUM`, and `### HIGH`.
   - GitHub command: `gh pr create --base main` with the extracted title and body passed as literal arguments.
3. If the command succeeds, report the pull request URL from its output.
4. If parsing fails, the command fails, or setup is missing, report its message and stop. Do not retry with other flags or commands.

## Boundaries

- Preserve the extracted section content; do not replace it with `--fill` or rewrite it.
- Create a ready-for-review pull request, not a draft.
- Do not commit, push, fetch, switch branches, alter remotes, or modify project files.
- Do not claim uncommitted changes are included. A pull request contains only commits available from its published head branch.
- Do not create another pull request when the command reports that one already exists.

## Testing the Skill

Run the parser and command-construction tests when changing this skill, not when creating a pull request:

```sh
python3 -B .github/skills/create-pr/scripts/test_create_pr.py
```
