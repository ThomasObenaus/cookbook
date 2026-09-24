# Shopping List: Second Increment

Source: [description.md](description.md), Second Increment. Implementation:
[steps2.md](steps2.md). Planning date: 2026-09-23.

Status: implemented and automatically verified on 2026-09-24. This document is
retained as the design record for the second increment; observed results and
remaining manual checks are recorded in [steps2.md](steps2.md).

## Goal And Scope

Make the local shopping list easier to maintain: complete entries by tapping
their text, group completed entries in a collapsed section at the bottom,
reorder and edit entries, add ingredients from the displayed meal-planner week,
and clear the entire list.

Preserve offline storage, independent duplicate entries, recipe-detail addition,
and existing recipe/planner navigation. No accounts, synchronization, multiple
lists, manual creation of new entries, ingredient aggregation, unit conversion,
serving scaling, or undo/history is included.

## Requirements And Acceptance Criteria

IDs are scoped to this increment; first-increment IDs remain unchanged.

| ID    | Requirement                  | Observable acceptance criterion                                                                                                                                                                                     | Steps   |
| ----- | ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| I2-R1 | Tap text to complete         | Tapping an active entry's text or checkbox performs one persisted check operation; edit, remove, and drag controls do not also toggle it.                                                                           | 1, 7    |
| I2-R2 | Completed section            | Checked entries leave the active group only after saving and appear in an expandable Completed section after all active entries. It starts collapsed; expanded entries can be unchecked back into the active group. | 1, 7    |
| I2-R3 | Reorder entries              | Users can move entries within either section, including identical-looking entries. The saved order survives reload; moving an entry preserves its values and checked flag.                                          | 2, 7    |
| I2-R4 | Edit entries                 | Users can change name, quantity, unit, and note for one active or completed entry. Save preserves its ID, order, and checked flag; cancel or failure leaves the saved item unchanged.                               | 3, 7    |
| I2-R5 | Add planned week             | A planner button appends every ingredient for every meal occurrence in the displayed week as one saved, unchecked batch, preserving existing shopping entries. No ingredient from another week is included.         | 5, 6, 7 |
| I2-R6 | Clear entire list            | A confirmed clear removes all active and completed entries, including hidden completed entries. Cancel changes nothing; an empty list remains empty after restart.                                                  | 4, 7    |
| I2-R7 | Durable, truthful operations | All new mutations work offline and publish success only after persistence. Failed writes retain the last saved state, corrupt data is not overwritten, and overlapping actions cannot lose updates.                 | 1-7     |
| I2-R8 | Accessible, compatible UI    | Touch, keyboard, and screen-reader actions are named and usable. Controls fit at 320-dp width and 200% text scale; existing recipe addition and tab/week state continue to work.                                    | 1-7     |

## Planning Baseline

- [Shopping list view](../../lib/features/shopping_list/ui/shopping_list_screen.dart)
  renders a flat list. Only the checkbox toggles completion; checked items stay
  in place. Each row has a remove icon; there is no edit, reorder, or clear action.
- [Shopping item](../../lib/features/shopping_list/models/shopping_list_item.dart)
  stores ID, immutable ingredient data, and checked state. Its current copy method
  changes only the checked flag. The [ingredient model](../../lib/features/recipe_catalog/models/recipe.dart)
  supports string quantities and units, optional notes, and validated parsing.
- [Local storage](../../lib/features/shopping_list/data/local_shopping_list_repository.dart)
  persists version-1 JSON with ordered items. It serializes mutations, validates
  data, replaces a flushed temporary file, and returns confirmed saved snapshots.
- [Controller](../../lib/features/shopping_list/logic/shopping_list_controller.dart)
  exposes load, append, check, and remove through a busy-guarded operation runner.
  [Home](../../lib/app/cookbook_home_screen.dart) owns its lifecycle and shares
  additions with recipe details. Keep this single state owner.
