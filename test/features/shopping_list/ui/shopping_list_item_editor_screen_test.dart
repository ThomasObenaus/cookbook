import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/shopping_list/models/shopping_list_item.dart';
import 'package:cookbook/features/shopping_list/ui/shopping_list_item_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const item = ShoppingListItem(
    id: 'item-1',
    ingredient: Ingredient(
      name: 'flour',
      quantity: '1/2',
      unit: 'cup',
      note: 'sifted',
    ),
    checked: true,
  );

  Future<void> open(
    WidgetTester tester,
    Future<bool> Function(Ingredient) onSave,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) =>
                    ShoppingListItemEditorScreen(item: item, onSave: onSave),
              ),
            ),
            child: const Text('Open editor'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
  }

  testWidgets('saves trimmed values and clears optional fields', (
    tester,
  ) async {
    Ingredient? saved;
    await open(tester, (ingredient) async {
      saved = ingredient;
      return true;
    });
    await tester.enterText(
      find.byKey(const ValueKey<String>('shopping-edit-name')),
      ' sea salt ',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('shopping-edit-quantity')),
      ' to taste ',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('shopping-edit-unit')),
      '',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('shopping-edit-note')),
      '',
    );
    await tester.tap(find.byKey(const ValueKey<String>('shopping-edit-save')));
    await tester.pumpAndSettle();

    expect(saved?.toJson(), {'name': 'sea salt', 'quantity': 'to taste'});
    expect(find.text('Open editor'), findsOneWidget);
  });

  testWidgets('invalid names do not call save', (tester) async {
    var calls = 0;
    await open(tester, (_) async {
      calls++;
      return true;
    });
    await tester.enterText(
      find.byKey(const ValueKey<String>('shopping-edit-name')),
      '   ',
    );
    await tester.tap(find.byKey(const ValueKey<String>('shopping-edit-save')));
    await tester.pump();

    expect(calls, 0);
    expect(find.text('Enter an ingredient name.'), findsOneWidget);
    expect(find.text('Edit shopping item'), findsOneWidget);
  });

  testWidgets('failed save retains the draft and permits retry', (
    tester,
  ) async {
    var calls = 0;
    await open(tester, (_) async => ++calls > 1);
    final name = find.byKey(const ValueKey<String>('shopping-edit-name'));
    await tester.enterText(name, 'pepper');
    await tester.tap(find.byKey(const ValueKey<String>('shopping-edit-save')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('shopping-edit-error')),
      findsOneWidget,
    );
    expect(tester.widget<TextFormField>(name).controller?.text, 'pepper');
    await tester.tap(find.byKey(const ValueKey<String>('shopping-edit-save')));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Open editor'), findsOneWidget);
  });

  testWidgets('cancel closes without saving at compact large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    var calls = 0;
    await open(tester, (_) async {
      calls++;
      return true;
    });
    final cancel = find.byKey(const ValueKey<String>('shopping-edit-cancel'));
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(tester.takeException(), isNull);
    expect(find.text('Open editor'), findsOneWidget);
  });
}
