import 'dart:async';
import 'dart:io';

import 'package:cookbook/features/recipe_catalog/data/recipe_repository.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe_image.dart';
import 'package:cookbook/features/recipe_creator/data/mutable_recipe_repository.dart';
import 'package:cookbook/features/recipe_creator/data/recipe_image_picker.dart';
import 'package:cookbook/features/recipe_creator/models/ingredient_unit.dart';
import 'package:cookbook/features/recipe_creator/models/new_recipe.dart';
import 'package:cookbook/features/recipe_creator/ui/recipe_creator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starts on Recipe with a tappable image and no separate button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        RecipeCreatorScreen(
          repository: _FakeRepository(),
          imagePicker: _SequencePicker(<String?>[]),
        ),
      ),
    );

    _expectStage(tester, 'Recipe', 1);
    expect(find.bySemanticsLabel('Choose recipe image'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('choose-recipe-image')),
      findsNothing,
    );
    expect(find.byKey(_ingredientNameKey), findsNothing);
    expect(find.byKey(_preparationKey), findsNothing);
    expect(find.byKey(const ValueKey<String>('save-recipe')), findsNothing);
  });

  testWidgets('validates only Recipe and retains state across image outcomes', (
    tester,
  ) async {
    final imagePath = _imagePath;
    final picker = _SequencePicker(<String?>[null, imagePath, imagePath]);
    await tester.pumpWidget(
      _testApp(
        RecipeCreatorScreen(repository: _FakeRepository(), imagePicker: picker),
      ),
    );

    await _tap(tester, _continueKey);
    expect(find.text('Choose a recipe image'), findsWidgets);
    expect(find.text('Enter a recipe title'), findsOneWidget);
    expect(find.text('Add at least one ingredient'), findsNothing);

    await tester.enterText(find.byKey(_titleKey), 'Family Soup');
    await _tap(tester, _imageKey);
    expect(find.text('Family Soup'), findsOneWidget);
    expect(find.bySemanticsLabel('Choose recipe image'), findsOneWidget);

    await _tap(tester, _imageKey);
    expect(find.bySemanticsLabel('Change recipe image'), findsOneWidget);
    expect(picker.pickCount, 2);

    await _tap(tester, _imageKey);
    expect(picker.pickCount, 3);
    expect(find.text('Family Soup'), findsOneWidget);
  });

  testWidgets(
    'shows picker progress, blocks duplicate taps, and reports failure',
    (tester) async {
      final picker = _PendingPicker();
      await tester.pumpWidget(
        _testApp(
          RecipeCreatorScreen(
            repository: _FakeRepository(),
            imagePicker: picker,
          ),
        ),
      );

      await tester.tap(find.byKey(_imageKey));
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('recipe-image-progress')),
        findsOneWidget,
      );
      expect(tester.widget<InkWell>(find.byKey(_imageKey)).onTap, isNull);
      expect(
        tester.widget<FilledButton>(find.byKey(_continueKey)).onPressed,
        isNull,
      );
      await tester.tap(find.byKey(_imageKey), warnIfMissed: false);
      expect(picker.pickCount, 1);

      picker.complete(null);
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        _testApp(
          RecipeCreatorScreen(
            repository: _FakeRepository(),
            imagePicker: _FailingPicker(),
          ),
        ),
      );
      await tester.enterText(find.byKey(_titleKey), 'Family Soup');
      await _tap(tester, _imageKey);
      expect(find.text('Family Soup'), findsOneWidget);
      expect(
        find.text('The image could not be selected. Please try again.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('navigates stages in order and preserves Recipe values', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        RecipeCreatorScreen(
          repository: _FakeRepository(),
          imagePicker: _pickerWithImage,
        ),
      ),
    );

    await _completeRecipeStage(tester, title: 'Family Soup');
    _expectStage(tester, 'Ingredients', 2);
    expect(find.byKey(_ingredientNameKey), findsOneWidget);

    await _tap(tester, _backKey);
    _expectStage(tester, 'Recipe', 1);
    expect(find.text('Family Soup'), findsOneWidget);
    expect(find.bySemanticsLabel('Change recipe image'), findsOneWidget);

    await _tap(tester, _continueKey);
    _expectStage(tester, 'Ingredients', 2);
  });

  testWidgets('uses one ingredient editor with the exact typed units', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        RecipeCreatorScreen(
          repository: _FakeRepository(),
          imagePicker: _pickerWithImage,
        ),
      ),
    );
    await _completeRecipeStage(tester);

    expect(find.byKey(_ingredientNameKey), findsOneWidget);
    final dropdown = _unitDropdown(tester);
    expect(
      dropdown.items!.map((item) => item.value).toList(growable: false),
      <IngredientUnit?>[null, ...IngredientUnit.values],
    );
    expect(
      dropdown.items!
          .map((item) => (item.child as Text).data)
          .toList(growable: false),
      <String?>['No unit', ...IngredientUnit.values.map((unit) => unit.label)],
    );

    await _fillIngredient(
      tester,
      name: 'carrots',
      quantity: '2',
      unit: IngredientUnit.gram,
      note: 'chopped',
    );
    await _tap(tester, _saveIngredientKey);
    expect(find.byKey(_ingredientNameKey), findsNothing);
    expect(find.text('2 g carrots'), findsOneWidget);

    await _tap(tester, _addIngredientKey);
    expect(find.byKey(_ingredientNameKey), findsOneWidget);
    expect(find.text('Ingredient 2'), findsOneWidget);
    expect(find.byKey(_addIngredientKey), findsNothing);
  });

  testWidgets('edits, removes, and renumbers committed ingredients', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        RecipeCreatorScreen(
          repository: _FakeRepository(),
          imagePicker: _pickerWithImage,
        ),
      ),
    );
    await _completeRecipeStage(tester);
    await _commitIngredient(
      tester,
      name: 'carrots',
      quantity: '2',
      unit: IngredientUnit.gram,
    );
    await _tap(tester, _addIngredientKey);
    await _commitIngredient(
      tester,
      name: 'salt',
      quantity: '1',
      unit: IngredientUnit.teaspoon,
    );

    await _tap(tester, const ValueKey<String>('edit-ingredient-0'));
    expect(find.byKey(_ingredientNameKey), findsOneWidget);
    expect(_unitDropdown(tester).value, IngredientUnit.gram);
    await tester.enterText(find.byKey(_ingredientNameKey), 'baby carrots');
    await _tap(tester, _saveIngredientKey);

    expect(find.text('2 g baby carrots'), findsOneWidget);
    expect(find.text('1 tsp salt'), findsOneWidget);
    await _tap(tester, const ValueKey<String>('remove-ingredient-0'));
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey<String>('ingredient-summary-0')),
          )
          .data,
      '1 tsp salt',
    );
    await _tap(tester, const ValueKey<String>('remove-ingredient-0'));
    expect(find.text('Ingredient 1'), findsOneWidget);
    expect(find.byKey(_ingredientNameKey), findsOneWidget);
  });

  testWidgets('validates and commits a pending ingredient on Continue', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        RecipeCreatorScreen(
          repository: _FakeRepository(),
          imagePicker: _pickerWithImage,
        ),
      ),
    );
    await _completeRecipeStage(tester);

    await _tap(tester, _continueKey);
    expect(find.text('Add at least one ingredient'), findsOneWidget);
    await tester.enterText(find.byKey(_ingredientQuantityKey), '2');
    await _tap(tester, _continueKey);
    expect(find.text('Enter an ingredient name'), findsOneWidget);
    await tester.enterText(find.byKey(_ingredientNameKey), 'carrots');
    await _tap(tester, _continueKey);
    _expectStage(tester, 'Preparation', 3);

    await _tap(tester, _backKey);
    expect(find.text('2 carrots'), findsOneWidget);
    await _tap(tester, _addIngredientKey);
    await _tap(tester, _continueKey);
    _expectStage(tester, 'Preparation', 3);
  });

  testWidgets('adds, edits, removes, and renumbers one preparation step', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        RecipeCreatorScreen(
          repository: _FakeRepository(),
          imagePicker: _pickerWithImage,
        ),
      ),
    );
    await _goToPreparation(tester);

    await _tap(tester, _continueKey);
    expect(find.text('Add at least one preparation step'), findsOneWidget);
    await tester.enterText(find.byKey(_preparationKey), 'Mix.\nCook.');
    await _tap(tester, _saveStepKey);
    expect(find.text('Mix.\nCook.'), findsOneWidget);
    expect(find.text('Step 2'), findsNothing);

    await _tap(tester, _addStepKey);
    expect(find.byKey(_preparationKey), findsOneWidget);
    await tester.enterText(find.byKey(_preparationKey), 'Serve.');
    await _tap(tester, _saveStepKey);
    await _tap(tester, const ValueKey<String>('edit-preparation-step-0'));
    await tester.enterText(find.byKey(_preparationKey), 'Mix and cook.');
    await _tap(tester, _saveStepKey);
    expect(find.text('Mix and cook.'), findsOneWidget);
    expect(find.text('Serve.'), findsOneWidget);

    await _tap(tester, const ValueKey<String>('remove-preparation-step-0'));
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey<String>('preparation-summary-0')),
          )
          .data,
      'Serve.',
    );
    await _tap(tester, const ValueKey<String>('remove-preparation-step-0'));
    expect(find.text('Step 1'), findsOneWidget);
    expect(find.byKey(_preparationKey), findsOneWidget);
  });

  testWidgets('reviews ordered content and edits sections before saving', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await tester.pumpWidget(
      _CreatorHost(repository: repository, imagePicker: _pickerWithImage),
    );
    await _openCreator(tester);
    await _completeWizard(tester, title: '  Family Soup  ');

    _expectStage(tester, 'Review', 4);
    expect(find.text('Family Soup'), findsOneWidget);
    expect(find.text('2 g carrots'), findsOneWidget);
    expect(find.text('1 tsp salt'), findsOneWidget);
    expect(find.text('Chop.'), findsOneWidget);
    expect(find.text('Simmer.'), findsOneWidget);
    expect(find.text('Serves 4'), findsOneWidget);
    expect(find.text('Preparation 0 min'), findsOneWidget);
    expect(find.text('Cooking 0 min'), findsOneWidget);

    await _tap(tester, const ValueKey<String>('edit-preparation-section'));
    _expectStage(tester, 'Preparation', 3);
    expect(find.text('Chop.'), findsOneWidget);
    expect(find.text('Simmer.'), findsOneWidget);
    await _tap(tester, _continueKey);
    _expectStage(tester, 'Review', 4);

    await _tap(tester, _saveRecipeKey);
    expect(repository.createdRecipes, hasLength(1));
    expect(repository.createdRecipes.single.name, 'Family Soup');
    expect(
      repository.createdRecipes.single.ingredients.map((item) => item.name),
      <String>['carrots', 'salt'],
    );
    expect(repository.createdRecipes.single.steps, <String>[
      'Chop.',
      'Simmer.',
    ]);
    expect(find.text('Saved Family Soup'), findsOneWidget);
  });

  testWidgets('locks the reviewed snapshot while save is pending', (
    tester,
  ) async {
    final repository = _PendingRepository();
    await tester.pumpWidget(
      _CreatorHost(repository: repository, imagePicker: _pickerWithImage),
    );
    await _openCreator(tester);
    await _completeWizard(tester);

    await tester.tap(find.byKey(_saveRecipeKey));
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('recipe-save-progress')),
      findsOneWidget,
    );
    expect(repository.createCount, 1);
    expect(
      tester.widget<OutlinedButton>(find.byKey(_backKey)).onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const ValueKey<String>('edit-recipe-section')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester.widget<FilledButton>(find.byKey(_saveRecipeKey)).onPressed,
      isNull,
    );

    repository.complete();
    await tester.pumpAndSettle();
    expect(find.text('Saved Family Soup'), findsOneWidget);
  });

  testWidgets('retains Review and the complete draft after save failure', (
    tester,
  ) async {
    await tester.pumpWidget(
      _CreatorHost(
        repository: _FailingRepository(),
        imagePicker: _pickerWithImage,
      ),
    );
    await _openCreator(tester);
    await _completeWizard(tester);

    await _tap(tester, _saveRecipeKey);
    _expectStage(tester, 'Review', 4);
    expect(find.text('Family Soup'), findsOneWidget);
    expect(find.text('2 g carrots'), findsOneWidget);
    expect(find.text('Chop.'), findsOneWidget);
    expect(
      find.text('The recipe could not be saved. Please try again.'),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byKey(_saveRecipeKey)).onPressed,
      isNotNull,
    );
  });

  testWidgets('system Back follows stages before discard confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _CreatorHost(
        repository: _FakeRepository(),
        imagePicker: _pickerWithImage,
      ),
    );
    await _openCreator(tester);
    await _completeRecipeStage(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    _expectStage(tester, 'Recipe', 1);
    expect(find.text('Discard recipe?'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Discard recipe?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Family Soup'), findsOneWidget);

    await _tap(tester, _backKey);
    expect(find.text('Discard recipe?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('open-creator')), findsOneWidget);
  });

  for (final width in <double>[320, 412]) {
    testWidgets(
      'keeps all stages reachable at ${width.toInt()} dp and 200% text',
      (tester) async {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(
          _testApp(
            RecipeCreatorScreen(
              repository: _FakeRepository(),
              imagePicker: _pickerWithImage,
            ),
          ),
        );
        await _tap(tester, _imageKey);
        await tester.ensureVisible(find.byKey(_titleKey));
        await tester.showKeyboard(find.byKey(_titleKey));
        await tester.enterText(find.byKey(_titleKey), 'Family Soup');
        await _tap(tester, _continueKey);
        expect(tester.takeException(), isNull);

        await tester.enterText(
          find.byKey(_ingredientNameKey),
          'Very long family garden carrots',
        );
        await _tap(tester, _continueKey);
        expect(tester.takeException(), isNull);

        await tester.enterText(
          find.byKey(_preparationKey),
          'Prepare every ingredient carefully before cooking and serving.',
        );
        await _tap(tester, _continueKey);
        await tester.ensureVisible(find.byKey(_saveRecipeKey));
        await tester.pump();
        expect(tester.takeException(), isNull);
        _expectStage(tester, 'Review', 4);
      },
    );
  }
}

const _imageKey = ValueKey<String>('recipe-image-control');
const _titleKey = ValueKey<String>('recipe-title-field');
const _continueKey = ValueKey<String>('wizard-continue');
const _backKey = ValueKey<String>('wizard-back');
const _ingredientNameKey = ValueKey<String>('ingredient-name-field');
const _ingredientQuantityKey = ValueKey<String>('ingredient-quantity-field');
const _ingredientUnitKey = ValueKey<String>('ingredient-unit-field');
const _saveIngredientKey = ValueKey<String>('save-ingredient');
const _addIngredientKey = ValueKey<String>('add-ingredient');
const _preparationKey = ValueKey<String>('preparation-step-field');
const _saveStepKey = ValueKey<String>('save-preparation-step');
const _addStepKey = ValueKey<String>('add-preparation-step');
const _saveRecipeKey = ValueKey<String>('save-recipe');

String get _imagePath =>
    File('assets/images/recipe_placeholder.png').absolute.path;

_SequencePicker get _pickerWithImage => _SequencePicker(<String?>[_imagePath]);

Widget _testApp(Widget home) => MaterialApp(home: home);

void _expectStage(WidgetTester tester, String title, int number) {
  expect(
    tester
        .widget<Text>(find.byKey(const ValueKey<String>('creator-stage-title')))
        .data,
    title,
  );
  expect(
    tester
        .widget<Text>(
          find.byKey(const ValueKey<String>('creator-stage-progress')),
        )
        .data,
    'Step $number of 4',
  );
}

DropdownButton<IngredientUnit> _unitDropdown(WidgetTester tester) {
  return tester.widget<DropdownButton<IngredientUnit>>(
    find.descendant(
      of: find.byKey(_ingredientUnitKey),
      matching: find.byType(DropdownButton<IngredientUnit>),
    ),
  );
}

Future<void> _tap(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openCreator(WidgetTester tester) async {
  await _tap(tester, const ValueKey<String>('open-creator'));
}

Future<void> _completeRecipeStage(
  WidgetTester tester, {
  String title = 'Family Soup',
}) async {
  await _tap(tester, _imageKey);
  await tester.enterText(find.byKey(_titleKey), title);
  await _tap(tester, _continueKey);
}

Future<void> _fillIngredient(
  WidgetTester tester, {
  required String name,
  String? quantity,
  IngredientUnit? unit,
  String? note,
}) async {
  await tester.ensureVisible(find.byKey(_ingredientNameKey));
  await tester.enterText(find.byKey(_ingredientNameKey), name);
  if (quantity != null) {
    await tester.enterText(find.byKey(_ingredientQuantityKey), quantity);
  }
  if (unit != null) {
    await tester.tap(find.byKey(_ingredientUnitKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text(unit.label).last);
    await tester.pumpAndSettle();
  }
  if (note != null) {
    await tester.enterText(
      find.byKey(const ValueKey<String>('ingredient-note-field')),
      note,
    );
  }
}

Future<void> _commitIngredient(
  WidgetTester tester, {
  required String name,
  String? quantity,
  IngredientUnit? unit,
}) async {
  await _fillIngredient(tester, name: name, quantity: quantity, unit: unit);
  await _tap(tester, _saveIngredientKey);
}

Future<void> _goToPreparation(WidgetTester tester) async {
  await _completeRecipeStage(tester);
  await tester.enterText(find.byKey(_ingredientNameKey), 'carrots');
  await _tap(tester, _continueKey);
}

Future<void> _completeWizard(
  WidgetTester tester, {
  String title = 'Family Soup',
}) async {
  await _completeRecipeStage(tester, title: title);
  await _commitIngredient(
    tester,
    name: 'carrots',
    quantity: '2',
    unit: IngredientUnit.gram,
  );
  await _tap(tester, _addIngredientKey);
  await _commitIngredient(
    tester,
    name: 'salt',
    quantity: '1',
    unit: IngredientUnit.teaspoon,
  );
  await _tap(tester, _continueKey);
  await tester.enterText(find.byKey(_preparationKey), 'Chop.');
  await _tap(tester, _saveStepKey);
  await _tap(tester, _addStepKey);
  await tester.enterText(find.byKey(_preparationKey), 'Simmer.');
  await _tap(tester, _saveStepKey);
  await _tap(tester, _continueKey);
}

class _CreatorHost extends StatefulWidget {
  const _CreatorHost({required this.repository, required this.imagePicker});

  final MutableRecipeRepository repository;
  final RecipeImagePicker imagePicker;

  @override
  State<_CreatorHost> createState() => _CreatorHostState();
}

class _CreatorHostState extends State<_CreatorHost> {
  Recipe? result;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: <Widget>[
              FilledButton(
                key: const ValueKey<String>('open-creator'),
                onPressed: () async {
                  final recipe = await Navigator.of(context).push<Recipe>(
                    MaterialPageRoute<Recipe>(
                      builder: (context) => RecipeCreatorScreen(
                        repository: widget.repository,
                        imagePicker: widget.imagePicker,
                      ),
                    ),
                  );
                  if (mounted) {
                    setState(() {
                      result = recipe;
                    });
                  }
                },
                child: const Text('Open'),
              ),
              if (result != null) Text('Saved ${result!.name}'),
            ],
          ),
        ),
      ),
    );
  }
}

