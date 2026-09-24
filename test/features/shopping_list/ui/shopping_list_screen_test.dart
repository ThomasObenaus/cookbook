import 'dart:async';

import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/shopping_list/logic/shopping_list_controller.dart';
import 'package:cookbook/features/shopping_list/ui/shopping_list_screen.dart';
import 'package:flutter/material.dart';
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

  Future<void> mount(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(home: ShoppingListScreen(controller: controller)),
  );

  testWidgets('loading is distinct from empty and then becomes empty', (
    tester,
  ) async {
    repository.loadGate = Completer<void>();
    final load = controller.load();
    await mount(tester);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Your shopping list is empty.'), findsNothing);
    repository.loadGate!.complete();
    await load;
    await tester.pumpAndSettle();
    expect(find.text('Your shopping list is empty.'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('independent duplicates can be checked, unchecked and removed', (
    tester,
  ) async {
    await controller.appendIngredients([
      const Ingredient(
        name: 'flour',
        quantity: '1/2',
        unit: 'cup',
        note: 'sifted',
      ),
      const Ingredient(
        name: 'flour',
        quantity: '1/2',
        unit: 'cup',
        note: 'sifted',
      ),
    ]);
    await mount(tester);
    expect(find.text('1/2 cup flour (sifted)'), findsNWidgets(2));
    final checkbox = find.byKey(
      const ValueKey<String>('shopping-check-item-1'),
    );
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    expect(controller.items.map((item) => item.checked), [true, false]);
    expect(checkbox, findsNothing);
    expect(find.text('1/2 cup flour (sifted)'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('shopping-completed-header')),
    );
    await tester.pumpAndSettle();
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    expect(controller.items.first.checked, isFalse);
    await tester.tap(
      find.byKey(const ValueKey<String>('shopping-remove-item-1')),
    );
    await tester.pumpAndSettle();
    expect(controller.items.single.id, 'item-2');
    expect(find.text('1/2 cup flour (sifted)'), findsOneWidget);
    expect(find.byTooltip('Remove 1/2 cup flour (sifted)'), findsOneWidget);
  });

  testWidgets('failed load shows retry without a false empty state', (
    tester,
  ) async {
    repository.loadError = StateError('unavailable');
    await controller.load();
    await mount(tester);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Your shopping list is empty.'), findsNothing);
    repository.loadError = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Your shopping list is empty.'), findsOneWidget);
  });

  testWidgets(
    'move actions preserve identity and failed reorder keeps saved order',
    (tester) async {
      await controller.appendIngredients([
        const Ingredient(name: 'salt'),
        const Ingredient(name: 'pepper'),
      ]);
      await mount(tester);
      final menu = find.byKey(const ValueKey<String>('shopping-move-item-1'));
      await tester.tap(menu);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PopupMenuItem<String>>(
              find.widgetWithText(PopupMenuItem<String>, 'Move up'),
            )
            .enabled,
        isFalse,
      );
      repository.writeError = StateError('disk');
      await tester.tap(find.text('Move down'));
      await tester.pumpAndSettle();
      expect(controller.items.map((item) => item.id), ['item-1', 'item-2']);
      repository.writeError = null;
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move down'));
      await tester.pumpAndSettle();
      expect(controller.items.map((item) => item.id), ['item-2', 'item-1']);
      expect(controller.items.every((item) => !item.checked), isTrue);
      await controller.setChecked('item-1', true);
      await controller.setChecked('item-2', true);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('shopping-completed-header')),
      );
      await tester.pumpAndSettle();
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move up'));
      await tester.pumpAndSettle();
      expect(controller.items.map((item) => item.id), ['item-1', 'item-2']);
      expect(controller.items.every((item) => item.checked), isTrue);
    },
  );

  testWidgets('drag handle changes saved order without toggling', (
    tester,
  ) async {
    await controller.appendIngredients([
      const Ingredient(name: 'salt'),
      const Ingredient(name: 'pepper'),
    ]);
    await mount(tester);
    final handle = find.byKey(const ValueKey<String>('shopping-drag-item-1'));
    await tester.drag(handle, const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(controller.items.map((item) => item.id), ['item-2', 'item-1']);
    expect(controller.items.every((item) => !item.checked), isTrue);
  });

  testWidgets('text toggles once and completed-only lists remain expandable', (
    tester,
  ) async {
    await controller.appendIngredients([const Ingredient(name: 'salt')]);
    await mount(tester);
    final writes = repository.writeCount;
    await tester.tap(
      find.byKey(const ValueKey<String>('shopping-text-item-1')),
    );
    await tester.pumpAndSettle();
    expect(repository.writeCount, writes + 1);
    expect(find.text('salt'), findsNothing);
    expect(find.text('Your shopping list is empty.'), findsNothing);
    final header = find.byKey(
      const ValueKey<String>('shopping-completed-header'),
    );
    await tester.tap(header);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('shopping-text-item-1')),
    );
    await tester.pumpAndSettle();
    expect(controller.items.single.checked, isFalse);
    expect(header, findsNothing);
    await tester.tap(
      find.byKey(const ValueKey<String>('shopping-text-item-1')),
    );
    await tester.pumpAndSettle();
    expect(find.text('salt'), findsNothing);
    await tester.tap(header);
    await tester.pumpAndSettle();
    final beforeRemove = repository.writeCount;
    await tester.tap(
      find.byKey(const ValueKey<String>('shopping-remove-item-1')),
    );
    await tester.pumpAndSettle();
    expect(repository.writeCount, beforeRemove + 1);
    expect(find.text('Your shopping list is empty.'), findsOneWidget);
  });

  testWidgets('edits a completed item without changing identity or state', (
    tester,
  ) async {
    await controller.appendIngredients([const Ingredient(name: 'salt')]);
    await controller.setChecked('item-1', true);
    await mount(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('shopping-completed-header')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('shopping-edit-item-1')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('shopping-edit-name')),
      'sea salt',
    );
    await tester.tap(find.byKey(const ValueKey<String>('shopping-edit-save')));
    await tester.pumpAndSettle();

    expect(controller.items.single.id, 'item-1');
    expect(controller.items.single.checked, isTrue);
    expect(controller.items.single.ingredient.name, 'sea salt');
    expect(find.text('sea salt'), findsOneWidget);
  });

  testWidgets(
    'busy controls are disabled and failed writes keep the saved row',
    (tester) async {
      await controller.appendIngredients([const Ingredient(name: 'salt')]);
      repository.writeGate = Completer<void>();
      repository.writeError = StateError('storage');
      await mount(tester);
      final checkbox = find.byKey(
        const ValueKey<String>('shopping-check-item-1'),
      );
      await tester.tap(checkbox);
      await tester.pump();
      expect(tester.widget<Checkbox>(checkbox).onChanged, isNull);
      expect(tester.widget<Checkbox>(checkbox).value, isFalse);
      final remove = find.byKey(
        const ValueKey<String>('shopping-remove-item-1'),
      );
      expect(tester.widget<IconButton>(remove).onPressed, isNull);
      repository.writeGate!.complete();
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(checkbox).value, isFalse);
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(find.text('salt'), findsOneWidget);
      repository.writeError = null;
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(find.text('Your shopping list is empty.'), findsOneWidget);
    },
  );

  testWidgets('clear cancellation does not write', (tester) async {
    await controller.appendIngredients([const Ingredient(name: 'salt')]);
    await mount(tester);
    final writes = repository.writeCount;
    await tester.tap(find.byKey(const ValueKey<String>('shopping-clear')));
    await tester.pumpAndSettle();
    expect(
      find.text('Remove all 1 entry, including active and completed items?'),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('shopping-clear-cancel')),
    );
    await tester.pumpAndSettle();

    expect(repository.writeCount, writes);
    expect(controller.items, hasLength(1));
  });

  testWidgets('clear removes hidden completed items in one write', (
    tester,
  ) async {
    await controller.appendIngredients([
      const Ingredient(name: 'salt'),
      const Ingredient(name: 'pepper'),
    ]);
    await controller.setChecked('item-2', true);
    await mount(tester);
    final writes = repository.writeCount;
    await tester.tap(find.byKey(const ValueKey<String>('shopping-clear')));
    await tester.pumpAndSettle();
    expect(
      find.text('Remove all 2 entries, including active and completed items?'),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('shopping-clear-confirm')),
    );
    await tester.pumpAndSettle();

    expect(repository.writeCount, writes + 1);
    expect(controller.items, isEmpty);
    expect(find.text('Your shopping list is empty.'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey<String>('shopping-clear')),
          )
          .onPressed,
      isNull,
    );
    await controller.appendIngredients([const Ingredient(name: 'milk')]);
    await tester.pumpAndSettle();
    expect(find.text('milk'), findsOneWidget);
  });

  testWidgets('failed clear retains all items and can be retried', (
    tester,
  ) async {
    await controller.appendIngredients([const Ingredient(name: 'salt')]);
    repository.writeError = StateError('disk');
    await mount(tester);
    await tester.tap(find.byKey(const ValueKey<String>('shopping-clear')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('shopping-clear-confirm')),
    );
    await tester.pumpAndSettle();

    expect(controller.items, hasLength(1));
    expect(find.text('Retry'), findsOneWidget);
    repository.writeError = null;
    await tester.tap(find.byKey(const ValueKey<String>('shopping-clear')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('shopping-clear-confirm')),
    );
    await tester.pumpAndSettle();
    expect(controller.items, isEmpty);
  });

  testWidgets('long rows and controls fit at 320 dp and 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await controller.appendIngredients([
      const Ingredient(
        name: 'freshly chopped vegetables',
        quantity: '1/2',
        unit: 'cup',
        note: 'finely sliced',
      ),
      const Ingredient(name: 'salt'),
    ]);
    await mount(tester);
    final remove = find.byKey(const ValueKey<String>('shopping-remove-item-2'));
    await tester.scrollUntilVisible(remove, 200);
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(controller.items, hasLength(1));
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.byType(Checkbox).first, -200);
    expect(find.byType(Checkbox), findsOneWidget);
  });
}
