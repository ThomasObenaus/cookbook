# Weekly Meal Planner: Increment 1 Implementation Steps

Complete the steps in order. A step is complete only when all tasks and its focused check are checked.

## 1. Add Calendar and Meal-Plan Domain Values

- [x] Add `MealType` with Breakfast, Lunch, and Dinner in display order.
- [x] Give every meal type one display label and one strict stored value.
- [x] Add immutable `MealAssignment` with normalized local date, meal type, and non-empty recipe ID.
- [x] Define `(date, mealType)` as the assignment's composite identity.
- [x] Add validated assignment JSON conversion.
- [x] Add pure helpers to normalize local dates and compare year, month, and day.
- [x] Add a helper that returns the Monday containing any local date.
- [x] Add helpers for the seven visible dates and previous or next week.
- [x] Use calendar constructors instead of 24-hour duration arithmetic.
- [x] Test meal ordering and stored-value decoding.
- [x] Test assignment validation and JSON round trips.
- [x] Test weeks across month, year, leap-day, and daylight-saving boundaries.
- [x] Run the focused model and date tests:

```bash
flutter test test/features/meal_planner/models test/features/meal_planner/logic
```

## 2. Add the Durable Meal-Plan Repository

- [x] Define `MealPlanRepository` operations to load one week, set or replace one assignment, and remove one assignment.
- [x] Define a planner-specific repository exception with a friendly message, cause, and stack trace.
- [x] Implement `LocalMealPlanRepository` with an injected application support directory.
- [x] Store planner data in `cookbook/meal_plan.json` without changing recipe storage.
- [x] Treat a missing file as an empty plan.
- [x] Validate schema version 1 and the complete assignment list before returning data.
- [x] Reject malformed dates, unknown meal types, blank recipe IDs, and duplicate date-and-meal identities.
- [x] Filter weekly reads to the requested normalized Monday-to-Sunday range.
- [x] Replace an existing assignment with the same date and meal type rather than appending a duplicate.
- [x] Remove only the requested date-and-meal assignment.
- [x] Preserve assignments in all other slots and weeks during mutations.
- [x] Sort persisted records by date and meal-type order.
- [x] Write through a temporary file and atomically rename it into place.
- [x] Clean up failed temporary files without replacing the last valid document.
- [x] Serialize overlapping mutations so read-modify-write operations cannot lose updates.
- [x] Return immutable assignment collections.
- [x] Test first use, set, replace, remove, cross-week preservation, deterministic order, and restart loading.
- [x] Test malformed data, unsupported versions, duplicate slots, failed writes, cleanup, and overlapping mutations.
- [x] Run the focused repository tests:

```bash
flutter test test/features/meal_planner/data
```

## 3. Build the Weekly Planner Read Model and Layout

- [x] Create `WeeklyMealPlannerScreen` with injected recipe repository, meal-plan repository, and current-date provider.
- [x] Normalize the injected current date and derive its Monday week start.
- [x] Load recipes and current-week assignments on first entry.
- [x] Represent loading, success, and recoverable failure explicitly.
- [x] Build an ID-to-recipe map for assignment rendering.
- [x] Add a localized week-range header.
- [x] Add Previous week, Next week, and Today controls with stable keys and tooltips.
- [x] Load only assignments when changing weeks and retain the recipe map.
- [x] Discard stale load results when navigation overtakes an earlier request.
- [x] Reset planner scrolling to the top after a successful week change.
- [x] Render Monday through Sunday in chronological order.
- [x] Show each weekday name and date through `MaterialLocalizations`.
- [x] Mark today's day with text or semantics in addition to color.
- [x] Render Breakfast, Lunch, and Dinner in fixed order for every day.
- [x] Extract a stable `MealSlotTile` for empty, assigned, unavailable, and mutating states.
- [x] Keep individual slot geometry stable while state changes.
- [x] Show unresolved recipe IDs as `Recipe unavailable` without deleting the assignment.
- [x] Test initial date, week navigation, stale loads, retry, all 21 slots, ordering, and unavailable recipes.
- [x] Test 320 dp, 412 dp, and 200% text-scale layouts.
- [x] Run the focused planner tests:

```bash
flutter test test/features/meal_planner/ui/weekly_meal_planner_screen_test.dart
```

## 4. Add Catalogue-Backed Recipe Selection

- [x] Create a full-screen `RecipeSelectionScreen` with an injected `RecipeRepository`.
- [x] Load recipes fresh every time the route opens.
- [x] Represent loading, success, empty-catalogue, and failure states explicitly.
- [x] Add Retry for repository failures.
- [x] Reuse the existing name-only recipe search behavior.
- [x] Add the search field, clear action, and no-search-results state.
- [x] Reuse `RecipeCard` and the responsive catalogue grid where practical.
- [x] Make a card tap return the selected `Recipe` instead of opening details.
- [x] Keep creator actions absent from selection mode.
- [x] Return `null` on normal back navigation.
- [x] Test loading, retry, empty, search, clear, no results, selection, and cancellation.
- [x] Verify newly created local recipes appear when selection opens after planner initialization.
- [x] Test narrow and large-text layouts.
- [x] Run the focused selector tests:

```bash
flutter test test/features/meal_planner/ui/recipe_selection_screen_test.dart
```

## 5. Implement Assignment, Change, and Removal Flows