class _SequencePicker implements RecipeImagePicker {
  _SequencePicker(this.paths);

  final List<String?> paths;
  int pickCount = 0;

  @override
  Future<String?> pickFromGallery() async {
    final index = pickCount++;
    return index < paths.length ? paths[index] : paths.lastOrNull;
  }
}

class _PendingPicker implements RecipeImagePicker {
  final Completer<String?> _completer = Completer<String?>();
  int pickCount = 0;

  @override
  Future<String?> pickFromGallery() {
    pickCount++;
    return _completer.future;
  }

  void complete(String? path) => _completer.complete(path);
}

class _FailingPicker implements RecipeImagePicker {
  @override
  Future<String?> pickFromGallery() async {
    throw RecipeImagePickerException(
      message: 'The image could not be selected. Please try again.',
      cause: Exception('picker failed'),
      stackTrace: StackTrace.current,
    );
  }
}

class _FakeRepository implements MutableRecipeRepository {
  final List<NewRecipe> createdRecipes = <NewRecipe>[];

  @override
  Future<Recipe> createRecipe(NewRecipe recipe) async {
    createdRecipes.add(recipe);
    return _recipeFromDraft(recipe);
  }

  @override
  Future<List<Recipe>> getAllRecipes() async => const <Recipe>[];
}

class _PendingRepository implements MutableRecipeRepository {
  final Completer<Recipe> _completer = Completer<Recipe>();
  NewRecipe? _recipe;
  int createCount = 0;

  @override
  Future<Recipe> createRecipe(NewRecipe recipe) {
    createCount++;
    _recipe = recipe;
    return _completer.future;
  }

  void complete() => _completer.complete(_recipeFromDraft(_recipe!));

  @override
  Future<List<Recipe>> getAllRecipes() async => const <Recipe>[];
}

class _FailingRepository implements MutableRecipeRepository {
  @override
  Future<Recipe> createRecipe(NewRecipe recipe) async {
    throw RecipeRepositoryException(
      message: 'The recipe could not be saved. Please try again.',
      cause: const FileSystemException('Write failed.'),
      stackTrace: StackTrace.current,
    );
  }

  @override
  Future<List<Recipe>> getAllRecipes() async => const <Recipe>[];
}

Recipe _recipeFromDraft(NewRecipe recipe) => Recipe(
  id: 'created-id',
  name: recipe.name,
  servings: 4,
  prepMinutes: 0,
  cookMinutes: 0,
  image: RecipeImage.file(recipe.sourceImagePath),
  ingredients: recipe.ingredients,
  steps: recipe.steps,
);
