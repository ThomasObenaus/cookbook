# In-App Shopping List: Implementation Steps

Source: [description.md](description.md). Design and acceptance criteria:
[plan1.md](plan1.md). This checklist supersedes [steps.md](steps.md).

Implementation status: steps 1-5 and the automated portion of step 6 are complete.
The user's implementation request accepts the defaults in the description.
Remaining manual checks and committed-diff review are recorded below.

## Ordered Checklist

### 1. Define Shopping Items And Shared Formatting

- [x] Introduce immutable shopping items and reuse ingredient display formatting.

Requirements: R2, R4, R6. Prerequisites: confirm single-list, note-preservation,
and duplicate-handling defaults.

Change: add `ShoppingListItem` with stable ID, ingredient snapshot, checked flag,
and validated serialization. Extract the private formatter from
[recipe details](../../lib/features/recipe_catalog/ui/recipe_detail_screen.dart)
into a shared pure function without changing recipe data or displayed output.

Tests: add focused model/formatter tests under the corresponding feature test
directories. Cover round trips, missing/invalid fields, absent quantity/unit,
fractional/nonnumeric quantities, notes, whitespace, and independent duplicate
ingredients. Retain the existing detail rendering assertions.

Verification: `flutter test test/features/recipe_catalog` and
`flutter test test/features/shopping_list` after creating that test directory.
Complete when formatting is unchanged and item snapshots serialize without loss.

Completed 2026-09-23: immutable item snapshots, checked-state copies, validated
JSON serialization, and shared formatting are implemented. The combined command
`flutter test test/features/recipe_catalog test/features/shopping_list` passed
all 69 tests, and `make analyze` passed. Changed Dart files were formatted.
Hot reload was attempted after DTD discovery/connection, but no app was running.
Step 1 was subsequently committed and reviewed with no supported findings.
The remaining implementation below is not covered by that earlier review.

### 2. Persist Shopping-List Mutations

- [x] Implement the local shopping-list repository with serialized batch writes.

Requirements: R2, R4, R5, R6, R7, R8. Prerequisite: step 1.

Change: add the repository contract, local implementation, and typed storage
errors under the proposed shopping-list feature. Follow
[local meal-plan storage](../../lib/features/meal_planner/data/local_meal_plan_repository.dart)
for versioned JSON, serialized mutations, and temporary-file replacement. Inject
the application-support directory and ID generator. Support load, append a whole
recipe batch, set checked by ID, and remove by ID. Preserve existing item order
and state. Never replace corrupt data with an empty document.

Tests: temporary-directory repository tests cover missing files, multiple batches,
duplicate ingredients with distinct IDs, check/uncheck/removal, a fresh repository
instance reading saved data, corrupt/version-invalid documents, duplicate IDs,
write failures, concurrent mutations, and successful recovery after failure.
Verify failure leaves previously saved data intact and uses no network service.

Verification: `flutter test test/features/shopping_list` and `make analyze`.
Complete when every operation preserves unrelated items, one recipe adds in one
committed batch, and restart tests reproduce the exact saved list.

Completed 2026-09-23: the versioned local repository implements atomic batch
append, check/uncheck, and removal with serialized writes. Nine repository tests
passed, including corruption preservation, write failures, ordering, recovery,
and fresh-instance restoration. Mutations return their confirmed saved snapshot.

### 3. Compose Shared Shopping-List State

- [x] Inject one repository and coordinate home-owned list state and callbacks.

Requirements: R3, R4, R5, R6, R7, R8. Prerequisite: step 2.

Change: compose the repository in [app startup](../../lib/main.dart), pass it
through `CookbookApp` to [home](../../lib/app/cookbook_home_screen.dart), and add
home-owned snapshot/status state and async mutation callbacks. Load outside build,
guard lifecycle changes, and prevent stale refreshes or overlapping state updates.
Publish the confirmed snapshot returned by each committed write and keep shopping
errors isolated from other tabs. No second read follows a save, avoiding ambiguous
post-save refresh failures and duplicate append retries.

Tests: extend [home tests](../../test/app/cookbook_home_screen_test.dart) and
[startup/widget tests](../../test/widget_test.dart) with injected fakes. Cover
initial load, missing storage, load/write/refresh errors, disposal during work,
mutation ordering, and preserved recipe access. Update affected constructor call
sites and existing test doubles without changing unrelated behavior.

Verification: `flutter test test/app test/widget_test.dart` and `make analyze`.
Complete when one shared repository/state owner serves all intended actions and
failures do not prevent Cookbook startup or offline recipe browsing.

Completed 2026-09-23: startup injects the repository; home owns and disposes a
built-in ChangeNotifier controller. Six controller tests cover saved-only state,
load/write failures, busy guards, disposal, and no post-save reads. App tests
confirm shopping storage failure does not block recipe browsing.

### 4. Add The Shopping List View

- [x] Expose the persistent checklist as a third navigation destination.

Requirements: R3, R4, R5, R7, R8. Prerequisite: step 3.

