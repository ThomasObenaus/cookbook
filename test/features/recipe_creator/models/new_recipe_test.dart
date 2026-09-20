import 'package:cookbook/features/recipe_creator/models/ingredient_unit.dart';
import 'package:cookbook/features/recipe_creator/models/new_recipe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes form input and preserves ordered preparation steps', () {
    final recipe = NewRecipe.fromInput(
      name: '  Sunday Soup  ',
      ingredients: const <IngredientDraft>[
        IngredientDraft(
          name: ' carrots ',
          quantity: ' 2 ',
          unit: IngredientUnit.gram,
          note: ' chopped ',
        ),
        IngredientDraft(),
        IngredientDraft(name: 'salt'),
      ],
      steps: const <String>[' Chop vegetables. ', ' Simmer gently. '],
      sourceImagePath: ' /tmp/soup.jpg ',
    );

    expect(recipe.name, 'Sunday Soup');
    expect(recipe.sourceImagePath, '/tmp/soup.jpg');
    expect(recipe.ingredients, hasLength(2));
    expect(recipe.ingredients.first.name, 'carrots');
    expect(recipe.ingredients.first.quantity, '2');
    expect(recipe.ingredients.first.unit, 'g');
    expect(recipe.ingredients.first.note, 'chopped');
    expect(recipe.ingredients.last.name, 'salt');
    expect(recipe.ingredients.last.quantity, isNull);
    expect(recipe.steps, <String>['Chop vegetables.', 'Simmer gently.']);
    expect(() => recipe.ingredients.clear(), throwsUnsupportedError);
    expect(() => recipe.steps.clear(), throwsUnsupportedError);
  });

  test('maps No unit to null without changing ingredient JSON', () {
    final recipe = NewRecipe.fromInput(
      name: 'Toast',
      ingredients: const <IngredientDraft>[
        IngredientDraft(name: 'bread', quantity: '1'),
      ],
      steps: const <String>['Toast the bread.'],
      sourceImagePath: '/tmp/toast.jpg',
    );

    expect(recipe.ingredients.single.unit, isNull);
    expect(recipe.ingredients.single.toJson(), <String, Object?>{
      'name': 'bread',
      'quantity': '1',
    });
  });

  test('copies source collections while preserving insertion order', () {
    final ingredients = <IngredientDraft>[
      const IngredientDraft(name: 'first'),
      const IngredientDraft(name: 'second'),
    ];
    final steps = <String>['First step.', 'Second step.'];

    final recipe = NewRecipe.fromInput(
      name: 'Ordered',
      ingredients: ingredients,
      steps: steps,
      sourceImagePath: '/tmp/ordered.jpg',
    );
    ingredients.removeAt(0);
    steps[0] = 'Changed after creation.';

    expect(recipe.ingredients.map((ingredient) => ingredient.name), <String>[
      'first',
      'second',
    ]);
    expect(recipe.steps, <String>['First step.', 'Second step.']);
  });

  test('rejects empty required text', () {
    expect(
      () => NewRecipe.fromInput(
        name: ' ',
        ingredients: const <IngredientDraft>[IngredientDraft(name: 'salt')],
        steps: const <String>['Season.'],
        sourceImagePath: '/tmp/image.jpg',
      ),
      throwsFormatException,
    );
    expect(
      () => NewRecipe.fromInput(
        name: 'Soup',
        ingredients: const <IngredientDraft>[IngredientDraft(name: 'salt')],
        steps: const <String>['Season.'],
        sourceImagePath: ' ',
      ),
      throwsFormatException,
    );
    expect(
      () => NewRecipe.fromInput(
        name: 'Soup',
        ingredients: const <IngredientDraft>[IngredientDraft(name: 'salt')],
        steps: const <String>[' '],
        sourceImagePath: '/tmp/image.jpg',
      ),
      throwsFormatException,
    );
  });

  test('requires one complete ingredient', () {
    expect(
      () => NewRecipe.fromInput(
        name: 'Soup',
        ingredients: const <IngredientDraft>[IngredientDraft()],
        steps: const <String>['Cook.'],
        sourceImagePath: '/tmp/image.jpg',
      ),
      throwsFormatException,
    );
    expect(
      () => NewRecipe.fromInput(
        name: 'Soup',
        ingredients: const <IngredientDraft>[IngredientDraft(quantity: '2')],
        steps: const <String>['Cook.'],
        sourceImagePath: '/tmp/image.jpg',
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Ingredient 1 must have a name'),
        ),
      ),
    );
  });
}
