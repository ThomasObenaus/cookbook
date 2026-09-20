import 'package:cookbook/features/recipe_catalog/data/recipe_repository.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/recipe_creator/models/new_recipe.dart';

abstract interface class MutableRecipeRepository implements RecipeRepository {
  Future<Recipe> createRecipe(NewRecipe recipe);
}
