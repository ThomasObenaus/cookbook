import 'package:cookbook/features/recipe_catalog/models/recipe.dart';

List<Recipe> searchRecipesByName(Iterable<Recipe> recipes, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return List<Recipe>.unmodifiable(recipes);
  }

  return List<Recipe>.unmodifiable(
    recipes.where(
      (recipe) => recipe.name.toLowerCase().contains(normalizedQuery),
    ),
  );
}
