import 'dart:convert';

import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/shopping_list/models/shopping_list_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShoppingListItem', () {
    test('starts unchecked and retains an immutable ingredient snapshot', () {
      const ingredient = Ingredient(
        name: 'flour',
        quantity: '1/2',
        unit: 'cup',
        note: 'sifted',
      );
      const item = ShoppingListItem(id: 'item-1', ingredient: ingredient);

      expect(item.id, 'item-1');
      expect(item.ingredient, same(ingredient));
      expect(item.checked, isFalse);
    });

    test('copies checked state without mutating identity or ingredient', () {
      const item = ShoppingListItem(
        id: 'item-1',
        ingredient: Ingredient(name: 'salt'),
      );

      final checkedItem = item.copyWith(checked: true);
      final uncheckedItem = checkedItem.copyWith(checked: false);

      expect(item.checked, isFalse);
      expect(checkedItem.checked, isTrue);
      expect(checkedItem.id, item.id);
      expect(checkedItem.ingredient, same(item.ingredient));
      expect(checkedItem.copyWith().checked, isTrue);
      expect(uncheckedItem.toJson(), item.toJson());
    });

    test('replaces ingredient without changing identity or checked state', () {
      const item = ShoppingListItem(
        id: 'item-1',
        ingredient: Ingredient(name: 'salt'),
        checked: true,
      );

      final updated = item.copyWith(
        ingredient: const Ingredient(name: 'pepper', quantity: 'to taste'),
      );

      expect(updated.id, item.id);
      expect(updated.checked, isTrue);
      expect(updated.ingredient.name, 'pepper');
      expect(item.ingredient.name, 'salt');
    });

    test('keeps duplicate ingredients independently identifiable', () {
      const ingredient = Ingredient(name: 'salt', quantity: 'to taste');
      const first = ShoppingListItem(id: 'item-1', ingredient: ingredient);
      const second = ShoppingListItem(id: 'item-2', ingredient: ingredient);

      final items = <ShoppingListItem>[first.copyWith(checked: true), second];
      final restored = items
          .map((item) => ShoppingListItem.fromJson(item.toJson()))
          .toList();

      expect(restored.map((item) => item.id), <String>['item-1', 'item-2']);
      expect(restored.map((item) => item.checked), <bool>[true, false]);
      expect(restored[0].ingredient.toJson(), restored[1].ingredient.toJson());
      expect(second.checked, isFalse);
    });
  });

  group('ShoppingListItem JSON', () {
    test('round-trips all fields through encoded JSON', () {
      for (final checked in <bool>[false, true]) {
        final json = _validItemJson()..['checked'] = checked;
        final item = ShoppingListItem.fromJson(jsonDecode(jsonEncode(json)));

        expect(item.id, 'item-1');
        expect(item.ingredient.name, 'flour');
        expect(item.ingredient.quantity, '1/2');
        expect(item.ingredient.unit, 'cup');
        expect(item.ingredient.note, 'sifted');
        expect(item.checked, checked);
        expect(jsonDecode(jsonEncode(item.toJson())), json);
      }
    });

    test('preserves missing optional values and nonnumeric quantities', () {
      for (final ingredient in <Ingredient>[
        const Ingredient(name: 'salt'),
        const Ingredient(name: 'pepper', quantity: 'to taste'),
        const Ingredient(name: 'milk', unit: 'ml', note: ''),
      ]) {
        final item = ShoppingListItem(id: 'item-1', ingredient: ingredient);
        final restored = ShoppingListItem.fromJson(
          jsonDecode(jsonEncode(item.toJson())),
        );

        expect(restored.toJson(), item.toJson());
      }
    });

    test('normalizes whitespace using the existing ingredient parser', () {
      final item = ShoppingListItem.fromJson(<String, Object?>{
        'id': ' item-1 ',
        'ingredient': <String, Object?>{
          'name': ' flour ',
          'quantity': ' 1/2 ',
          'unit': ' cup ',
          'note': ' sifted ',
        },
        'checked': false,
      });

      expect(item.toJson(), _validItemJson());
    });

    test('does not retain mutable input or output maps', () {
      final ingredientJson = <String, Object?>{'name': 'salt'};
      final json = <String, Object?>{
        'id': 'item-1',
        'ingredient': ingredientJson,
        'checked': false,
      };
      final item = ShoppingListItem.fromJson(json);

      ingredientJson['name'] = 'pepper';
      json['checked'] = true;
      item.toJson().clear();
      item.ingredient.toJson().clear();

      expect(item.ingredient.name, 'salt');
      expect(item.checked, isFalse);
      expect(item.toJson()['id'], 'item-1');
    });

    test('rejects non-object input', () {
      for (final json in <Object?>[null, 'item', 1, true, <Object?>[]]) {
        expect(
          () => ShoppingListItem.fromJson(json),
          throwsFormatException,
          reason: '$json',
        );
      }
    });

    test('rejects every missing required field', () {
      for (final field in <String>['id', 'ingredient', 'checked']) {
        final json = _validItemJson()..remove(field);

        expect(
          () => ShoppingListItem.fromJson(json),
          throwsFormatException,
          reason: field,
        );
      }
    });

    test('rejects empty and wrongly typed identifiers', () {
      for (final id in <Object?>[null, '', '   ', 1, false, <Object?>[]]) {
        final json = _validItemJson()..['id'] = id;

        expect(
          () => ShoppingListItem.fromJson(json),
          throwsFormatException,
          reason: '$id',
        );
      }
    });

    test('requires a boolean checked flag without coercion', () {
      for (final checked in <Object?>[
        null,
        0,
        1,
        'false',
        'true',
        <Object?>[],
      ]) {
        final json = _validItemJson()..['checked'] = checked;

        expect(
          () => ShoppingListItem.fromJson(json),
          throwsFormatException,
          reason: '$checked',
        );
      }
    });

    test('rejects malformed ingredient snapshots', () {
      for (final ingredient in <Object?>[
        null,
        'salt',
        <Object?>[],
        <String, Object?>{},
        <String, Object?>{'name': '   '},
        <String, Object?>{'name': 1},
        for (final field in <String>['quantity', 'unit', 'note'])
          <String, Object?>{'name': 'salt', field: 1},
      ]) {
        final json = _validItemJson()..['ingredient'] = ingredient;

        expect(
          () => ShoppingListItem.fromJson(json),
          throwsFormatException,
          reason: '$ingredient',
        );
      }
    });
  });
}

Map<String, Object?> _validItemJson() => <String, Object?>{
  'id': 'item-1',
  'ingredient': <String, Object?>{
    'name': 'flour',
    'quantity': '1/2',
    'unit': 'cup',
    'note': 'sifted',
  },
  'checked': false,
};
