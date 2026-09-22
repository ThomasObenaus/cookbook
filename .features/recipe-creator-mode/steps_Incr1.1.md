# Recipe Creator Mode: Increment 1.1 Implementation Steps

Complete the steps in order. A step is complete only when all tasks and its focused check are checked.

## 1. Define Wizard and Unit Contracts

- [x] Add a creator-stage value for Recipe, Ingredients, Preparation, and Review.
- [x] Add a typed, ordered ingredient-unit definition.
- [x] Include `No unit`, `ml`, `l`, `tsp`, `tbsp`, `cup`, `g`, `kg`, `piece`, `pinch`, `handful`, `clove`, `slice`, `can`, and `package`.
- [x] Map `No unit` to `null` and every other option to its documented stored string.
- [x] Change `IngredientDraft` to accept a nullable typed unit selection instead of arbitrary unit text.
- [x] Map typed units back to the existing `Ingredient.unit` string in `NewRecipe.fromInput`.
- [x] Keep persisted recipe JSON and existing recipe decoding unchanged.
- [x] Add model tests for option order, labels, stored values, null mapping, validation, and immutable ordered output.
- [x] Run the focused model tests:

```bash
flutter test test/features/recipe_creator/models test/features/recipe_catalog/models
```

## 2. Build the Wizard Shell

- [x] Replace the single long creator form with four explicit stages.
- [x] Add a visible current-stage title and `Step n of 4` progress indicator.
- [x] Add stable Back and Continue actions without swipe navigation.
- [x] Keep title, image, committed ingredients, committed steps, and active editors owned by `RecipeCreatorScreen`.
- [x] Preserve stage data when navigating backward and forward.
- [x] Make system back return to the previous stage before attempting to leave creator mode.
- [x] Preserve the existing discard confirmation when leaving a modified first stage.
- [x] Validate only the current stage on Continue and focus its first invalid control.
- [x] Test stage order, progress, navigation, validation boundaries, and state retention.
- [x] Run the focused creator widget tests:

```bash
flutter test test/features/recipe_creator/ui/recipe_creator_screen_test.dart
```

## 3. Make the Image Area Interactive

- [x] Remove the separate choose or replace image button.
- [x] Wrap the full empty image placeholder in a Material tap and focus target.
- [x] Wrap the full selected-image preview in the same interaction target.
- [x] Expose `Choose recipe image` semantics before selection.
- [x] Expose `Change recipe image` semantics after selection.
- [x] Preserve picker progress, cancellation, failure, and mounted checks.
- [x] Disable image interaction while picking or saving.
- [x] Test placeholder tap, preview tap, semantics, cancellation, failure, progress, and lockout.
- [x] Run the focused image-picker and creator tests:

```bash
flutter test test/features/recipe_creator/data test/features/recipe_creator/ui/recipe_creator_screen_test.dart
```

## 4. Implement One-at-a-Time Ingredient Entry

- [x] Replace repeated ingredient form rows with one active ingredient editor.
- [x] Keep name required and quantity, unit, and note optional.
- [x] Replace the unit text field with the typed dropdown.
- [x] Commit valid input through `Save ingredient`.
- [x] Show committed ingredients as compact summaries rather than additional input fields.
- [x] Add `Add another ingredient` only after the active item is committed.
- [x] Reuse the single editor for editing an existing ingredient.
- [x] Preserve an edited ingredient's list position.
- [x] Add accessible remove actions and renumber summaries after removal.
- [x] Return to an empty first editor when the last ingredient is removed.
- [x] On Continue, commit a valid non-empty editor or ignore a blank editor when at least one item exists.
- [x] Block Continue for missing or partially invalid ingredient input.
- [x] Dispose all editor controllers and focus nodes correctly.
- [x] Test single-editor rendering, exact dropdown options, commit, add another, edit, remove, renumber, validation, and Continue behavior.
- [x] Run the focused creator widget tests:

```bash
flutter test test/features/recipe_creator/ui/recipe_creator_screen_test.dart
```

## 5. Implement One-at-a-Time Preparation Entry

