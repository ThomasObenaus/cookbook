# Recipe Creator Mode: Increment 1 Implementation Plan

## Goal

Add a focused recipe creator flow that lets a family member:

- open creator mode from the recipe catalogue;
- enter a title and structured ingredients;
- enter preparation steps;
- choose one main image from the device gallery;
- save the recipe locally; and
- return to the catalogue with the new recipe visible.

Created recipes and their images must remain available after the app is closed or the device is restarted. The feature remains fully offline and extends the current asset-backed catalogue without adding editing, sharing, or camera capture.

## Agreed Decisions

- Use a dedicated add action on the Recipes screen because the app does not yet have a main menu.
- Keep widget-local form state with `StatefulWidget` and `setState`.
- Use `image_picker` for gallery selection and inject a small picker abstraction for tests.
- Use `path_provider` to locate application support storage.
- Copy the selected image into app-owned storage before persisting the recipe. Do not retain a temporary gallery-picker path as the durable reference.
- Keep bundled recipes immutable and store only user-created recipes in a separate JSON file.
- Merge user recipes with bundled recipes when loading the catalogue. Show user recipes newest first, followed by bundled recipes in their existing order.
- Represent recipe images explicitly as either bundled assets or local files and render both through one shared widget.
- Use UUIDs for stable user-recipe IDs and inject ID generation in repository tests.
- Keep preparation time and cooking time fixed at `0` minutes in this increment.
- Keep servings fixed at `4` because the current recipe model requires it and serving input is not part of this increment.
- Enter ingredients as repeatable structured rows with a required name and optional quantity, unit, and note.
- Enter preparation steps in one multiline field, with each non-empty line becoming one ordered step. A dedicated one-step-at-a-time editor remains deferred.

## Scope

### Included

- Entry into creator mode from the recipe catalogue.
- A vertically scrollable, validated recipe form.
- One required title.
- One or more structured ingredients with add and remove controls.
- One or more preparation steps entered as separate non-empty lines.
- One required gallery image with an in-form preview and replacement action.
- Save progress, success, and recoverable failure behavior.
- A discard confirmation when leaving a modified form.
- Durable JSON metadata and app-owned image storage.
- Display of local images in recipe cards and recipe details.
- Catalogue refresh after saving, with any active search cleared so the new recipe is visible.
- Automated model, repository, picker, widget, navigation, and integration coverage.

### Excluded

- Taking a new photo with the camera.
- Multiple recipe images.
- Images attached to individual preparation steps.
- A one-step-at-a-time step editor.
- Step timers or durations.
- Tags and difficulty.
- User-editable servings, preparation time, or cooking time.
- Editing, deleting, duplicating, importing, or exporting recipes.
- Cloud persistence, accounts, invitations, or sharing.
- Image cropping or a full image editor.

## User Experience

### Enter Creator Mode

1. The Recipes screen exposes a familiar add action with the tooltip `Create recipe`.
2. Activating it opens a full-screen `Create recipe` route.
3. The existing catalogue query and scroll state remain owned by the catalogue route.

### Complete the Form

- Show the main-image selector near the top of the form.
- Before selection, show a stable placeholder and a `Choose image` action.
- After selection, show the chosen image and a `Replace image` action.
- Provide a labeled recipe-title field.
- Start with one ingredient row.
- Each ingredient row contains name, quantity, unit, and note fields; only name is required.
- Provide add and remove controls for ingredient rows while always retaining at least one row.
- Provide one labeled multiline preparation field. Each non-empty trimmed line is one ordered step.
- Do not show controls for servings, preparation time, or cooking time.
- Keep all controls reachable at 320 dp width, with the keyboard open, and at 200% text scaling.

### Validate and Save

- Require a non-empty title, selected image, at least one valid ingredient, and at least one non-empty preparation step.
- Treat a completely blank extra ingredient row as absent, but reject a partially completed row without a name.
- Show field-level validation near the relevant control and move focus or scroll to the first invalid section.
- Disable duplicate save attempts and show progress while persistence is running.
- Keep all entered values intact if image selection or saving fails, and show a concise retryable error.
- On success, close creator mode, reload the catalogue, clear an active search query, and show the created recipe.
- Normal back navigation from recipe details continues to retain catalogue search state.

### Cancel and Discard

- Back navigation from an untouched form closes immediately.
- Back navigation from a modified form asks whether to discard the draft or continue editing.
- Cancelling image selection leaves the current image and form state unchanged.

## Data Design

### Recipe Image

Replace the asset-only image path with a typed immutable value:

- `kind`: `asset` or `file`.
- `path`: required, non-empty path.

Both variants support validated JSON conversion. Migrate bundled recipe JSON to the same representation so persistence and presentation use one model.

### New Recipe

Introduce an immutable creation value containing only user-entered fields:

- `name`;
- immutable structured `ingredients`;
- immutable ordered `steps`; and
- the selected source image path.

Add validated creation factories so UI input cannot bypass the same non-empty and range invariants enforced for decoded recipes. The persistence boundary assigns:

- a generated UUID;
- `servings: 4`;
- `prepMinutes: 0`;
- `cookMinutes: 0`; and
- the durable copied-image reference.

