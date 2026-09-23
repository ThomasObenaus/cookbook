import 'package:cookbook/features/recipe_catalog/models/recipe.dart';

String formatIngredient(Ingredient ingredient) {
  final parts = <String?>[ingredient.quantity, ingredient.unit, ingredient.name]
      .whereType<String>()
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty);
  final ingredientText = parts.join(' ');
  final note = ingredient.note?.trim();

  return note == null || note.isEmpty
      ? ingredientText
      : '$ingredientText ($note)';
}
