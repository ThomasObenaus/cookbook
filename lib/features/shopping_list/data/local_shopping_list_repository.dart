import 'dart:convert';
import 'dart:io';

import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/shopping_list/data/shopping_list_repository.dart';
import 'package:cookbook/features/shopping_list/models/shopping_list_item.dart';

class LocalShoppingListRepository implements ShoppingListRepository {
  LocalShoppingListRepository({
    required Directory applicationSupportDirectory,
    required this._createId,
  }) : _dataFile = File.fromUri(
         applicationSupportDirectory.uri.resolve('cookbook/shopping_list.json'),
       );

  final File _dataFile;
  final String Function() _createId;
  Future<void> _mutationTail = Future<void>.value();

  @override
  Future<List<ShoppingListItem>> load() async {
    await _mutationTail;
    try {
      return List<ShoppingListItem>.unmodifiable(await _read());
    } catch (error, stackTrace) {
      throw ShoppingListRepositoryException(
        message: 'The shopping list could not be loaded. Please try again.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<ShoppingListItem>> appendIngredients(
    List<Ingredient> ingredients,
  ) {
    final snapshot = List<Ingredient>.of(ingredients);
    return _mutate((items) {
      final identities = items.map((item) => item.id).toSet();
      return <ShoppingListItem>[
        ...items,
        for (final ingredient in snapshot) _newItem(ingredient, identities),
      ];
    });
  }

  ShoppingListItem _newItem(Ingredient ingredient, Set<String> identities) {
    final item = ShoppingListItem.fromJson(<String, Object?>{
      'id': _createId(),
      'ingredient': ingredient.toJson(),
      'checked': false,
    });
    if (!identities.add(item.id)) {
      throw const FormatException('Duplicate shopping-list item ID.');
    }
    return item;
  }

  @override
  Future<List<ShoppingListItem>> setChecked({
    required String id,
    required bool checked,
  }) {
    return _mutate((items) {
      if (!items.any((item) => item.id == id)) {
        throw StateError('The shopping-list item no longer exists.');
      }
      return <ShoppingListItem>[
        for (final item in items)
          item.id == id ? item.copyWith(checked: checked) : item,
      ];
    });
  }

  @override
  Future<List<ShoppingListItem>> remove(String id) =>
      _mutate((items) => items.where((item) => item.id != id).toList());

  Future<List<ShoppingListItem>> _mutate(
    List<ShoppingListItem> Function(List<ShoppingListItem>) update,
  ) {
    final result = _mutationTail.then((_) async {
      try {
        final updated = update(await _read());
        await _write(updated);
        return List<ShoppingListItem>.unmodifiable(updated);
      } catch (error, stackTrace) {
        throw ShoppingListRepositoryException(
          message: 'The shopping list could not be saved. Please try again.',
          cause: error,
          stackTrace: stackTrace,
        );
      }
    });
    _mutationTail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<List<ShoppingListItem>> _read() async {
    final type = await FileSystemEntity.type(
      _dataFile.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.notFound) {
      return <ShoppingListItem>[];
    }
    if (type != FileSystemEntityType.file) {
      throw FileSystemException(
        'Shopping-list storage is not a file.',
        _dataFile.path,
      );
    }
    final Object? document = jsonDecode(await _dataFile.readAsString());
    if (document is! Map<String, Object?> ||
        document['version'] is! int ||
        document['version'] != 1) {
      throw const FormatException('Unsupported shopping-list data.');
    }
    final values = document['items'];
    if (values is! List<Object?>) {
      throw const FormatException('Shopping-list items must be a list.');
    }
    final identities = <String>{};
    return <ShoppingListItem>[
      for (final value in values) _readItem(value, identities),
    ];
  }

  ShoppingListItem _readItem(Object? value, Set<String> identities) {
    final item = ShoppingListItem.fromJson(value);
    if (!identities.add(item.id)) {
      throw const FormatException('Duplicate shopping-list item ID.');
    }
    return item;
  }

  Future<void> _write(List<ShoppingListItem> items) async {
    await _dataFile.parent.create(recursive: true);
    final temporaryFile = File('${_dataFile.path}.tmp');
    try {
      await temporaryFile.writeAsString(
        jsonEncode(<String, Object?>{
          'version': 1,
          'items': items.map((item) => item.toJson()).toList(),
        }),
        flush: true,
      );
      await temporaryFile.rename(_dataFile.path);
    } catch (_) {
      try {
        if (await FileSystemEntity.type(
              temporaryFile.path,
              followLinks: false,
            ) ==
            FileSystemEntityType.file) {
          await temporaryFile.delete();
        }
      } on FileSystemException catch (_) {}
      rethrow;
    }
  }
}
