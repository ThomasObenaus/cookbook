---
name: plan-feature
description: "Create a feature plan and ordered implementation steps from a feature folder's description.md without overwriting earlier plans."
argument-hint: "<feature-folder> (for example: .features/add_to_shopping_list)"
agent: agent
---

Create planning documents for the feature folder provided by the user. This is a
planning-only task: do not implement the feature, modify application code, install
dependencies, commit changes, or create a pull request.

## Input And Scope

1. Resolve the feature folder from the user's arguments or an explicitly attached
   feature description. If no folder is supplied or the target is ambiguous, ask
   the user for the folder before proceeding.
2. Read `description.md` in that folder in full. If it is missing or empty, ask the
   user to supply it; do not invent requirements or create a replacement.
3. Follow applicable repository instructions. Inspect only the nearby code,
   tests, configuration, and documentation needed to ground the plan in the
   existing application. Do not treat existing implementations as assumptions.
4. Cover every requirement in the requested increment. Separate later increments
   and explicit non-goals; do not silently expand the scope.
5. Verify external service capabilities, authentication constraints, and platform
   support against official documentation when they determine feasibility.
   Cite supporting sources. Distinguish verified facts from assumptions and
   unresolved questions. Never present an unsupported integration as feasible.
6. Ask about decisions that block a useful plan. Record non-blocking assumptions
   and open questions explicitly. Do not silently substitute another service or
   change a requirement; mark blocked work and describe alternatives for approval.

## Choose A New Output Pair

Keep both documents directly in the provided feature folder. Inspect existing
entries, including earlier plans and steps, before choosing filenames. Earlier
documents are context only and must remain unchanged.

- If neither `plan.md` nor `steps.md` exists, use that pair.
- If either exists, choose the smallest positive integer `N` for which neither
  `planN.md` nor `stepsN.md` exists, starting at `1`.
- Always use a matched pair with the same suffix. Treat any existing filesystem
  entry at either path as occupied, even if the other member is missing.
- Recheck both paths immediately before creating the documents. If either has
  become occupied, select another free pair. Never overwrite, append to, rename,
  or delete an existing file, and never update an old plan in place.

Examples: an empty folder gets `plan.md` and `steps.md`; a folder containing only
`plan.md` gets `plan1.md` and `steps1.md`; if `steps1.md` also exists, it gets
`plan2.md` and `steps2.md` (provided both are free).

## Plan Document

Write a concise, actionable plan using these sections:

- **Goal And Scope**: intended outcome, requested increment, and non-goals.
- **Requirements And Acceptance Criteria**: assign stable requirement IDs such
  as `R1`; give observable criteria for each requirement.
- **Current Implementation**: relevant existing behavior and reusable code, with
  links to verified local files. Clearly label proposed files that do not exist.
- **Proposed Design**: affected components, data flow, state and persistence,
  user-facing behavior, failure states, and security considerations as applicable.
- **Dependencies And Feasibility**: external capabilities, setup prerequisites,
  verified constraints, supporting sources, and any blockers.
- **Validation Strategy**: focused tests, relevant repository checks, and manual
  checks needed to demonstrate acceptance criteria.
- **Assumptions And Open Questions**: unresolved decisions, risks, and approval
  needed before implementation. Use `None` when there are none.

Link to `description.md` and the newly selected steps document using relative
Markdown links. Do not include unrelated cleanup or speculative extra features.

## Steps Document

Link back to the newly selected plan document, not a previous version. Write an
ordered checklist of small implementation steps that follow dependency order.
Each step must contain:

- An unchecked checkbox and a clear, action-oriented title.
- The requirement IDs covered and any prerequisite steps or external setup.
- The specific change and the files or components expected to be affected.
- Focused tests to add or update, including relevant failure cases.
- Verification commands grounded in the repository, or explicit manual checks
  when automation is unavailable, with an observable completion condition.

Keep each step focused on one cohesive change. Mark steps blocked by unresolved
decisions as blocked and name their prerequisites. Do not mark any implementation
step complete merely because its plan has been written.

## Final Check And Response

Verify that every in-scope requirement maps to at least one step and acceptance
criterion, dependencies are ordered, both documents use the selected filenames,
their relative links resolve, and existing files remain unchanged. Do not claim
that planned tests have run or that the feature has been implemented.

Finish with links to the two created documents, a brief scope summary, and any
blocking questions or prerequisites. Stop after planning.
