# Shopping List: Second-Increment Steps

Source: [description.md](description.md), Second Increment. Design, defaults, and
acceptance criteria: [plan2.md](plan2.md).

Status: implemented and automatically verified on 2026-09-24. Steps 1-6 are
complete. Step 7 retains pending manual checks that cannot be inferred from
automated tests. Earlier plans and implementation records remain unchanged.

## 1. Complete Entries By Text And Group Them

- [x] Add text toggling and the collapsed bottom Completed section.

Requirements: I2-R1, I2-R2, I2-R7, I2-R8. Prerequisite: agree on plan2's section,
restoration-order, and expansion defaults; first-increment code is present.

Change: update [shopping view](../../lib/features/shopping_list/ui/shopping_list_screen.dart)
to derive active/completed groups from the existing saved snapshot. Reuse
setChecked for both checkbox and text, with distinct edit/remove/drag hit targets.
Keep one scrolling surface, a collapsed disclosure header/count below active
items, stable ID keys, and local expansion state retained across tab switches.
Unchecking restores the active row in canonical order. Distinguish a completely
empty list from a list containing only completed entries. Change the existing
tests that intentionally expected checked rows to stay in the active group.

Tests: extend [shopping widget tests](../../test/features/shopping_list/ui/shopping_list_screen_test.dart)
for one write per text/checkbox tap, independent duplicates, default collapse,
expansion, unchecking, checked-only/empty states, failed writes retaining groups,
busy controls, and no accidental toggle from another row action. Extend
[home tests](../../test/app/cookbook_home_screen_test.dart) for expansion/tab state.
Cover 320-dp width, 200% text, and accessible checked/expanded states.

Verification: `flutter test test/features/shopping_list test/app` and
`make analyze`. Complete when grouping follows confirmed saves and every entry
remains reachable without layout overflow or duplicate activation.

## 2. Persist And Expose Reordering

- [x] Allow entries to be reordered within their section.

Requirements: I2-R3, I2-R7, I2-R8. Prerequisite: step 1 and agreed ordering defaults.

Change: extend [repository contract](../../lib/features/shopping_list/data/shopping_list_repository.dart),
[local storage](../../lib/features/shopping_list/data/local_shopping_list_repository.dart),
[controller](../../lib/features/shopping_list/logic/shopping_list_controller.dart),
and [shared fake](../../test/features/shopping_list/fake_shopping_list_repository.dart)
with a serialized reorder operation. Validate a section's exact ID permutation
against current storage, replace only its positions in the canonical array,
and return the saved snapshot. Keep version-1 compatibility.

Use built-in Flutter reorderable widgets with drag handles, stable keys, and
scrolling during drag. Provide accessible Move up/Move down actions, disabled
at boundaries. Keep checked state unchanged, prohibit cross-section dragging,
and restore the saved order if persistence fails.

Tests: extend [repository tests](../../test/features/shopping_list/data/local_shopping_list_repository_test.dart)
for both sections, duplicates, invalid/missing/extra/stale IDs, caller-list mutation,
no-op order, preserved other-section positions, failed writes, queued add/remove,
and reload. Extend controller/widget tests for busy guards, up/down indexing,
first/last moves, drag versus tap, failed-save restoration, and expanded completed
reordering. Verify existing version-1 data loads without migration.

Verification: `flutter test test/features/shopping_list` and `make analyze`.
Complete when drag and accessible actions yield the same durable order without
changing identities, values, or section membership.

## 3. Edit Individual Shopping Entries

- [x] Add a persisted ingredient editor for active and completed entries.

Requirements: I2-R4, I2-R7, I2-R8. Prerequisites: steps 1-2; confirm editable fields.

Change: extend the repository/controller/fake with validated update-by-ID and,
if useful, the [item copy method](../../lib/features/shopping_list/models/shopping_list_item.dart)
to replace an ingredient without changing ID, order, or checked state. Add a
focused shopping editor under the existing shopping UI directory (proposed new
component) with name, quantity, unit, note, Save, and Cancel. Allow clearing
optional fields and arbitrary string units/quantities; require a nonblank name.
Use local drafts, not optimistic edits to shared state. Prevent double saves,
retain draft/error after failure, and guard disposal during async completion.

Tests: extend model/repository/controller tests for field replacement, whitespace,
fractions, nonnumeric quantities, cleared optional values, invalid/missing IDs,
independent duplicates, saved-state preservation, and fresh-instance restoration.
Extend shopping widget tests for active/completed edits, cancel/back, validation,
busy/error/retry, unrelated item and source-recipe preservation, keyboard insets,
and 320-dp/200% layout. Add an editor-only test file only if it avoids overloading
the existing focused view tests.

Verification: `flutter test test/features/shopping_list test/features/recipe_catalog`
and `make analyze`. Complete when only the selected saved item changes and
cancel/failure never discards its prior values.

## 4. Clear The Entire List

- [x] Add confirmed clearing of active and completed entries.

Requirements: I2-R6, I2-R7, I2-R8. Prerequisites: steps 1-3.

Change: add clear to the repository/controller/fake as one serialized, validated
empty-document write. Add a named list-level action with confirmation that
includes hidden completed entries and the total count. Disable it when busy,
not loaded, or completely empty; recheck on confirmation. Cancel/back does not
write. Publish empty state and reset expansion only after a successful save;
retain items and show an error on failure. Do not delete files to bypass validation.

