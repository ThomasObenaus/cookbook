# Recipe Creator Mode: Increment 1.1 Implementation Steps

Complete the steps in order. A step is complete only when all tasks and its focused check are checked.

## 1. Define Wizard and Unit Contracts

- [ ] Add a creator-stage value for Recipe, Ingredients, Preparation, and Review.
- [ ] Add a typed, ordered ingredient-unit definition.
- [ ] Include `No unit`, `ml`, `l`, `tsp`, `tbsp`, `cup`, `g`, `kg`, `piece`, `pinch`, `handful`, `clove`, `slice`, `can`, and `package`.
- [ ] Map `No unit` to `null` and every other option to its documented stored string.
- [ ] Change `IngredientDraft` to accept a nullable typed unit selection instead of arbitrary unit text.
- [ ] Map typed units back to the existing `Ingredient.unit` string in `NewRecipe.fromInput`.
- [ ] Keep persisted recipe JSON and existing recipe decoding unchanged.
- [ ] Add model tests for option order, labels, stored values, null mapping, validation, and immutable ordered output.
- [ ] Run the focused model tests:

```bash
flutter test test/features/recipe_creator/models test/features/recipe_catalog/models
```

## 2. Build the Wizard Shell

- [ ] Replace the single long creator form with four explicit stages.
- [ ] Add a visible current-stage title and `Step n of 4` progress indicator.
- [ ] Add stable Back and Continue actions without swipe navigation.
- [ ] Keep title, image, committed ingredients, committed steps, and active editors owned by `RecipeCreatorScreen`.
- [ ] Preserve stage data when navigating backward and forward.
- [ ] Make system back return to the previous stage before attempting to leave creator mode.
- [ ] Preserve the existing discard confirmation when leaving a modified first stage.
- [ ] Validate only the current stage on Continue and focus its first invalid control.
- [ ] Test stage order, progress, navigation, validation boundaries, and state retention.
- [ ] Run the focused creator widget tests:

```bash
flutter test test/features/recipe_creator/ui/recipe_creator_screen_test.dart
```

## 3. Make the Image Area Interactive

- [ ] Remove the separate choose or replace image button.
- [ ] Wrap the full empty image placeholder in a Material tap and focus target.
- [ ] Wrap the full selected-image preview in the same interaction target.
- [ ] Expose `Choose recipe image` semantics before selection.
- [ ] Expose `Change recipe image` semantics after selection.
- [ ] Preserve picker progress, cancellation, failure, and mounted checks.
- [ ] Disable image interaction while picking or saving.
- [ ] Test placeholder tap, preview tap, semantics, cancellation, failure, progress, and lockout.
- [ ] Run the focused image-picker and creator tests:

```bash
flutter test test/features/recipe_creator/data test/features/recipe_creator/ui/recipe_creator_screen_test.dart
```

## 4. Implement One-at-a-Time Ingredient Entry

- [ ] Replace repeated ingredient form rows with one active ingredient editor.
- [ ] Keep name required and quantity, unit, and note optional.
- [ ] Replace the unit text field with the typed dropdown.
- [ ] Commit valid input through `Save ingredient`.
- [ ] Show committed ingredients as compact summaries rather than additional input fields.
- [ ] Add `Add another ingredient` only after the active item is committed.
- [ ] Reuse the single editor for editing an existing ingredient.
- [ ] Preserve an edited ingredient's list position.
- [ ] Add accessible remove actions and renumber summaries after removal.
- [ ] Return to an empty first editor when the last ingredient is removed.
- [ ] On Continue, commit a valid non-empty editor or ignore a blank editor when at least one item exists.
- [ ] Block Continue for missing or partially invalid ingredient input.
- [ ] Dispose all editor controllers and focus nodes correctly.
- [ ] Test single-editor rendering, exact dropdown options, commit, add another, edit, remove, renumber, validation, and Continue behavior.
- [ ] Run the focused creator widget tests:

```bash
flutter test test/features/recipe_creator/ui/recipe_creator_screen_test.dart
```

## 5. Implement One-at-a-Time Preparation Entry

