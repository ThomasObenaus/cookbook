# Weekly Meal Planner: Increment 1 Implementation Plan

## Goal

Add a weekly meal planner beside the recipe catalogue so a family member can:

- open a dedicated Meal plan view from the app's primary navigation;
- see the current Monday-to-Sunday week by default;
- move to earlier or later weeks and return to the current week;
- see breakfast, lunch, and dinner slots for all seven days;
- assign a recipe from the catalogue to an empty slot; and
- change or remove an existing assignment.

Meal assignments remain available after the app is closed or the device is restarted. The feature remains fully offline and stores references to recipes rather than duplicating recipe data.

## Agreed Decisions

- Add a Material `NavigationBar` with `Recipes` and `Meal plan` destinations.
- Keep Recipes as the initial destination so the existing launch behavior remains familiar.
- Preserve both destination states with an `IndexedStack` while switching between them.
- Define a week as Monday through Sunday using the device's local calendar date.
- Open the planner on the week containing the injected current date.
- Provide previous-week, next-week, and return-to-current-week controls.
- Show the seven days vertically so all three meal slots remain readable on narrow phones.
- Use the app's `MaterialLocalizations` to display week ranges, day names, and dates. Do not add a date-formatting dependency.
- Keep planner state local to `WeeklyMealPlannerScreen` with `StatefulWidget` and `setState`.
- Persist assignments in app support storage through an injected `MealPlanRepository`.
- Store the recipe ID for each assignment, not a serialized recipe snapshot.
- Use one assignment per date and meal type. Saving another recipe to the same slot replaces the previous assignment.
- Open a dedicated catalogue-backed recipe selection route for assignment and replacement.
- When an assigned slot is tapped, offer explicit Change recipe and Remove actions.
- Reuse the existing recipe search and card presentation where practical.
- Add no state-management, database, routing, or date package in this increment.

## Scope

### Included

- Bottom app navigation between Recipes and Meal plan.
- A current-week planner with seven dated day sections.
- Breakfast, lunch, and dinner slots for every day.
- Previous-week and next-week navigation.
- A Today action that returns to the current week.
- A searchable recipe selection route backed by the existing recipe repository.
- Assigning a recipe to an empty slot.
- Replacing or removing an assigned recipe.
- Durable local JSON persistence for assignments.
- Loading, empty, failure, retry, and mutation-progress behavior.
- Graceful handling of an assignment whose recipe is no longer available.
- Automated date, model, repository, widget, app-shell, and integration coverage.

### Excluded

- More than one recipe in a meal slot.
- Snacks or custom meal types.
- Free-text meals that are not catalogue recipes.
- Notes, portions, guests, nutrition, or preparation status on an assignment.
- Drag-and-drop or copy-and-paste between slots or weeks.
- Day, multiweek, month, or calendar-agenda layouts.
- Recipe creation or editing from the selection route.
- Automatic meal suggestions or generation.
- Shopping-list generation.
- Notifications or reminders.
- Accounts, sharing, cloud persistence, or cross-device synchronization.
- Editing or deleting recipes as part of meal-plan management.

## User Experience

### App Navigation

1. The app opens on the existing Recipes destination.
2. A bottom navigation bar exposes Recipes and Meal plan with familiar icons and text labels.
3. Selecting Meal plan shows the planner without pushing another route onto the recipe catalogue.
4. Switching destinations preserves the catalogue query, catalogue scroll position, selected planner week, and planner scroll position for the current app session.
5. Detail, creator, and recipe-selection routes continue to use the existing `Navigator` above the selected destination.

### Week Header

- Show a concise localized date range for the visible week.
- Provide icon buttons with tooltips for Previous week and Next week.
- Provide a Today action. Disable it, or otherwise make its current state clear, when the current week is already visible.
- Week navigation always moves exactly one local calendar week and remains correct across month, year, leap-day, and daylight-saving boundaries.
- Changing weeks resets the planner list to the top and loads that week's assignments.
- Ignore stale asynchronous results if the user changes weeks again before an earlier load completes.

### Week Layout