### Serialization

- Add JSON serialization for `Ingredient`, the typed image value, and `Recipe`.
- Keep local storage schema explicit and versionable instead of serializing widget state.
- Reject malformed records, duplicate IDs, invalid image references, and collisions with bundled recipe IDs.
- Return immutable collections from all repository reads.

## Persistence Design

Use the application support directory with this logical layout:

```text
cookbook/
  user_recipes.json
  recipe_images/
    <recipe-id>.<extension>
```

Add a mutable local repository that wraps the existing asset repository:

- `getAllRecipes` loads validated user recipes and bundled recipes, then merges them in the documented order.
- `createRecipe` validates the draft, generates an ID, copies the selected image into `recipe_images`, writes the updated user list, and returns the created `Recipe`.
- Write metadata to a temporary file and rename it into place so interruption cannot leave partially written JSON.
- If metadata persistence fails after copying an image, remove the new image so failed saves do not leave orphaned files.
- If the local JSON file does not exist, treat it as an empty user collection.
- Convert file, decoding, validation, and copy failures into friendly repository exceptions while retaining the cause and stack trace.
- A missing or unreadable saved image uses the existing visual fallback without preventing the remaining catalogue from loading.

Keep the existing read-only `RecipeRepository` contract for consumers that only load recipes. Add a mutable extension for creation so the asset repository remains a valid read-only seed source and test doubles do not gain unsupported write methods.

## Image Selection

Define a small gallery-picker contract owned by recipe creator mode. Its production adapter wraps `ImagePicker` and returns either a selected local source path or cancellation.

- Request gallery images only.
- Constrain very large selections to a practical display size and quality.
- Do not request camera access in this increment.
- Convert plugin failures into a user-facing selection error.
- Inject a fake picker in widget and integration tests so tests never depend on the system picker UI.

## Architecture

Extend the feature-oriented structure without adding a state-management framework:

```text
lib/
  main.dart
  features/
    recipe_catalog/
      data/
        asset_recipe_repository.dart
        local_recipe_repository.dart
        recipe_repository.dart
      models/
        recipe.dart
        recipe_image.dart
      ui/
        recipe_card.dart
        recipe_catalog_screen.dart
        recipe_detail_screen.dart
        recipe_image_view.dart
    recipe_creator/
      data/
        gallery_recipe_image_picker.dart
        recipe_image_picker.dart
      models/
        new_recipe.dart
      ui/
        recipe_creator_screen.dart
        ingredient_form_row.dart
test/
  features/
    recipe_catalog/
      data/
      models/
      ui/
    recipe_creator/
      data/
      models/
      ui/
```

### Responsibilities

- `Recipe`, `Ingredient`, and the typed image value own domain invariants and JSON conversion.
- `NewRecipe` represents validated creator input without persistence-generated fields.
- `AssetRecipeRepository` remains responsible only for bundled seed data.
- `LocalRecipeRepository` owns durable user metadata, image copying, ID assignment, atomic writes, and merged reads.
- `RecipeImagePicker` isolates the gallery plugin from form widgets and tests.
- `RecipeImageView` renders asset and local-file images with one consistent fallback.
- `RecipeCreatorScreen` owns controllers, ingredient rows, validation, dirty state, save progress, and discard behavior.
- `RecipeCatalogScreen` opens creator mode and refreshes after a successful save.
- `main.dart` resolves platform storage and injects production repository and picker implementations.

## Failure Handling

- Gallery cancellation is a normal no-op.
- Gallery errors leave the draft untouched and permit another attempt.
- Save errors leave the creator route open with all fields and the selected preview intact.
- Corrupt local metadata produces the existing recoverable catalogue error instead of silently dropping user recipes.
- Missing local image files render the standard fallback while the recipe remains usable.
- Navigating away during an asynchronous picker or save operation must not call `setState` or use `BuildContext` after disposal.

## Acceptance Criteria

- The Recipes screen opens creator mode through an accessible add action.
- The form accepts a title, at least one structured ingredient, multiline preparation steps, and one gallery image.
- Invalid or incomplete input cannot be saved and receives actionable field feedback.
- Gallery cancellation and plugin errors do not clear entered form data.
- A successful save returns to the catalogue and immediately shows the new recipe.
- The created recipe opens in the existing detail screen with its local image, ingredients, and ordered steps.
- Created recipes remain present with working images after force-stop and relaunch.
- Bundled recipes remain present in their original order after user recipes.
- Created recipes use 4 servings and 0-minute preparation and cooking placeholders, with no editable controls for those values.
- Failed saves do not create visible recipes, corrupt existing metadata, or leave copied image files behind.
- Leaving a modified form requires discard confirmation.
- The creator and resulting catalogue/detail views remain usable from 320 dp through 412 dp and at 200% text scaling.
- Camera capture, extra images, per-step images, timers, tags, difficulty, editing, and deleting remain absent.
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

After Flutter changes, hot restart a connected app. Exercise real gallery selection, save a recipe, force-stop and relaunch, and verify both the persisted recipe and its image. If the implementation is committed in `main...HEAD`, follow the repository review workflow before creating or updating the pull request.