- [x] Remove the field that parses multiple preparation lines.
- [x] Add one active preparation-step editor.
- [x] Trim and commit one non-empty instruction through `Save step`.
- [x] Show committed instructions as a numbered summary list.
- [x] Add `Add another step` only after the active step is committed.
- [x] Reuse the single editor for editing an existing step.
- [x] Preserve an edited step's list position.
- [x] Add accessible remove actions and renumber after removal.
- [x] Return to an empty first editor when the last step is removed.
- [x] On Continue, commit a valid non-empty editor or ignore a blank editor when at least one step exists.
- [x] Remove all newline-splitting behavior from creator input.
- [x] Test single-editor rendering, commit, add another, edit, remove, renumber, order, validation, and Continue behavior.
- [x] Run the focused creator model and widget tests:

```bash
flutter test test/features/recipe_creator/models test/features/recipe_creator/ui/recipe_creator_screen_test.dart
```

## 6. Add Review and Final Save

- [x] Add a read-only Review stage for image, title, ingredients, preparation steps, servings, and times.
- [x] Show ingredients and preparation steps in insertion order.
- [x] Add section edit actions that return to the corresponding stage.
- [x] Build `NewRecipe` from committed wizard state only at final save.
- [x] Keep `servings: 4`, `prepMinutes: 0`, and `cookMinutes: 0` assigned by persistence.
- [x] Replace Continue with `Save recipe` on Review.
- [x] Lock every stage action and draft mutation while saving.
- [x] Keep the full draft and Review stage visible after save failure.
- [x] Return the created recipe only after save success.
- [x] Test review content, section editing, normalized save payload, progress, lockout, failure, and success.
- [x] Run the focused creator and catalogue tests:

```bash
flutter test test/features/recipe_creator/ui test/features/recipe_catalog/ui/recipe_catalog_screen_test.dart
```

## 7. Complete Accessibility and Responsive Behavior

- [x] Verify image button semantics, keyboard focus, pressed state, and 48 dp target size.
- [x] Verify stage title and progress are announced without relying on color.
- [x] Add item-specific tooltips and semantic labels to edit and remove actions.
- [x] Verify dropdown focus order and selected-value announcements.
- [x] Verify validation messages are associated with the active control.
- [x] Keep the active editor and bottom navigation reachable with the keyboard open.
- [x] Verify all four stages at 320 dp and 412 dp widths.
- [x] Verify all four stages at 200% text scaling.
- [x] Verify long ingredient and preparation summaries wrap without overlap.
- [x] Run the focused responsive widget tests:

```bash
flutter test test/features/recipe_creator/ui/recipe_creator_screen_test.dart
```

## 8. Update the Android Integration Journey

- [x] Open creator mode from the catalogue.
- [x] Tap the image placeholder to select the fake gallery image.
- [x] Complete the Recipe stage.
- [x] Add at least two ingredients one at a time with different unit selections.
- [x] Edit one committed ingredient and preserve its position.
- [x] Add at least three preparation steps one at a time.
- [x] Edit one committed preparation step and preserve its position.
- [x] Verify all content on Review before saving.
- [x] Save and verify the catalogue contains the new recipe.
- [x] Open details and verify image, ingredient units, and preparation order.
- [x] Recreate the app with the same storage and verify persistence compatibility.
- [x] Run the Android integration test:

```bash
make integration-test DEVICE=emulator-5554
```

## 9. Complete the Scope and Device Audit

- [x] Confirm no separate image selection button remains.
- [x] Confirm only one ingredient editor can be visible.
- [x] Confirm no free-text unit input remains.
- [x] Confirm only one preparation-step editor can be visible.
- [x] Confirm newline splitting no longer creates preparation steps.
- [x] Confirm camera capture, multiple images, step images, timers, custom units, tags, difficulty, editing saved recipes, and draft persistence remain absent.
- [ ] On a physical Android device, exercise real gallery selection by tapping both the placeholder and an existing preview.
- [ ] Complete the wizard with multiple ingredients and preparation steps.
- [ ] Force-stop and relaunch after saving.
- [ ] Verify the recipe and copied image remain available offline.

## 10. Complete Final Validation

- [x] Confirm every acceptance criterion in [plan_Incr1.1.md](plan_Incr1.1.md#acceptance-criteria).
- [x] Run formatting and strict static analysis:

```bash
make lint
```

- [x] Run the complete unit and widget test suite:

```bash
make test
```

- [x] Run the complete Android integration journey:

```bash
make integration-test DEVICE=emulator-5554
```

- [x] Build the debug APK:

```bash
make build
```

- [x] Hot restart a connected app and inspect all four stages for runtime errors.
- [ ] If the implementation is committed in `main...HEAD`, run the repository review workflow.
