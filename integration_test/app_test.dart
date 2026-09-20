import 'dart:io';

import 'package:cookbook/features/recipe_catalog/data/asset_recipe_repository.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe_image.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_image_view.dart';
import 'package:cookbook/features/recipe_creator/data/local_recipe_repository.dart';
import 'package:cookbook/features/recipe_creator/data/recipe_image_picker.dart';
import 'package:cookbook/features/recipe_creator/models/ingredient_unit.dart';
import 'package:cookbook/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('family creates a recipe that survives an app restart', (
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
    await tester.pumpWidget(
      CookbookApp(
        key: const ValueKey<String>('initial-app'),
        repository: repository,
        imagePicker: _FakePicker(sourceImage.path),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Recipes'), findsOneWidget);
    expect(_gridItemCount(tester), 8);

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

    await tester.pageBack();
    await tester.pumpAndSettle();

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
    await tester.pumpWidget(
      CookbookApp(
        key: const ValueKey<String>('restarted-app'),
        repository: reloadedRepository,
        imagePicker: _FakePicker(sourceImage.path),
      ),
    );
    await tester.pumpAndSettle();

    expect(_gridItemCount(tester), 9);
    expect(find.text('Family Vegetable Soup'), findsOneWidget);
  });
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey<String>(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
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
  await tester.tap(find.byKey(const ValueKey<String>('ingredient-unit-field')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(unit.label).last);
  await tester.pumpAndSettle();
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
