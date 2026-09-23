import 'package:cookbook/features/meal_planner/models/meal_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('meal types keep display and storage order', () {
    expect(MealType.values.map((value) => value.label), <String>[
      'Breakfast',
      'Lunch',
      'Dinner',
    ]);
    expect(MealType.values.map((value) => value.storedValue), <String>[
      'breakfast',
      'lunch',
      'dinner',
    ]);
  });

  test('decodes only exact stored values', () {
    for (final mealType in MealType.values) {
      expect(MealType.fromStoredValue(mealType.storedValue), mealType);
    }

    for (final invalidValue in <Object?>['Breakfast', 'snack', '', null, 1]) {
      expect(
        () => MealType.fromStoredValue(invalidValue),
        throwsFormatException,
        reason: '$invalidValue',
      );
    }
  });
}
