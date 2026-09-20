import 'package:cookbook/features/recipe_catalog/logic/recipe_search.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final recipes = <Recipe>[
    _recipe(
      id: 'tomato-pasta',
      name: 'Tomato Basil Pasta',
      ingredient: 'mushrooms',
      step: 'Finish with lemon.',
    ),
    _recipe(
      id: 'mushroom-pasta',
      name: 'Creamy Mushroom Pasta',
      ingredient: 'cardamom',
      step: 'Simmer gently.',
    ),
    _recipe(
      id: 'pancakes',
      name: 'Banana Oat Pancakes',
      ingredient: 'banana',
      step: 'Cook until golden.',
    ),
  ];

  test('returns all recipes in source order for an empty query', () {
    expect(searchRecipesByName(recipes, ''), orderedEquals(recipes));
  });

  test('matches a partial recipe name and preserves source order', () {
    final results = searchRecipesByName(recipes, 'pasta');

    expect(results.map((recipe) => recipe.id), <String>[
      'tomato-pasta',
      'mushroom-pasta',
    ]);
  });

  test('matches names case-insensitively', () {
    expect(
      searchRecipesByName(recipes, 'mUsHrOoM').single.id,
      'mushroom-pasta',
    );
  });

  test('trims surrounding query whitespace', () {
    expect(
      searchRecipesByName(recipes, '  banana oat  ').single.id,
      'pancakes',
    );
  });

  test('returns no recipes for an unmatched query', () {
    expect(searchRecipesByName(recipes, 'risotto'), isEmpty);
  });

  test('does not match ingredient-only text', () {
    final results = searchRecipesByName(recipes, 'cardamom');

    expect(results, isEmpty);
  });

  test('does not match instruction-only text', () {
    final results = searchRecipesByName(recipes, 'lemon');

    expect(results, isEmpty);
  });
}

Recipe _recipe({
  required String id,
  required String name,
  required String ingredient,
  required String step,
}) {
  return Recipe(
    id: id,
    name: name,
    servings: 4,
    prepMinutes: 10,
    cookMinutes: 20,
    imageAssetPath: 'assets/images/recipe_placeholder.png',
    ingredients: <Ingredient>[Ingredient(name: ingredient)],
    steps: <String>[step],
  );
}
