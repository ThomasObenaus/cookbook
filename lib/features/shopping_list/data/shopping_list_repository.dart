import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/shopping_list/models/shopping_list_item.dart';

abstract interface class ShoppingListRepository {
  Future<List<ShoppingListItem>> load();

  Future<List<ShoppingListItem>> appendIngredients(
    List<Ingredient> ingredients,
  );

  Future<List<ShoppingListItem>> setChecked({
    required String id,
    required bool checked,
  });

  Future<List<ShoppingListItem>> remove(String id);
}

class ShoppingListRepositoryException implements Exception {
  const ShoppingListRepositoryException({
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
