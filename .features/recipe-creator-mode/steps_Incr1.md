# Recipe Creator Mode: Increment 1 Implementation Steps

Complete the steps in order. A step is complete only when all tasks and its focused check are checked.

## 1. Add Dependencies and Platform Storage

- [x] Add `image_picker`, `path_provider`, and `uuid` as direct dependencies.
- [x] Resolve dependencies without changing unrelated packages.
- [x] Confirm the selected `image_picker` version needs no additional Android storage permission for gallery selection.
- [x] Initialize Flutter bindings before resolving the application support directory.
- [x] Run dependency resolution:

```bash
flutter pub get
```

## 2. Generalize Recipe Images and Serialization

- [x] Add an immutable typed recipe-image value with `asset` and `file` variants.
- [x] Validate that every image kind is supported and every path is non-empty.
- [x] Replace `Recipe.imageAssetPath` with the typed image value.
- [x] Add `toJson` methods for `Ingredient`, recipe images, and `Recipe`.
- [x] Keep parsed and constructed ingredient and step collections immutable.
- [x] Add validated factories for user-created ingredients and recipes so form input cannot bypass domain invariants.
- [x] Migrate all bundled recipes to the typed image JSON schema.
- [x] Update existing fixtures and call sites for the new image model.
- [x] Test JSON round trips, both image kinds, malformed image values, and creation validation.
- [x] Run the focused model and asset tests:

```bash
flutter test test/features/recipe_catalog/models test/features/recipe_catalog/data/recipe_assets_test.dart
```

## 3. Define the Creation Contract

- [x] Add an immutable `NewRecipe` value for title, ingredients, ordered steps, and selected source image path.
- [x] Trim all textual input at the boundary.
- [x] Ignore completely blank optional ingredient rows.
- [x] Reject a partially completed ingredient row without a name.
- [x] Split multiline preparation text into trimmed, non-empty ordered steps.
- [x] Keep servings and time fields out of `NewRecipe`.
- [x] Extend the read-only repository contract with a separate mutable creation interface.
- [x] Have creation return the persisted `Recipe` so navigation can report success precisely.
- [x] Test draft normalization and every validation boundary.
- [x] Run the focused creator-model tests:

```bash
flutter test test/features/recipe_creator/models
```

## 4. Add Durable Local Recipe Storage

- [x] Implement `LocalRecipeRepository` around the existing asset repository.
- [x] Inject the application support directory and ID generator for deterministic tests.
- [x] Treat a missing `user_recipes.json` as an empty user collection.
- [x] Decode and validate every stored recipe.
- [x] Reject duplicate user IDs and collisions with bundled IDs.
- [x] Return user recipes newest first, followed by bundled recipes in their original order.
- [x] Generate a UUID for each created recipe.
- [x] Assign `servings: 4`, `prepMinutes: 0`, and `cookMinutes: 0` during creation.
- [x] Create the app-owned `recipe_images` directory when first needed.
- [x] Copy the selected image to a safe recipe-ID-based filename.
- [x] Persist only user-created recipe metadata.
- [x] Write JSON through a temporary file and rename it into place atomically.
- [x] Remove a newly copied image if metadata persistence fails.
- [x] Return immutable merged recipe lists.
- [x] Wrap read, parse, copy, and write failures in friendly repository exceptions while retaining diagnostics.
- [x] Test first-run loading, successful creation, ordering, restart persistence, duplicate IDs, malformed JSON, missing source images, failed writes, and cleanup.
- [x] Run the focused repository tests:

```bash
flutter test test/features/recipe_catalog/data/local_recipe_repository_test.dart
```

## 5. Add Gallery Image Selection

- [x] Define an injectable `RecipeImagePicker` contract.
- [x] Implement the production adapter with `ImagePicker` and `ImageSource.gallery`.
- [x] Request a practical maximum image size and quality for recipe display.
- [x] Return `null` for user cancellation without treating it as an error.
- [x] Convert plugin failures into a creator-specific selection exception.
- [x] Ensure asynchronous completion does not update a disposed creator screen.
- [x] Test selection, cancellation, configuration, and plugin failure conversion with a fake picker platform.
- [x] Run the focused picker tests:

```bash
flutter test test/features/recipe_creator/data
```

## 6. Share Asset and Local Image Rendering

- [x] Extract one `RecipeImageView` used by recipe cards, details, and creator preview.
- [x] Render asset images with `Image.asset`.
- [x] Render persisted images with `Image.file`.
- [x] Preserve the existing aspect ratios and crop behavior.
- [x] Use the same stable fallback for missing, unreadable, or invalid image files.
- [x] Keep semantics appropriate for decorative card images and the creator preview.
- [x] Update existing card and detail tests for both image sources and fallback behavior.
- [x] Run the focused presentation tests:

```bash
flutter test test/features/recipe_catalog/ui
```

## 7. Build the Recipe Creator Form

- [x] Create a full-screen, vertically scrollable `RecipeCreatorScreen`.
- [x] Add the title field and own/dispose its controller.
- [x] Add the gallery placeholder, choose action, selected preview, and replace action.
- [x] Start with one structured ingredient row.
- [x] Add accessible controls to append and remove ingredient rows while retaining at least one.
- [x] Own and dispose every ingredient-row controller when rows are removed or the screen closes.
- [x] Add the multiline preparation field and explain its line-based structure through the field label or helper text.
- [x] Add save and back actions with tooltips and stable touch targets.
- [x] Validate title, image, ingredient rows, and preparation steps before persistence.
- [x] Scroll or focus the first invalid section after a failed validation attempt.
- [x] Disable save while a request is active and show progress without shifting the layout.
- [x] Keep form values and the selected preview after picker or save failures.
- [x] Pop the created `Recipe` only after persistence succeeds.
- [x] Add dirty-state tracking and discard confirmation for back navigation.
- [x] Guard all asynchronous state and context access with `mounted` checks.
- [x] Test initial state, validation, ingredient add/remove, line parsing, image selection/cancellation/failure, save progress, save failure, success, and discard behavior.
- [x] Test the form at 320 dp and 412 dp with the keyboard open and at 200% text scaling.
- [x] Run the focused creator widget tests:

```bash
flutter test test/features/recipe_creator/ui/recipe_creator_screen_test.dart
```

## 8. Integrate Creator Mode with the Catalogue

- [x] Add an accessible `Create recipe` action to the Recipes screen.
- [x] Inject the mutable repository and gallery picker without using globals.
- [x] Push `RecipeCreatorScreen` and await its result.
- [x] Leave the catalogue unchanged when creator mode is cancelled.
- [x] After a successful save, clear an active search and reload repository data.
- [x] Keep normal detail-screen back navigation behavior unchanged.
- [x] Show the created recipe immediately and allow opening its details.
- [x] Handle a post-save reload failure through the existing recoverable error state.
- [x] Test entry, cancellation, successful refresh, search clearing, and opening a created recipe.
- [x] Run the focused catalogue navigation tests:

```bash
flutter test test/features/recipe_catalog/ui/recipe_catalog_screen_test.dart
```

## 9. Compose Production Dependencies

- [x] Resolve the application support directory in the app composition root.
- [x] Construct `AssetRecipeRepository` as the bundled seed source.
- [x] Construct one `LocalRecipeRepository` for catalogue reads and recipe creation.
- [x] Construct and inject the production gallery picker.
- [x] Update app-level test doubles to implement only the contracts each test needs.
- [x] Verify startup failures produce a controlled app state instead of an uncaught exception.
- [x] Update the app smoke test to cover the creator entry action.
- [x] Run the app-level test:

```bash
flutter test test/widget_test.dart
```

## 10. Extend the Android Integration Journey

- [x] Use isolated temporary storage so existing device recipes cannot affect assertions.
- [x] Inject a deterministic fake gallery picker that returns a valid test image.
- [x] Launch with the eight bundled recipes.
- [x] Open creator mode from the catalogue.
- [x] Enter a title and structured ingredients.
- [x] Enter at least three preparation steps as separate lines.
- [x] Select and preview the fake gallery image.
- [x] Save and verify the app returns to the catalogue.
- [x] Verify the new recipe is visible and the catalogue contains nine recipes.
- [x] Open the new recipe and verify image, ingredients, ordered steps, 4 servings, and 0-minute placeholders.
- [x] Recreate the repository and app against the same temporary storage and verify the recipe persists.
- [x] Run the Android integration test:

```bash
make integration-test DEVICE=emulator-5554
```

## 11. Complete the Scope and Device Audit

- [x] Confirm camera capture is absent.
- [x] Confirm additional and per-step images are absent.
- [x] Confirm step timers, tags, difficulty, editing, and deleting are absent.
- [x] Confirm servings and preparation/cooking time have no editable controls.
- [x] Verify keyboard navigation, focus order, labels, tooltips, validation announcements, and touch targets.
- [x] Verify creator layouts from 320 dp through 412 dp and at 200% text scaling.
- [x] On a physical Android device, choose a real gallery image and save a recipe.
- [x] Force-stop and relaunch the app.
- [x] Verify the created recipe and copied image remain available offline.
- [x] Verify a missing copied image uses the fallback without hiding the recipe.

## 12. Complete Final Validation

- [x] Confirm every acceptance criterion in [plan_Incr1.md](plan_Incr1.md#acceptance-criteria).
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

- [x] Hot restart a connected app and inspect creator, catalogue, and detail flows for runtime errors.
- [ ] If the implementation is committed in `main...HEAD`, complete the repository review workflow.