- Render Monday through Sunday in chronological order.
- Give each day an unambiguous localized heading containing both weekday name and date.
- Mark today's day heading without relying on color alone.
- Under each day, show exactly three stable slots in this order: Breakfast, Lunch, Dinner.
- Keep day sections unframed and use compact bounded tiles only for the individual meal slots.
- Keep slot height and image dimensions stable so loading, assignment, and mutation states do not shift the layout.

### Empty Meal Slot

1. Show the meal label and a clear empty state such as `Add breakfast`.
2. Tapping the slot opens recipe selection.
3. Selecting a recipe persists the assignment before updating the visible slot.
4. Cancelling recipe selection leaves the slot unchanged.

### Assigned Meal Slot

- Show the meal label, recipe name, and a compact recipe image or the existing image fallback.
- Tapping the assigned slot opens an action sheet with Change recipe and Remove.
- Change recipe opens the same recipe selection route and preselects nothing implicitly.
- Selecting the currently assigned recipe is valid and produces no duplicate assignment.
- Remove deletes only that date-and-meal assignment without requiring a destructive confirmation dialog.
- While a mutation is pending, prevent a second mutation of the same slot and show stable progress feedback.
- On persistence failure, retain the previous visible assignment and show a concise retryable message.

### Recipe Selection

- Open a full-screen `Select recipe` route.
- Load the latest recipes from the existing `RecipeRepository` each time the route opens so newly created recipes are available.
- Reuse the existing name-only search behavior and source ordering.
- Present recipes in the existing responsive card grid where practical.
- Tapping a recipe returns that `Recipe` to the planner; it does not open recipe details.
- Do not expose recipe creation from this route in this increment.
- Show loading, retryable repository failure, empty-catalogue, and no-search-results states.
- Cancelling through normal back navigation returns no selection and changes nothing.

## Calendar Rules

Use one pure date-logic module for all week calculations:

- Strip time-of-day from the injected current date before comparing dates.
- Treat `DateTime.monday` as the first day of a week.
- Derive the visible seven dates from the normalized week start.
- Construct calendar dates by year, month, and day values rather than adding 24-hour durations, avoiding daylight-saving drift.
- Compare dates by year, month, and day only.
- Keep persisted dates timezone-free in strict `YYYY-MM-DD` form.
- Do not convert planner dates to UTC because an assignment represents a local calendar day, not an instant.

The production current-date provider uses `DateTime.now`. Inject the provider into the planner for deterministic model, widget, and integration tests.

## Data Design

### Meal Type

Add an ordered enum or equivalent immutable value with exactly:

| Display label | Stored value |
| ------------- | ------------ |
| Breakfast     | `breakfast`  |
| Lunch         | `lunch`      |
| Dinner        | `dinner`     |

The model owns display ordering and strict storage decoding. Unknown stored meal types are invalid data rather than silently becoming another slot.

### Meal Assignment

Add an immutable value containing:

- `date`: a normalized local calendar date;
- `mealType`: breakfast, lunch, or dinner; and
- `recipeId`: a required non-empty recipe ID.

The composite identity is `(date, mealType)`. A valid stored collection cannot contain two assignments with the same composite identity.

Provide validated JSON conversion at the persistence boundary. Return immutable assignment collections from repository reads.

### Recipe Resolution

The planner joins `MealAssignment.recipeId` with recipes loaded from the existing repository:

- Persist only the ID so recipe names and images are not duplicated or allowed to drift.
- Keep a local ID-to-recipe map for rendering the visible week.
- Add a newly selected returned `Recipe` to that map immediately.
- If an ID cannot be resolved, show `Recipe unavailable` while retaining Change and Remove actions.
- Do not silently delete unresolved assignments.

## Persistence Design

Use the existing application support directory with this logical addition:

```text
cookbook/
  user_recipes.json
  meal_plan.json
  recipe_images/
```

Use a versioned JSON document:

```json
{
  "version": 1,
  "assignments": [
    {
      "date": "2026-09-21",
      "mealType": "dinner",
      "recipeId": "tomato-basil-pasta"
    }
  ]
}
```

Define an injected `MealPlanRepository` with operations to:

- load assignments for one normalized week;
- set or replace one date-and-meal assignment; and
- remove one date-and-meal assignment.

Implement `LocalMealPlanRepository` with these rules:

- Treat a missing file as an empty meal plan.
- Validate the schema version, exact date representation, meal type, recipe ID, and unique composite identities.
- Preserve assignments for every week when mutating one slot.
- Sort persisted assignments by date and meal-type order for deterministic output.
- Write the full document to a temporary file and rename it into place so interruption cannot leave partial JSON.
- Remove a failed temporary file without damaging the last valid document.
- Serialize UI mutations so overlapping writes cannot lose an assignment.
- Convert file, decoding, validation, and write failures into a friendly planner repository exception while retaining cause and stack trace.
- Do not make the planner repository responsible for validating recipe existence; recipe ownership remains with `RecipeRepository`.

## State and Loading Design

`WeeklyMealPlannerScreen` owns:

- the normalized current week start;
- the normalized visible week start;
- the visible week's immutable assignments;
- the loaded ID-to-recipe map;
- loading, success, and failure state;
- the slot currently being mutated, if any; and
- a request generation used to discard stale week-load results.

On first load, fetch recipes and the current week's assignments. On week changes, retain the recipe map and fetch only the new week's assignments. Recipe selection independently reloads the current catalogue each time it opens.

Update visible state only after a set or remove operation succeeds. This keeps the screen consistent with durable storage and makes rollback logic unnecessary.

## Architecture

Extend the existing feature-oriented structure without adding a state-management framework:

```text
lib/
  app/
    cookbook_home_screen.dart
  features/
    meal_planner/
      data/
        local_meal_plan_repository.dart
        meal_plan_repository.dart
      logic/
        week_dates.dart
      models/
        meal_assignment.dart
        meal_type.dart
      ui/
        meal_slot_tile.dart
        recipe_selection_screen.dart
        weekly_meal_planner_screen.dart
    recipe_catalog/
      ... existing catalogue files ...
test/
  app/
    cookbook_home_screen_test.dart
  features/
    meal_planner/
      data/
      logic/
      models/
      ui/
```

### Responsibilities

- `CookbookHomeScreen` owns the selected primary destination and preserves both destination subtrees.
- `MealType` owns the fixed meal vocabulary, display order, and stored values.
- `MealAssignment` owns assignment invariants and JSON conversion.
- `week_dates.dart` owns pure local-calendar normalization and Monday-to-Sunday calculations.
- `MealPlanRepository` describes planner reads and slot mutations independently of file storage.
- `LocalMealPlanRepository` owns versioned JSON, atomic writes, mutation serialization, and storage error conversion.
- `WeeklyMealPlannerScreen` owns visible-week state, recipe resolution, loading, week navigation, and assignment orchestration.
- `MealSlotTile` presents one stable empty, assigned, unavailable, or mutating slot.
- `RecipeSelectionScreen` owns fresh catalogue loading, search, result states, and returning a selected recipe.
- `RecipeCatalogScreen` retains its existing browsing, detail, and creation responsibilities.
- `main.dart` resolves platform storage and injects the recipe repository, meal-plan repository, image picker, and current-date provider.

## Failure Handling

- A missing meal-plan file is a normal empty first-run state.
- Corrupt or unsupported meal-plan JSON shows a recoverable planner error and does not overwrite the file.
- Recipe-loading or assignment-loading failure shows one stable planner failure state with Retry.
- A stale week-load response cannot replace a newer visible week.
- Recipe-selection loading failure remains on the selection route and supports Retry.
- Selection cancellation leaves the slot unchanged.
- Assignment or removal failure retains the prior slot state and permits another attempt.
- Asynchronous completions check `mounted` before updating widget state or using `BuildContext`.
- An unresolved persisted recipe remains visible as unavailable and can still be changed or removed.

## Accessibility and Responsive Behavior

- Give both primary destinations an icon and text label.
- Give previous, next, Today, Change, and Remove actions clear tooltips or semantic labels.
- Announce each slot with its date, meal type, and recipe name or empty state.
- Mark today's heading with text or semantics in addition to color.
- Keep every interactive target at least 48 dp.
- Keep logical focus order from the week header through Monday breakfast to Sunday dinner.
- Keep day headings, recipe names, and empty labels readable at 320 dp and 412 dp widths and at 200% text scaling.
- Let long recipe names wrap or ellipsize within stable bounds without overlapping actions.
- Keep the planner vertically scrollable with the bottom navigation bar visible.
- Ensure modal actions and recipe selection remain operable with TalkBack and keyboard navigation.