Tests: repository/controller tests cover mixed/active-only/completed-only lists,
empty no-op behavior, failed writes, corrupt data protection, queued operations,
and empty restoration. Widget tests cover cancel, confirm, duplicate taps,
disabled availability, hidden completed removal, failed saves, and successful
addition after clearing. Verify recipes and meal assignments are unaffected.

Verification: `flutter test test/features/shopping_list test/app` and
`make analyze`. Complete when confirmation removes every shopping entry in one
durable operation and every nonconfirmed/failed action preserves saved data.

## 5. Resolve A Week Into One Ingredient Batch

- [x] Add pure, deterministic weekly ingredient collection.

Requirements: I2-R5, I2-R7. Prerequisite: confirm displayed-week, duplicate-meal,
and unavailable-recipe defaults. This logic does not depend on steps 1-4.

Change: add a small helper under meal-planner logic (proposed new file), using
existing assignment/recipe models and week-date helpers. Filter the captured
Monday-through-Sunday week; order by date, breakfast/lunch/dinner, then ingredient
position. Include repeated recipe occurrences independently, skip empty slots,
and preserve quantities/units/notes without scaling. Return no batch for an empty
week and an explicit unavailable-recipe result before any write if a planned
recipe cannot be resolved. Do not mutate assignments or recipes.

Tests: add a focused helper test beside existing meal-planner logic tests. Cover
shuffled assignments, all meal types, repeated recipes, empty slots/weeks,
outside-week assignments, Sunday/Monday and year/leap/DST boundaries, missing
recipes, and exact ingredient field/order preservation. Verify collection failure
cannot produce a partial batch suitable for submission.

Verification: `flutter test test/features/meal_planner/logic` and `make analyze`.
Complete when inputs fully determine one immutable ordered batch or a specific
non-success result, without storage or network dependencies.

## 6. Add The Planner Shopping Action

- [x] Append all meals in the displayed week through shared shopping state.

Requirements: I2-R5, I2-R7, I2-R8. Prerequisite: step 5; first-increment shared state.

Change: pass the shared append callback and observable busy availability from
[home](../../lib/app/cookbook_home_screen.dart) into the
[weekly planner](../../lib/features/meal_planner/ui/weekly_meal_planner_screen.dart).
Place an accessible icon-and-text button near the week controls. Gate it on a
successful nonempty week load, no pending meal mutations, and shopping availability.
Resolve the whole captured week before one batch append. Surface missing recipes
without partial writes, suppress overlapping taps, and report success only after
the existing repository confirms persistence. Keep retries deliberate.

Capture the week and batch before awaiting. Permit week navigation without
retargeting an in-flight save; feedback must identify the captured week and not
overwrite current planner state. Preserve recipe-detail addition, checked items,
tab state, and late-completion safety without adding another repository instance.

Tests: extend [planner tests](../../test/features/meal_planner/ui/weekly_meal_planner_screen_test.dart)
for week selection, fresh assignment changes, empty/loading/error states, missing
recipes, shared busy state, pending slot mutations, double taps, later duplicate
adds, failed save/retry, week switches during saves, and disposal. Extend home
tests for already-built shopping-tab freshness and existing recipe-add behavior.
Check action layout and labels at 320 dp and 200% text.

Verification: `flutter test test/features/meal_planner test/app test/features/recipe_catalog`
and `make analyze`. Complete when exactly the captured week's ingredients are
added once per successful press and no failed/partial operation reports success.

## 7. Verify The Complete Second Increment

- [ ] Add device workflow coverage and run acceptance/regression checks. Automated
      coverage and checks are complete; manual checks listed below remain pending.

Requirements: I2-R1 through I2-R8. Prerequisite: steps 1-6.

Change: extend [integration flow](../../integration_test/app_test.dart) using its
existing helpers and temporary application-support directory. Exercise recipe
and week additions, text completion, collapse/expand/restore, reorder, edit,
independent duplicates, and new app/repository instances loading exact saved
state. Clear while Completed is collapsed and verify a fresh instance is empty.
Retain recipe/meal-plan regressions and avoid the user's actual shopping data.

Verification after focused tests pass:

- `dart format --output=none --set-exit-if-changed lib test integration_test`
- `make analyze`
- `make test`
- `make integration-test DEVICE=<device-id>` on an unlocked Android test device.
- Hot reload/restart a connected development app and inspect runtime errors.
- Manually exercise a disposable list offline, including full process restart,
  hidden completed clearing, edit with keyboard open, long-list drag scrolling,
  TalkBack/keyboard actions, compact width, and large text.

Complete only with observed results; app/repository recreation in an integration
test is not a full OS process restart or manual accessibility pass. Record missing
device/manual checks as pending. Update this checklist and feature documentation
with actual outcomes, not assumed passes. Follow repository committed-diff review
and PR procedures when applicable; do not commit merely to enable review.

Observed automated results on 2026-09-24:

- Formatting check passed for `lib`, `test`, and `integration_test` (68 files).
- `make analyze` passed with no issues.
- `make test` passed 204 Flutter tests and 5 deployment-selector tests.
- `make integration-test DEVICE=emulator-5554` passed the expanded Android flow.
- A connected debug app hot-restarted successfully with no Flutter runtime errors.

Pending manual observations: a true OS process restart, offline interaction,
long-list drag scrolling, TalkBack and hardware-keyboard actions, and manual
compact-width/large-text inspection. Automated tests cover app/repository
recreation, keyboard-open editing, 320-dp width, and 200% text scaling, but those
are not substitutes for the listed manual checks.
