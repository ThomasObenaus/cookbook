# Recipe Catalogue: Increment 1 Implementation Plan

## Goal

Replace the Flutter counter template with a read-only recipe catalogue that lets the family:

- browse recipes in an image grid;
- search recipes by name;
- open a recipe and read its cooking details; and
- use the catalogue without a network connection.

Recipe data will be bundled as JSON and loaded through a replaceable repository. This is the simplest local storage for a read-only increment and allows a later increment to replace it with writable device storage or shared cloud persistence without changing the catalogue UI.

## Agreed Decisions

- Ship eight realistic sample recipes.
- Use one bundled 4:3 placeholder image for every sample recipe.
- Display recipes in an image grid at all supported widths.
- Include cooking basics: name, image, servings, preparation time, cooking time, structured ingredients, and ordered steps.
- Keep state local to Flutter widgets with `StatefulWidget` and `setState`.
- Add no database, network client, state-management framework, or storage plugin in this increment.
- Keep persistence replaceable through an injected `RecipeRepository` contract.

## Scope

### Included

- Loading locally bundled recipe data.
- Loading and displaying bundled recipe images.
- Browsing all recipes in a responsive grid.
- Live name-only search.
- Loading, error, empty-catalogue, and no-search-results states.
- A recipe detail screen with ingredients and numbered instructions.
- Back navigation that retains the current search and results.
- Automated tests for parsing, loading, search, presentation, and navigation.

### Excluded

- Creating, editing, or deleting recipes.
- Searching ingredients, steps, or tags.
- Sorting and filtering.
- Favorites or pinned recipes.
- Meal planning and shopping lists.
- Cook mode and timers.
- Accounts, invitations, sharing, backend access, or cross-device sync.
- User-selected or downloaded pictures.

## User Experience

### Catalogue

1. The app opens on a Recipes screen.
2. A search field appears above the recipe grid.
3. Each card shows the placeholder image, recipe name, total time, and servings.
4. The grid uses two columns on common phone widths and adds columns when space permits.
5. Selecting a card opens that recipe's detail screen.

### Search

- Filter the already-loaded recipe list as the user types.
- Trim surrounding query whitespace.
- Match a case-insensitive substring of the recipe name.
- Preserve the original recipe order.
- Show every recipe for an empty query.
- Show a dedicated no-results state when nothing matches.
- Do not match text found only in ingredients or instructions.
- Provide a visible clear-search action.

### Recipe Details

The detail screen is vertically scrollable and shows:

- the recipe image;
- recipe name;
- servings;
- preparation time;
- cooking time;
- structured ingredient rows; and
- numbered cooking steps.

Returning to the catalogue preserves the search query and filtered result set.

## Data Design

### Ingredient

- `name`: required, non-empty string.
- `quantity`: optional string so fractions and values such as `to taste` remain representable.
- `unit`: optional string.
- `note`: optional string.

### Recipe

- `id`: required, stable, non-empty, and unique.
- `name`: required, non-empty string.
- `servings`: required positive integer.
- `prepMinutes`: required non-negative integer.
- `cookMinutes`: required non-negative integer.
- `imageAssetPath`: required non-empty asset path.
- `ingredients`: required non-empty immutable list of `Ingredient` values.
- `steps`: required non-empty immutable ordered list of non-empty strings.
- `totalMinutes`: derived from preparation and cooking time.

JSON parsing must reject wrong types, invalid ranges, empty required values, empty ingredient or step lists, and duplicate recipe IDs. Repository errors shown in the UI must use a friendly message while retaining useful diagnostic context for development.

## Sample Content

Create eight concise, original sample recipes:

1. Tomato Basil Pasta
2. Creamy Mushroom Pasta
3. Lemon Herb Chicken
4. Vegetable Fried Rice
5. Red Lentil Curry
6. Banana Oat Pancakes
7. Roasted Vegetable Tray Bake
8. Apple Crumble

Each recipe should contain at least four ingredients and three cooking steps. All recipes reference the same copyright-safe bundled placeholder image.

## Architecture

Organize the implementation by feature:

```text
assets/
  data/recipes.json
  images/recipe_placeholder.png
lib/
  main.dart
  features/recipe_catalog/
    data/
      asset_recipe_repository.dart
      recipe_repository.dart
    logic/
      recipe_search.dart
    models/
      recipe.dart
    ui/
      recipe_card.dart
      recipe_catalog_screen.dart
      recipe_detail_screen.dart
test/
  features/recipe_catalog/
    data/
    logic/
    models/
    ui/
```

### Responsibilities

- `Recipe` and `Ingredient` are immutable domain values and own validated JSON conversion.
- `RecipeRepository` exposes one asynchronous operation that returns all recipes.
- `AssetRecipeRepository` knows about `AssetBundle`, the JSON asset path, decoding, and repository error conversion.
- `recipe_search.dart` contains a pure synchronous name filter over an already-loaded list.
- `RecipeCatalogScreen` owns loading state and the search query.
- `RecipeCard` owns stable grid-card presentation, semantics, and the missing-image fallback.
- `RecipeDetailScreen` presents one recipe and contains no data-access logic.
- `main.dart` is the composition root and injects the production repository.

The repository must not expose speculative create, update, delete, favorite, or search methods. A future persistence implementation only needs to satisfy the all-recipes contract for this increment.

## Implementation Steps

Track implementation progress in [steps_incr1.md](steps_incr1.md).

## Acceptance Criteria

- The app displays exactly eight recipes in JSON order after loading.
- Every card displays its image, name, total time, and servings without clipping or overlap.
- Search follows the documented name-only behavior.
- Unmatched searches display a clear no-results state.
- Selecting any card opens the matching detail screen.
- Every detail screen displays all recipe fields and remains scrollable with large text.
- Back navigation retains catalogue search state.
- Missing or malformed data produces a recoverable error state instead of a crash.
- A missing image displays the fallback without changing the card layout.
- The feature works offline and requires no account or external service.
- Focused tests, static analysis, the Android integration journey, and the debug build all pass.

## Final Validation

Run the complete repository checks after all focused tests pass:

```bash
make lint
make test
make integration-test DEVICE=emulator-5554
make build
```

After Flutter code changes, hot restart a connected app and inspect the catalogue and detail journey for runtime errors. If the implementation is committed in `main...HEAD`, follow the repository review workflow before creating or updating the pull request.
