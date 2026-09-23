# In-App Shopping List

Source: [description.md](description.md). Implementation: [steps1.md](steps1.md).

Planning date: 2026-09-23. This pair supersedes the Google Keep design in
[plan.md](plan.md) and [steps.md](steps.md), which remain unchanged as history.
Requirement IDs below apply to this revised scope. Planning only; no application
code has been changed and no implementation steps have been completed.

## Goal And Scope

Add recipe ingredients to a single shopping list inside the Android app. Provide
a Shopping list destination alongside Recipes and Meal plan. The revised feature
does not depend on Google Keep, network access, accounts, or a settings screen.

Proposed first-increment defaults: local persistence, check/uncheck and individual
removal, ingredient notes preserved, and duplicate additions allowed. No quantity
aggregation, unit conversion, serving scaling, manual item editing/creation,
multiple lists, sharing, synchronization, or bulk clearing.

## Requirements And Acceptance Criteria

| ID  | Requirement                  | Observable acceptance criterion                                                                                                                                                                                   | Steps         |
| --- | ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- |
| R1  | Recipe-detail action         | Each recipe detail screen exposes an accessible "Add to shopping list" button without an account setup prerequisite.                                                                                              | 5, 6          |
| R2  | Complete ingredient transfer | A successful press appends every ingredient in recipe order with name, supplied quantity/unit, and optional note preserved; new items are unchecked and existing items remain unchanged.                          | 1, 2, 5, 6    |
| R3  | In-app shopping list         | Main navigation opens a dedicated Shopping list view showing the saved entries; switching destinations preserves catalog search and meal-plan state.                                                              | 3, 4, 6       |
| R4  | Check purchased items        | Each entry can be checked and unchecked independently, including duplicate ingredients; state survives restart.                                                                                                   | 1, 2, 3, 4, 6 |
| R5  | Remove individual items      | A remove action deletes only the selected entry and remains deleted after restart. Other entries and their states remain unchanged.                                                                               | 2, 3, 4, 6    |
| R6  | Local persistence            | A new installation starts with an empty list. Contents, order, and checked states reload after app restart; failed writes do not discard the last saved list.                                                     | 1, 2, 3, 6    |
| R7  | Offline and account-free     | Reading and modifying the shopping list works without network access, Google credentials, or integration configuration.                                                                                           | 2, 3, 4, 5, 6 |
| R8  | Truthful interaction states  | Loading, empty, busy, and error states are represented. Success follows persistence; repeated taps during a save do not duplicate the batch. Read/write failure offers recovery without blocking recipe browsing. | 2, 3, 4, 5, 6 |

## Current Implementation

- [Ingredient model](../../lib/features/recipe_catalog/models/recipe.dart) stores
  name, optional quantity/unit, and optional note as strings. Preserve values
  such as "to taste" and fractions; no numeric migration is necessary.
- [Recipe details](../../lib/features/recipe_catalog/ui/recipe_detail_screen.dart)
  has a private ingredient formatter, but no shopping-list action. Its
  [tests](../../test/features/recipe_catalog/ui/recipe_detail_screen_test.dart)
  cover missing fields, optional notes, narrow layouts, and back navigation.
- [Catalog](../../lib/features/recipe_catalog/ui/recipe_catalog_screen.dart)
  creates the detail route. It must forward the new injected dependency.
- [Home](../../lib/app/cookbook_home_screen.dart) owns an IndexedStack and two
  navigation destinations using StatefulWidget/setState.
- [App startup](../../lib/main.dart) injects repositories using an application
  support directory. [Local meal-plan storage](../../lib/features/meal_planner/data/local_meal_plan_repository.dart)
  provides a concrete pattern for versioned JSON, serialized mutations,
  temporary-file replacement, and domain-specific storage errors.
- [Dependencies](../../pubspec.yaml) already include path_provider and uuid.
  No new package or state-management framework is needed for this design.

## Proposed Design

### Model And Formatting

Introduce a focused shopping-list feature with an immutable `ShoppingListItem`
containing a stable ID, an ingredient snapshot, and a checked flag. IDs distinguish
identical ingredients; do not use display text or list position as identity.
Store the ingredient data itself, not a reference that depends on a recipe's
continued existence. Keep list order explicit through array order.

Extract the existing ingredient formatter into a shared pure function used by
recipe details and shopping rows. Retain its trimming, missing-field behavior,
and parenthesized notes. Do not alter the recipe serialization format.

### Repository And Persistence

Add an injectable `ShoppingListRepository` with load, append-recipe-ingredients,
set-checked, and remove operations, plus a `LocalShoppingListRepository` following
the nearby meal-plan pattern. These are proposed components, not existing files.
Persist a versioned document in a separate `cookbook/shopping_list.json` inside
the app's support directory. Reuse uuid for IDs with an injected ID generator
in tests. Avoid introducing a database or generic persistence framework.

