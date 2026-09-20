import 'package:cookbook/features/recipe_catalog/data/recipe_repository.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app launches into the recipe catalogue', (tester) async {
    await tester.pumpWidget(
      CookbookApp(
        repository: _StaticRepository(<Recipe>[
          Recipe(
            id: 'tomato-basil-pasta',
            name: 'Tomato Basil Pasta',
            servings: 4,
            prepMinutes: 10,
            cookMinutes: 20,
            imageAssetPath: 'assets/images/recipe_placeholder.png',
            ingredients: const <Ingredient>[
              Ingredient(name: 'spaghetti', quantity: '350', unit: 'g'),
            ],
            steps: const <String>['Cook the pasta.'],
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Recipes'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Search recipes'), findsOneWidget);
    expect(find.text('Tomato Basil Pasta'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);
    expect(find.text('Serves 4'), findsOneWidget);
  });
}

class _StaticRepository implements RecipeRepository {
  _StaticRepository(this.recipes);

  final List<Recipe> recipes;

  @override
  Future<List<Recipe>> getAllRecipes() async => recipes;
}
