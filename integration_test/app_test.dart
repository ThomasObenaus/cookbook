import 'package:cookbook/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('family browses and searches the bundled recipe catalogue', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Recipes'), findsOneWidget);
    expect(_gridItemCount(tester), 8);
    expect(find.text('Tomato Basil Pasta'), findsOneWidget);

    final searchField = find.byKey(
      const ValueKey<String>('recipe-search-field'),
    );
    await tester.enterText(searchField, 'mushroom');
    await tester.pump();

    expect(_gridItemCount(tester), 1);
    expect(find.text('Creamy Mushroom Pasta'), findsOneWidget);
    expect(find.text('Tomato Basil Pasta'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('recipe-card-creamy-mushroom-pasta')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Creamy Mushroom Pasta'), findsOneWidget);
    expect(find.text('Serves 4'), findsOneWidget);
    expect(find.text('Preparation 10 min'), findsOneWidget);
    expect(find.text('Cooking 25 min'), findsOneWidget);
    expect(find.text('350 g fettuccine'), findsOneWidget);
    expect(find.text('300 g chestnut mushrooms (sliced)'), findsOneWidget);

    final lastStep = find.text(
      'Stir in the cream and parmesan, loosen with pasta water, and toss with the fettuccine.',
    );
    await tester.scrollUntilVisible(
      lastStep,
      300,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey<String>('recipe-detail-scroll-view')),
        matching: find.byType(Scrollable),
      ),
    );

    expect(lastStep, findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(searchField);
    expect(textField.controller?.text, 'mushroom');
    expect(_gridItemCount(tester), 1);
    expect(find.text('Creamy Mushroom Pasta'), findsOneWidget);
    expect(find.text('Tomato Basil Pasta'), findsNothing);
  });
}

int? _gridItemCount(WidgetTester tester) {
  final grid = tester.widget<GridView>(
    find.byKey(const ValueKey<String>('recipe-grid')),
  );
  return grid.childrenDelegate.estimatedChildCount;
}
