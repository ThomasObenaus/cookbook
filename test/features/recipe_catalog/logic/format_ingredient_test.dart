import 'package:cookbook/features/recipe_catalog/logic/format_ingredient.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatIngredient', () {
    test('trims fields and retains optional notes', () {
      const ingredient = Ingredient(
        name: ' flour ',
        quantity: ' 2 ',
        unit: ' cups ',
        note: ' sifted ',
      );

      expect(formatIngredient(ingredient), '2 cups flour (sifted)');
      expect(ingredient.quantity, ' 2 ');
      expect(ingredient.note, ' sifted ');
    });

    test('omits missing or blank optional fields without extra separators', () {
      for (final ingredient in <Ingredient>[
        const Ingredient(name: 'salt'),
        const Ingredient(name: 'salt', quantity: '', unit: '  ', note: ' '),
      ]) {
        expect(formatIngredient(ingredient), 'salt');
      }

      expect(
        formatIngredient(const Ingredient(name: 'milk', unit: 'ml')),
        'ml milk',
      );
    });

    test('preserves fractional and nonnumeric quantities', () {
      expect(
        formatIngredient(
          const Ingredient(name: 'milk', quantity: '1/2', unit: 'cup'),
        ),
        '1/2 cup milk',
      );
      expect(
        formatIngredient(
          const Ingredient(name: 'pepper', quantity: 'to taste'),
        ),
        'to taste pepper',
      );
    });

    test('formats ingredients in order without merging duplicates', () {
      const ingredients = <Ingredient>[
        Ingredient(name: 'flour', quantity: '2', unit: 'cups'),
        Ingredient(name: 'salt'),
        Ingredient(name: 'flour', quantity: '2', unit: 'cups'),
      ];

      expect(ingredients.map(formatIngredient).toList(), <String>[
        '2 cups flour',
        'salt',
        '2 cups flour',
      ]);
    });
  });
}
