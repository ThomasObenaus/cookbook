import 'dart:async';
import 'dart:io';

import 'package:cookbook/features/recipe_catalog/data/recipe_repository.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe_image.dart';
import 'package:cookbook/features/recipe_creator/data/mutable_recipe_repository.dart';
import 'package:cookbook/features/recipe_creator/data/recipe_image_picker.dart';
import 'package:cookbook/features/recipe_creator/models/new_recipe.dart';
import 'package:cookbook/features/recipe_creator/ui/recipe_creator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starts with one blank ingredient and no selected image', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        RecipeCreatorScreen(
          repository: _FakeRepository(),
          imagePicker: _FakePicker(null),
        ),
      ),
    );

    expect(find.text('No image selected'), findsOneWidget);
    expect(find.text('Ingredient 1'), findsOneWidget);
    expect(find.text('Ingredient 2'), findsNothing);
    expect(find.text('Enter one step per line'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey<String>('remove-ingredient-0')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('validates required recipe fields', (tester) async {
    final repository = _FakeRepository();
    await tester.pumpWidget(
      _testApp(
        RecipeCreatorScreen(
          repository: repository,
          imagePicker: _FakePicker(null),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Save recipe'));
    await tester.pump();

    expect(find.text('Enter a recipe title'), findsOneWidget);
    expect(find.text('Choose a recipe image'), findsOneWidget);
    expect(find.text('Add at least one ingredient'), findsOneWidget);
    expect(find.text('Enter at least one step'), findsOneWidget);
    expect(repository.createdRecipes, isEmpty);
  });

  testWidgets('adds and removes structured ingredient rows', (tester) async {
    await tester.pumpWidget(
      _testApp(
        RecipeCreatorScreen(
          repository: _FakeRepository(),
          imagePicker: _FakePicker(null),
        ),
      ),
    );

    expect(find.text('Ingredient 1'), findsOneWidget);
    final addIngredient = find.byKey(const ValueKey<String>('add-ingredient'));
    await tester.ensureVisible(addIngredient);
    await tester.tap(addIngredient);
    await tester.pump();
    expect(find.text('Ingredient 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('remove-ingredient-1')));
    await tester.pump();
    expect(find.text('Ingredient 2'), findsNothing);
    expect(find.text('Ingredient 1'), findsOneWidget);
  });

  testWidgets('gallery cancellation preserves entered form data', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        RecipeCreatorScreen(
          repository: _FakeRepository(),
          imagePicker: _FakePicker(null),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('recipe-title-field')),
      'Family Soup',
    );

    final chooseImage = find.byKey(
      const ValueKey<String>('choose-recipe-image'),
    );
    await tester.ensureVisible(chooseImage);
    await tester.tap(chooseImage);
    await tester.pump();

    expect(find.text('Family Soup'), findsOneWidget);
    expect(find.text('No image selected'), findsOneWidget);
  });

  testWidgets('picker failure preserves data and shows a friendly error', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        RecipeCreatorScreen(
          repository: _FakeRepository(),
          imagePicker: _FailingPicker(),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('recipe-title-field')),
      'Family Soup',
    );

    final chooseImage = find.byKey(
      const ValueKey<String>('choose-recipe-image'),
    );
    await tester.ensureVisible(chooseImage);
    await tester.tap(chooseImage);
    await tester.pumpAndSettle();

    expect(find.text('Family Soup'), findsOneWidget);
    expect(
      find.text('The image could not be selected. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('saves normalized input and returns the created recipe', (
    tester,
  ) async {
    final repository = _FakeRepository();
    final imagePath = File('assets/images/recipe_placeholder.png')
        .absolute
        .path;
    await tester.pumpWidget(
      _CreatorHost(repository: repository, imagePicker: _FakePicker(imagePath)),
    );
    await tester.tap(find.byKey(const ValueKey<String>('open-creator')));
    await tester.pumpAndSettle();

    final chooseImage = find.byKey(
      const ValueKey<String>('choose-recipe-image'),
    );
    await tester.ensureVisible(chooseImage);
    await tester.tap(chooseImage);
    await tester.pumpAndSettle();
    expect(find.text('Replace image'), findsOneWidget);
    expect(find.bySemanticsLabel('Selected recipe image'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey<String>('recipe-title-field')),
      '  Family Soup  ',
    );
    final ingredientName = find.byKey(
      const ValueKey<String>('ingredient-name-0'),
    );
    await tester.ensureVisible(ingredientName);
    await tester.enterText(ingredientName, ' carrots ');
    await tester.enterText(
      find.byKey(const ValueKey<String>('ingredient-quantity-0')),
      ' 2 ',
    );
    final steps = find.byKey(const ValueKey<String>('recipe-steps-field'));
    await tester.ensureVisible(steps);
    await tester.enterText(steps, ' Chop. \n\n Simmer. ');
    await tester.tap(find.byTooltip('Save recipe'));
    await tester.pumpAndSettle();

    expect(repository.createdRecipes, hasLength(1));
    expect(repository.createdRecipes.single.name, 'Family Soup');
    expect(repository.createdRecipes.single.ingredients.single.name, 'carrots');
    expect(repository.createdRecipes.single.steps, <String>[
      'Chop.',
      'Simmer.',
    ]);
    expect(find.text('Saved Family Soup'), findsOneWidget);
  });

  testWidgets('disables duplicate saves and shows progress while pending', (
    tester,
  ) async {
    final repository = _PendingRepository();
    final imagePath = File('assets/images/recipe_placeholder.png')
        .absolute
        .path;
    await tester.pumpWidget(
      _CreatorHost(repository: repository, imagePicker: _FakePicker(imagePath)),
    );
    await tester.tap(find.byKey(const ValueKey<String>('open-creator')));
    await tester.pumpAndSettle();
    await _fillRequiredFields(tester);

    await tester.tap(find.byTooltip('Save recipe'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('recipe-save-progress')),
      findsOneWidget,
    );
    expect(find.byTooltip('Save recipe'), findsNothing);
    expect(repository.createCount, 1);

    repository.complete();
    await tester.pumpAndSettle();
    expect(find.text('Saved Family Soup'), findsOneWidget);
  });

  testWidgets('keeps the complete draft when saving fails', (tester) async {
    final imagePath = File('assets/images/recipe_placeholder.png')
        .absolute
        .path;
    await tester.pumpWidget(
      _CreatorHost(
        repository: _FailingRepository(),
        imagePicker: _FakePicker(imagePath),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('open-creator')));
    await tester.pumpAndSettle();
    await _fillRequiredFields(tester);

    await tester.tap(find.byTooltip('Save recipe'));
    await tester.pumpAndSettle();

    expect(find.text('Family Soup'), findsOneWidget);
    expect(find.text('carrots'), findsOneWidget);
    expect(find.text('Chop the carrots.'), findsOneWidget);
    expect(find.text('Replace image'), findsOneWidget);
    expect(
      find.text('The recipe could not be saved. Please try again.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Save recipe'), findsOneWidget);
  });

  testWidgets('asks before discarding a modified form', (tester) async {
    await tester.pumpWidget(
      _CreatorHost(
        repository: _FakeRepository(),
        imagePicker: _FakePicker(null),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('open-creator')));
    await tester.pumpAndSettle();
    final addIngredient = find.byKey(const ValueKey<String>('add-ingredient'));
    await tester.ensureVisible(addIngredient);
    await tester.tap(addIngredient);
    await tester.pump();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Discard recipe?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Ingredient 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('open-creator')), findsOneWidget);
  });

  for (final width in <double>[320, 412]) {
    testWidgets(
      'keeps the form reachable at ${width.toInt()} dp with keyboard and 200% text',
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
              imagePicker: _FakePicker(null),
            ),
          ),
        );

        final title = find.byKey(const ValueKey<String>('recipe-title-field'));
        await tester.ensureVisible(title);
        await tester.showKeyboard(title);
        await tester.enterText(title, 'Family Soup');

        final steps = find.byKey(const ValueKey<String>('recipe-steps-field'));
        await tester.ensureVisible(steps);
        await tester.showKeyboard(steps);
        await tester.enterText(steps, 'Prepare.\nCook.\nServe.');
        await tester.pump();

        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Widget _testApp(Widget home) => MaterialApp(home: home);

Future<void> _fillRequiredFields(WidgetTester tester) async {
  final chooseImage = find.byKey(const ValueKey<String>('choose-recipe-image'));
  await tester.ensureVisible(chooseImage);
  await tester.tap(chooseImage);
  await tester.pumpAndSettle();

  final title = find.byKey(const ValueKey<String>('recipe-title-field'));
  await tester.ensureVisible(title);
  await tester.enterText(title, 'Family Soup');

  final ingredient = find.byKey(const ValueKey<String>('ingredient-name-0'));
  await tester.ensureVisible(ingredient);
  await tester.enterText(ingredient, 'carrots');

  final steps = find.byKey(const ValueKey<String>('recipe-steps-field'));
  await tester.ensureVisible(steps);
  await tester.enterText(steps, 'Chop the carrots.');
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

class _FakePicker implements RecipeImagePicker {
  const _FakePicker(this.path);

  final String? path;

  @override
  Future<String?> pickFromGallery() async => path;
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
    return Recipe(
      id: 'created-id',
      name: recipe.name,
      servings: 4,
      prepMinutes: 0,
      cookMinutes: 0,
      image: RecipeImage.file(recipe.sourceImagePath),
      ingredients: recipe.ingredients,
      steps: recipe.steps,
    );
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

  void complete() {
    final recipe = _recipe!;
    _completer.complete(
      Recipe(
        id: 'created-id',
        name: recipe.name,
        servings: 4,
        prepMinutes: 0,
        cookMinutes: 0,
        image: RecipeImage.file(recipe.sourceImagePath),
        ingredients: recipe.ingredients,
        steps: recipe.steps,
      ),
    );
  }

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