## Test Strategy

### Date and Model Tests

- Verify date-only normalization and equality.
- Verify Monday week starts for every weekday.
- Verify seven-day generation across month, year, leap-day, and daylight-saving boundaries.
- Verify previous-week and next-week calculations.
- Verify all meal labels, order, and stored values.
- Verify assignment validation, JSON round trips, strict dates, and immutable values.

### Repository Tests

- Verify missing-file first use.
- Verify setting, replacing, and removing assignments.
- Verify assignments in other slots and weeks are preserved.
- Verify deterministic persisted ordering and restart reads.
- Verify malformed JSON, unsupported versions, invalid dates, invalid meal types, blank IDs, and duplicate composite identities.
- Verify atomic-write failure preserves the previous valid file and cleans up temporary output.
- Verify overlapping mutations do not lose updates.

### Widget Tests

- Verify the injected current week is shown by default.
- Verify Monday through Sunday and exactly three ordered slots per day.
- Verify localized day headings and today's marker.
- Verify previous, next, and Today navigation across date boundaries.
- Verify stale week loads are ignored.
- Verify loading, empty, failure, retry, and unresolved-recipe states.
- Verify empty-slot selection, cancellation, successful assignment, and assignment failure.
- Verify assigned-slot Change and Remove behavior, including mutation failure.
- Verify recipe selection loading, name search, clear, no results, empty catalogue, retry, and return value.
- Verify a newly created recipe can be loaded by opening selection after the planner was initialized.
- Verify layouts at 320 dp and 412 dp and at 200% text scaling.

### App-Shell Tests

- Verify Recipes is selected initially.
- Verify navigation exposes and opens Meal plan.
- Verify switching destinations preserves catalogue and planner state.
- Verify existing recipe details and creator navigation remain functional above the app shell.

### Integration Test

- Launch with isolated recipe and meal-plan storage and a fixed current date.
- Open Meal plan and verify the expected Monday-to-Sunday range.
- Navigate to another week and back to the current week.
- Assign a bundled recipe to an empty slot.
- Change the slot to a different recipe.
- Remove one assignment and leave another persisted assignment in place.
- Recreate both repositories and the app against the same temporary storage.
- Return to the persisted week and verify the remaining recipe assignment survives restart.

## Acceptance Criteria

- The app exposes Recipes and Meal plan as adjacent primary destinations.
- Recipes remains the initial destination and existing catalogue behavior is unchanged.
- Meal plan initially shows the local current Monday-to-Sunday week.
- Previous, next, and Today controls navigate weeks correctly.
- Every visible day shows its weekday name, date, and exactly Breakfast, Lunch, and Dinner slots.
- Tapping an empty slot opens a searchable selection of current catalogue recipes.
- Selecting a recipe assigns it to exactly that date and meal type.
- Tapping an assigned slot permits changing or removing it.
- A failed assignment mutation leaves the last persisted slot state visible.
- Meal assignments persist after force-stop and relaunch.
- Assignments reference recipe IDs and reflect current recipe names and images.
- Missing referenced recipes remain manageable through Change and Remove.
- Catalogue and planner state are retained while switching destinations in one app session.
- The planner and selector remain usable at supported phone widths and 200% text scaling.
- Snacks, free-text meals, suggestions, shopping lists, reminders, accounts, and sharing remain absent.
- Focused tests, strict static analysis, the Android integration journey, and the debug build pass.

## Implementation Steps

Track implementation progress in [steps_Incr1.md](steps_Incr1.md).

## Final Validation

Run the complete repository checks after all focused tests pass:

```bash
make lint
make test
make integration-test DEVICE=emulator-5554
make build
```

After Flutter changes, hot restart a connected app and inspect Recipes, Meal plan, recipe selection, assignment changes, and removal for runtime errors. On a physical Android device, assign meals, force-stop and relaunch, and verify the assignments remain available offline. If the implementation is committed in `main...HEAD`, follow the repository review workflow before creating or updating the pull request.
