import 'dart:io';

import 'package:cookbook/features/meal_planner/data/local_meal_plan_repository.dart';
import 'package:cookbook/features/meal_planner/ui/meal_slot_tile.dart';
import 'package:cookbook/features/recipe_catalog/data/asset_recipe_repository.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe_image.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_image_view.dart';
import 'package:cookbook/features/recipe_creator/data/local_recipe_repository.dart';
import 'package:cookbook/features/recipe_creator/data/recipe_image_picker.dart';
import 'package:cookbook/features/recipe_creator/models/ingredient_unit.dart';
import 'package:cookbook/features/shopping_list/data/local_shopping_list_repository.dart';
import 'package:cookbook/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('recipes, meal plans and shopping items survive app recreation', (
    tester,
  ) async {
    final supportDirectory = await Directory.systemTemp.createTemp(
      'cookbook-integration-',
    );
    addTearDown(() async {
      if (await supportDirectory.exists()) {
        await supportDirectory.delete(recursive: true);
      }
    });
    final sourceImage = File.fromUri(
      supportDirectory.uri.resolve('selected_recipe.png'),
    );
    final imageData = await rootBundle.load(
      'assets/images/recipe_placeholder.png',
    );
    await sourceImage.writeAsBytes(imageData.buffer.asUint8List(), flush: true);

    final repository = LocalRecipeRepository(
      seedRepository: AssetRecipeRepository(assetBundle: rootBundle),
      applicationSupportDirectory: supportDirectory,
      createId: () => 'integration-family-soup',
    );
    final mealPlanRepository = LocalMealPlanRepository(
      applicationSupportDirectory: supportDirectory,
    );
    var nextShoppingId = 0;
    final shoppingListRepository = LocalShoppingListRepository(
      applicationSupportDirectory: supportDirectory,
      createId: () => 'shopping-${++nextShoppingId}',
    );
    await tester.pumpWidget(
      CookbookApp(
        key: const ValueKey<String>('initial-app'),
        repository: repository,
        mealPlanRepository: mealPlanRepository,
        shoppingListRepository: shoppingListRepository,
        imagePicker: _FakePicker(sourceImage.path),
        currentDateProvider: () => DateTime(2026, 9, 22),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Recipes'), findsOneWidget);
    expect(_gridItemCount(tester), 8);

    await tester.tap(find.text('Meal plan'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Meal plan'), findsOneWidget);
    expect(find.textContaining('Sep 21'), findsOneWidget);
    expect(find.textContaining('Sep 27'), findsOneWidget);
    expect(find.text('Breakfast'), findsNWidgets(7));
    expect(find.text('Lunch'), findsNWidgets(7));
    expect(find.text('Dinner'), findsNWidgets(7));

    await tester.tap(find.byTooltip('Next week'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sep 28'), findsOneWidget);
    await _tapKey(tester, 'today-action');
    expect(find.textContaining('Sep 21'), findsOneWidget);

    const breakfastSlot = 'meal-slot-2026-09-21-breakfast';
    const lunchSlot = 'meal-slot-2026-09-21-lunch';
    await _assignRecipe(
      tester,
      slotKey: breakfastSlot,
      recipeId: 'tomato-basil-pasta',
    );
    expect(find.text('Tomato Basil Pasta'), findsOneWidget);

    await _changeRecipe(
      tester,
      slotKey: breakfastSlot,
      recipeId: 'creamy-mushroom-pasta',
    );
    expect(find.text('Creamy Mushroom Pasta'), findsOneWidget);

    await _assignRecipe(
      tester,
      slotKey: lunchSlot,
      recipeId: 'tomato-basil-pasta',
    );
    expect(find.text('Tomato Basil Pasta'), findsOneWidget);

    await _tapKey(tester, breakfastSlot);
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Creamy Mushroom Pasta'), findsNothing);

    await _tapKey(tester, 'add-week-to-shopping-list');
    expect(
      (await shoppingListRepository.load()).map((item) => item.ingredient.name),
      <String>[
        'spaghetti',
        'crushed tomatoes',
        'garlic',
        'fresh basil',
        'olive oil',
      ],
    );

    await tester.tap(find.text('Recipes'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Recipes'), findsOneWidget);

    await tester.tap(find.byTooltip('Create recipe'));
    await tester.pumpAndSettle();
    expect(find.text('Create recipe'), findsOneWidget);

    final imageControl = find.byKey(
      const ValueKey<String>('recipe-image-control'),
    );
    await tester.ensureVisible(imageControl);
    await tester.tap(imageControl);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Change recipe image'), findsOneWidget);

    final title = find.byKey(const ValueKey<String>('recipe-title-field'));
    await tester.ensureVisible(title);
    await tester.enterText(title, 'Family Vegetable Soup');
    await _tapKey(tester, 'wizard-continue');

    await _fillIngredient(
      tester,
      name: 'carrots',
      quantity: '2',
      unit: IngredientUnit.cup,
      note: 'sliced',
    );
    await _tapKey(tester, 'save-ingredient');
    await _tapKey(tester, 'add-ingredient');
    await _fillIngredient(
      tester,
      name: 'garlic',
      quantity: '3',
      unit: IngredientUnit.clove,
    );
    await _tapKey(tester, 'save-ingredient');

    await _tapKey(tester, 'edit-ingredient-0');
    await tester.enterText(
      find.byKey(const ValueKey<String>('ingredient-name-field')),
      'rainbow carrots',
    );
    await _tapKey(tester, 'save-ingredient');
    await _tapKey(tester, 'wizard-continue');

    final step = find.byKey(const ValueKey<String>('preparation-step-field'));
    await tester.ensureVisible(step);
    await tester.enterText(step, 'Prepare the vegetables.');
    await _tapKey(tester, 'save-preparation-step');
    await _tapKey(tester, 'add-preparation-step');
    await tester.enterText(step, 'Simmer.');
    await _tapKey(tester, 'save-preparation-step');
    await _tapKey(tester, 'add-preparation-step');
    await tester.enterText(step, 'Season and serve.');
    await _tapKey(tester, 'save-preparation-step');

    await _tapKey(tester, 'edit-preparation-step-1');
    await tester.enterText(step, 'Simmer until tender.');
    await _tapKey(tester, 'save-preparation-step');
    await _tapKey(tester, 'wizard-continue');

    expect(find.text('Step 4 of 4'), findsOneWidget);
    expect(find.text('2 cup rainbow carrots (sliced)'), findsOneWidget);
    expect(find.text('3 clove garlic'), findsOneWidget);
    expect(find.text('Prepare the vegetables.'), findsOneWidget);
    expect(find.text('Simmer until tender.'), findsOneWidget);
    expect(find.text('Season and serve.'), findsOneWidget);

    await _tapKey(tester, 'save-recipe');

    expect(find.widgetWithText(AppBar, 'Recipes'), findsOneWidget);
    expect(_gridItemCount(tester), 9);
    expect(find.text('Family Vegetable Soup'), findsOneWidget);
    await sourceImage.delete();

    await tester.tap(
      find.byKey(const ValueKey<String>('recipe-card-integration-family-soup')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Family Vegetable Soup'), findsOneWidget);
    expect(find.text('Serves 4'), findsOneWidget);
    expect(find.text('Preparation 0 min'), findsOneWidget);
    expect(find.text('Cooking 0 min'), findsOneWidget);
    expect(find.text('2 cup rainbow carrots (sliced)'), findsOneWidget);
    expect(find.text('3 clove garlic'), findsOneWidget);

    final detailImage = tester.widget<RecipeImageView>(
      find.byKey(const ValueKey<String>('recipe-detail-image')),
    );
    expect(detailImage.image.kind, RecipeImageKind.file);
    expect(await File(detailImage.image.path).exists(), isTrue);

    final lastStep = find.text('Season and serve.');
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

    await _tapKey(tester, 'add-to-shopping-list');
    expect(find.text('Ingredients added to shopping list.'), findsOneWidget);
    await _tapKey(tester, 'add-to-shopping-list');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _tapKey(tester, 'shopping-list-destination');
    expect(find.text('2 cup rainbow carrots (sliced)'), findsWidgets);
    expect(find.text('350 g spaghetti'), findsOneWidget);
    final addedShoppingItems = await shoppingListRepository.load();
    expect(
      addedShoppingItems.where(
        (item) => item.ingredient.name == 'rainbow carrots',
      ),
      hasLength(2),
    );
    expect(
      addedShoppingItems.where(
        (item) =>
            item.ingredient.name == 'garlic' && item.ingredient.quantity == '3',
      ),
      hasLength(2),
    );
    expect(addedShoppingItems.every((item) => !item.checked), isTrue);
    await _tapKey(tester, 'shopping-text-shopping-1');
    expect(find.text('350 g spaghetti'), findsNothing);
    await _tapShoppingKey(tester, 'shopping-completed-header');
    expect(find.text('Completed (1)'), findsOneWidget);

    await _tapShoppingKey(tester, 'shopping-move-shopping-8');
    await tester.tap(find.text('Move up'));
    await tester.pumpAndSettle();
    expect(
      (await shoppingListRepository.load()).map((item) => item.id),
      <String>[
        'shopping-1',
        'shopping-2',
        'shopping-3',
        'shopping-4',
        'shopping-5',
        'shopping-6',
        'shopping-8',
        'shopping-7',
        'shopping-9',
      ],
    );

    await _tapShoppingKey(tester, 'shopping-edit-shopping-1');
    await tester.enterText(
      find.byKey(const ValueKey<String>('shopping-edit-name')),
      'whole-wheat spaghetti',
    );
    await _tapKey(tester, 'shopping-edit-save');
    await _scrollToShoppingKey(tester, 'shopping-text-shopping-1');
    expect(find.text('350 g whole-wheat spaghetti'), findsOneWidget);

    await _tapShoppingKey(tester, 'shopping-remove-shopping-7');
    expect(find.text('3 clove garlic'), findsOneWidget);
    final savedShoppingItems = await shoppingListRepository.load();
    expect(savedShoppingItems.map((item) => item.id), [
      'shopping-1',
      'shopping-2',
      'shopping-3',
      'shopping-4',
      'shopping-5',
      'shopping-6',
      'shopping-8',
      'shopping-9',
    ]);
    expect(savedShoppingItems.first.ingredient.name, 'whole-wheat spaghetti');
    expect(savedShoppingItems.first.checked, isTrue);
    expect(savedShoppingItems.skip(1).every((item) => !item.checked), isTrue);

    final reloadedRepository = LocalRecipeRepository(
      seedRepository: AssetRecipeRepository(assetBundle: rootBundle),
      applicationSupportDirectory: supportDirectory,
      createId: () => 'unused-integration-id',
    );
    final reloadedRecipes = await reloadedRepository.getAllRecipes();
    final reloadedRecipe = reloadedRecipes.singleWhere(
      (recipe) => recipe.id == 'integration-family-soup',
    );
    expect(
      reloadedRecipe.ingredients.map((ingredient) => ingredient.name),
      <String>['rainbow carrots', 'garlic'],
    );
    expect(
      reloadedRecipe.ingredients.map((ingredient) => ingredient.unit),
      <String?>['cup', 'clove'],
    );
    expect(reloadedRecipe.steps, <String>[
      'Prepare the vegetables.',
      'Simmer until tender.',
      'Season and serve.',
    ]);
    final reloadedMealPlanRepository = LocalMealPlanRepository(
      applicationSupportDirectory: supportDirectory,
    );
    final reloadedShoppingListRepository = LocalShoppingListRepository(
      applicationSupportDirectory: supportDirectory,
      createId: () => 'reloaded-shopping-${++nextShoppingId}',
    );
    expect(
      (await reloadedShoppingListRepository.load()).map(
        (item) => item.toJson(),
      ),
      savedShoppingItems.map((item) => item.toJson()),
    );
    await tester.pumpWidget(
      CookbookApp(
        key: const ValueKey<String>('restarted-app'),
        repository: reloadedRepository,
        mealPlanRepository: reloadedMealPlanRepository,
        shoppingListRepository: reloadedShoppingListRepository,
        imagePicker: _FakePicker(sourceImage.path),
        currentDateProvider: () => DateTime(2026, 9, 22),
      ),
    );
    await tester.pumpAndSettle();

    expect(_gridItemCount(tester), 9);
    expect(find.text('Family Vegetable Soup'), findsOneWidget);

    await _tapKey(tester, 'shopping-list-destination');
    expect(find.text('350 g whole-wheat spaghetti'), findsNothing);
    await _tapShoppingKey(tester, 'shopping-completed-header');
    expect(find.text('Completed (1)'), findsOneWidget);
    await _scrollToShoppingKey(tester, 'shopping-check-shopping-1');
    expect(find.text('350 g whole-wheat spaghetti'), findsOneWidget);
    expect(
      tester
          .widget<Checkbox>(
            find.byKey(const ValueKey<String>('shopping-check-shopping-1')),
          )
          .value,
      isTrue,
    );
    expect(
      find.byKey(const ValueKey<String>('shopping-item-shopping-7')),
      findsNothing,
    );

    await _tapShoppingKey(tester, 'shopping-completed-header');
    expect(find.text('350 g whole-wheat spaghetti'), findsNothing);
    await _tapKey(tester, 'shopping-clear');
    expect(
      find.text('Remove all 8 entries, including active and completed items?'),
      findsOneWidget,
    );
    await _tapKey(tester, 'shopping-clear-confirm');
    expect(find.text('Your shopping list is empty.'), findsOneWidget);
    final clearedShoppingListRepository = LocalShoppingListRepository(
      applicationSupportDirectory: supportDirectory,
      createId: () => 'cleared-shopping-${++nextShoppingId}',
    );
    expect(await clearedShoppingListRepository.load(), isEmpty);

    await tester.tap(find.text('Meal plan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sep 21'), findsOneWidget);
    expect(find.text('Tomato Basil Pasta'), findsOneWidget);
    final breakfast = tester.widget<MealSlotTile>(
      find.byKey(const ValueKey<String>(breakfastSlot)),
    );
    final lunch = tester.widget<MealSlotTile>(
      find.byKey(const ValueKey<String>(lunchSlot)),
    );
    expect(breakfast.recipe, isNull);
    expect(breakfast.isUnavailable, isFalse);
    expect(lunch.recipe?.id, 'tomato-basil-pasta');
    expect(find.text('Creamy Mushroom Pasta'), findsNothing);

    await _verifyWeekBoundary(
      tester,
      repository: reloadedRepository,
      mealPlanRepository: reloadedMealPlanRepository,
      shoppingListRepository: clearedShoppingListRepository,
      imagePath: sourceImage.path,
      currentDate: DateTime(2025, 12, 31, 23),
      expectedStart: 'Dec 29',
      expectedEnd: 'Jan 4',
      expectedNextStart: 'Jan 5',
      appKey: 'year-boundary-app',
    );
    await _verifyWeekBoundary(
      tester,
      repository: reloadedRepository,
      mealPlanRepository: reloadedMealPlanRepository,
      shoppingListRepository: clearedShoppingListRepository,
      imagePath: sourceImage.path,
      currentDate: DateTime(2024, 2, 29, 23),
      expectedStart: 'Feb 26',
      expectedEnd: 'Mar 3',
      expectedNextStart: 'Mar 4',
      appKey: 'leap-boundary-app',
    );
    await _verifyWeekBoundary(
      tester,
      repository: reloadedRepository,
      mealPlanRepository: reloadedMealPlanRepository,
      shoppingListRepository: clearedShoppingListRepository,
      imagePath: sourceImage.path,
      currentDate: DateTime(2026, 3, 8, 23),
      expectedStart: 'Mar 2',
      expectedEnd: 'Mar 8',
      expectedNextStart: 'Mar 9',
      appKey: 'daylight-saving-boundary-app',
    );
  });
}

Future<void> _verifyWeekBoundary(
  WidgetTester tester, {
  required LocalRecipeRepository repository,
  required LocalMealPlanRepository mealPlanRepository,
  required LocalShoppingListRepository shoppingListRepository,
  required String imagePath,
  required DateTime currentDate,
  required String expectedStart,
  required String expectedEnd,
  required String expectedNextStart,
  required String appKey,
}) async {
  await tester.pumpWidget(
    CookbookApp(
      key: ValueKey<String>(appKey),
      repository: repository,
      mealPlanRepository: mealPlanRepository,
      shoppingListRepository: shoppingListRepository,
      imagePicker: _FakePicker(imagePath),
      currentDateProvider: () => currentDate,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Meal plan'));
  await tester.pumpAndSettle();

  expect(find.textContaining(expectedStart), findsOneWidget);
  expect(find.textContaining(expectedEnd), findsOneWidget);
  await tester.tap(find.byTooltip('Next week'));
  await tester.pumpAndSettle();
  expect(find.textContaining(expectedNextStart), findsOneWidget);
}

Future<void> _assignRecipe(
  WidgetTester tester, {
  required String slotKey,
  required String recipeId,
}) async {
  await _tapKey(tester, slotKey);
  expect(find.text('Select recipe'), findsOneWidget);
  await _tapKey(tester, 'select-recipe-card-$recipeId');
}

Future<void> _changeRecipe(
  WidgetTester tester, {
  required String slotKey,
  required String recipeId,
}) async {
  await _tapKey(tester, slotKey);
  await tester.tap(find.text('Change recipe'));
  await tester.pumpAndSettle();
  await _tapKey(tester, 'select-recipe-card-$recipeId');
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey<String>(key));
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _tapShoppingKey(WidgetTester tester, String key) async {
  await _scrollToShoppingKey(tester, key);
  await _tapKey(tester, key);
}

Future<void> _scrollToShoppingKey(WidgetTester tester, String key) async {
  final list = find.byKey(const PageStorageKey<String>('shopping-list-items'));
  final scrollable = find.descendant(
    of: list,
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(
    find.byKey(ValueKey<String>(key)),
    300,
    scrollable: scrollable,
  );
}

Future<void> _fillIngredient(
  WidgetTester tester, {
  required String name,
  required String quantity,
  required IngredientUnit unit,
  String? note,
}) async {
  final nameField = find.byKey(const ValueKey<String>('ingredient-name-field'));
  await tester.ensureVisible(nameField);
  await tester.enterText(nameField, name);
  await tester.enterText(
    find.byKey(const ValueKey<String>('ingredient-quantity-field')),
    quantity,
  );
  final unitField = find.byKey(const ValueKey<String>('ingredient-unit-field'));
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(unitField);
  await tester.pumpAndSettle();
  await tester.tap(unitField);
  await tester.pumpAndSettle();
  final unitOptions = find.text(unit.label);
  expect(unitOptions, findsWidgets);
  final unitOption = unitOptions.last;
  await tester.ensureVisible(unitOption);
  await tester.pumpAndSettle();
  expect(unitOption.hitTestable(), findsOneWidget);
  await tester.tap(unitOption);
  await tester.pumpAndSettle();
  expect(tester.state<FormFieldState<IngredientUnit>>(unitField).value, unit);
  if (note != null) {
    await tester.enterText(
      find.byKey(const ValueKey<String>('ingredient-note-field')),
      note,
    );
  }
}

class _FakePicker implements RecipeImagePicker {
  const _FakePicker(this.path);

  final String path;

  @override
  Future<String?> pickFromGallery() async => path;
}

int? _gridItemCount(WidgetTester tester) {
  final grid = tester.widget<GridView>(
    find.byKey(const ValueKey<String>('recipe-grid')),
  );
  return grid.childrenDelegate.estimatedChildCount;
}
