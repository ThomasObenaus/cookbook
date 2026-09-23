import 'dart:async';

import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe_image.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_catalog_screen.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_detail_screen.dart';
import 'package:cookbook/features/recipe_creator/data/mutable_recipe_repository.dart';
import 'package:cookbook/features/recipe_creator/data/recipe_image_picker.dart';
import 'package:cookbook/features/recipe_creator/models/new_recipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'adds the exact ordered snapshot and permits later duplicate batches',
    (tester) async {
      final recipe = _fullRecipe();
      final batches = <List<Ingredient>>[];
      await tester.pumpWidget(
        _testApp(
          RecipeDetailScreen(
            recipe: recipe,
            onAddIngredients: (ingredients) async {
              batches.add(ingredients);
              return true;
            },
          ),
        ),
      );
      final button = find.byKey(const ValueKey<String>('add-to-shopping-list'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(
        batches.single.map((item) => item.toJson()),
        recipe.ingredients.map((item) => item.toJson()),
      );
      expect(() => batches.single.clear(), throwsUnsupportedError);
      expect(find.text('Ingredients added to shopping list.'), findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(batches, hasLength(2));
    },
  );

  testWidgets('blocks repeated taps until persistence confirms success', (
    tester,
  ) async {
    final save = Completer<bool>();
    var calls = 0;
    await tester.pumpWidget(
      _testApp(
        RecipeDetailScreen(
          recipe: _fullRecipe(),
          onAddIngredients: (_) {
            calls++;
            return save.future;
          },
        ),
      ),
    );
    final button = find.byKey(const ValueKey<String>('add-to-shopping-list'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.tap(button);
    await tester.pump();
    expect(calls, 1);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(find.text('Ingredients added to shopping list.'), findsNothing);
    save.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Ingredients added to shopping list.'), findsOneWidget);
  });

  testWidgets('failed additions show an error and can be retried', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      _testApp(
        RecipeDetailScreen(
          recipe: _fullRecipe(),
          onAddIngredients: (_) async {
            calls++;
            if (calls == 1) return false;
            if (calls == 2) throw StateError('storage');
            return true;
          },
        ),
      ),
    );
    final button = find.byKey(const ValueKey<String>('add-to-shopping-list'));
    await tester.ensureVisible(button);
    for (var attempt = 0; attempt < 2; attempt++) {
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(
        find.text('Ingredients could not be added. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Ingredients added to shopping list.'), findsNothing);
    }
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Ingredients added to shopping list.'), findsOneWidget);
    expect(
      find.text('Ingredients could not be added. Please try again.'),
      findsNothing,
    );
  });

  testWidgets(
    'leaving details during save does not report on a disposed route',
    (tester) async {
      final save = Completer<bool>();
      await tester.pumpWidget(
        _testApp(
          Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => RecipeDetailScreen(
                      recipe: _fullRecipe(),
                      onAddIngredients: (_) => save.future,
                    ),
                  ),
                ),
                child: const Text('Open recipe'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Open recipe'));
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey<String>('add-to-shopping-list'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      save.complete(true);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Ingredients added to shopping list.'), findsNothing);
    },
  );

  testWidgets('displays every recipe field and ordered step number', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(RecipeDetailScreen(recipe: _fullRecipe())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test Kitchen Pasta'), findsOneWidget);
    expect(find.text('Serves 3'), findsOneWidget);
    expect(find.text('Preparation 12 min'), findsOneWidget);
    expect(find.text('Cooking 28 min'), findsOneWidget);
    expect(find.text('Ingredients'), findsOneWidget);
    expect(find.text('2 cups flour (sifted)'), findsOneWidget);
    expect(find.text('salt'), findsOneWidget);
    expect(find.text('to taste pepper'), findsOneWidget);
    expect(find.text('Method'), findsOneWidget);
    expect(find.text('Mix the ingredients.'), findsOneWidget);
    expect(find.text('Cook until golden.'), findsOneWidget);
    expect(find.text('Plate and serve.'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('scrolls at 320 dp with 200% text scaling', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      _testApp(
        RecipeDetailScreen(
          recipe: _fullRecipe(),
          onAddIngredients: (_) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final button = find.byKey(const ValueKey<String>('add-to-shopping-list'));
    await tester.ensureVisible(button);
    expect(find.bySemanticsLabel('Add to shopping list'), findsOneWidget);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Ingredients added to shopping list.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Plate and serve.'),
      300,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey<String>('recipe-detail-scroll-view')),
        matching: find.byType(Scrollable),
      ),
    );

    expect(find.text('Plate and serve.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens details and retains search state after back navigation', (
    tester,
  ) async {
    final mushroomRecipe = _recipe(
      id: 'mushroom',
      name: 'Creamy Mushroom Pasta',
    );
    final tomatoRecipe = _recipe(id: 'tomato', name: 'Tomato Basil Pasta');

    await tester.pumpWidget(
      _testApp(
        RecipeCatalogScreen(
          repository: _StaticRepository(<Recipe>[tomatoRecipe, mushroomRecipe]),
          imagePicker: const _FakePicker(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final searchField = find.byKey(
      const ValueKey<String>('recipe-search-field'),
    );
    await tester.enterText(searchField, 'mushroom');
    await tester.pump();
    expect(find.text('Tomato Basil Pasta'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('recipe-card-mushroom')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RecipeDetailScreen), findsOneWidget);
    expect(find.text('Creamy Mushroom Pasta'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(searchField);
    expect(textField.controller?.text, 'mushroom');
    expect(find.text('Creamy Mushroom Pasta'), findsOneWidget);
    expect(find.text('Tomato Basil Pasta'), findsNothing);
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

Recipe _fullRecipe() {
  return Recipe(
    id: 'test-kitchen-pasta',
    name: 'Test Kitchen Pasta',
    servings: 3,
    prepMinutes: 12,
    cookMinutes: 28,
    image: RecipeImage.asset('assets/images/recipe_placeholder.png'),
    ingredients: const <Ingredient>[
      Ingredient(name: 'flour', quantity: '2', unit: 'cups', note: 'sifted'),
      Ingredient(name: 'salt'),
      Ingredient(name: 'pepper', quantity: 'to taste'),
    ],
    steps: const <String>[
      'Mix the ingredients.',
      'Cook until golden.',
      'Plate and serve.',
    ],
  );
}

Recipe _recipe({required String id, required String name}) {
  return Recipe(
    id: id,
    name: name,
    servings: 4,
    prepMinutes: 10,
    cookMinutes: 25,
    image: RecipeImage.asset('assets/images/recipe_placeholder.png'),
    ingredients: const <Ingredient>[Ingredient(name: 'ingredient')],
    steps: const <String>['Cook the recipe.'],
  );
}

class _StaticRepository implements MutableRecipeRepository {
  _StaticRepository(this.recipes);

  final List<Recipe> recipes;

  @override
  Future<List<Recipe>> getAllRecipes() async => recipes;

  @override
  Future<Recipe> createRecipe(NewRecipe recipe) async {
    throw UnsupportedError('Creation is not used by this test.');
  }
}

class _FakePicker implements RecipeImagePicker {
  const _FakePicker();

  @override
  Future<String?> pickFromGallery() async => null;
}
