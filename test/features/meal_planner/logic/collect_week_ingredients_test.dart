import 'package:cookbook/features/meal_planner/logic/collect_week_ingredients.dart';
import 'package:cookbook/features/meal_planner/models/meal_assignment.dart';
import 'package:cookbook/features/meal_planner/models/meal_type.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe_image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final breakfast = _recipe('breakfast', const <Ingredient>[
    Ingredient(name: 'oats', quantity: '1/2', unit: 'cup'),
    Ingredient(name: 'salt', quantity: 'to taste', note: 'fine'),
  ]);
  final lunch = _recipe('lunch', const <Ingredient>[
    Ingredient(name: 'bread', quantity: '2', unit: 'slices'),
  ]);
  final dinner = _recipe('dinner', const <Ingredient>[
    Ingredient(name: 'beans', quantity: '1', unit: 'can'),
  ]);
  final recipes = <String, Recipe>{
    breakfast.id: breakfast,
    lunch.id: lunch,
    dinner.id: dinner,
  };

  test('collects shuffled assignments by day, meal, and ingredient order', () {
    final result = collectWeekIngredients(
      weekStart: DateTime(2026, 9, 23, 18),
      assignments: <MealAssignment>[
        MealAssignment(
          date: DateTime(2026, 9, 27),
          mealType: MealType.breakfast,
          recipeId: breakfast.id,
        ),
        MealAssignment(
          date: DateTime(2026, 9, 21),
          mealType: MealType.dinner,
          recipeId: dinner.id,
        ),
        MealAssignment(
          date: DateTime(2026, 9, 21),
          mealType: MealType.breakfast,
          recipeId: breakfast.id,
        ),
        MealAssignment(
          date: DateTime(2026, 9, 21),
          mealType: MealType.lunch,
          recipeId: lunch.id,
        ),
        MealAssignment(
          date: DateTime(2026, 9, 28),
          mealType: MealType.breakfast,
          recipeId: lunch.id,
        ),
      ],
      recipesById: recipes,
    );

    expect(result, isA<WeekIngredientBatch>());
    final ingredients = (result as WeekIngredientBatch).ingredients;
    expect(ingredients.map((ingredient) => ingredient.name), [
      'oats',
      'salt',
      'bread',
      'beans',
      'oats',
      'salt',
    ]);
    expect(ingredients.first.toJson(), {
      'name': 'oats',
      'quantity': '1/2',
      'unit': 'cup',
    });
    expect(ingredients[1].toJson(), {
      'name': 'salt',
      'quantity': 'to taste',
      'note': 'fine',
    });
    expect(() => ingredients.clear(), throwsUnsupportedError);
  });

  test('includes a repeated recipe once for each meal occurrence', () {
    final result = collectWeekIngredients(
      weekStart: DateTime(2026, 9, 21),
      assignments: <MealAssignment>[
        MealAssignment(
          date: DateTime(2026, 9, 21),
          mealType: MealType.breakfast,
          recipeId: breakfast.id,
        ),
        MealAssignment(
          date: DateTime(2026, 9, 22),
          mealType: MealType.dinner,
          recipeId: breakfast.id,
        ),
      ],
      recipesById: recipes,
    ) as WeekIngredientBatch;

    expect(result.ingredients.map((ingredient) => ingredient.name), [
      'oats',
      'salt',
      'oats',
      'salt',
    ]);
  });

  test('returns an immutable empty batch for an empty displayed week', () {
    final result = collectWeekIngredients(
      weekStart: DateTime(2025, 12, 31),
      assignments: <MealAssignment>[
        MealAssignment(
          date: DateTime(2026, 1, 5),
          mealType: MealType.breakfast,
          recipeId: breakfast.id,
        ),
      ],
      recipesById: recipes,
    ) as WeekIngredientBatch;

    expect(result.ingredients, isEmpty);
    expect(
      () => result.ingredients.add(const Ingredient(name: 'milk')),
      throwsUnsupportedError,
    );
  });

  test('handles leap-day and daylight-saving week boundaries', () {
    for (final date in <DateTime>[
      DateTime(2024, 2, 29),
      DateTime(2026, 3, 8),
      DateTime(2026, 11, 1),
    ]) {
      final result = collectWeekIngredients(
        weekStart: date,
        assignments: <MealAssignment>[
          MealAssignment(
            date: date,
            mealType: MealType.lunch,
            recipeId: lunch.id,
          ),
        ],
        recipesById: recipes,
      ) as WeekIngredientBatch;
      expect(result.ingredients.single.name, 'bread', reason: '$date');
    }
  });

  test('missing recipe returns an explicit result without a partial batch', () {
    final result = collectWeekIngredients(
      weekStart: DateTime(2026, 9, 21),
      assignments: <MealAssignment>[
        MealAssignment(
          date: DateTime(2026, 9, 21),
          mealType: MealType.breakfast,
          recipeId: breakfast.id,
        ),
        MealAssignment(
          date: DateTime(2026, 9, 22),
          mealType: MealType.lunch,
          recipeId: 'missing',
        ),
      ],
      recipesById: recipes,
    );

    expect(result, isA<MissingWeekRecipe>());
    final missing = result as MissingWeekRecipe;
    expect(missing.recipeId, 'missing');
    expect(missing.date, DateTime(2026, 9, 22));
    expect(missing.mealType, MealType.lunch);
    expect(result, isNot(isA<WeekIngredientBatch>()));
  });
}

Recipe _recipe(String id, List<Ingredient> ingredients) => Recipe(
  id: id,
  name: id,
  servings: 1,
  prepMinutes: 0,
  cookMinutes: 0,
  image: RecipeImage.asset('assets/images/$id.jpg'),
  ingredients: ingredients,
  steps: const <String>['Cook'],
);
