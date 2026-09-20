import 'package:cookbook/features/recipe_catalog/models/recipe.dart';

abstract interface class RecipeRepository {
  Future<List<Recipe>> getAllRecipes();
}

class RecipeRepositoryException implements Exception {
  const RecipeRepositoryException({
    required this.message,
    required this.cause,
    required this.stackTrace,
  });

  final String message;
  final Object cause;
  final StackTrace stackTrace;

  @override
  String toString() => message;
}