- [Weekly planner](../../lib/features/meal_planner/ui/weekly_meal_planner_screen.dart)
  owns the displayed week, loaded assignments, recipe lookup, loading generation,
  and pending slot mutations. Assignments are not necessarily in display order.
  It currently has no shopping-list action.
- [Meal types](../../lib/features/meal_planner/models/meal_type.dart) define
  breakfast/lunch/dinner order. Existing week/date helpers use local calendar
  dates and should remain the source of week boundaries.
- Existing shopping, planner, home, and integration tests provide fakes,
  temporary storage, narrow-layout coverage, and cross-screen test helpers.

## Proposed Design

### Completion And Sections

Derive active and completed groups from the controller's one saved item array;
do not maintain separate mutable lists or move data between files. Keep each
group in stored order. Checking changes only the checked flag; successful state
publication moves the row between the derived groups.

Make the text area and checkbox invoke the same toggle handler. Use nonoverlapping
tap targets so a checkbox tap runs once and edit/remove/drag never toggle. Expose
checked state and the ingredient label accessibly without duplicate actions.

Use one vertical scrolling surface with active entries followed by a Material
Completed disclosure header and count. It is initially collapsed, hidden when
there are no completed entries, and never auto-expands on checking. Keep expansion
as widget-local state across tab switches, reset it after clearing/no completed
items, and start collapsed after app recreation. Do not persist expansion state.
When only completed items remain, keep that header reachable; do not show the
whole-list-empty message. Expanded completed text/checkbox toggles back to active.

### Ordering And Storage Compatibility

Retain the version-1 document and use its array order as the canonical order.
No new rank field or migration is needed. Checking/unchecking retains canonical
position, so restoration uses the saved position rather than completion time.

Propose a repository operation accepting a checked-status group and its ordered
item IDs. Validate an exact permutation of that group's current IDs: reject
duplicates, missing/unknown IDs, or IDs from the other group. Replace only that
group's positions in the canonical array, preserving the other group's order.
Capture caller input before awaiting the mutation queue. A stale order request
fails without dropping newly added entries or resurrecting deleted ones.

Use Flutter's built-in reorderable list/sliver facilities with stable ID keys
and explicit drag handles, including scrolling during a drag. Map positions
against the displayed group, never the full filtered array. Provide named
Move up/Move down actions for keyboard and assistive use; boundary moves are
disabled. No cross-section dragging: checking controls section membership.
Keep long text wrapping with reachable edit/remove/reorder controls at compact
widths. Show only saved order after success; if drag feedback temporarily changes
visual order, restore the last confirmed order on failure.

### Editing

Add a row edit icon opening a focused Material form for name, quantity, unit, and
note, including completed entries. A shopping-specific editor is a proposed new
component, not an existing file. Name must be nonblank after trimming; optional
fields can be cleared. Preserve fractions, nonnumeric quantities such as
"to taste", and arbitrary existing units rather than forcing a numeric field or
the recipe creator's unit enum. Edit a draft, never the live item.

Extend the repository/controller with update-by-ID using a replacement Ingredient.
Validate at the storage boundary; preserve ID, checked status, and position, and
do not edit the original recipe or other duplicates. Missing IDs fail rather than
creating new entries. Keep the draft and actionable error on failure; close only
on successful save or cancellation. Disable duplicate saves and dismissal while
saving; guard mounted state if the owner is otherwise disposed.

### Clear All

Provide a named Clear shopping list action with a Material icon and a confirmation
dialog explicitly including active and completed entries and their total count.
Disable it during loading/mutations and when the entire list is empty. Cancel or
back closes the dialog without writing. Recheck availability when confirming.

Implement clear as one serialized, validated write of an empty version-1 document,
not repeated per-item removals or an unconditional file deletion. Retain existing
corrupt-data protection; data repair/reset is not part of this feature. Publish
empty state and collapse Completed only after saving. Surface failure and allow
a deliberate retry without claiming the list was cleared.

### Add The Displayed Week

