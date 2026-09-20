# Repository Instructions

## Implementation Workflow

For implementation and bug-fix requests:

1. Implement the requested changes or feature. Implement at max only one change or feature at a time. Don't start automatically on multiple changes or features. Focus on one thing at a time. If you realize you need to make additional changes, which would exceed the current scope, then add them to the BACKLOG.md.
2. Add or update focused tests for the changed behavior.
3. Run the relevant tests and checks. Fix failures caused by the implementation and rerun them.
4. When the requested changes are included in the committed `main...HEAD` diff, load and follow the [review-change prompt](prompts/review-change.prompt.md).
5. Fix supported `HIGH` findings introduced by the requested changes, then rerun the affected tests and review until no supported `HIGH` findings remain.
6. Do not fix `LOW` or `MEDIUM` findings unless the user requests it or they block a required `HIGH` fix.

Do not commit changes solely to make the review step available. If the implementation is not included in the committed diff, state that the review prompt cannot inspect it and leave the review step pending.
