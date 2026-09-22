# Recipe Creator Mode: Increment 1.1 Adjustment Plan

## Goal

Refine recipe creation into a guided, one-step-at-a-time experience that lets a family member:

- choose or replace the main image by tapping the image area itself;
- move through clear recipe, ingredient, preparation, and review stages;
- add and edit one ingredient at a time;
- select ingredient units from a consistent dropdown;
- add and edit one preparation step at a time; and
- review the complete recipe before saving it.

Increment 1.1 changes the creator experience, not the stored recipe format. Recipes created with Increment 1 remain readable, and recipes created with Increment 1.1 continue to use the existing offline JSON and app-owned image storage.

## Relationship to Increment 1

This plan supersedes these Increment 1 creator-form decisions:

- a separate `Choose image` or `Replace image` button;
- multiple ingredient input rows shown on one form;
- free-text ingredient-unit entry; and
- one multiline field that splits preparation steps by line.

All other Increment 1 behavior remains in scope, including catalogue entry, gallery-only image selection, local persistence, fixed servings and times, save progress, discard confirmation, and catalogue refresh after creation.

## Agreed Decisions

- Keep creator mode on one full-screen route.
- Use one guided wizard with four stages: `Recipe`, `Ingredients`, `Preparation`, and `Review`.
- Keep wizard and draft state local to `RecipeCreatorScreen` with `StatefulWidget` and `setState`.
- Prevent swipe navigation from bypassing validation; move between stages through explicit Back and Continue actions.
- Keep all entered and committed values when moving backward and forward.
- Make the complete image placeholder or preview the image-selection control. Do not show a separate image-selection button.
- Add ingredients one at a time. Never render multiple ingredient editors simultaneously.
- Add preparation steps one at a time. Never use newline parsing to create multiple steps.
- Show committed ingredients and steps as compact summaries with edit and remove actions.
- Preserve ingredient and preparation order by insertion order.
- Use a fixed unit selection and store its existing string value, so no local-storage migration is required.
- Keep ingredient quantity and note optional and the ingredient name required.
- Keep at least one committed ingredient and one committed preparation step required before final review.
- Keep camera capture, multiple images, step images, timers, tags, difficulty, servings, and time editing outside this increment.

## Scope

### Included

- A four-stage recipe creator wizard with visible progress and stage titles.
- Back and Continue navigation that validates the current stage.
- A tappable image placeholder and tappable selected-image preview.
- Accessible image semantics that change from `Choose recipe image` to `Change recipe image`.
- One-at-a-time ingredient entry, review, editing, and removal.
- A fixed ingredient-unit dropdown.
- One-at-a-time preparation-step entry, review, editing, and removal.
- A final recipe review stage with links back to editable sections.
- Final-save progress and mutation lockout.
- Preservation of all draft data after picker or save failures.
- Updated model, widget, navigation, and integration tests.

### Excluded

- Camera capture or camera permissions.
- More than one main recipe image.
- Image cropping or editing.
- Custom user-defined units.
- Unit conversion, pluralization, or automatic quantity calculation.
- Drag-and-drop reordering or insertion at an arbitrary position.
- Images, timers, or durations attached to preparation steps.
- Tags, difficulty, servings, preparation time, or cooking time input.
- Editing or deleting a recipe after it has been saved.
- Persisting unfinished creator drafts across app restarts.
- Changes to the local recipe JSON schema.

## User Experience

### Wizard Shell

1. Opening creator mode starts at the `Recipe` stage.
2. The screen shows the current stage title and progress, such as `Step 1 of 4`.
3. A stable bottom action area exposes Back and Continue where applicable.
4. Back from the first stage follows the existing discard behavior.
5. Back from a later stage returns to the preceding stage without discarding data.
6. Continue validates and commits any in-progress item before advancing.
7. The final stage replaces Continue with `Save recipe`.
8. System back follows wizard navigation first; leaving the first stage prompts only when the draft is modified.

### Recipe Stage

- Show the 4:3 main-image area near the top.
- Before selection, the full placeholder is tappable and exposes a photo-library icon with the accessible label `Choose recipe image`.
- After selection, the full preview is tappable and exposes the accessible label `Change recipe image`.
- Use an `InkWell` or equivalent Material interaction so the image has visible pressed and focus states.
- Do not render a separate choose or replace button.
- Keep the title field below the image.
- Continue requires a non-empty title and selected image.
- Gallery cancellation leaves the stage unchanged.

### Ingredient Stage

The ingredient stage cycles between editing one ingredient and reviewing committed ingredients:

1. On first entry, show one editor labeled `Ingredient 1`.
2. The editor contains name, quantity, unit, and note controls.
3. Name is required. Quantity, unit, and note remain optional.
4. `Save ingredient` validates and commits the editor, then shows the compact ingredient summary.
5. `Add another ingredient` opens one cleared editor for the next ingredient.
6. Editing a summary item reopens that item in the same single editor and preserves its position.
7. Removing an item updates numbering. Removing the last item returns to the first empty editor.
8. Continue advances only when at least one ingredient is committed and no invalid editor is pending.
9. If a partially completed editor is visible when Continue is activated, validate and commit it before advancing.
10. If the editor is blank and at least one ingredient is committed, Continue advances without adding an empty item.

No action may append another set of input fields below the active editor.

### Ingredient Unit Selection

Use a `DropdownButtonFormField` or equivalent accessible Material dropdown. The initial option is `No unit`, which maps to `null` in the stored ingredient.

The Increment 1.1 unit vocabulary is:

| Display label | Stored value |
| ------------- | ------------ |
| No unit       | `null`       |
| Milliliter    | `ml`         |
| Liter         | `l`          |
| Teaspoon      | `tsp`        |
| Tablespoon    | `tbsp`       |
| Cup           | `cup`        |
| Gram          | `g`          |
| Kilogram      | `kg`         |
| Piece         | `piece`      |
| Pinch         | `pinch`      |
| Handful       | `handful`    |
| Clove         | `clove`      |
| Slice         | `slice`      |
| Can           | `can`        |
| Package       | `package`    |

- Keep the options in one typed, ordered definition rather than duplicating strings in widgets.
- Do not permit arbitrary unit text in creator mode.
- Existing bundled or persisted recipes with other unit strings remain valid and display unchanged.
- Do not automatically pluralize selected units in this increment.

### Preparation Stage

The preparation stage follows the same one-item-at-a-time pattern:

1. On first entry, show one editor labeled `Step 1`.
2. The editor accepts the instruction for exactly one preparation step.
3. `Save step` trims and commits a non-empty instruction, then shows the numbered step summary.
4. `Add another step` opens one cleared editor for the next step.
5. Editing a summary item reopens that item in the same editor and preserves its position.
6. Removing a step renumbers subsequent steps. Removing the last step returns to the first empty editor.
7. Continue advances only when at least one step is committed and no invalid editor is pending.
8. If a non-empty editor is visible when Continue is activated, validate and commit it before advancing.
9. If the editor is blank and at least one step is committed, Continue advances without adding an empty step.

The input may wrap long text visually, but each editor creates exactly one step. Newline splitting is removed.

### Review Stage

- Show the selected image, title, ingredient list, and numbered preparation steps.
- Show the fixed values `Serves 4`, `Preparation 0 min`, and `Cooking 0 min` without edit controls.
- Provide section edit actions that return to the corresponding wizard stage.
- Keep the review layout read-only except for navigation and final save.
- Disable all navigation and draft mutation while final persistence is pending.
- On success, return the created recipe to the catalogue as in Increment 1.
- On failure, remain on Review, retain the complete draft, and permit another save attempt.

## Validation and Navigation

- Validate only the current stage when Continue is activated.
- Move focus to the first invalid control on the current stage.
- Announce validation messages through normal form-field semantics.
- Do not discard an active ingredient or preparation editor during stage navigation.
- Treat stage navigation alone as clean; mark the draft dirty only when user-entered content or committed collections change.
- Prevent duplicate image picks and saves.
- Disable stage controls that could mutate the submitted snapshot while saving.
- Preserve the existing discard confirmation for any modified draft.

## Data Design

### Ingredient Units

Add a typed creator-owned unit value, for example `IngredientUnit`, containing the ordered options and their stored string values.

- `IngredientDraft.unit` becomes nullable typed selection rather than arbitrary text.
- `NewRecipe.fromInput` maps the selected option to the existing nullable `Ingredient.unit` string.
- The persisted `Ingredient` and recipe JSON format remain unchanged.
- Unit decoding for existing recipes remains permissive because older data is not limited to the creator dropdown.

### Wizard Draft

Keep one source of truth in `RecipeCreatorScreen` for:

- the current wizard stage;
- title and selected source-image path;
- immutable committed ingredient drafts in insertion order;
- one optional active ingredient editor and optional edited index;
- immutable committed preparation-step strings in insertion order;
- one optional active preparation editor and optional edited index;
- dirty, picking, and saving states; and
- validation messages for the active stage.

Convert the committed draft to `NewRecipe` only from the Review stage immediately before saving.

## Architecture

Keep the existing feature structure and state-management approach. Extract stage widgets only where they isolate ownership or materially simplify tests.

```text
lib/features/recipe_creator/
  models/
    ingredient_unit.dart
    new_recipe.dart
  ui/
    recipe_creator_screen.dart
    recipe_basics_step.dart
    ingredient_wizard_step.dart
    preparation_wizard_step.dart
    recipe_review_step.dart
```