Change: add the proposed `ShoppingListScreen` and a Shopping list destination in
[home navigation](../../lib/app/cookbook_home_screen.dart). Render stable-keyed rows
with ingredient text, checkboxes, and accessible remove icons. Keep checked items
visible in order. Connect check/remove callbacks and loading/empty/error/retry
states to the shared owner. Do not add login, settings, or another list selector.

Tests: focused shopping-list widget tests cover duplicate rows, check/uncheck,
single-item removal, busy controls, failures retaining the last saved state,
empty/loading/retry states, long text, 320-dp width, and 200% text scaling. Extend
home tests for switching tabs without resetting catalog or meal-plan state.

Verification: `flutter test test/features/shopping_list test/app`.
Complete when the list is independently navigable and each check/remove affects
only its intended stable item, with no clipped controls or stale success states.

Completed 2026-09-23: Shopping list is the third destination. Five focused view
tests cover loading/empty/retry, duplicate identity, check/uncheck/removal, failed
writes, busy controls, and 320-dp/200% text. Home tests preserve recipe search and
scroll position plus the planner's selected week and scroll position across tabs.

### 5. Wire Recipe Ingredients Into The List

- [x] Add the recipe-detail action with saved-result feedback and busy protection.

Requirements: R1, R2, R7, R8. Prerequisites: steps 1-4.

Change: forward the shared add callback through
[catalog](../../lib/features/recipe_catalog/ui/recipe_catalog_screen.dart) into
[details](../../lib/features/recipe_catalog/ui/recipe_detail_screen.dart). Add an
icon-and-text button near Ingredients. Send a recipe snapshot as one batch,
prevent overlapping taps, await confirmed persistence, and show success/error
feedback. No account, network, or destination-configuration gate applies.

Tests: extend [detail tests](../../test/features/recipe_catalog/ui/recipe_detail_screen_test.dart)
for exact ingredient data/order, missing quantity/unit, optional notes, repeated
taps while saving, deliberate later duplicate batches, storage errors, navigation
away during save, accessibility, and narrow/large-text layouts. Add a home flow
asserting the already-created Shopping list tab refreshes after a recipe addition.

Verification: `flutter test test/features/recipe_catalog test/app`.
Complete when every ingredient appears unchecked in the list after a successful
add, previous entries are preserved, and failed saves never report success.

Completed 2026-09-23: the detail action forwards one immutable batch through the
catalog to shared state. Seven detail tests and six home tests passed, covering
ordered ingredient data, repeat taps, deliberate duplicates, failures/retry,
navigation during saving, compact large-text layouts, and cross-tab freshness.

### 6. Verify The Complete Offline Workflow

- [x] Add cross-screen persistence coverage and run the automated checks.
- [ ] Complete manual offline, full-process-restart, and accessibility checks.

Requirements: R1, R2, R3, R4, R5, R6, R7, R8. Prerequisites: steps 1-5.

Change: extend [integration tests](../../integration_test/app_test.dart) using
the existing helpers and a temporary application-support directory. Exercise
recipe add, list navigation, check/uncheck, independent duplicate removal, and
recreation of app/repository instances to confirm persisted state. Do not change
the user's actual stored shopping list in automated tests.

Tests: cover the full R1-R8 flow and regression checks for Recipes/Meal plan.
Use deterministic fakes for failures and real temporary local storage for
persistence. Verify no Google dependency or network setup is needed.

Verification after focused tests pass:

- `dart format --output=none --set-exit-if-changed lib test integration_test`
- `make analyze`
- `make test`
- `make integration-test DEVICE=<device-id>` on a connected Android test device.
- Hot reload/restart a connected app and inspect runtime errors.
- Manually add, check, and remove entries offline; restart the process and verify
  the list. Inspect 320-dp layouts, large text, and accessible control labels.

Complete only with observed results for every criterion. Record unavailable
device/manual checks as pending, not passed. Follow repository review/PR gates
when later applicable; do not commit merely to enable review.

Observed 2026-09-23:

- `dart format --output=none --set-exit-if-changed lib test integration_test`:
  passed, 64 files checked with no changes.
- `make analyze`: passed with no issues.
- `make test`: all 176 Flutter tests and five deployment-selector tests passed.
- `make integration-test DEVICE=5000AF1001008153`: passed on Armor 10 5G,
  Android 10, after unlocking the phone. The first locked-device attempt was
  stopped and is not counted as a pass.
- Integration coverage uses temporary storage: recipe creation, two ingredient
  batches, check/uncheck, independent duplicate removal, then new app/repository
  instances restoring exact order, values, checked states, and deletion. Existing
  recipe and meal-plan regressions also passed. This is app recreation within
  the test process, not an OS process restart.
- The normal app was built and launched on the same phone. Hot reload succeeded;
  the runtime-error tool reported no errors.
- No package, Google dependency, or network setup was added. Automated tests did
  not alter the user's saved shopping list.

Pending: a manual airplane-mode add/check/remove flow, full OS process restart,
and on-device compact/large-text and screen-reader inspection. Compact layout
and accessible labels already have automated widget coverage, but that is not a
manual accessibility pass.

The new implementation is uncommitted. The committed `main...HEAD` review prompt
cannot inspect it yet; review and PR updates remain pending. No commit or push
was made, and the earlier root review report was left unchanged.
