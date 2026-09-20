# Recipe Catalogue: Increment 1 Implementation Steps

Complete the steps in order. A step is complete only when all of its tasks and its focused check are checked.

## 1. Add the Domain Model

- [x] Create immutable `Ingredient` and `Recipe` types.
- [x] Add validated JSON factories.
- [x] Copy parsed collections into immutable lists.
- [x] Add the derived total cooking time.
- [x] Test valid recipe and ingredient parsing.
- [x] Test every required field, type, range, and empty-list boundary.
- [x] Run the focused model test:

```bash
flutter test test/features/recipe_catalog/models/recipe_test.dart
```

## 2. Add Local Recipe Assets

- [x] Create `assets/data/recipes.json` with the eight recipes defined in the plan.
- [x] Give every recipe at least four ingredients and three cooking steps.
- [x] Create `assets/images/recipe_placeholder.png` with a 4:3 aspect ratio.
- [x] Reference the shared placeholder image from every recipe.
- [x] Register both explicit asset paths in `pubspec.yaml`.
- [x] Verify that the JSON and image load from the Flutter asset bundle.
- [x] Resolve the asset declaration changes:

```bash
flutter pub get
```

## 3. Add the Replaceable Repository

- [x] Define the `RecipeRepository` contract with one asynchronous all-recipes operation.
- [x] Define a domain-specific repository exception.
- [x] Implement `AssetRecipeRepository` with an injected `AssetBundle`.
- [x] Decode and validate the complete recipe collection once per load.
- [x] Reject duplicate recipe IDs.
- [x] Return an immutable recipe list.
- [x] Convert asset, decoding, and validation failures into repository errors.
- [x] Retain useful diagnostic context without exposing technical details in the UI.
- [x] Test successful loading with a small fake asset bundle.
- [x] Test missing assets, malformed JSON, invalid recipes, and duplicate IDs.
- [x] Run the focused repository tests:

```bash
flutter test test/features/recipe_catalog/data
```

## 4. Add Name Search

- [x] Implement search as a pure synchronous function over the loaded recipe list.
- [x] Trim surrounding query whitespace.
- [x] Match a case-insensitive substring of `Recipe.name` only.
- [x] Preserve source order in the results.
- [x] Return all recipes for an empty query.
- [x] Keep search out of the repository so typing never reloads assets.
- [x] Test empty, partial, case-insensitive, whitespace-trimmed, and unmatched queries.
- [x] Verify that ingredient-only and instruction-only queries do not match.
- [x] Run the focused search tests:

```bash
flutter test test/features/recipe_catalog/logic
```

## 5. Build the Catalogue Grid

- [x] Create `RecipeCatalogScreen` with an injected `RecipeRepository`.
- [x] Load recipes exactly once for the screen lifecycle.
- [x] Check `mounted` after asynchronous loading before updating widget state.
- [x] Represent loading, success, empty-catalogue, and failure states explicitly.
- [x] Add a Retry action for load failures.
- [x] Add the live name-search field and a visible clear action.
- [x] Derive displayed recipes from the loaded list and current query.
- [x] Display a dedicated no-search-results state.
- [x] Build an image grid using width-based maximum tile extents.
- [x] Show two columns on common phone widths and add columns when space permits.
- [x] Keep image and text regions constrained under long names and large text.
- [x] Create `RecipeCard` with image, name, total time, and servings.
- [x] Use `InkWell`, semantic labels, and touch targets of at least 48 dp.
- [x] Add a stable icon fallback for missing images.
- [x] Test loading, success, empty, error, retry, and no-results states.
- [x] Test search and clear interactions.
- [x] Test grid behavior at narrow widths and 200% text scaling.
- [x] Test the missing-image fallback.
- [x] Run the focused catalogue tests:

```bash
flutter test test/features/recipe_catalog/ui/recipe_catalog_screen_test.dart
```

## 6. Build Recipe Details

- [x] Create a vertically scrollable `RecipeDetailScreen`.
- [x] Display the recipe image and name.
- [x] Display servings, preparation time, and cooking time.
- [x] Display every structured ingredient.
- [x] Omit awkward separators or gaps when quantity, unit, or note is absent.
- [x] Display cooking steps in their stored order with visible numbers.
- [x] Push the screen with Flutter's built-in `Navigator` and `MaterialPageRoute`.
- [x] Test every displayed recipe field.
- [x] Test scrolling at narrow widths and 200% text scaling.
- [x] Test navigation to details and back to the catalogue.
- [x] Verify that back navigation retains the search query and filtered results.
- [x] Run the focused detail tests:

```bash
flutter test test/features/recipe_catalog/ui/recipe_detail_screen_test.dart
```

## 7. Compose the Application

- [x] Remove the generated counter screen and template comments from `lib/main.dart`.
- [x] Keep `main.dart` focused on the app shell and dependency composition.
- [x] Construct `AssetRecipeRepository` with the root asset bundle.
- [x] Inject the repository into `RecipeCatalogScreen`.
- [x] Replace the counter widget test with an app-level catalogue smoke test.
- [x] Run the app-level widget test:

```bash
flutter test test/widget_test.dart
```

## 8. Replace the Integration Journey

- [x] Replace the counter flow in `integration_test/app_test.dart`.
- [x] Verify that the app launches with eight recipes.
- [x] Search for `mushroom` and verify that only Creamy Mushroom Pasta remains.
- [x] Open Creamy Mushroom Pasta and verify that the correct details appear.
- [x] Verify that metadata, ingredients, and cooking steps are visible.
- [x] Return to the catalogue and verify that the query and result remain.
- [x] Run the Android integration test:

```bash
make integration-test DEVICE=emulator-5554
```

## 9. Complete the Scope Audit

- [x] Confirm that no excluded feature has acquired UI, storage, or placeholder controls.
- [x] Verify portrait layouts from 320 dp through 412 dp wide.
- [x] Verify the catalogue and details at 200% text scaling.
- [x] Verify keyboard search and clear behavior.
- [x] Verify focus order and semantic labels.
- [x] Verify image cropping and fallback layout.
- [x] Verify catalogue and detail scrolling.
- [x] Force-stop and relaunch the app.
- [x] Confirm that all eight recipes remain available without network access.

## 10. Complete Final Validation

- [x] Confirm every acceptance criterion in [plan_incr1.md](plan_incr1.md#acceptance-criteria).
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

- [x] Hot restart a connected app and inspect the catalogue and detail journey for runtime errors.
- [ ] If the implementation is committed in `main...HEAD`, complete the repository review workflow.