### Responsibilities

- `RecipeCreatorScreen` owns wizard navigation, the complete draft, discard behavior, and final persistence.
- `RecipeBasicsStep` owns presentation for the tappable image and title controls.
- `IngredientWizardStep` presents one ingredient editor plus committed summaries and reports immutable updates upward.
- `PreparationWizardStep` presents one step editor plus committed summaries and reports immutable updates upward.
- `RecipeReviewStep` presents the read-only final draft and section edit actions.
- `IngredientUnit` owns the stable dropdown order, labels, and stored values.
- `NewRecipe` remains the validated boundary between creator input and persistence.

Do not introduce a new state-management dependency for this increment.

## Failure Handling

- Gallery cancellation is a no-op and retains the previous image.
- Gallery failures retain every stage value and expose the existing retryable message.
- Invalid ingredient or preparation input remains in its editor for correction.
- Save failures retain the complete committed draft on Review.
- Navigating away during image selection or saving must not update disposed state or use a disposed context.
- Missing persisted images continue to use the shared image fallback after creation.

## Accessibility and Responsive Behavior

- Give the image control button semantics, keyboard focus, and a minimum 48 dp interaction target.
- Announce the current wizard stage and progress without relying on color alone.
- Give every icon-only edit or remove action a tooltip and semantic label that identifies its item.
- Keep the active editor and primary navigation reachable with the keyboard open.
- Keep controls usable at 320 dp and 412 dp widths and at 200% text scaling.
- Ensure dropdown labels and long ingredient or preparation summaries wrap without overlap.
- Preserve logical focus order within each stage.

## Test Strategy

### Model Tests

- Verify every unit label and stored value, including `No unit` mapping to `null`.
- Verify creator input accepts only the typed unit options.
- Verify unit mapping does not change recipe JSON output.
- Verify committed ingredient and preparation collections remain immutable and ordered.

### Widget Tests

- Tap the empty image placeholder and selected preview to invoke the picker.
- Verify no separate choose or replace image button exists.
- Verify picker cancellation and failure retain the current wizard draft.
- Verify stage progress, Back, Continue, and current-stage validation.
- Verify one ingredient editor is visible at a time.
- Verify the exact unit dropdown options and selected-value restoration during editing.
- Verify ingredient commit, add another, edit, remove, renumber, and Continue behavior.
- Verify one preparation editor is visible at a time and newline splitting is absent.
- Verify preparation commit, add another, edit, remove, renumber, and Continue behavior.
- Verify backward and section-edit navigation retain all values.
- Verify Review shows the complete normalized recipe and fixed metadata.
- Verify final save uses the reviewed snapshot, locks mutation, handles failure, and returns success.
- Verify discard behavior from every stage.
- Verify 320 dp, 412 dp, keyboard-open, and 200% text-scale layouts.

### Integration Test

- Open creator mode and complete all four stages.
- Select an image by tapping the placeholder.
- Add at least two ingredients with different dropdown units.
- Add at least three preparation steps one at a time.
- Review and save the recipe.
- Verify catalogue and detail presentation preserve ingredient and step order.
- Recreate the repository and app to verify persistence remains compatible.

## Acceptance Criteria

- The creator presents Recipe, Ingredients, Preparation, and Review as a guided sequence.
- The image placeholder and preview open gallery selection when tapped.
- No separate image selection button is present.
- Only one ingredient editor is visible at a time.
- Ingredients can be committed, reviewed, edited, and removed without creating parallel input rows.
- Ingredient units come only from the documented dropdown vocabulary.
- Existing recipes with other stored unit strings still load and display.
- Only one preparation-step editor is visible at a time.
- Preparation steps are committed individually and remain in insertion order.
- Newline parsing is no longer used to create preparation steps.
- Backward navigation and validation do not lose draft data.
- Review shows the complete recipe before persistence.
- A successful save preserves existing catalogue, detail, and restart behavior.
- Picker and save failures retain the entire draft.
- The wizard remains usable at supported phone widths and 200% text scaling.
- Focused tests, strict analysis, Android integration, and the debug build pass.

## Implementation Steps

Track implementation progress in [steps_Incr1.1.md](steps_Incr1.1.md).

## Final Validation

Run the complete repository checks after focused tests pass:

```bash
make lint
make test
make integration-test DEVICE=emulator-5554
make build
```

After Flutter changes, hot restart a connected app and inspect each wizard stage for runtime errors. On a physical Android device, exercise real gallery selection, complete the wizard, save, force-stop, relaunch, and verify the recipe and copied image remain available. If committed in `main...HEAD`, complete the repository review workflow before creating or updating a pull request.
