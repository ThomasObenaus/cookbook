import 'package:cookbook/features/meal_planner/models/meal_assignment.dart';
import 'package:cookbook/features/meal_planner/models/meal_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes input and round trips JSON', () {
    final assignment = MealAssignment(
      date: DateTime(2026, 9, 21, 18, 30),
      mealType: MealType.dinner,
      recipeId: ' tomato-basil-pasta ',
    );

    expect(assignment.date, DateTime(2026, 9, 21));
    expect(assignment.recipeId, 'tomato-basil-pasta');
    expect(assignment.toJson(), <String, Object?>{
      'date': '2026-09-21',
      'mealType': 'dinner',
      'recipeId': 'tomato-basil-pasta',
    });
    expect(MealAssignment.fromJson(assignment.toJson()), assignment);
  });

  test('defines identity by normalized date and meal type', () {
    final first = MealAssignment(
      date: DateTime(2026, 9, 21, 8),
      mealType: MealType.breakfast,
      recipeId: 'porridge',
    );
    final replacement = MealAssignment(
      date: DateTime(2026, 9, 21, 20),
      mealType: MealType.breakfast,
      recipeId: 'pancakes',
    );
    final otherSlot = MealAssignment(
      date: DateTime(2026, 9, 21),
      mealType: MealType.lunch,
      recipeId: 'pancakes',
    );

    expect(first.identity, replacement.identity);
    expect(first.identity, isNot(otherSlot.identity));
  });

  test('rejects blank recipe IDs', () {
    expect(
      () => MealAssignment(
        date: DateTime(2026, 9, 21),
        mealType: MealType.lunch,
        recipeId: '   ',
      ),
      throwsFormatException,
    );
  });

  test('rejects malformed assignment JSON', () {
    final validJson = <String, Object?>{
      'date': '2026-09-21',
      'mealType': 'lunch',
      'recipeId': 'soup',
    };

    for (final invalidJson in <Object?>[
      null,
      <Object?>[],
      <String, Object?>{...validJson, 'date': '2026-9-21'},
      <String, Object?>{...validJson, 'date': '2026-02-29'},
      <String, Object?>{...validJson, 'mealType': 'snack'},
      <String, Object?>{...validJson, 'recipeId': '   '},
      <String, Object?>{...validJson, 'recipeId': 1},
    ]) {
      expect(
        () => MealAssignment.fromJson(invalidJson),
        throwsFormatException,
        reason: '$invalidJson',
      );
    }
  });
}
