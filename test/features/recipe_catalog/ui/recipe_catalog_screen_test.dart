import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:cookbook/features/recipe_catalog/data/recipe_repository.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_card.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_catalog_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows loading while the repository is pending', (tester) async {
    final completer = Completer<List<Recipe>>();

    await tester.pumpWidget(
      _testApp(RecipeCatalogScreen(repository: _PendingRepository(completer))),
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
      _testApp(RecipeCatalogScreen(repository: repository)),
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
      _testApp(RecipeCatalogScreen(repository: _StaticRepository(const []))),
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
      _testApp(RecipeCatalogScreen(repository: repository)),
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
          _testApp(RecipeCatalogScreen(repository: _StaticRepository(recipes))),
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
      _testApp(RecipeCatalogScreen(repository: _StaticRepository(recipes))),
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
              imageAssetPath: 'assets/images/does_not_exist.png',
            ),
          ]),
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

Recipe _recipe({
  required String id,
  required String name,
  String imageAssetPath = 'assets/images/recipe_placeholder.png',
}) {
  return Recipe(
    id: id,
    name: name,
    servings: 4,
    prepMinutes: 10,
    cookMinutes: 25,
    imageAssetPath: imageAssetPath,
    ingredients: const <Ingredient>[
      Ingredient(name: 'ingredient', quantity: '1', unit: 'cup'),
    ],
    steps: const <String>['Cook the recipe.'],
  );
}

class _StaticRepository implements RecipeRepository {
  _StaticRepository(this.recipes);

  final List<Recipe> recipes;
  int callCount = 0;

  @override
  Future<List<Recipe>> getAllRecipes() async {
    callCount++;
    return recipes;
  }
}

class _PendingRepository implements RecipeRepository {
  _PendingRepository(this.completer);

  final Completer<List<Recipe>> completer;

  @override
  Future<List<Recipe>> getAllRecipes() => completer.future;
}

class _FailThenSucceedRepository implements RecipeRepository {
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
