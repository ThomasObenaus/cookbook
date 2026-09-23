import 'dart:async';

import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/shopping_list/data/shopping_list_repository.dart';
import 'package:cookbook/features/shopping_list/models/shopping_list_item.dart';

class FakeShoppingListRepository implements ShoppingListRepository {
  List<ShoppingListItem> items = <ShoppingListItem>[];
  Object? loadError;
  Object? writeError;
  Completer<void>? loadGate;
  Completer<void>? writeGate;
  int loadCount = 0;
  int writeCount = 0;
  int _nextId = 0;

  @override
  Future<List<ShoppingListItem>> load() async {
    loadCount++;
    await loadGate?.future;
    final error = loadError;
    if (error != null) throw error;
    return List<ShoppingListItem>.of(items);
  }

  @override
  Future<List<ShoppingListItem>> appendIngredients(
    List<Ingredient> ingredients,
  ) {
    final snapshot = List<Ingredient>.of(ingredients);
    return _write(
      () => <ShoppingListItem>[
        ...items,
        for (final ingredient in snapshot)
          ShoppingListItem(id: 'item-${++_nextId}', ingredient: ingredient),
      ],
    );
  }

  @override
  Future<List<ShoppingListItem>> setChecked({
    required String id,
    required bool checked,
  }) => _write(
    () => <ShoppingListItem>[
      for (final item in items)
        item.id == id ? item.copyWith(checked: checked) : item,
    ],
  );

  @override
  Future<List<ShoppingListItem>> remove(String id) =>
      _write(() => items.where((item) => item.id != id).toList());

  Future<List<ShoppingListItem>> _write(
    List<ShoppingListItem> Function() update,
  ) async {
    writeCount++;
    await writeGate?.future;
    final error = writeError;
    if (error != null) throw error;
    items = update();
    return List<ShoppingListItem>.of(items);
  }
}