Append all ingredients in one read-modify-write operation. Serialize all
mutations through the same repository instance to avoid lost updates between
append, check, and remove. Write and flush a temporary file, then replace the
destination. Publish success only after the write completes; a failed operation
must not poison the queue for subsequent retries.

Treat a missing file as an empty list. Validate schema version, item identities,
ingredient fields, and checked flags. Corrupt or unsupported data is a load error,
not an empty list: never overwrite unreadable data through a later mutation.
Shopping-list failures must remain isolated from recipe and meal-plan use.

### Shared State And Navigation

Compose a single repository in app startup and pass it to the home shell. The
home state owns the current immutable list snapshot and loading/mutation/error
state. It loads once outside build, and passes state and asynchronous callbacks
to the Shopping list view and the add callback through Catalog to recipe details.

Use existing StatefulWidget/setState patterns. A shared callback for each
successful mutation refreshes the snapshot before returning, so an IndexedStack
child that was already built does not remain stale after a recipe addition.
Serialize the mutation-and-refresh UI flow as well, or otherwise discard stale
load responses. Distinguish a committed write followed by refresh failure from
a failed write; retry refresh, not append, in that situation.

Add a third Material navigation destination with a shopping-list icon and label.
Preserve the existing children and their state when switching destinations. Use
app-level dependency injection for tests; no mutable globals or new framework.

### Shopping List View

Render unframed list rows with a checkbox, wrapping ingredient text, and a delete
icon with tooltip and accessible label. Keep checked entries visible in their
original order, with a clear checked appearance. Use stable item keys so repeated
ingredients remain independently actionable.

Include a loading indicator, an empty-list state, and error/retry handling. Await
persistence for check/remove before committing visible state, or restore the old
state on failure. Serialize controls while a mutation is in flight. Preserve
the last confirmed list when reporting a recoverable failure; do not show stale
data as successfully modified. Support 320-dp layouts and 200% text scaling.

### Recipe-Detail Action

Place an icon-and-text add button near Ingredients. Adding requires no login,
chosen destination, or network. Await the injected add callback, disable repeat
presses while it is running, and show a success message only after saving.
Optionally expose navigation to the list through that message if it fits the
existing navigation contract; it is not required for this increment.

Capture the recipe's ingredients for one batch. A later deliberate press creates
new item IDs and another batch; there is no deduplication or aggregation. Report
storage failures and allow a deliberate retry when the write did not commit.
Guard mounted state after asynchronous work; navigating away must not abort a
valid local save or cause updates to a disposed route.

## Dependencies And Feasibility

The Google Keep API blockers are removed by the approved move to local storage.
No external authorization, cloud resource, API key, or network API is required.
The repository already has suitable storage, ID-generation, and navigation
patterns; reuse its current dependencies and Android application-support path.

No application changes or new dependency installations are authorized by this
planning document alone. Implement one approved step at a time. Device access is
needed for the final Android integration/manual checks, not for unit/widget tests.

## Validation Strategy

- Unit tests: formatting and model decoding; repository append/check/remove,
  ordered snapshots, restart restoration, missing/corrupt data, duplicate IDs,
  write failure, mutation ordering, and recovery after a failed operation.
- Widget tests: list loading/empty/error/busy states, independent duplicate rows,
  check/remove persistence outcomes, and recipe-add feedback without login.
- Extend [detail tests](../../test/features/recipe_catalog/ui/recipe_detail_screen_test.dart)
  and [home tests](../../test/app/cookbook_home_screen_test.dart) for add-then-switch
  freshness, preserved catalog/meal-plan state, and 320-dp/200% text layouts.
- Extend [integration tests](../../integration_test/app_test.dart) to exercise
  add, navigate, check, remove, and recreate repositories against a temporary
  support directory to establish persistence without depending on Google.
- After implementation, run focused tests, then
  `dart format --output=none --set-exit-if-changed lib test integration_test`,
  `make analyze`, `make test`, and
  `make integration-test DEVICE=<device-id>` from the repository root.
- Hot reload/restart a connected app after Dart changes and inspect runtime
  errors. Manually verify adding/checking/removing offline, full process restart,
  compact layout, and accessibility. Report unavailable checks explicitly.

Only planning-document checks are performed now; the tests above are future work.

## Assumptions And Open Questions

- Confirmed change: use an in-app shopping list instead of Google Keep.
- Proposed defaults, recorded in the description: one persisted list, check/uncheck
  and individual deletion, ingredient notes preserved, duplicate batches allowed,
  no automatic aggregation. Confirm or adjust before implementing affected steps.
- Android remains the target based on the existing app. Device-local storage
  does not promise multi-device sync, export, or recovery after uninstall.
- No blocking external dependencies remain for this design. Existing Keep plans
  are historical and must not be used as the current implementation checklist.
