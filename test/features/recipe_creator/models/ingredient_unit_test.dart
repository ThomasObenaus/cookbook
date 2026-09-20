import 'package:cookbook/features/recipe_creator/models/ingredient_unit.dart';
import 'package:cookbook/features/recipe_creator/models/recipe_creator_stage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defines the ordered creator unit vocabulary', () {
    expect(
      IngredientUnit.values
          .map((unit) => (unit.label, unit.storedValue))
          .toList(growable: false),
      <(String, String)>[
        ('Milliliter', 'ml'),
        ('Liter', 'l'),
        ('Teaspoon', 'tsp'),
        ('Tablespoon', 'tbsp'),
        ('Cup', 'cup'),
        ('Gram', 'g'),
        ('Kilogram', 'kg'),
        ('Piece', 'piece'),
        ('Pinch', 'pinch'),
        ('Handful', 'handful'),
        ('Clove', 'clove'),
        ('Slice', 'slice'),
        ('Can', 'can'),
        ('Package', 'package'),
      ],
    );
  });

  test('defines the four wizard stages in navigation order', () {
    expect(
      RecipeCreatorStage.values
          .map((stage) => (stage.title, stage.stepNumber))
          .toList(growable: false),
      <(String, int)>[
        ('Recipe', 1),
        ('Ingredients', 2),
        ('Preparation', 3),
        ('Review', 4),
      ],
    );
  });
}
