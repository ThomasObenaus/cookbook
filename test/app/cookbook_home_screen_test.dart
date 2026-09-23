import 'package:cookbook/app/cookbook_home_screen.dart';
import 'package:cookbook/features/meal_planner/data/meal_plan_repository.dart';
import 'package:cookbook/features/meal_planner/logic/week_dates.dart';
import 'package:cookbook/features/meal_planner/models/meal_assignment.dart';
import 'package:cookbook/features/meal_planner/models/meal_type.dart';
import 'package:cookbook/features/meal_planner/ui/recipe_selection_screen.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe_image.dart';
import 'package:cookbook/features/recipe_catalog/ui/recipe_detail_screen.dart';
import 'package:cookbook/features/recipe_creator/data/mutable_recipe_repository.dart';
import 'package:cookbook/features/recipe_creator/data/recipe_image_picker.dart';
import 'package:cookbook/features/recipe_creator/models/new_recipe.dart';
import 'package:cookbook/features/recipe_creator/ui/recipe_creator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/shopping_list/fake_shopping_list_repository.dart';

void main() {
  testWidgets(
    'recipe additions update the existing tab and preserve previous items',
    (tester) async {
      final repository = FakeShoppingListRepository();
      await repository.appendIngredients([const Ingredient(name: 'pepper')]);
      await repository.setChecked(id: 'item-1', checked: true);
      await tester.pumpWidget(_testApp(shoppingListRepository: repository));
      await tester.pumpAndSettle();
      final destination = find.byKey(
        const ValueKey<String>('shopping-list-destination'),
      );
      await tester.tap(destination);
      await tester.pumpAndSettle();
      expect(find.text('pepper'), findsOneWidget);
      for (var batch = 0; batch < 2; batch++) {
        await tester.tap(find.text('Recipes'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('recipe-card-family-soup')),
        );
        await tester.pumpAndSettle();
        final button = find.byKey(
          const ValueKey<String>('add-to-shopping-list'),
        );
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.tap(destination);
        await tester.pumpAndSettle();
        expect(find.text('salt'), findsNWidgets(batch + 1));
        expect(
          tester
              .widget<Checkbox>(
                find.byKey(const ValueKey<String>('shopping-check-item-1')),
              )
              .value,
          isTrue,
        );
        expect(repository.items.skip(1).every((item) => !item.checked), isTrue);
      }
      expect(repository.loadCount, 1);
    },
  );

  testWidgets('opens on Recipes and switches primary destinations', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    final navigation = find.byKey(
      const ValueKey<String>('cookbook-primary-navigation'),
    );
    expect(navigation, findsOneWidget);
    expect(tester.widget<NavigationBar>(navigation).selectedIndex, 0);
    await tester.tap(
      find.byKey(const ValueKey<String>('shopping-list-destination')),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<NavigationBar>(navigation).selectedIndex, 2);
    expect(find.text('Your shopping list is empty.'), findsOneWidget);
    await tester.tap(find.text('Recipes'));
    await tester.pumpAndSettle();
    expect(find.text('Recipes'), findsNWidgets(2));

    await tester.tap(find.text('Meal plan'));
    await tester.pumpAndSettle();

    expect(tester.widget<NavigationBar>(navigation).selectedIndex, 1);
    expect(find.text('Meal plan'), findsNWidgets(2));
    expect(find.byTooltip('Previous week'), findsOneWidget);

    await tester.tap(find.text('Recipes'));
    await tester.pumpAndSettle();
    expect(tester.widget<NavigationBar>(navigation).selectedIndex, 0);
  });

  testWidgets('preserves catalogue and planner state between destinations', (
    tester,
  ) async {
    final recipes = List<Recipe>.generate(
      24,
      (index) => _recipe(
        'recipe-$index',
        index.isEven ? 'Soup Recipe $index' : 'Pasta Recipe $index',
      ),
    );
    await tester.pumpWidget(
      _testApp(recipeRepository: _TestRecipeRepository(recipes)),
    );
    await tester.pumpAndSettle();

    final search = find.byKey(const ValueKey<String>('recipe-search-field'));
    await tester.enterText(search, 'Soup');
    await tester.pump();
    final recipeGrid = find.byKey(const ValueKey<String>('recipe-grid'));
    await tester.drag(recipeGrid, const Offset(0, -700));
    await tester.pumpAndSettle();
    final catalogueOffset = _scrollOffset(tester, recipeGrid);
    expect(catalogueOffset, greaterThan(0));

    await tester.tap(find.text('Meal plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next week'));
    await tester.pumpAndSettle();
    final planner = find.byKey(
      const PageStorageKey<String>('meal-plan-week-list'),
    );
    await tester.drag(planner, const Offset(0, -900));
    await tester.pumpAndSettle();
    final plannerOffset = _scrollOffset(tester, planner);
    expect(plannerOffset, greaterThan(0));

    await tester.tap(
      find.byKey(const ValueKey<String>('shopping-list-destination')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your shopping list is empty.'), findsOneWidget);

    await tester.tap(find.text('Recipes'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(search).controller?.text, 'Soup');
    expect(_scrollOffset(tester, recipeGrid), catalogueOffset);

    await tester.tap(find.text('Meal plan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sep 28'), findsOneWidget);
    expect(_scrollOffset(tester, planner), plannerOffset);
  });

  testWidgets('details and creator routes cover primary navigation', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('recipe-card-family-soup')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RecipeDetailScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('cookbook-primary-navigation')),
      findsNothing,
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Create recipe'));
    await tester.pumpAndSettle();
    expect(find.byType(RecipeCreatorScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('cookbook-primary-navigation')),
      findsNothing,
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('cookbook-primary-navigation')),
      findsOneWidget,
    );
  });

  testWidgets('recipe selection covers primary navigation', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Meal plan'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('meal-slot-2026-09-21-breakfast')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RecipeSelectionScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('cookbook-primary-navigation')),
      findsNothing,
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('cookbook-primary-navigation')),
      findsOneWidget,
    );
  });

  testWidgets(
    'keeps Sunday dinner reachable above navigation at compact large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(_testApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Meal plan'));
      await tester.pumpAndSettle();

      final planner = find.byKey(
        const PageStorageKey<String>('meal-plan-week-list'),
      );
      final sundayDinner = find.byKey(
        const ValueKey<String>('meal-slot-2026-09-27-dinner'),
      );
      await tester.scrollUntilVisible(
        sundayDinner,
        400,
        scrollable: find.descendant(
          of: planner,
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();

      final navigation = find.byKey(
        const ValueKey<String>('cookbook-primary-navigation'),
      );
      expect(
        tester.getBottomLeft(sundayDinner).dy,
        lessThanOrEqualTo(tester.getTopLeft(navigation).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _testApp({
  _TestRecipeRepository? recipeRepository,
  MealPlanRepository? mealPlanRepository,
  FakeShoppingListRepository? shoppingListRepository,
}) {
  return MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
    ),
    home: CookbookHomeScreen(
      recipeRepository:
          recipeRepository ??
          _TestRecipeRepository(<Recipe>[
            _recipe('family-soup', 'Family Soup'),
          ]),
      mealPlanRepository: mealPlanRepository ?? _TestMealPlanRepository(),
      shoppingListRepository:
          shoppingListRepository ?? FakeShoppingListRepository(),
      imagePicker: const _FakePicker(),
      currentDateProvider: () => DateTime(2026, 9, 22),
    ),
  );
}

double _scrollOffset(WidgetTester tester, Finder scrollView) {
  final scrollable = find.descendant(
    of: scrollView,
    matching: find.byType(Scrollable),
  );
  return tester.state<ScrollableState>(scrollable).position.pixels;
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

class _TestRecipeRepository implements MutableRecipeRepository {
  _TestRecipeRepository(this.recipes);

  final List<Recipe> recipes;

  @override
  Future<List<Recipe>> getAllRecipes() async => recipes;

  @override
  Future<Recipe> createRecipe(NewRecipe recipe) async {
    throw UnsupportedError('Creation is not used by this test.');
  }
}

class _TestMealPlanRepository implements MealPlanRepository {
  final List<MealAssignment> assignments = <MealAssignment>[];

  @override
  Future<List<MealAssignment>> loadWeek(DateTime weekStart) async {
    final followingMonday = nextWeek(weekStart);
    return assignments
        .where(
          (assignment) =>
              !assignment.date.isBefore(weekStart) &&
              assignment.date.isBefore(followingMonday),
        )
        .toList(growable: false);
  }

  @override
  Future<void> removeAssignment({
    required DateTime date,
    required MealType mealType,
  }) async {
    final identity = MealAssignmentIdentity(date: date, mealType: mealType);
    assignments.removeWhere((assignment) => assignment.identity == identity);
  }

  @override
  Future<void> setAssignment(MealAssignment assignment) async {
    assignments
      ..removeWhere((existing) => existing.identity == assignment.identity)
      ..add(assignment);
  }
}

class _FakePicker implements RecipeImagePicker {
  const _FakePicker();

  @override
  Future<String?> pickFromGallery() async => null;
}