Add an icon-and-text button near the planner's week controls, outside the day
list so it stays reachable. Forward the home-owned append callback to the planner;
do not construct another shopping repository. Observe shared shopping busy state
for button availability without recreating the planner or resetting its week.

Introduce a small pure meal-planner helper (proposed) that receives the captured
week start, assignments, and recipe lookup and returns an ingredient batch or
a specific unavailable-recipe result. Iterate local dates Monday through Sunday,
then breakfast/lunch/dinner, then each recipe's ingredient order. Ignore empty
slots and exclude assignments outside that week. Repeated recipe assignments
contribute ingredients once per meal occurrence; do not deduplicate or scale.

Enable the button only after a successful week load, with at least one planned
meal, no pending slot save/removal, and no shopping operation in progress. If any
planned recipe cannot be resolved, block the whole add with an accessible error
identifying the unavailable meal; do not silently add a partial week. Existing
change/remove meal actions allow correction. Prevent a zero-ingredient snapshot
from reporting a successful addition.

Capture the visible week and immutable ingredient batch before the async save.
Append once using existing atomic batch storage, guard repeat taps, and show
success only after persistence. A later deliberate press appends a new batch.
If week navigation occurs during saving, the operation still belongs to the
captured week; feedback identifies that week and does not overwrite the newly
loaded planner state. Navigating away cannot cancel a committed save or update
a disposed widget. Failure permits retry but never automatically re-appends.

## Dependencies And Feasibility

All behavior is local and can use current Flutter Material widgets, repositories,
date helpers, and installed packages. No cloud service, permissions, package
installation, or state-management framework is needed. Extend the existing
repository interface, controller, and shared fake together for each new operation.
Do not refactor unrelated recipe creation or meal-plan persistence.

## Validation Strategy

- Extend existing model/repository/controller tests for edit, section reordering,
  clear, invalid/stale IDs, immutable inputs, failure recovery, overlapping writes,
  old version-1 data, and fresh-instance restoration of values/order/checked state.
- Extend shopping widget tests for text/checkbox hit targets, default collapse,
  expansion, unchecking, completed-only state, edit/cancel/error, drag and accessible
  moves, destructive confirmation, hidden-item clearing, and narrow large text.
- Add focused tests beside existing meal-planner logic tests for batch resolution:
  shuffled assignments, week boundaries, repeated recipes, missing recipes, and
  exact ingredient values/order. Extend planner/home tests for loading/busy/error,
  double taps, week changes during save, disposal, and shopping-tab freshness.
- Extend the temporary-directory Android integration flow to cover both recipe
  and week additions, grouping, reorder/edit, restoration, clear, and empty reload.
  Never use the user's saved list for automated test mutations.
- After focused tests: formatting check, `make analyze`, `make test`, and
  `make integration-test DEVICE=<device-id>`. Hot reload/restart a connected app
  and inspect runtime errors. Commands and completion conditions are in steps2.
- Manually verify offline behavior, full process restart, long-list drag scrolling,
  keyboard/TalkBack access, compact width, and large text with disposable data.
  Report unavailable checks as pending. No tests were run for this planning task.

## Assumptions And Open Questions

These are proposed defaults, not additional user-confirmed requirements:

- Reordering is allowed within both active and completed sections, not across
  them. Restored items follow canonical saved order, not completion chronology.
- Completed entries can be unchecked, edited, reordered, and removed when expanded.
  Expansion is session-only; the header is omitted when its count is zero.
- Editing covers all ingredient text fields, including clearing optional values,
  but does not create new entries or change source recipes.
- "The week" means the displayed week, not necessarily today's week. Each planned
  occurrence counts, with no serving adjustment or merging.
- An unavailable planned recipe blocks the entire weekly add rather than silently
  skipping it. Empty weeks do not trigger writes.
- Clearing requires confirmation and includes hidden completed entries; no undo
  or destructive recovery of corrupt storage is included.

No external feasibility blocker remained. The implementation follows these
interaction defaults.
