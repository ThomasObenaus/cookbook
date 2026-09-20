import 'dart:io';

import 'package:cookbook/features/recipe_catalog/data/asset_recipe_repository.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe_image.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_image_view.dart';
import 'package:cookbook/features/recipe_creator/data/local_recipe_repository.dart';
import 'package:cookbook/features/recipe_creator/data/recipe_image_picker.dart';
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

    final chooseImage = find.byKey(
      const ValueKey<String>('choose-recipe-image'),
    );
    await tester.ensureVisible(chooseImage);
    await tester.tap(chooseImage);
    await tester.pumpAndSettle();
    expect(find.text('Replace image'), findsOneWidget);
    expect(find.bySemanticsLabel('Selected recipe image'), findsOneWidget);

    final title = find.byKey(const ValueKey<String>('recipe-title-field'));
    await tester.ensureVisible(title);
    await tester.enterText(title, 'Family Vegetable Soup');

    final ingredientName = find.byKey(
      const ValueKey<String>('ingredient-name-0'),
    );
    await tester.ensureVisible(ingredientName);
    await tester.enterText(ingredientName, 'carrots');
    await tester.enterText(
      find.byKey(const ValueKey<String>('ingredient-quantity-0')),
      '2',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('ingredient-unit-0')),
      'cups',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('ingredient-note-0')),
      'sliced',
    );

    final steps = find.byKey(const ValueKey<String>('recipe-steps-field'));
    await tester.ensureVisible(steps);
    await tester.enterText(
      steps,
      'Prepare the vegetables.\nSimmer until tender.\nSeason and serve.',
    );

    await tester.tap(find.byTooltip('Save recipe'));
    await tester.pumpAndSettle();

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
    expect(find.text('2 cups carrots (sliced)'), findsOneWidget);

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
