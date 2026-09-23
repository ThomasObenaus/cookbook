import 'dart:async';

import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/shopping_list/data/shopping_list_repository.dart';
import 'package:cookbook/features/shopping_list/logic/shopping_list_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_shopping_list_repository.dart';

void main() {
  late FakeShoppingListRepository repository;
  late ShoppingListController controller;

  setUp(() {
    repository = FakeShoppingListRepository();
    controller = ShoppingListController(repository: repository);
  });

  tearDown(() => controller.dispose());

  test('loads once and publishes only confirmed immutable snapshots', () async {
    expect(controller.loaded, isFalse);
    expect(await controller.load(), isTrue);
    expect(controller.loaded, isTrue);
    repository.writeGate = Completer<void>();
    final addition = controller.appendIngredients([
      const Ingredient(name: 'salt'),
    ]);
    expect(controller.busy, isTrue);
    expect(controller.items, isEmpty);
    expect(await controller.load(), isFalse);
    expect(
      await controller.appendIngredients([const Ingredient(name: 'pepper')]),
      isFalse,
    );
    repository.writeGate!.complete();
    expect(await addition, isTrue);
    expect(repository.writeCount, 1);
    expect(repository.loadCount, 1);
    expect(controller.items.single.ingredient.name, 'salt');
    expect(() => controller.items.clear(), throwsUnsupportedError);
    expect(await controller.setChecked('item-1', true), isTrue);
    expect(controller.items.single.checked, isTrue);
    expect(await controller.remove('item-1'), isTrue);
    expect(controller.items, isEmpty);
  });

  test('failed load is recoverable without a false empty success', () async {
    repository.loadError = StateError('broken');
    expect(await controller.load(), isFalse);
    expect(controller.loaded, isFalse);
    expect(controller.error, isNotNull);
    repository.loadError = null;
    expect(await controller.load(), isTrue);
    expect(controller.error, isNull);
    expect(controller.busy, isFalse);
  });

  test(
    'failed writes retain saved state and expose a retryable error',
    () async {
      await controller.appendIngredients([const Ingredient(name: 'salt')]);
      repository.writeError = ShoppingListRepositoryException(
        message: 'Save failed',
        cause: StateError('disk'),
        stackTrace: StackTrace.current,
      );
      expect(await controller.setChecked('item-1', true), isFalse);
      expect(controller.items.single.checked, isFalse);
      expect(controller.error, 'Save failed');
      expect(await controller.remove('item-1'), isFalse);
      expect(controller.items, hasLength(1));
      repository.writeError = null;
      expect(await controller.remove('item-1'), isTrue);
      expect(controller.error, isNull);
    },
  );

  test('a committed addition never requires a second load', () async {
    await controller.load();
    repository.loadError = StateError('reads unavailable');
    expect(
      await controller.appendIngredients([const Ingredient(name: 'salt')]),
      isTrue,
    );
    expect(repository.loadCount, 1);
    expect(controller.items, hasLength(1));
  });

  test('initial load cannot overwrite a later mutation', () async {
    repository.loadGate = Completer<void>();
    final load = controller.load();
    expect(
      await controller.appendIngredients([const Ingredient(name: 'salt')]),
      isFalse,
    );
    expect(repository.writeCount, 0);
    repository.loadGate!.complete();
    await load;
    expect(
      await controller.appendIngredients([const Ingredient(name: 'salt')]),
      isTrue,
    );
    expect(controller.items, hasLength(1));
  });

  test(
    'disposal during save does not cancel storage or notify disposed state',
    () async {
      final disposedController = ShoppingListController(repository: repository);
      var notifications = 0;
      disposedController.addListener(() => notifications++);
      repository.writeGate = Completer<void>();
      final save = disposedController.appendIngredients([
        const Ingredient(name: 'salt'),
      ]);
      disposedController.dispose();
      repository.writeGate!.complete();
      expect(await save, isTrue);
      expect(repository.items, hasLength(1));
      expect(notifications, 1);
      expect(await disposedController.load(), isFalse);
    },
  );
}
