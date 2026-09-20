import 'dart:convert';

import 'package:cookbook/features/recipe_catalog/data/recipe_repository.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:flutter/services.dart';

class AssetRecipeRepository implements RecipeRepository {
  AssetRecipeRepository({
    required this.assetBundle,
    this.assetPath = 'assets/data/recipes.json',
  });

  static const _friendlyErrorMessage =
      'Recipes could not be loaded. Please try again.';

  final AssetBundle assetBundle;
  final String assetPath;

  @override
  Future<List<Recipe>> getAllRecipes() async {
    try {
      final source = await assetBundle.loadString(assetPath);
      final Object? decoded = jsonDecode(source);
      if (decoded is! List<Object?>) {
        throw const FormatException('The recipe collection must be a list.');
      }

      final recipes = <Recipe>[];
      final recipeIds = <String>{};
      for (var index = 0; index < decoded.length; index++) {
        late final Recipe recipe;
        try {
          recipe = Recipe.fromJson(decoded[index]);
        } on FormatException catch (error) {
          throw FormatException(
            'Recipe at index $index is invalid: ${error.message}',
          );
        }

        if (!recipeIds.add(recipe.id)) {
          throw FormatException('Duplicate recipe id: ${recipe.id}.');
        }
        recipes.add(recipe);
      }

      return List<Recipe>.unmodifiable(recipes);
    } on RecipeRepositoryException {
      rethrow;
    } catch (error, stackTrace) {
      throw RecipeRepositoryException(
        message: _friendlyErrorMessage,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}
