import 'dart:collection';

import 'package:cookbook/features/recipe_catalog/models/recipe_image.dart';

class Ingredient {
  const Ingredient({required this.name, this.quantity, this.unit, this.note});

  factory Ingredient.fromJson(Object? json) {
    final values = _objectMap(json, 'Ingredient');

    return Ingredient(
      name: _requiredString(values, 'name', 'Ingredient'),
      quantity: _optionalString(values, 'quantity', 'Ingredient'),
      unit: _optionalString(values, 'unit', 'Ingredient'),
      note: _optionalString(values, 'note', 'Ingredient'),
    );
  }

  final String name;
  final String? quantity;
  final String? unit;
  final String? note;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    if (quantity != null) 'quantity': quantity,
    if (unit != null) 'unit': unit,
    if (note != null) 'note': note,
  };
}

class Recipe {
  Recipe({
    required this.id,
    required this.name,
    required this.servings,
    required this.prepMinutes,
    required this.cookMinutes,
    required this.image,
    required List<Ingredient> ingredients,
    required List<String> steps,
  }) : ingredients = UnmodifiableListView(List<Ingredient>.of(ingredients)),
       steps = UnmodifiableListView(List<String>.of(steps));

  factory Recipe.fromJson(Object? json) {
    final values = _objectMap(json, 'Recipe');
    final ingredientValues = _requiredList(values, 'ingredients', 'Recipe');
    final stepValues = _requiredList(values, 'steps', 'Recipe');

    if (ingredientValues.isEmpty) {
      throw const FormatException('Recipe.ingredients must not be empty.');
    }
    if (stepValues.isEmpty) {
      throw const FormatException('Recipe.steps must not be empty.');
    }

    final ingredients = <Ingredient>[];
    for (var index = 0; index < ingredientValues.length; index++) {
      try {
        ingredients.add(Ingredient.fromJson(ingredientValues[index]));
      } on FormatException catch (error) {
        throw FormatException(
          'Recipe.ingredients[$index] is invalid: ${error.message}',
        );
      }
    }

    final steps = <String>[];
    for (var index = 0; index < stepValues.length; index++) {
      final value = stepValues[index];
      if (value is! String) {
        throw FormatException('Recipe.steps[$index] must be a string.');
      }
      final step = value.trim();
      if (step.isEmpty) {
        throw FormatException('Recipe.steps[$index] must not be empty.');
      }
      steps.add(step);
    }

    return Recipe(
      id: _requiredString(values, 'id', 'Recipe'),
      name: _requiredString(values, 'name', 'Recipe'),
      servings: _requiredInt(values, 'servings', 'Recipe', minimum: 1),
      prepMinutes: _requiredInt(values, 'prepMinutes', 'Recipe', minimum: 0),
      cookMinutes: _requiredInt(values, 'cookMinutes', 'Recipe', minimum: 0),
      image: RecipeImage.fromJson(values['image']),
      ingredients: ingredients,
      steps: steps,
    );
  }

  final String id;
  final String name;
  final int servings;
  final int prepMinutes;
  final int cookMinutes;
  final RecipeImage image;
  final List<Ingredient> ingredients;
  final List<String> steps;

  int get totalMinutes => prepMinutes + cookMinutes;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'servings': servings,
    'prepMinutes': prepMinutes,
    'cookMinutes': cookMinutes,
    'image': image.toJson(),
    'ingredients': ingredients
        .map((ingredient) => ingredient.toJson())
        .toList(growable: false),
    'steps': List<String>.of(steps, growable: false),
  };
}

Map<String, Object?> _objectMap(Object? value, String context) {
  if (value is! Map<String, Object?>) {
    throw FormatException('$context must be a JSON object.');
  }
  return value;
}

String _requiredString(
  Map<String, Object?> values,
  String field,
  String context,
) {
  final value = values[field];
  if (value is! String) {
    throw FormatException('$context.$field must be a string.');
  }
  final trimmedValue = value.trim();
  if (trimmedValue.isEmpty) {
    throw FormatException('$context.$field must not be empty.');
  }
  return trimmedValue;
}

String? _optionalString(
  Map<String, Object?> values,
  String field,
  String context,
) {
  final value = values[field];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw FormatException('$context.$field must be a string when provided.');
  }
  return value.trim();
}

int _requiredInt(
  Map<String, Object?> values,
  String field,
  String context, {
  required int minimum,
}) {
  final value = values[field];
  if (value is! int) {
    throw FormatException('$context.$field must be an integer.');
  }
  if (value < minimum) {
    throw FormatException('$context.$field must be at least $minimum.');
  }
  return value;
}

List<Object?> _requiredList(
  Map<String, Object?> values,
  String field,
  String context,
) {
  final value = values[field];
  if (value is! List<Object?>) {
    throw FormatException('$context.$field must be a list.');
  }
  return value;
}
