# Recipe Creator Mode: Increment 1 Implementation Steps

Complete the steps in order. A step is complete only when all tasks and its focused check are checked.

## 1. Add Dependencies and Platform Storage

- [ ] Add `image_picker`, `path_provider`, and `uuid` as direct dependencies.
- [ ] Resolve dependencies without changing unrelated packages.
- [ ] Confirm the selected `image_picker` version needs no additional Android storage permission for gallery selection.
- [ ] Initialize Flutter bindings before resolving the application support directory.
- [ ] Run dependency resolution:

```bash
flutter pub get
```

## 2. Generalize Recipe Images and Serialization

- [ ] Add an immutable typed recipe-image value with `asset` and `file` variants.
- [ ] Validate that every image kind is supported and every path is non-empty.
- [ ] Replace `Recipe.imageAssetPath` with the typed image value.
- [ ] Add `toJson` methods for `Ingredient`, recipe images, and `Recipe`.
- [ ] Keep parsed and constructed ingredient and step collections immutable.
- [ ] Add validated factories for user-created ingredients and recipes so form input cannot bypass domain invariants.
- [ ] Migrate all bundled recipes to the typed image JSON schema.
- [ ] Update existing fixtures and call sites for the new image model.
- [ ] Test JSON round trips, both image kinds, malformed image values, and creation validation.
- [ ] Run the focused model and asset tests:

```bash
flutter test test/features/recipe_catalog/models test/features/recipe_catalog/data/recipe_assets_test.dart
```

## 3. Define the Creation Contract

- [ ] Add an immutable `NewRecipe` value for title, ingredients, ordered steps, and selected source image path.
- [ ] Trim all textual input at the boundary.
- [ ] Ignore completely blank optional ingredient rows.
- [ ] Reject a partially completed ingredient row without a name.
- [ ] Split multiline preparation text into trimmed, non-empty ordered steps.
- [ ] Keep servings and time fields out of `NewRecipe`.
- [ ] Extend the read-only repository contract with a separate mutable creation interface.
- [ ] Have creation return the persisted `Recipe` so navigation can report success precisely.
- [ ] Test draft normalization and every validation boundary.
- [ ] Run the focused creator-model tests:

```bash
flutter test test/features/recipe_creator/models
```

## 4. Add Durable Local Recipe Storage

- [ ] Implement `LocalRecipeRepository` around the existing asset repository.
- [ ] Inject the application support directory and ID generator for deterministic tests.
- [ ] Treat a missing `user_recipes.json` as an empty user collection.
- [ ] Decode and validate every stored recipe.
- [ ] Reject duplicate user IDs and collisions with bundled IDs.
- [ ] Return user recipes newest first, followed by bundled recipes in their original order.
- [ ] Generate a UUID for each created recipe.
- [ ] Assign `servings: 4`, `prepMinutes: 0`, and `cookMinutes: 0` during creation.
- [ ] Create the app-owned `recipe_images` directory when first needed.
- [ ] Copy the selected image to a safe recipe-ID-based filename.
- [ ] Persist only user-created recipe metadata.
- [ ] Write JSON through a temporary file and rename it into place atomically.
- [ ] Remove a newly copied image if metadata persistence fails.
- [ ] Return immutable merged recipe lists.
- [ ] Wrap read, parse, copy, and write failures in friendly repository exceptions while retaining diagnostics.
- [ ] Test first-run loading, successful creation, ordering, restart persistence, duplicate IDs, malformed JSON, missing source images, failed writes, and cleanup.
- [ ] Run the focused repository tests:

```bash
flutter test test/features/recipe_catalog/data/local_recipe_repository_test.dart
```

## 5. Add Gallery Image Selection

- [ ] Define an injectable `RecipeImagePicker` contract.
- [ ] Implement the production adapter with `ImagePicker` and `ImageSource.gallery`.
- [ ] Request a practical maximum image size and quality for recipe display.
- [ ] Return `null` for user cancellation without treating it as an error.
- [ ] Convert plugin failures into a creator-specific selection exception.
- [ ] Ensure asynchronous completion does not update a disposed creator screen.
- [ ] Test selection, cancellation, configuration, and plugin failure conversion with a fake picker platform.
- [ ] Run the focused picker tests:

```bash
flutter test test/features/recipe_creator/data
```

## 6. Share Asset and Local Image Rendering

- [ ] Extract one `RecipeImageView` used by recipe cards, details, and creator preview.
- [ ] Render asset images with `Image.asset`.
- [ ] Render persisted images with `Image.file`.
- [ ] Preserve the existing aspect ratios and crop behavior.
- [ ] Use the same stable fallback for missing, unreadable, or invalid image files.
- [ ] Keep semantics appropriate for decorative card images and the creator preview.
- [ ] Update existing card and detail tests for both image sources and fallback behavior.
- [ ] Run the focused presentation tests:

```bash
flutter test test/features/recipe_catalog/ui
```

## 7. Build the Recipe Creator Form

- [ ] Create a full-screen, vertically scrollable `RecipeCreatorScreen`.
- [ ] Add the title field and own/dispose its controller.
- [ ] Add the gallery placeholder, choose action, selected preview, and replace action.
- [ ] Start with one structured ingredient row.
- [ ] Add accessible controls to append and remove ingredient rows while retaining at least one.
- [ ] Own and dispose every ingredient-row controller when rows are removed or the screen closes.
- [ ] Add the multiline preparation field and explain its line-based structure through the field label or helper text.
- [ ] Add save and back actions with tooltips and stable touch targets.
- [ ] Validate title, image, ingredient rows, and preparation steps before persistence.
- [ ] Scroll or focus the first invalid section after a failed validation attempt.
- [ ] Disable save while a request is active and show progress without shifting the layout.
- [ ] Keep form values and the selected preview after picker or save failures.
- [ ] Pop the created `Recipe` only after persistence succeeds.
- [ ] Add dirty-state tracking and discard confirmation for back navigation.
- [ ] Guard all asynchronous state and context access with `mounted` checks.
- [ ] Test initial state, validation, ingredient add/remove, line parsing, image selection/cancellation/failure, save progress, save failure, success, and discard behavior.
- [ ] Test the form at 320 dp and 412 dp with the keyboard open and at 200% text scaling.
- [ ] Run the focused creator widget tests:

```bash
flutter test test/features/recipe_creator/ui/recipe_creator_screen_test.dart
```

## 8. Integrate Creator Mode with the Catalogue

- [ ] Add an accessible `Create recipe` action to the Recipes screen.
- [ ] Inject the mutable repository and gallery picker without using globals.
- [ ] Push `RecipeCreatorScreen` and await its result.
- [ ] Leave the catalogue unchanged when creator mode is cancelled.
- [ ] After a successful save, clear an active search and reload repository data.
- [ ] Keep normal detail-screen back navigation behavior unchanged.
- [ ] Show the created recipe immediately and allow opening its details.
- [ ] Handle a post-save reload failure through the existing recoverable error state.
- [ ] Test entry, cancellation, successful refresh, search clearing, and opening a created recipe.
- [ ] Run the focused catalogue navigation tests:

```bash
flutter test test/features/recipe_catalog/ui/recipe_catalog_screen_test.dart
```

## 9. Compose Production Dependencies

- [ ] Resolve the application support directory in the app composition root.
- [ ] Construct `AssetRecipeRepository` as the bundled seed source.
- [ ] Construct one `LocalRecipeRepository` for catalogue reads and recipe creation.
- [ ] Construct and inject the production gallery picker.
- [ ] Update app-level test doubles to implement only the contracts each test needs.
- [ ] Verify startup failures produce a controlled app state instead of an uncaught exception.
- [ ] Update the app smoke test to cover the creator entry action.
- [ ] Run the app-level test:

```bash
flutter test test/widget_test.dart
```

## 10. Extend the Android Integration Journey

- [ ] Use isolated temporary storage so existing device recipes cannot affect assertions.
- [ ] Inject a deterministic fake gallery picker that returns a valid test image.
- [ ] Launch with the eight bundled recipes.
- [ ] Open creator mode from the catalogue.
- [ ] Enter a title and structured ingredients.
- [ ] Enter at least three preparation steps as separate lines.
- [ ] Select and preview the fake gallery image.
- [ ] Save and verify the app returns to the catalogue.
- [ ] Verify the new recipe is visible and the catalogue contains nine recipes.
- [ ] Open the new recipe and verify image, ingredients, ordered steps, 4 servings, and 0-minute placeholders.
- [ ] Recreate the repository and app against the same temporary storage and verify the recipe persists.
- [ ] Run the Android integration test:

```bash
make integration-test DEVICE=emulator-5554
```

## 11. Complete the Scope and Device Audit

- [ ] Confirm camera capture is absent.
- [ ] Confirm additional and per-step images are absent.
- [ ] Confirm step timers, tags, difficulty, editing, and deleting are absent.
- [ ] Confirm servings and preparation/cooking time have no editable controls.
- [ ] Verify keyboard navigation, focus order, labels, tooltips, validation announcements, and touch targets.
- [ ] Verify creator layouts from 320 dp through 412 dp and at 200% text scaling.
- [ ] On a physical Android device, choose a real gallery image and save a recipe.
- [ ] Force-stop and relaunch the app.
- [ ] Verify the created recipe and copied image remain available offline.
- [ ] Verify a missing copied image uses the fallback without hiding the recipe.

## 12. Complete Final Validation

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

- [ ] Hot restart a connected app and inspect creator, catalogue, and detail flows for runtime errors.
- [ ] If the implementation is committed in `main...HEAD`, complete the repository review workflow.
