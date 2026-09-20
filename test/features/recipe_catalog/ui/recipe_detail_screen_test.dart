import 'package:cookbook/features/recipe_catalog/data/recipe_repository.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_catalog_screen.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
      _testApp(RecipeDetailScreen(recipe: _fullRecipe())),
    );
    await tester.pumpAndSettle();

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
    imageAssetPath: 'assets/images/recipe_placeholder.png',
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
    imageAssetPath: 'assets/images/recipe_placeholder.png',
    ingredients: const <Ingredient>[Ingredient(name: 'ingredient')],
    steps: const <String>['Cook the recipe.'],
  );
}

class _StaticRepository implements RecipeRepository {
  _StaticRepository(this.recipes);

  final List<Recipe> recipes;

  @override
  Future<List<Recipe>> getAllRecipes() async => recipes;
}
