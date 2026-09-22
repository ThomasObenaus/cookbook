# Weekly Meal Planner: Increment 1 Implementation Steps

Complete the steps in order. A step is complete only when all tasks and its focused check are checked.

## 1. Add Calendar and Meal-Plan Domain Values

- [ ] Add `MealType` with Breakfast, Lunch, and Dinner in display order.
- [ ] Give every meal type one display label and one strict stored value.
- [ ] Add immutable `MealAssignment` with normalized local date, meal type, and non-empty recipe ID.
- [ ] Define `(date, mealType)` as the assignment's composite identity.
- [ ] Add validated assignment JSON conversion.
- [ ] Add pure helpers to normalize local dates and compare year, month, and day.
- [ ] Add a helper that returns the Monday containing any local date.
- [ ] Add helpers for the seven visible dates and previous or next week.
- [ ] Use calendar constructors instead of 24-hour duration arithmetic.
- [ ] Test meal ordering and stored-value decoding.
- [ ] Test assignment validation and JSON round trips.
- [ ] Test weeks across month, year, leap-day, and daylight-saving boundaries.
- [ ] Run the focused model and date tests:

```bash
flutter test test/features/meal_planner/models test/features/meal_planner/logic
```

## 2. Add the Durable Meal-Plan Repository

- [ ] Define `MealPlanRepository` operations to load one week, set or replace one assignment, and remove one assignment.
- [ ] Define a planner-specific repository exception with a friendly message, cause, and stack trace.
- [ ] Implement `LocalMealPlanRepository` with an injected application support directory.
- [ ] Store planner data in `cookbook/meal_plan.json` without changing recipe storage.
- [ ] Treat a missing file as an empty plan.
- [ ] Validate schema version 1 and the complete assignment list before returning data.
- [ ] Reject malformed dates, unknown meal types, blank recipe IDs, and duplicate date-and-meal identities.
- [ ] Filter weekly reads to the requested normalized Monday-to-Sunday range.
- [ ] Replace an existing assignment with the same date and meal type rather than appending a duplicate.
- [ ] Remove only the requested date-and-meal assignment.
- [ ] Preserve assignments in all other slots and weeks during mutations.
- [ ] Sort persisted records by date and meal-type order.
- [ ] Write through a temporary file and atomically rename it into place.
- [ ] Clean up failed temporary files without replacing the last valid document.
- [ ] Serialize overlapping mutations so read-modify-write operations cannot lose updates.
- [ ] Return immutable assignment collections.
- [ ] Test first use, set, replace, remove, cross-week preservation, deterministic order, and restart loading.
- [ ] Test malformed data, unsupported versions, duplicate slots, failed writes, cleanup, and overlapping mutations.
- [ ] Run the focused repository tests:

```bash
flutter test test/features/meal_planner/data
```

## 3. Build the Weekly Planner Read Model and Layout

- [ ] Create `WeeklyMealPlannerScreen` with injected recipe repository, meal-plan repository, and current-date provider.
- [ ] Normalize the injected current date and derive its Monday week start.
- [ ] Load recipes and current-week assignments on first entry.
- [ ] Represent loading, success, and recoverable failure explicitly.
- [ ] Build an ID-to-recipe map for assignment rendering.
- [ ] Add a localized week-range header.
- [ ] Add Previous week, Next week, and Today controls with stable keys and tooltips.
- [ ] Load only assignments when changing weeks and retain the recipe map.
- [ ] Discard stale load results when navigation overtakes an earlier request.
- [ ] Reset planner scrolling to the top after a successful week change.
- [ ] Render Monday through Sunday in chronological order.
- [ ] Show each weekday name and date through `MaterialLocalizations`.
- [ ] Mark today's day with text or semantics in addition to color.
- [ ] Render Breakfast, Lunch, and Dinner in fixed order for every day.
- [ ] Extract a stable `MealSlotTile` for empty, assigned, unavailable, and mutating states.
- [ ] Keep individual slot geometry stable while state changes.
- [ ] Show unresolved recipe IDs as `Recipe unavailable` without deleting the assignment.
- [ ] Test initial date, week navigation, stale loads, retry, all 21 slots, ordering, and unavailable recipes.
- [ ] Test 320 dp, 412 dp, and 200% text-scale layouts.
- [ ] Run the focused planner tests:

```bash
flutter test test/features/meal_planner/ui/weekly_meal_planner_screen_test.dart
```

## 4. Add Catalogue-Backed Recipe Selection

- [ ] Create a full-screen `RecipeSelectionScreen` with an injected `RecipeRepository`.
- [ ] Load recipes fresh every time the route opens.
- [ ] Represent loading, success, empty-catalogue, and failure states explicitly.
- [ ] Add Retry for repository failures.
- [ ] Reuse the existing name-only recipe search behavior.
- [ ] Add the search field, clear action, and no-search-results state.
- [ ] Reuse `RecipeCard` and the responsive catalogue grid where practical.
- [ ] Make a card tap return the selected `Recipe` instead of opening details.
- [ ] Keep creator actions absent from selection mode.
- [ ] Return `null` on normal back navigation.
- [ ] Test loading, retry, empty, search, clear, no results, selection, and cancellation.
- [ ] Verify newly created local recipes appear when selection opens after planner initialization.
- [ ] Test narrow and large-text layouts.
- [ ] Run the focused selector tests:

