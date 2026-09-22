import 'dart:async';
import 'dart:io';
import 'dart:ui' show SemanticsAction;

import 'package:cookbook/features/recipe_catalog/data/recipe_repository.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe_image.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_card.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_catalog_screen.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_detail_screen.dart';
import 'package:cookbook/features/recipe_creator/data/mutable_recipe_repository.dart';
import 'package:cookbook/features/recipe_creator/data/recipe_image_picker.dart';
import 'package:cookbook/features/recipe_creator/models/ingredient_unit.dart';
import 'package:cookbook/features/recipe_creator/models/new_recipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows loading while the repository is pending', (tester) async {
    final completer = Completer<List<Recipe>>();

    await tester.pumpWidget(
      _testApp(
        RecipeCatalogScreen(
          repository: _PendingRepository(completer),
          imagePicker: const _FakePicker(),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('recipe-loading-indicator')),
      findsOneWidget,
    );
  });

  testWidgets('loads once and displays recipe cards', (tester) async {
    final repository = _StaticRepository(<Recipe>[
      _recipe(id: 'mushroom', name: 'Creamy Mushroom Pasta'),
      _recipe(id: 'pancakes', name: 'Banana Oat Pancakes'),
    ]);

    await tester.pumpWidget(
      _testApp(
        RecipeCatalogScreen(
          repository: repository,
          imagePicker: const _FakePicker(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.callCount, 1);
    expect(find.text('Creamy Mushroom Pasta'), findsOneWidget);
    expect(find.text('Banana Oat Pancakes'), findsOneWidget);
    expect(find.text('35 min'), findsNWidgets(2));
    expect(find.text('Serves 4'), findsNWidgets(2));

    await tester.pump();
    expect(repository.callCount, 1);
  });

  testWidgets('shows an empty-catalogue state', (tester) async {
    await tester.pumpWidget(
      _testApp(
        RecipeCatalogScreen(
          repository: _StaticRepository(const []),
          imagePicker: const _FakePicker(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('recipe-empty-state')),
      findsOneWidget,
    );
    expect(find.text('No recipes yet'), findsOneWidget);
  });

  testWidgets('shows a friendly error and retries the load', (tester) async {
    final repository = _FailThenSucceedRepository(<Recipe>[
      _recipe(id: 'mushroom', name: 'Creamy Mushroom Pasta'),
    ]);

    await tester.pumpWidget(
      _testApp(
        RecipeCatalogScreen(
          repository: repository,
          imagePicker: const _FakePicker(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('recipe-error-state')),
      findsOneWidget,
    );
    expect(
      find.text('Recipes could not be loaded. Please try again.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pumpAndSettle();

    expect(repository.callCount, 2);
    expect(find.text('Creamy Mushroom Pasta'), findsOneWidget);
  });

  testWidgets('searches live and clears the query', (tester) async {
    await tester.pumpWidget(
      _testApp(
        RecipeCatalogScreen(
          repository: _StaticRepository(<Recipe>[
            _recipe(id: 'tomato', name: 'Tomato Basil Pasta'),
            _recipe(id: 'mushroom', name: 'Creamy Mushroom Pasta'),
          ]),
          imagePicker: const _FakePicker(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('recipe-search-field')),
      '  MUSHROOM  ',
    );
    await tester.pump();

    expect(find.text('Tomato Basil Pasta'), findsNothing);
    expect(find.text('Creamy Mushroom Pasta'), findsOneWidget);
    expect(find.byTooltip('Clear search'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();

    expect(find.text('Tomato Basil Pasta'), findsOneWidget);
    expect(find.text('Creamy Mushroom Pasta'), findsOneWidget);
    expect(find.byTooltip('Clear search'), findsNothing);
  });

  testWidgets('shows a dedicated no-results state', (tester) async {
    await tester.pumpWidget(
      _testApp(
        RecipeCatalogScreen(
          repository: _StaticRepository(<Recipe>[
            _recipe(id: 'mushroom', name: 'Creamy Mushroom Pasta'),
          ]),
          imagePicker: const _FakePicker(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('recipe-search-field')),
      'risotto',
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('recipe-no-results-state')),
      findsOneWidget,
    );
    expect(find.text('No recipes found'), findsOneWidget);
    expect(find.text('No recipe names match "risotto".'), findsOneWidget);
  });

  testWidgets('creator cancellation preserves the catalogue query', (
    tester,
  ) async {
    final repository = _CreatingRepository(<Recipe>[
      _recipe(id: 'mushroom', name: 'Creamy Mushroom Pasta'),
      _recipe(id: 'tomato', name: 'Tomato Basil Pasta'),
    ]);
    await tester.pumpWidget(
      _testApp(
        RecipeCatalogScreen(
          repository: repository,
          imagePicker: const _FakePicker(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final searchField = find.byKey(
      const ValueKey<String>('recipe-search-field'),
    );
    await tester.enterText(searchField, 'mushroom');

    await tester.tap(find.byTooltip('Create recipe'));
    await tester.pumpAndSettle();
    expect(find.text('Create recipe'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(repository.readCount, 1);
    expect(tester.widget<TextField>(searchField).controller?.text, 'mushroom');
    expect(find.text('Creamy Mushroom Pasta'), findsOneWidget);
    expect(find.text('Tomato Basil Pasta'), findsNothing);
  });

  testWidgets('successful creation clears search, reloads, and opens details', (
    tester,
  ) async {
    final repository = _CreatingRepository(<Recipe>[
      _recipe(id: 'mushroom', name: 'Creamy Mushroom Pasta'),
      _recipe(id: 'tomato', name: 'Tomato Basil Pasta'),
    ]);
    final imagePath = File('assets/images/recipe_placeholder.png')
        .absolute
        .path;
    await tester.pumpWidget(
      _testApp(
        RecipeCatalogScreen(
          repository: repository,
          imagePicker: _FakePicker(imagePath),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final searchField = find.byKey(
      const ValueKey<String>('recipe-search-field'),
    );
    await tester.enterText(searchField, 'mushroom');

    await _createRecipe(tester, title: 'Family Soup');

    expect(repository.readCount, 2);
    expect(tester.widget<TextField>(searchField).controller?.text, isEmpty);
    expect(find.text('Family Soup'), findsOneWidget);
    expect(find.text('Tomato Basil Pasta'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('recipe-card-created-recipe')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RecipeDetailScreen), findsOneWidget);
    expect(find.text('1 cup carrots'), findsOneWidget);
    expect(find.text('Chop the carrots.'), findsOneWidget);
    expect(find.text('Preparation 0 min'), findsOneWidget);
    expect(find.text('Cooking 0 min'), findsOneWidget);
  });

  testWidgets('shows the recoverable error state when post-save reload fails', (
    tester,
  ) async {
    final repository = _CreatingRepository(<Recipe>[
      _recipe(id: 'mushroom', name: 'Creamy Mushroom Pasta'),
    ], failReloadAfterCreation: true);
    final imagePath = File('assets/images/recipe_placeholder.png')
        .absolute
        .path;
    await tester.pumpWidget(
      _testApp(
        RecipeCatalogScreen(
          repository: repository,
          imagePicker: _FakePicker(imagePath),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _createRecipe(tester, title: 'Family Soup');

    expect(
      find.byKey(const ValueKey<String>('recipe-error-state')),
      findsOneWidget,
    );
    expect(
      find.text('Recipes could not be loaded. Please try again.'),
      findsOneWidget,
    );
  });

  for (final width in <double>[320, 412]) {
    testWidgets(
      'uses two columns at ${width.toInt()} dp and survives 200% text scaling',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final recipes = List<Recipe>.generate(
          4,
          (index) => _recipe(
            id: 'recipe-$index',
            name: 'A Deliberately Long Recipe Name $index',
          ),
        );

        await tester.pumpWidget(
          _testApp(
            RecipeCatalogScreen(
              repository: _StaticRepository(recipes),
              imagePicker: const _FakePicker(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final cards = find.byType(RecipeCard);
        expect(cards, findsNWidgets(4));
        expect(
          tester.getTopLeft(cards.at(0)).dy,
          tester.getTopLeft(cards.at(1)).dy,
        );
        expect(
          tester.getTopLeft(cards.at(2)).dy,
          greaterThan(tester.getTopLeft(cards.at(0)).dy),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('adds a third grid column when width permits', (tester) async {
    tester.view.physicalSize = const Size(700, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final recipes = List<Recipe>.generate(
      4,
      (index) => _recipe(id: 'recipe-$index', name: 'Recipe $index'),
    );

    await tester.pumpWidget(
      _testApp(
        RecipeCatalogScreen(
          repository: _StaticRepository(recipes),
          imagePicker: const _FakePicker(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cards = find.byType(RecipeCard);
    expect(
      tester.getTopLeft(cards.at(0)).dy,
      tester.getTopLeft(cards.at(2)).dy,
    );
    expect(
      tester.getTopLeft(cards.at(3)).dy,
      greaterThan(tester.getTopLeft(cards.at(0)).dy),
    );
  });

  testWidgets('recovers from a transient zero-sized viewport', (tester) async {
    tester.view.physicalSize = Size.zero;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        RecipeCatalogScreen(
          repository: _StaticRepository(<Recipe>[
            _recipe(id: 'mushroom', name: 'Creamy Mushroom Pasta'),
          ]),
          imagePicker: const _FakePicker(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(320, 640);
    await tester.pumpAndSettle();

    expect(find.text('Creamy Mushroom Pasta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exposes a semantic card action with a large touch target', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _testApp(
        RecipeCatalogScreen(
          repository: _StaticRepository(<Recipe>[
            _recipe(id: 'mushroom', name: 'Creamy Mushroom Pasta'),
          ]),
          imagePicker: const _FakePicker(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cardSemantics = find.bySemanticsLabel(
      'Open Creamy Mushroom Pasta, 35 minutes, serves 4',
    );
    expect(cardSemantics, findsOneWidget);
    expect(
      tester
          .getSemantics(cardSemantics)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    final cardSize = tester.getSize(find.byType(RecipeCard));
    expect(cardSize.width, greaterThanOrEqualTo(48));
    expect(cardSize.height, greaterThanOrEqualTo(48));
    semantics.dispose();
  });

  testWidgets('shows a stable fallback when a recipe image is missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        RecipeCatalogScreen(
          repository: _StaticRepository(<Recipe>[
            _recipe(
              id: 'missing-image',
              name: 'Missing Image Recipe',
              image: RecipeImage.asset('assets/images/does_not_exist.png'),
            ),
          ]),
          imagePicker: const _FakePicker(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('recipe-image-fallback-missing-image')),
      findsOneWidget,
    );
    expect(find.text('Missing Image Recipe'), findsOneWidget);
  });
}

Widget _testApp(Widget home) {
  return MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
    ),
    home: home,
  );
}

Future<void> _createRecipe(WidgetTester tester, {required String title}) async {
  await tester.tap(find.byTooltip('Create recipe'));
  await tester.pumpAndSettle();

  await _tapCreatorKey(tester, 'recipe-image-control');

  final titleField = find.byKey(const ValueKey<String>('recipe-title-field'));
  await tester.ensureVisible(titleField);
  await tester.enterText(titleField, title);
  await _tapCreatorKey(tester, 'wizard-continue');

  final ingredientName = find.byKey(
    const ValueKey<String>('ingredient-name-field'),
  );
  await tester.ensureVisible(ingredientName);
  await tester.enterText(ingredientName, 'carrots');
  await tester.enterText(
    find.byKey(const ValueKey<String>('ingredient-quantity-field')),
    '1',
  );
  await tester.tap(find.byKey(const ValueKey<String>('ingredient-unit-field')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(IngredientUnit.cup.label).last);
  await tester.pumpAndSettle();
  await _tapCreatorKey(tester, 'save-ingredient');
  await _tapCreatorKey(tester, 'wizard-continue');

  final step = find.byKey(const ValueKey<String>('preparation-step-field'));
  await tester.ensureVisible(step);
  await tester.enterText(step, 'Chop the carrots.');
  await _tapCreatorKey(tester, 'save-preparation-step');
  await _tapCreatorKey(tester, 'add-preparation-step');
  await tester.enterText(step, 'Cook until tender.');
  await _tapCreatorKey(tester, 'save-preparation-step');
  await _tapCreatorKey(tester, 'wizard-continue');
  await _tapCreatorKey(tester, 'save-recipe');
}

Future<void> _tapCreatorKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey<String>(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Recipe _recipe({required String id, required String name, RecipeImage? image}) {
  return Recipe(
    id: id,
    name: name,
    servings: 4,
    prepMinutes: 10,
    cookMinutes: 25,
    image: image ?? RecipeImage.asset('assets/images/recipe_placeholder.png'),
    ingredients: const <Ingredient>[
      Ingredient(name: 'ingredient', quantity: '1', unit: 'cup'),
    ],
    steps: const <String>['Cook the recipe.'],
  );
}

abstract class _ReadOnlyMutableRepository implements MutableRecipeRepository {
  @override
  Future<Recipe> createRecipe(NewRecipe recipe) async {
    throw UnsupportedError('Creation is not used by this test.');
  }
}

class _StaticRepository extends _ReadOnlyMutableRepository {
  _StaticRepository(this.recipes);

  final List<Recipe> recipes;
  int callCount = 0;

  @override
  Future<List<Recipe>> getAllRecipes() async {
    callCount++;
    return recipes;
  }
}

class _PendingRepository extends _ReadOnlyMutableRepository {
  _PendingRepository(this.completer);

  final Completer<List<Recipe>> completer;

  @override
  Future<List<Recipe>> getAllRecipes() => completer.future;
}

class _FailThenSucceedRepository extends _ReadOnlyMutableRepository {
  _FailThenSucceedRepository(this.recipes);

  final List<Recipe> recipes;
  int callCount = 0;

  @override
  Future<List<Recipe>> getAllRecipes() async {
    callCount++;
    if (callCount == 1) {
      throw RecipeRepositoryException(
        message: 'Recipes could not be loaded. Please try again.',
        cause: const FormatException('Invalid recipes.'),
        stackTrace: StackTrace.current,
      );
    }
    return recipes;
  }
}

class _FakePicker implements RecipeImagePicker {
  const _FakePicker([this.path]);

  final String? path;

  @override
  Future<String?> pickFromGallery() async => path;
}

class _CreatingRepository implements MutableRecipeRepository {
  _CreatingRepository(
    List<Recipe> recipes, {
    this.failReloadAfterCreation = false,
  }) : _recipes = List<Recipe>.of(recipes);

  final List<Recipe> _recipes;
  final bool failReloadAfterCreation;
  int readCount = 0;
  bool _hasCreatedRecipe = false;

  @override
  Future<List<Recipe>> getAllRecipes() async {
    readCount++;
    if (_hasCreatedRecipe && failReloadAfterCreation) {
      throw RecipeRepositoryException(
        message: 'Recipes could not be loaded. Please try again.',
        cause: const FormatException('Reload failed.'),
        stackTrace: StackTrace.current,
      );
    }
    return List<Recipe>.unmodifiable(_recipes);
  }

  @override
  Future<Recipe> createRecipe(NewRecipe newRecipe) async {
    final recipe = Recipe(
      id: 'created-recipe',
      name: newRecipe.name,
      servings: 4,
      prepMinutes: 0,
      cookMinutes: 0,
      image: RecipeImage.file(newRecipe.sourceImagePath),
      ingredients: newRecipe.ingredients,
      steps: newRecipe.steps,
    );
    _recipes.insert(0, recipe);
    _hasCreatedRecipe = true;
    return recipe;
  }
}