- [ ] Remove the field that parses multiple preparation lines.
- [ ] Add one active preparation-step editor.
- [ ] Trim and commit one non-empty instruction through `Save step`.
- [ ] Show committed instructions as a numbered summary list.
- [ ] Add `Add another step` only after the active step is committed.
- [ ] Reuse the single editor for editing an existing step.
- [ ] Preserve an edited step's list position.
- [ ] Add accessible remove actions and renumber after removal.
- [ ] Return to an empty first editor when the last step is removed.
- [ ] On Continue, commit a valid non-empty editor or ignore a blank editor when at least one step exists.
- [ ] Remove all newline-splitting behavior from creator input.
- [ ] Test single-editor rendering, commit, add another, edit, remove, renumber, order, validation, and Continue behavior.
- [ ] Run the focused creator model and widget tests:

```bash
flutter test test/features/recipe_creator/models test/features/recipe_creator/ui/recipe_creator_screen_test.dart
```

## 6. Add Review and Final Save

- [ ] Add a read-only Review stage for image, title, ingredients, preparation steps, servings, and times.
- [ ] Show ingredients and preparation steps in insertion order.
- [ ] Add section edit actions that return to the corresponding stage.
- [ ] Build `NewRecipe` from committed wizard state only at final save.
- [ ] Keep `servings: 4`, `prepMinutes: 0`, and `cookMinutes: 0` assigned by persistence.
- [ ] Replace Continue with `Save recipe` on Review.
- [ ] Lock every stage action and draft mutation while saving.
- [ ] Keep the full draft and Review stage visible after save failure.
- [ ] Return the created recipe only after save success.
- [ ] Test review content, section editing, normalized save payload, progress, lockout, failure, and success.
- [ ] Run the focused creator and catalogue tests:

```bash
flutter test test/features/recipe_creator/ui test/features/recipe_catalog/ui/recipe_catalog_screen_test.dart
```

## 7. Complete Accessibility and Responsive Behavior

- [ ] Verify image button semantics, keyboard focus, pressed state, and 48 dp target size.
- [ ] Verify stage title and progress are announced without relying on color.
- [ ] Add item-specific tooltips and semantic labels to edit and remove actions.
- [ ] Verify dropdown focus order and selected-value announcements.
- [ ] Verify validation messages are associated with the active control.
- [ ] Keep the active editor and bottom navigation reachable with the keyboard open.
- [ ] Verify all four stages at 320 dp and 412 dp widths.
- [ ] Verify all four stages at 200% text scaling.
- [ ] Verify long ingredient and preparation summaries wrap without overlap.
- [ ] Run the focused responsive widget tests:

```bash
flutter test test/features/recipe_creator/ui/recipe_creator_screen_test.dart
```

## 8. Update the Android Integration Journey

- [ ] Open creator mode from the catalogue.
- [ ] Tap the image placeholder to select the fake gallery image.
- [ ] Complete the Recipe stage.
- [ ] Add at least two ingredients one at a time with different unit selections.
- [ ] Edit one committed ingredient and preserve its position.
- [ ] Add at least three preparation steps one at a time.
- [ ] Edit one committed preparation step and preserve its position.
- [ ] Verify all content on Review before saving.
- [ ] Save and verify the catalogue contains the new recipe.
- [ ] Open details and verify image, ingredient units, and preparation order.
- [ ] Recreate the app with the same storage and verify persistence compatibility.
- [ ] Run the Android integration test:

```bash
make integration-test DEVICE=emulator-5554
```

## 9. Complete the Scope and Device Audit

- [ ] Confirm no separate image selection button remains.
- [ ] Confirm only one ingredient editor can be visible.
- [ ] Confirm no free-text unit input remains.
- [ ] Confirm only one preparation-step editor can be visible.
- [ ] Confirm newline splitting no longer creates preparation steps.
- [ ] Confirm camera capture, multiple images, step images, timers, custom units, tags, difficulty, editing saved recipes, and draft persistence remain absent.
- [ ] On a physical Android device, exercise real gallery selection by tapping both the placeholder and an existing preview.
- [ ] Complete the wizard with multiple ingredients and preparation steps.
- [ ] Force-stop and relaunch after saving.
- [ ] Verify the recipe and copied image remain available offline.

## 10. Complete Final Validation

- [ ] Confirm every acceptance criterion in [plan_Incr1.1.md](plan_Incr1.1.md#acceptance-criteria).
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

- [ ] Hot restart a connected app and inspect all four stages for runtime errors.
- [ ] If the implementation is committed in `main...HEAD`, run the repository review workflow.