```bash
flutter test test/features/meal_planner/ui/recipe_selection_screen_test.dart
```

## 5. Implement Assignment, Change, and Removal Flows

- [ ] Open recipe selection when an empty meal slot is tapped.
- [ ] Leave the slot unchanged when selection is cancelled.
- [ ] Persist the selected assignment before updating visible state.
- [ ] Add the returned recipe to the local recipe map immediately.
- [ ] Open an accessible action sheet when an assigned or unavailable slot is tapped.
- [ ] Add Change recipe and Remove actions with familiar icons and labels.
- [ ] Use recipe selection for replacement and preserve the slot when replacement is cancelled.
- [ ] Replace the matching assignment after persistence succeeds.
- [ ] Remove only the matching assignment after persistence succeeds.
- [ ] Prevent a second mutation of the same slot while one is pending.
- [ ] Keep layout stable and expose progress while mutating.
- [ ] Retain the previous assignment and show a retryable message after mutation failure.
- [ ] Check `mounted` after every asynchronous gap before changing state or using context.
- [ ] Test assign, cancellation, change, same-recipe replacement, remove, unavailable-recipe actions, progress lockout, and failures.
- [ ] Run all focused meal-planner UI tests:

```bash
flutter test test/features/meal_planner/ui
```

## 6. Add Primary App Navigation

- [ ] Create `CookbookHomeScreen` as the owner of primary destination selection.
- [ ] Add a Material `NavigationBar` with Recipes and Meal plan destinations.
- [ ] Use familiar recipe and calendar icons with visible labels.
- [ ] Keep Recipes selected initially.
- [ ] Preserve both destination subtrees with an `IndexedStack`.
- [ ] Inject the existing mutable recipe repository and image picker into the catalogue.
- [ ] Inject the recipe repository, meal-plan repository, and current-date provider into the planner.
- [ ] Keep catalogue details, creator mode, and recipe selection on the existing navigator.
- [ ] Verify bottom navigation remains visible on both primary destinations and absent from full-screen child routes as intended.
- [ ] Test switching destinations and preserving catalogue query, catalogue scroll, planner week, and planner scroll state.
- [ ] Test that recipe details and creator mode still open and return correctly.
- [ ] Run the focused app-shell tests:

```bash
flutter test test/app/cookbook_home_screen_test.dart
```

## 7. Compose Production Dependencies

- [ ] Construct `LocalMealPlanRepository` from the same application support directory used for local recipes.
- [ ] Keep recipe and meal-plan files separate under `cookbook/`.
- [ ] Pass `DateTime.now` as the production current-date provider.
- [ ] Inject all dependencies through `CookbookApp` and `CookbookHomeScreen` without mutable globals.
- [ ] Update app-level and existing catalogue test doubles for the new constructor dependencies.
- [ ] Keep startup configuration failure controlled by `CookbookStartupFailureApp`.
- [ ] Update the smoke test to verify both primary destinations and Recipes as the default.
- [ ] Run the app-level tests:

```bash
flutter test test/widget_test.dart test/app
```

## 8. Extend the Android Integration Journey

- [ ] Use isolated temporary storage for both local recipes and meal assignments.
- [ ] Inject a fixed current date so expected week labels are deterministic.
- [ ] Launch on Recipes and switch to Meal plan.
- [ ] Verify the current Monday-to-Sunday week and all three meal types.
- [ ] Navigate to another week and return with Today.
- [ ] Open an empty slot and select a bundled recipe.
- [ ] Open the assigned slot and change it to another recipe.
- [ ] Assign a second slot, then remove the first assignment.
- [ ] Recreate the repositories and app against the same temporary directory.
- [ ] Return to Meal plan and verify the remaining assignment persisted in the correct date and slot.
- [ ] Keep interactions viewport-safe on the CI emulator's 320x640 display.
- [ ] Run the Android integration test:

```bash
make integration-test DEVICE=emulator-5554
```

## 9. Complete the Accessibility, Responsive, and Scope Audit

- [ ] Verify destination, week-navigation, slot, Change, and Remove semantics and tooltips.
- [ ] Verify each slot announces date, meal type, and assignment or empty state.
- [ ] Verify today's marker does not rely on color alone.
- [ ] Verify every interactive target is at least 48 dp.
- [ ] Verify logical keyboard and TalkBack focus order.
- [ ] Verify planner and selector layouts from 320 dp through 412 dp and at 200% text scaling.
- [ ] Verify long recipe names do not overlap icons or neighboring content.
- [ ] Verify the bottom navigation does not obscure Sunday or the last meal slot.
- [ ] Verify month, year, leap-day, and daylight-saving week boundaries on device.
- [ ] Verify assignments survive force-stop and relaunch without network access.
- [ ] Confirm snacks, custom meal types, free-text meals, suggestions, shopping lists, reminders, sharing, and cloud sync are absent.

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
