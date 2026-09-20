# Recipe Catalogue: Increment 1 Implementation Steps

Complete the steps in order. A step is complete only when all of its tasks and its focused check are checked.

## 1. Add the Domain Model

- [ ] Create immutable `Ingredient` and `Recipe` types.
- [ ] Add validated JSON factories.
- [ ] Copy parsed collections into immutable lists.
- [ ] Add the derived total cooking time.
- [ ] Test valid recipe and ingredient parsing.
- [ ] Test every required field, type, range, and empty-list boundary.
- [ ] Run the focused model test:

```bash
flutter test test/features/recipe_catalog/models/recipe_test.dart
```

## 2. Add Local Recipe Assets

- [ ] Create `assets/data/recipes.json` with the eight recipes defined in the plan.
- [ ] Give every recipe at least four ingredients and three cooking steps.
- [ ] Create `assets/images/recipe_placeholder.png` with a 4:3 aspect ratio.
- [ ] Reference the shared placeholder image from every recipe.
- [ ] Register both explicit asset paths in `pubspec.yaml`.
- [ ] Verify that the JSON and image load from the Flutter asset bundle.
- [ ] Resolve the asset declaration changes:

```bash
flutter pub get
```

## 3. Add the Replaceable Repository

- [ ] Define the `RecipeRepository` contract with one asynchronous all-recipes operation.
- [ ] Define a domain-specific repository exception.
- [ ] Implement `AssetRecipeRepository` with an injected `AssetBundle`.
- [ ] Decode and validate the complete recipe collection once per load.
- [ ] Reject duplicate recipe IDs.
- [ ] Return an immutable recipe list.
- [ ] Convert asset, decoding, and validation failures into repository errors.
- [ ] Retain useful diagnostic context without exposing technical details in the UI.
- [ ] Test successful loading with a small fake asset bundle.
- [ ] Test missing assets, malformed JSON, invalid recipes, and duplicate IDs.
- [ ] Run the focused repository tests:

```bash
flutter test test/features/recipe_catalog/data
```

## 4. Add Name Search

- [ ] Implement search as a pure synchronous function over the loaded recipe list.
- [ ] Trim surrounding query whitespace.
- [ ] Match a case-insensitive substring of `Recipe.name` only.
- [ ] Preserve source order in the results.
- [ ] Return all recipes for an empty query.
- [ ] Keep search out of the repository so typing never reloads assets.
- [ ] Test empty, partial, case-insensitive, whitespace-trimmed, and unmatched queries.
- [ ] Verify that ingredient-only and instruction-only queries do not match.
- [ ] Run the focused search tests:

```bash
flutter test test/features/recipe_catalog/logic
```

## 5. Build the Catalogue Grid

- [ ] Create `RecipeCatalogScreen` with an injected `RecipeRepository`.
- [ ] Load recipes exactly once for the screen lifecycle.
- [ ] Check `mounted` after asynchronous loading before updating widget state.
- [ ] Represent loading, success, empty-catalogue, and failure states explicitly.
- [ ] Add a Retry action for load failures.
- [ ] Add the live name-search field and a visible clear action.
- [ ] Derive displayed recipes from the loaded list and current query.
- [ ] Display a dedicated no-search-results state.
- [ ] Build an image grid using width-based maximum tile extents.
- [ ] Show two columns on common phone widths and add columns when space permits.
- [ ] Keep image and text regions constrained under long names and large text.
- [ ] Create `RecipeCard` with image, name, total time, and servings.
- [ ] Use `InkWell`, semantic labels, and touch targets of at least 48 dp.
- [ ] Add a stable icon fallback for missing images.
- [ ] Test loading, success, empty, error, retry, and no-results states.
- [ ] Test search and clear interactions.
- [ ] Test grid behavior at narrow widths and 200% text scaling.
- [ ] Test the missing-image fallback.
- [ ] Run the focused catalogue tests:

```bash
flutter test test/features/recipe_catalog/ui/recipe_catalog_screen_test.dart
```

## 6. Build Recipe Details

- [ ] Create a vertically scrollable `RecipeDetailScreen`.
- [ ] Display the recipe image and name.
- [ ] Display servings, preparation time, and cooking time.
- [ ] Display every structured ingredient.
- [ ] Omit awkward separators or gaps when quantity, unit, or note is absent.
- [ ] Display cooking steps in their stored order with visible numbers.
- [ ] Push the screen with Flutter's built-in `Navigator` and `MaterialPageRoute`.
- [ ] Test every displayed recipe field.
- [ ] Test scrolling at narrow widths and 200% text scaling.
- [ ] Test navigation to details and back to the catalogue.
- [ ] Verify that back navigation retains the search query and filtered results.
- [ ] Run the focused detail tests:

```bash
flutter test test/features/recipe_catalog/ui/recipe_detail_screen_test.dart
```

## 7. Compose the Application

- [ ] Remove the generated counter screen and template comments from `lib/main.dart`.
- [ ] Keep `main.dart` focused on the app shell and dependency composition.
- [ ] Construct `AssetRecipeRepository` with the root asset bundle.
- [ ] Inject the repository into `RecipeCatalogScreen`.
- [ ] Replace the counter widget test with an app-level catalogue smoke test.
- [ ] Run the app-level widget test:

```bash
flutter test test/widget_test.dart
```

## 8. Replace the Integration Journey

- [ ] Replace the counter flow in `integration_test/app_test.dart`.
- [ ] Verify that the app launches with eight recipes.
- [ ] Search for `mushroom` and verify that only Creamy Mushroom Pasta remains.
- [ ] Open Creamy Mushroom Pasta and verify that the correct details appear.
- [ ] Verify that metadata, ingredients, and cooking steps are visible.
- [ ] Return to the catalogue and verify that the query and result remain.
- [ ] Run the Android integration test:

```bash
make integration-test DEVICE=emulator-5554
```

## 9. Complete the Scope Audit

- [ ] Confirm that no excluded feature has acquired UI, storage, or placeholder controls.
- [ ] Verify portrait layouts from 320 dp through 412 dp wide.
- [ ] Verify the catalogue and details at 200% text scaling.
- [ ] Verify keyboard search and clear behavior.
- [ ] Verify focus order and semantic labels.
- [ ] Verify image cropping and fallback layout.
- [ ] Verify catalogue and detail scrolling.
- [ ] Force-stop and relaunch the app.
- [ ] Confirm that all eight recipes remain available without network access.

## 10. Complete Final Validation

- [ ] Confirm every acceptance criterion in [plan_incr1.md](plan_incr1.md#acceptance-criteria).
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

- [ ] Hot restart a connected app and inspect the catalogue and detail journey for runtime errors.
- [ ] If the implementation is committed in `main...HEAD`, complete the repository review workflow.
