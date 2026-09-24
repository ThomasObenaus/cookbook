import 'dart:convert';
import 'dart:io';

import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/shopping_list/data/local_shopping_list_repository.dart';
import 'package:cookbook/features/shopping_list/data/shopping_list_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late LocalShoppingListRepository repository;
  late File dataFile;
  var nextId = 0;
  const ingredients = <Ingredient>[
    Ingredient(name: 'flour', quantity: '1/2', unit: 'cup', note: 'sifted'),
    Ingredient(name: 'salt', quantity: 'to taste'),
  ];

  setUp(() async {
    nextId = 0;
    directory = await Directory.systemTemp.createTemp('cookbook-shopping-');
    repository = LocalShoppingListRepository(
      applicationSupportDirectory: directory,
      createId: () => 'item-${++nextId}',
    );
    dataFile = File.fromUri(
      directory.uri.resolve('cookbook/shopping_list.json'),
    );
  });

  tearDown(() async => directory.delete(recursive: true));

  test('missing data loads an immutable empty list', () async {
    final items = await repository.load();
    expect(items, isEmpty);
    expect(() => items.clear(), throwsUnsupportedError);
  });

  test(
    'appends batches, checks and removes by identity, and restores',
    () async {
      await repository.appendIngredients(ingredients);
      await repository.setChecked(id: 'item-1', checked: true);
      final appended = await repository.appendIngredients(ingredients);
      expect(appended.map((item) => item.id), [
        'item-1',
        'item-2',
        'item-3',
        'item-4',
      ]);
      expect(appended.map((item) => item.checked), [true, false, false, false]);
      expect(appended.map((item) => item.ingredient.toJson()), [
        ...ingredients.map((item) => item.toJson()),
        ...ingredients.map((item) => item.toJson()),
      ]);
      expect(() => appended.clear(), throwsUnsupportedError);
      await repository.setChecked(id: 'item-1', checked: false);
      await repository.setChecked(id: 'item-3', checked: true);
      final removed = await repository.remove('item-1');
      final restarted = LocalShoppingListRepository(
        applicationSupportDirectory: directory,
        createId: () => 'restart-id',
      );
      final restored = await restarted.load();
      expect(
        restored.map((item) => item.toJson()),
        removed.map((item) => item.toJson()),
      );
      expect(restored.map((item) => item.id), ['item-2', 'item-3', 'item-4']);
      expect(restored.map((item) => item.checked), [false, true, false]);
    },
  );

  test('serializes overlapping add, check, remove, and load', () async {
    await Future.wait([
      repository.appendIngredients(ingredients),
      repository.setChecked(id: 'item-1', checked: true),
      repository.remove('item-2'),
      repository.appendIngredients(ingredients),
    ]);
    final addition = repository.appendIngredients([
      const Ingredient(name: 'milk'),
    ]);
    final loaded = repository.load();
    await addition;
    final items = await loaded;
    expect(items.map((item) => item.id), [
      'item-1',
      'item-3',
      'item-4',
      'item-5',
    ]);
    expect(items.first.checked, isTrue);
  });

  test('captures the batch before awaiting queued operations', () async {
    final source = List<Ingredient>.of(ingredients);
    final result = repository.appendIngredients(source);
    source.clear();
    expect(await result, hasLength(2));
  });

  test(
    'updates one ingredient while preserving identity, state and order',
    () async {
      await repository.appendIngredients(ingredients);
      await repository.setChecked(id: 'item-2', checked: true);
      final updated = await repository.update(
        id: 'item-2',
        ingredient: const Ingredient(
          name: ' sea salt ',
          quantity: ' to taste ',
          unit: ' pinches ',
        ),
      );

      expect(updated.map((item) => item.id), ['item-1', 'item-2']);
      expect(updated.last.checked, isTrue);
      expect(updated.last.ingredient.toJson(), {
        'name': 'sea salt',
        'quantity': 'to taste',
        'unit': 'pinches',
      });
      expect(updated.first.ingredient.toJson(), ingredients.first.toJson());
      final fresh = LocalShoppingListRepository(
        applicationSupportDirectory: directory,
        createId: () => 'new',
      );
      expect(
        (await fresh.load()).map((item) => item.toJson()),
        updated.map((item) => item.toJson()),
      );
    },
  );

  test('invalid and missing item updates do not change saved data', () async {
    await repository.appendIngredients(ingredients);
    final original = await dataFile.readAsString();
    await expectLater(
      repository.update(
        id: 'missing',
        ingredient: const Ingredient(name: 'pepper'),
      ),
      throwsA(isA<ShoppingListRepositoryException>()),
    );
    await expectLater(
      repository.update(
        id: 'item-1',
        ingredient: const Ingredient(name: '   '),
      ),
      throwsA(isA<FormatException>()),
    );
    expect(await dataFile.readAsString(), original);
  });

  test(
    'clears active and completed items and restores an empty list',
    () async {
      await repository.appendIngredients(ingredients);
      await repository.setChecked(id: 'item-2', checked: true);

      expect(await repository.clear(), isEmpty);
      expect(await repository.clear(), isEmpty);
      final document = jsonDecode(await dataFile.readAsString());
      expect(document, {'version': 1, 'items': <Object?>[]});
      final fresh = LocalShoppingListRepository(
        applicationSupportDirectory: directory,
        createId: () => 'new',
      );
      expect(await fresh.load(), isEmpty);
    },
  );

  test(
    'reorders each section without changing other positions and restores',
    () async {
      await repository.appendIngredients([...ingredients, ...ingredients]);
      await repository.setChecked(id: 'item-2', checked: true);
      await repository.setChecked(id: 'item-4', checked: true);
      final ids = ['item-3', 'item-1'];
      final pending = repository.reorder(checked: false, ids: ids);
      ids.clear();
      expect((await pending).map((item) => item.id), [
        'item-3',
        'item-2',
        'item-1',
        'item-4',
      ]);
      final result = await repository.reorder(
        checked: true,
        ids: ['item-4', 'item-2'],
      );
      expect(result.map((item) => item.id), [
        'item-3',
        'item-4',
        'item-1',
        'item-2',
      ]);
      expect(result.map((item) => item.checked), [false, true, false, true]);
      final fresh = LocalShoppingListRepository(
        applicationSupportDirectory: directory,
        createId: () => 'new',
      );
      expect(
        (await fresh.load()).map((item) => item.toJson()),
        result.map((item) => item.toJson()),
      );
      expect(
        (jsonDecode(await dataFile.readAsString())
            as Map<String, Object?>)['version'],
        1,
      );
    },
  );

  test('rejects invalid and stale permutations without losing items', () async {
    await repository.appendIngredients(ingredients);
    final original = await dataFile.readAsString();
    for (final ids in <List<String>>[
      [],
      ['item-1'],
      ['item-1', 'item-1'],
      ['item-1', 'missing'],
      ['item-1', 'item-2', 'extra'],
    ]) {
      await expectLater(
        repository.reorder(checked: false, ids: ids),
        throwsA(isA<ShoppingListRepositoryException>()),
      );
      expect(await dataFile.readAsString(), original);
    }
    await expectLater(
      repository.reorder(checked: true, ids: ['item-1', 'item-2']),
      throwsA(isA<ShoppingListRepositoryException>()),
    );
    await repository.reorder(checked: false, ids: ['item-1', 'item-2']);
    final addition = repository.appendIngredients(ingredients);
    await expectLater(
      repository.reorder(checked: false, ids: ['item-2', 'item-1']),
      throwsA(isA<ShoppingListRepositoryException>()),
    );
    await addition;
    expect(await repository.load(), hasLength(4));
  });

  test('corrupt documents reject every mutation without overwriting', () async {
    final valid = (await repository.appendIngredients(ingredients)).first
        .toJson();
    for (final document in <Object?>[
      '{broken',
      null,
      {'version': 2, 'items': []},
      {'version': 1.0, 'items': []},
      {'version': 1, 'items': 'invalid'},
      {
        'version': 1,
        'items': [valid, valid],
      },
      {
        'version': 1,
        'items': [
          {...valid, 'checked': 'true'},
        ],
      },
      {
        'version': 1,
        'items': [
          {
            ...valid,
            'ingredient': {'name': ''},
          },
        ],
      },
    ]) {
      final contents = document is String ? document : jsonEncode(document);
      await dataFile.writeAsString(contents);
      for (final operation in [
        () => repository.load(),
        () => repository.appendIngredients(ingredients),
        () => repository.setChecked(id: 'item-1', checked: true),
        () => repository.remove('item-1'),
        () => repository.reorder(checked: false, ids: ['item-1', 'item-2']),
        () => repository.update(
          id: 'item-1',
          ingredient: const Ingredient(name: 'pepper'),
        ),
        repository.clear,
      ]) {
        await expectLater(
          operation(),
          throwsA(isA<ShoppingListRepositoryException>()),
        );
        expect(await dataFile.readAsString(), contents);
      }
    }
  });

  test('write failure preserves saved data and queue recovers', () async {
    await repository.appendIngredients(ingredients);
    final original = await dataFile.readAsString();
    final blocker = await Directory('${dataFile.path}.tmp').create();
    for (final operation in [
      () => repository.appendIngredients(ingredients),
      () => repository.setChecked(id: 'item-1', checked: true),
      () => repository.remove('item-2'),
      () => repository.reorder(checked: false, ids: ['item-2', 'item-1']),
      () => repository.update(
        id: 'item-1',
        ingredient: const Ingredient(name: 'pepper'),
      ),
      repository.clear,
    ]) {
      await expectLater(
        operation(),
        throwsA(
          isA<ShoppingListRepositoryException>().having(
            (error) => error.cause,
            'cause',
            isA<FileSystemException>(),
          ),
        ),
      );
      expect(await dataFile.readAsString(), original);
    }
    await blocker.delete();
    expect(await repository.appendIngredients(ingredients), hasLength(4));
    expect(await File('${dataFile.path}.tmp').exists(), isFalse);
  });

  test(
    'invalid IDs, collisions and ingredients never partially save a batch',
    () async {
      await repository.appendIngredients(ingredients);
      final original = await dataFile.readAsString();
      for (final id in ['item-1', ' ', 'same-id']) {
        final invalidRepository = LocalShoppingListRepository(
          applicationSupportDirectory: directory,
          createId: () => id,
        );
        await expectLater(
          invalidRepository.appendIngredients(ingredients),
          throwsA(isA<ShoppingListRepositoryException>()),
        );
        expect(await dataFile.readAsString(), original);
      }
      await expectLater(
        repository.appendIngredients([
          ingredients.first,
          const Ingredient(name: ''),
        ]),
        throwsA(isA<ShoppingListRepositoryException>()),
      );
      expect(await dataFile.readAsString(), original);
    },
  );

  test(
    'a directory at the data path is not treated as an empty list',
    () async {
      await Directory(dataFile.path).create(recursive: true);
      await expectLater(
        repository.load(),
        throwsA(isA<ShoppingListRepositoryException>()),
      );
      await expectLater(
        repository.appendIngredients(ingredients),
        throwsA(isA<ShoppingListRepositoryException>()),
      );
    },
  );

  test('missing item errors do not poison subsequent mutations', () async {
    await expectLater(
      repository.setChecked(id: 'missing', checked: true),
      throwsA(isA<ShoppingListRepositoryException>()),
    );
    expect(await repository.remove('missing'), isEmpty);
    expect(await repository.appendIngredients(ingredients), hasLength(2));
  });
}
