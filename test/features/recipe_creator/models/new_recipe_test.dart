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
          unit: ' large ',
          note: ' chopped ',
        ),
        IngredientDraft(),
        IngredientDraft(name: 'salt'),
      ],
      preparationSteps: ' Chop vegetables. \n\n Simmer gently. ',
      sourceImagePath: ' /tmp/soup.jpg ',
    );

    expect(recipe.name, 'Sunday Soup');
    expect(recipe.sourceImagePath, '/tmp/soup.jpg');
    expect(recipe.ingredients, hasLength(2));
    expect(recipe.ingredients.first.name, 'carrots');
    expect(recipe.ingredients.first.quantity, '2');
    expect(recipe.ingredients.first.unit, 'large');
    expect(recipe.ingredients.first.note, 'chopped');
    expect(recipe.ingredients.last.name, 'salt');
    expect(recipe.ingredients.last.quantity, isNull);
    expect(recipe.steps, <String>['Chop vegetables.', 'Simmer gently.']);
    expect(() => recipe.ingredients.clear(), throwsUnsupportedError);
    expect(() => recipe.steps.clear(), throwsUnsupportedError);
  });

  test('rejects empty required text', () {
    expect(
      () => NewRecipe.fromInput(
        name: ' ',
        ingredients: const <IngredientDraft>[IngredientDraft(name: 'salt')],
        preparationSteps: 'Season.',
        sourceImagePath: '/tmp/image.jpg',
      ),
      throwsFormatException,
    );
    expect(
      () => NewRecipe.fromInput(
        name: 'Soup',
        ingredients: const <IngredientDraft>[IngredientDraft(name: 'salt')],
        preparationSteps: 'Season.',
        sourceImagePath: ' ',
      ),
      throwsFormatException,
    );
    expect(
      () => NewRecipe.fromInput(
        name: 'Soup',
        ingredients: const <IngredientDraft>[IngredientDraft(name: 'salt')],
        preparationSteps: '\n  \n',
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
        preparationSteps: 'Cook.',
        sourceImagePath: '/tmp/image.jpg',
      ),
      throwsFormatException,
    );
    expect(
      () => NewRecipe.fromInput(
        name: 'Soup',
        ingredients: const <IngredientDraft>[IngredientDraft(quantity: '2')],
        preparationSteps: 'Cook.',
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
