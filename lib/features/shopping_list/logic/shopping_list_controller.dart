import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/shopping_list/data/shopping_list_repository.dart';
import 'package:cookbook/features/shopping_list/models/shopping_list_item.dart';
import 'package:flutter/foundation.dart';

class ShoppingListController extends ChangeNotifier {
  ShoppingListController({required this._repository});

  final ShoppingListRepository _repository;
  List<ShoppingListItem> _items = const <ShoppingListItem>[];
  bool _busy = false;
  bool _loaded = false;
  bool _disposed = false;
  String? _error;

  List<ShoppingListItem> get items => _items;
  bool get busy => _busy;
  bool get loaded => _loaded;
  String? get error => _error;

  Future<bool> load() => _run(_repository.load);

  Future<bool> appendIngredients(List<Ingredient> ingredients) =>
      _run(() => _repository.appendIngredients(ingredients));

  Future<bool> setChecked(String id, bool checked) =>
      _run(() => _repository.setChecked(id: id, checked: checked));

  Future<bool> remove(String id) => _run(() => _repository.remove(id));

  Future<bool> reorder({required bool checked, required List<String> ids}) =>
      _run(() => _repository.reorder(checked: checked, ids: ids));

  Future<bool> update(String id, Ingredient ingredient) =>
      _run(() => _repository.update(id: id, ingredient: ingredient));

  Future<bool> clear() => _run(_repository.clear);

  Future<bool> _run(Future<List<ShoppingListItem>> Function() operation) async {
    if (_disposed || _busy) {
      return false;
    }
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final items = await operation();
      if (!_disposed) {
        _items = List<ShoppingListItem>.unmodifiable(items);
        _loaded = true;
      }
      return true;
    } catch (error) {
      if (!_disposed) {
        _error = error is ShoppingListRepositoryException
            ? error.message
            : 'The shopping list is unavailable. Please try again.';
      }
      return false;
    } finally {
      if (!_disposed) {
        _busy = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
