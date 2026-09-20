import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe_image.dart';
import 'package:cookbook/features/recipe_creator/data/mutable_recipe_repository.dart';
import 'package:cookbook/features/recipe_creator/data/recipe_image_picker.dart';
import 'package:cookbook/features/recipe_creator/models/new_recipe.dart';
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
            image: RecipeImage.asset('assets/images/recipe_placeholder.png'),
            ingredients: const <Ingredient>[
              Ingredient(name: 'spaghetti', quantity: '350', unit: 'g'),
            ],
            steps: const <String>['Cook the pasta.'],
          ),
        ]),
        imagePicker: const _FakePicker(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Recipes'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Search recipes'), findsOneWidget);
    expect(find.text('Tomato Basil Pasta'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);
    expect(find.text('Serves 4'), findsOneWidget);
    expect(find.byTooltip('Create recipe'), findsOneWidget);
  });

  testWidgets('shows a controlled state when startup configuration fails', (
    tester,
  ) async {
    final root = await createCookbookApp(
      supportDirectoryProvider: () async => throw Exception('unavailable'),
    );

    await tester.pumpWidget(root);

    expect(
      find.byKey(const ValueKey<String>('cookbook-startup-error')),
      findsOneWidget,
    );
  });
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
