import 'dart:collection';

import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/recipe_creator/models/ingredient_unit.dart';

class IngredientDraft {
  const IngredientDraft({
    this.name = '',
    this.quantity = '',
    this.unit,
    this.note = '',
  });

  final String name;
  final String quantity;
  final IngredientUnit? unit;
  final String note;

  bool get isBlank =>
      name.trim().isEmpty &&
      quantity.trim().isEmpty &&
      unit == null &&
      note.trim().isEmpty;
}

class NewRecipe {
  factory NewRecipe.fromInput({
    required String name,
    required Iterable<IngredientDraft> ingredients,
    required Iterable<String> steps,
    required String sourceImagePath,
  }) {
    final normalizedName = _requiredText(name, 'Recipe name');
    final normalizedImagePath = _requiredText(
      sourceImagePath,
      'Recipe image path',
    );

    final normalizedIngredients = <Ingredient>[];
    var rowIndex = 0;
    for (final draft in ingredients) {
      rowIndex++;
      if (draft.isBlank) {
        continue;
      }

      final ingredientName = draft.name.trim();
      if (ingredientName.isEmpty) {
        throw FormatException('Ingredient $rowIndex must have a name.');
      }
      normalizedIngredients.add(
        Ingredient(
          name: ingredientName,
          quantity: _optionalText(draft.quantity),
          unit: draft.unit?.storedValue,
          note: _optionalText(draft.note),
        ),
      );
    }
    if (normalizedIngredients.isEmpty) {
      throw const FormatException('At least one ingredient is required.');
    }

    final normalizedSteps = <String>[];
    var stepIndex = 0;
    for (final value in steps) {
      stepIndex++;
      final step = value.trim();
      if (step.isEmpty) {
        throw FormatException('Preparation step $stepIndex must not be empty.');
      }
      normalizedSteps.add(step);
    }
    if (normalizedSteps.isEmpty) {
      throw const FormatException('At least one preparation step is required.');
    }

    return NewRecipe._(
      name: normalizedName,
      ingredients: normalizedIngredients,
      steps: normalizedSteps,
      sourceImagePath: normalizedImagePath,
    );
  }

  NewRecipe._({
    required this.name,
    required List<Ingredient> ingredients,
    required List<String> steps,
    required this.sourceImagePath,
  }) : ingredients = UnmodifiableListView(ingredients),
       steps = UnmodifiableListView(steps);

  final String name;
  final List<Ingredient> ingredients;
  final List<String> steps;
  final String sourceImagePath;
}

String _requiredText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw FormatException('$field must not be empty.');
  }
  return normalized;
}

String? _optionalText(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}
