import 'dart:async';

import 'package:cookbook/features/meal_planner/ui/recipe_selection_screen.dart';
import 'package:cookbook/features/recipe_catalog/data/recipe_repository.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe_image.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows loading while the catalogue is pending', (tester) async {
    final completer = Completer<List<Recipe>>();

    await tester.pumpWidget(
      _testApp(
        RecipeSelectionScreen(repository: _PendingRepository(completer)),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('recipe-selection-loading-indicator')),
      findsOneWidget,
    );
  });

  testWidgets('shows an empty-catalogue state without creator actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(RecipeSelectionScreen(repository: _StaticRepository([]))),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('recipe-selection-empty-state')),
      findsOneWidget,
    );
    expect(find.text('No recipes yet'), findsOneWidget);
    expect(find.byTooltip('Create recipe'), findsNothing);
  });

  testWidgets('shows a friendly error and retries', (tester) async {
    final repository = _FailThenSucceedRepository(<Recipe>[
      _recipe('soup', 'Tomato Soup'),
    ]);
    await tester.pumpWidget(
      _testApp(RecipeSelectionScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('recipe-selection-error-state')),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pumpAndSettle();

    expect(repository.callCount, 2);
    expect(find.text('Tomato Soup'), findsOneWidget);
  });

  testWidgets('searches by name, clears, and shows no results', (tester) async {
    await tester.pumpWidget(
      _testApp(
        RecipeSelectionScreen(
          repository: _StaticRepository(<Recipe>[
            _recipe('pasta', 'Tomato Basil Pasta'),
            _recipe('soup', 'Mushroom Soup'),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final search = find.byKey(
      const ValueKey<String>('recipe-selection-search-field'),
    );
    await tester.enterText(search, ' MUSHROOM ');
    await tester.pump();

    expect(find.text('Mushroom Soup'), findsOneWidget);
    expect(find.text('Tomato Basil Pasta'), findsNothing);

    await tester.enterText(search, 'risotto');
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('recipe-selection-no-results-state')),
      findsOneWidget,
    );
    expect(find.text('No recipe names match "risotto".'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(find.text('Mushroom Soup'), findsOneWidget);
    expect(find.text('Tomato Basil Pasta'), findsOneWidget);
  });

  testWidgets('returns the tapped recipe', (tester) async {
    final recipe = _recipe('soup', 'Tomato Soup');
    await tester.pumpWidget(
      _testApp(_SelectionHost(repository: _StaticRepository(<Recipe>[recipe]))),
    );

    await tester.tap(find.text('Open selector'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('select-recipe-card-soup')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Selected: Tomato Soup'), findsOneWidget);
  });

  testWidgets('normal back navigation returns no selection', (tester) async {
    await tester.pumpWidget(
      _testApp(
        _SelectionHost(
          repository: _StaticRepository(<Recipe>[
            _recipe('soup', 'Tomato Soup'),
          ]),
        ),
      ),
    );

    await tester.tap(find.text('Open selector'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Selected: none'), findsOneWidget);
  });

  testWidgets('loads fresh recipes each time the route opens', (tester) async {
    final repository = _MutableRepository(<Recipe>[
      _recipe('soup', 'Tomato Soup'),
    ]);
    await tester.pumpWidget(_testApp(_SelectionHost(repository: repository)));

    await tester.tap(find.text('Open selector'));
    await tester.pumpAndSettle();
    expect(find.text('Tomato Soup'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    repository.recipes.insert(0, _recipe('created', 'New Family Recipe'));
    await tester.tap(find.text('Open selector'));
    await tester.pumpAndSettle();

    expect(repository.callCount, 2);
    expect(find.text('New Family Recipe'), findsOneWidget);
  });

  for (final width in <double>[320, 412]) {
    testWidgets(
      'uses a stable grid at ${width.toInt()} dp and 200% text scaling',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(
          _testApp(
            RecipeSelectionScreen(
              repository: _StaticRepository(
                List<Recipe>.generate(
                  4,
                  (index) => _recipe(
                    'recipe-$index',
                    'A Deliberately Long Recipe Name $index',
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final cards = find.byType(RecipeCard);
        expect(cards, findsNWidgets(4));
        expect(
          tester.getTopLeft(cards.at(0)).dy,
          tester.getTopLeft(cards.at(1)).dy,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Widget _testApp(Widget home) {
  return MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
    ),
    home: home,
  );
}

class _SelectionHost extends StatefulWidget {
  const _SelectionHost({required this.repository});

  final RecipeRepository repository;

  @override
  State<_SelectionHost> createState() => _SelectionHostState();
}

class _SelectionHostState extends State<_SelectionHost> {
  Recipe? _selectedRecipe;

  Future<void> _openSelector() async {
    final recipe = await Navigator.of(context).push<Recipe>(
      MaterialPageRoute<Recipe>(
        builder: (context) =>
            RecipeSelectionScreen(repository: widget.repository),
      ),
    );
    if (!mounted || recipe == null) {
      return;
    }
    setState(() {
      _selectedRecipe = recipe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Text('Selected: ${_selectedRecipe?.name ?? 'none'}'),
          FilledButton(
            onPressed: _openSelector,
            child: const Text('Open selector'),
          ),
        ],
      ),
    );
  }
}

Recipe _recipe(String id, String name) {
  return Recipe(
    id: id,
    name: name,
    servings: 4,
    prepMinutes: 10,
    cookMinutes: 20,
    image: RecipeImage.asset('assets/images/recipe_placeholder.png'),
    ingredients: const <Ingredient>[Ingredient(name: 'salt')],
    steps: const <String>['Cook.'],
  );
}

class _StaticRepository implements RecipeRepository {
  _StaticRepository(this.recipes);

  final List<Recipe> recipes;

  @override
  Future<List<Recipe>> getAllRecipes() async => recipes;
}

class _MutableRepository implements RecipeRepository {
  _MutableRepository(this.recipes);

  final List<Recipe> recipes;
  int callCount = 0;

  @override
  Future<List<Recipe>> getAllRecipes() async {
    callCount++;
    return List<Recipe>.unmodifiable(recipes);
  }
}

class _PendingRepository implements RecipeRepository {
  const _PendingRepository(this.completer);

  final Completer<List<Recipe>> completer;

  @override
  Future<List<Recipe>> getAllRecipes() => completer.future;
}

class _FailThenSucceedRepository implements RecipeRepository {
  _FailThenSucceedRepository(this.recipes);

  final List<Recipe> recipes;
  int callCount = 0;

  @override
  Future<List<Recipe>> getAllRecipes() async {
    callCount++;
    if (callCount == 1) {
      throw RecipeRepositoryException(
        message: 'Recipes could not be loaded. Please try again.',
        cause: const FormatException('Invalid recipes.'),
        stackTrace: StackTrace.current,
      );
    }
    return recipes;
  }
}
