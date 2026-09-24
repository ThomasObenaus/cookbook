import 'dart:collection';

import 'package:cookbook/features/meal_planner/logic/week_dates.dart';
import 'package:cookbook/features/meal_planner/models/meal_assignment.dart';
import 'package:cookbook/features/meal_planner/models/meal_type.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe.dart';

sealed class WeekIngredientCollection {
  const WeekIngredientCollection();
}

final class WeekIngredientBatch extends WeekIngredientCollection {
  WeekIngredientBatch(Iterable<Ingredient> ingredients)
    : ingredients = UnmodifiableListView<Ingredient>(
        List<Ingredient>.of(ingredients),
      );

  final List<Ingredient> ingredients;
}

final class MissingWeekRecipe extends WeekIngredientCollection {
  const MissingWeekRecipe({
    required this.recipeId,
    required this.date,
    required this.mealType,
  });

  final String recipeId;
  final DateTime date;
  final MealType mealType;
}

WeekIngredientCollection collectWeekIngredients({
  required DateTime weekStart,
  required Iterable<MealAssignment> assignments,
  required Map<String, Recipe> recipesById,
}) {
  final assignmentsByIdentity = <MealAssignmentIdentity, MealAssignment>{
    for (final assignment in assignments)
      if (mondayOfWeek(assignment.date) == mondayOfWeek(weekStart))
        assignment.identity: assignment,
  };
  final ingredients = <Ingredient>[];

  for (final date in datesInWeek(weekStart)) {
    for (final mealType in MealType.values) {
      final assignment =
          assignmentsByIdentity[MealAssignmentIdentity(
            date: date,
            mealType: mealType,
          )];
      if (assignment == null) continue;
      final recipe = recipesById[assignment.recipeId];
      if (recipe == null) {
        return MissingWeekRecipe(
          recipeId: assignment.recipeId,
          date: date,
          mealType: mealType,
        );
      }
      ingredients.addAll(recipe.ingredients);
    }
  }

  return WeekIngredientBatch(ingredients);
}