- [x] Open recipe selection when an empty meal slot is tapped.
- [x] Leave the slot unchanged when selection is cancelled.
- [x] Persist the selected assignment before updating visible state.
- [x] Add the returned recipe to the local recipe map immediately.
- [x] Open an accessible action sheet when an assigned or unavailable slot is tapped.
- [x] Add Change recipe and Remove actions with familiar icons and labels.
- [x] Use recipe selection for replacement and preserve the slot when replacement is cancelled.
- [x] Replace the matching assignment after persistence succeeds.
- [x] Remove only the matching assignment after persistence succeeds.
- [x] Prevent a second mutation of the same slot while one is pending.
- [x] Keep layout stable and expose progress while mutating.
- [x] Retain the previous assignment and show a retryable message after mutation failure.
- [x] Check `mounted` after every asynchronous gap before changing state or using context.
- [x] Test assign, cancellation, change, same-recipe replacement, remove, unavailable-recipe actions, progress lockout, and failures.
- [x] Run all focused meal-planner UI tests:

```bash
flutter test test/features/meal_planner/ui
```

## 6. Add Primary App Navigation

- [x] Create `CookbookHomeScreen` as the owner of primary destination selection.
- [x] Add a Material `NavigationBar` with Recipes and Meal plan destinations.
- [x] Use familiar recipe and calendar icons with visible labels.
- [x] Keep Recipes selected initially.
- [x] Preserve both destination subtrees with an `IndexedStack`.
- [x] Inject the existing mutable recipe repository and image picker into the catalogue.
- [x] Inject the recipe repository, meal-plan repository, and current-date provider into the planner.
- [x] Keep catalogue details, creator mode, and recipe selection on the existing navigator.
- [x] Verify bottom navigation remains visible on both primary destinations and absent from full-screen child routes as intended.
- [x] Test switching destinations and preserving catalogue query, catalogue scroll, planner week, and planner scroll state.
- [x] Test that recipe details and creator mode still open and return correctly.
- [x] Run the focused app-shell tests:

```bash
flutter test test/app/cookbook_home_screen_test.dart
```

## 7. Compose Production Dependencies

- [x] Construct `LocalMealPlanRepository` from the same application support directory used for local recipes.
- [x] Keep recipe and meal-plan files separate under `cookbook/`.
- [x] Pass `DateTime.now` as the production current-date provider.
- [x] Inject all dependencies through `CookbookApp` and `CookbookHomeScreen` without mutable globals.
- [x] Update app-level and existing catalogue test doubles for the new constructor dependencies.
- [x] Keep startup configuration failure controlled by `CookbookStartupFailureApp`.
- [x] Update the smoke test to verify both primary destinations and Recipes as the default.
- [x] Run the app-level tests:

```bash
flutter test test/widget_test.dart test/app
```

## 8. Extend the Android Integration Journey

- [x] Use isolated temporary storage for both local recipes and meal assignments.
- [x] Inject a fixed current date so expected week labels are deterministic.
- [x] Launch on Recipes and switch to Meal plan.
- [x] Verify the current Monday-to-Sunday week and all three meal types.
- [x] Navigate to another week and return with Today.
- [x] Open an empty slot and select a bundled recipe.
- [x] Open the assigned slot and change it to another recipe.
- [x] Assign a second slot, then remove the first assignment.
- [x] Recreate the repositories and app against the same temporary directory.
- [x] Return to Meal plan and verify the remaining assignment persisted in the correct date and slot.
- [x] Keep interactions viewport-safe on the CI emulator's 320x640 display.
- [x] Run the Android integration test:

```bash
make integration-test DEVICE=emulator-5554
```

## 9. Complete the Accessibility, Responsive, and Scope Audit

- [x] Verify destination, week-navigation, slot, Change, and Remove semantics and tooltips.
- [x] Verify each slot announces date, meal type, and assignment or empty state.
- [x] Verify today's marker does not rely on color alone.
- [x] Verify every interactive target is at least 48 dp.
- [x] Verify logical keyboard and TalkBack focus order.
- [x] Verify planner and selector layouts from 320 dp through 412 dp and at 200% text scaling.
- [x] Verify long recipe names do not overlap icons or neighboring content.
- [x] Verify the bottom navigation does not obscure Sunday or the last meal slot.
- [x] Verify month, year, leap-day, and daylight-saving week boundaries on device.
- [ ] Verify assignments survive force-stop and relaunch without network access.
- [x] Confirm snacks, custom meal types, free-text meals, suggestions, shopping lists, reminders, sharing, and cloud sync are absent.

## 10. Complete Final Validation

- [ ] Confirm every acceptance criterion in [plan_Incr1.md](plan_Incr1.md#acceptance-criteria).
- [ ] Run formatting and strict static analysis:

```bash
make lint
```

- [ ] Run the complete unit and widget test suite:

```bash
make test
```

- [ ] Run the complete Android integration journey:

```bash
make integration-test DEVICE=emulator-5554
```

- [ ] Build the debug APK:

```bash
make build
```

- [ ] Hot restart a connected app and inspect Recipes, Meal plan, week navigation, selection, assignment, change, and removal for runtime errors.
- [ ] On a physical Android device, assign meals, force-stop and relaunch, and verify persisted assignments offline.
- [ ] If the implementation is committed in `main...HEAD`, complete the repository review workflow.
