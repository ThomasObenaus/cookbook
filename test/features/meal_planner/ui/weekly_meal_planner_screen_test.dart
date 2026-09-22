import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:cookbook/features/meal_planner/data/meal_plan_repository.dart';
import 'package:cookbook/features/meal_planner/logic/week_dates.dart';
import 'package:cookbook/features/meal_planner/models/meal_assignment.dart';
import 'package:cookbook/features/meal_planner/models/meal_type.dart';
import 'package:cookbook/features/meal_planner/ui/meal_slot_tile.dart';
import 'package:cookbook/features/meal_planner/ui/weekly_meal_planner_screen.dart';
import 'package:cookbook/features/recipe_catalog/data/recipe_repository.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows loading while initial data is pending', (tester) async {
    final recipes = Completer<List<Recipe>>();

    await tester.pumpWidget(
      _testApp(
        recipeRepository: _PendingRecipeRepository(recipes),
        mealPlanRepository: _StaticMealPlanRepository(),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('meal-plan-loading-indicator')),
      findsOneWidget,
    );
  });

  testWidgets('shows the current Monday-to-Sunday week and all 21 slots', (
    tester,
  ) async {
    final recipe = _recipe('porridge', 'Morning Porridge');
    final recipeRepository = _StaticRecipeRepository(<Recipe>[recipe]);
    final mealPlanRepository = _StaticMealPlanRepository(
      assignments: <MealAssignment>[
        MealAssignment(
          date: DateTime(2026, 9, 21),
          mealType: MealType.breakfast,
          recipeId: recipe.id,
        ),
      ],
    );

    await tester.pumpWidget(
      _testApp(
        recipeRepository: recipeRepository,
        mealPlanRepository: mealPlanRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Sep 21'), findsOneWidget);
    expect(find.textContaining('Sep 27'), findsOneWidget);
    expect(find.text('Monday, September 21, 2026'), findsOneWidget);
    expect(find.text('Sunday, September 27, 2026'), findsOneWidget);
    expect(find.text('Today'), findsNWidgets(2));
    expect(find.byType(MealSlotTile), findsNWidgets(21));
    expect(find.text('Morning Porridge'), findsOneWidget);
    expect(find.text('Add dinner'), findsNWidgets(7));
    expect(
      tester
          .widgetList<MealSlotTile>(find.byType(MealSlotTile))
          .map((tile) => tile.mealType),
      <MealType>[
        for (var day = 0; day < DateTime.daysPerWeek; day++) ...MealType.values,
      ],
    );
    expect(recipeRepository.callCount, 1);
    expect(mealPlanRepository.loadedWeeks, <DateTime>[DateTime(2026, 9, 21)]);
  });

  testWidgets('navigates calendar boundaries from the injected local date', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        recipeRepository: _StaticRecipeRepository(const <Recipe>[]),
        mealPlanRepository: _StaticMealPlanRepository(),
        currentDate: DateTime(2025, 12, 31, 23),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Dec 29'), findsOneWidget);
    expect(find.textContaining('Jan 4'), findsOneWidget);

    await tester.tap(find.byTooltip('Next week'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Jan 5'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      _testApp(
        recipeRepository: _StaticRecipeRepository(const <Recipe>[]),
        mealPlanRepository: _StaticMealPlanRepository(),
        currentDate: DateTime(2024, 2, 29, 23),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Feb 26'), findsOneWidget);
    expect(find.textContaining('Mar 3'), findsOneWidget);
  });

  testWidgets('exposes slot semantics and minimum action targets', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final recipe = _recipe('porridge', 'Morning Porridge');
    await tester.pumpWidget(
      _testApp(
        recipeRepository: _StaticRecipeRepository(<Recipe>[recipe]),
        mealPlanRepository: _StaticMealPlanRepository(
          assignments: <MealAssignment>[
            MealAssignment(
              date: DateTime(2026, 9, 21),
              mealType: MealType.breakfast,
              recipeId: recipe.id,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final assigned = find.bySemanticsLabel(
      '2026-09-21, Breakfast, Morning Porridge',
    );
    final empty = find.bySemanticsLabel('2026-09-21, Lunch, Add lunch');
    expect(assigned, findsOneWidget);
    expect(empty, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('meal-plan-focus-traversal')),
      findsOneWidget,
    );
    expect(
      tester
          .getSemantics(assigned)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(
      tester
          .getSemantics(empty)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );

    for (final target in <Finder>[
      find.byTooltip('Previous week'),
      find.byKey(const ValueKey<String>('today-action')),
      find.byTooltip('Next week'),
      _slot('2026-09-21', MealType.breakfast),
    ]) {
      final size = tester.getSize(target);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }

    await tester.tap(_slot('2026-09-21', MealType.breakfast));
    await tester.pumpAndSettle();
    for (final label in <String>['Change recipe', 'Remove']) {
      final action = find.text(label);
      expect(action, findsOneWidget);
      final actionTile = find.ancestor(
        of: action,
        matching: find.byType(ListTile),
      );
      expect(tester.getSize(actionTile).height, greaterThanOrEqualTo(48));
    }
    semantics.dispose();
  });

  testWidgets('navigates weeks, resets scrolling, and returns to today', (
    tester,
  ) async {
    final mealPlanRepository = _StaticMealPlanRepository();
    await tester.pumpWidget(
      _testApp(
        recipeRepository: _StaticRecipeRepository(const <Recipe>[]),
        mealPlanRepository: mealPlanRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const PageStorageKey<String>('meal-plan-week-list')),
      const Offset(0, -1200),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey<String>('meal-plan-day-2026-09-21')),
          )
          .dy,
      lessThan(0),
    );

    await tester.tap(find.byTooltip('Next week'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sep 28'), findsOneWidget);
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey<String>('meal-plan-day-2026-09-28')),
          )
          .dy,
      greaterThan(0),
    );
    expect(find.byKey(const ValueKey<String>('today-action')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('today-action')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sep 21'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous week'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sep 14'), findsOneWidget);
    expect(mealPlanRepository.loadedWeeks, <DateTime>[
      DateTime(2026, 9, 21),
      DateTime(2026, 9, 28),
      DateTime(2026, 9, 21),
      DateTime(2026, 9, 14),
    ]);
  });

  testWidgets('ignores stale week results', (tester) async {
    final repository = _ControlledMealPlanRepository();
    repository.complete(DateTime(2026, 9, 21), const <MealAssignment>[]);
    await tester.pumpWidget(
      _testApp(
        recipeRepository: _StaticRecipeRepository(<Recipe>[
          _recipe('stale', 'Stale Recipe'),
          _recipe('latest', 'Latest Recipe'),
        ]),
        mealPlanRepository: repository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Next week'));
    await tester.pump();
    await tester.tap(find.byTooltip('Next week'));
    await tester.pump();

    repository.complete(DateTime(2026, 10, 5), <MealAssignment>[
      MealAssignment(
        date: DateTime(2026, 10, 5),
        mealType: MealType.dinner,
        recipeId: 'latest',
      ),
    ]);
    await tester.pumpAndSettle();
    repository.complete(DateTime(2026, 9, 28), <MealAssignment>[
      MealAssignment(
        date: DateTime(2026, 9, 28),
        mealType: MealType.dinner,
        recipeId: 'stale',
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.textContaining('Oct 5'), findsOneWidget);
    expect(find.text('Latest Recipe'), findsOneWidget);
    expect(find.text('Stale Recipe'), findsNothing);
  });

  testWidgets('shows a retryable failure', (tester) async {
    final repository = _FailThenSucceedMealPlanRepository();
    await tester.pumpWidget(
      _testApp(
        recipeRepository: _StaticRecipeRepository(const <Recipe>[]),
        mealPlanRepository: repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('meal-plan-error-state')),
      findsOneWidget,
    );
    expect(find.text('Meal plan unavailable.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pumpAndSettle();

    expect(repository.callCount, 2);
    expect(find.byType(MealSlotTile), findsNWidgets(21));
  });

  testWidgets('keeps an unresolved assignment manageable in the layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        recipeRepository: _StaticRecipeRepository(const <Recipe>[]),
        mealPlanRepository: _StaticMealPlanRepository(
          assignments: <MealAssignment>[
            MealAssignment(
              date: DateTime(2026, 9, 21),
              mealType: MealType.dinner,
              recipeId: 'deleted-recipe',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recipe unavailable'), findsOneWidget);
  });

  testWidgets(
    'cancels selection and waits for persistence before assigning a slot',
    (tester) async {
      final recipe = _recipe('porridge', 'Morning Porridge');
      final repository = _RecordingMealPlanRepository();
      final setGate = Completer<void>();
      repository.setGate = setGate;
      await tester.pumpWidget(
        _testApp(
          recipeRepository: _StaticRecipeRepository(<Recipe>[recipe]),
          mealPlanRepository: repository,
        ),
      );
      await tester.pumpAndSettle();

      final breakfast = _slot('2026-09-21', MealType.breakfast);
      final initialSize = tester.getSize(breakfast);
      await tester.tap(breakfast);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(repository.setCalls, isEmpty);
      expect(find.text('Add breakfast'), findsNWidgets(7));

      await tester.tap(breakfast);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('select-recipe-card-porridge')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(repository.setCalls, hasLength(1));
      expect(repository.setCalls.single.recipeId, recipe.id);
      expect(repository.setCalls.single.date, DateTime(2026, 9, 21));
      expect(repository.setCalls.single.mealType, MealType.breakfast);
      expect(tester.widget<MealSlotTile>(breakfast).isMutating, isTrue);
      expect(tester.widget<MealSlotTile>(breakfast).recipe, isNull);
      expect(tester.getSize(breakfast), initialSize);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Select recipe'), findsNothing);
      final slotInkWell = find.descendant(
        of: breakfast,
        matching: find.byType(InkWell),
      );
      expect(tester.widget<InkWell>(slotInkWell).onTap, isNull);
      await tester.tap(breakfast);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Select recipe'), findsNothing);
      expect(repository.setCalls, hasLength(1));

      setGate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Morning Porridge'), findsOneWidget);
      expect(tester.widget<MealSlotTile>(breakfast).isMutating, isFalse);
      expect(tester.getSize(breakfast), initialSize);
    },
  );

  testWidgets('keeps overlapping slot mutations independently pending', (
    tester,
  ) async {
    final porridge = _recipe('porridge', 'Morning Porridge');
    final soup = _recipe('soup', 'Tomato Soup');
    final repository = _RecordingMealPlanRepository();
    final breakfastIdentity = MealAssignmentIdentity(
      date: DateTime(2026, 9, 21),
      mealType: MealType.breakfast,
    );
    final lunchIdentity = MealAssignmentIdentity(
      date: DateTime(2026, 9, 21),
      mealType: MealType.lunch,
    );
    final breakfastGate = Completer<void>();
    final lunchGate = Completer<void>();
    repository.setGates
      ..[breakfastIdentity] = breakfastGate
      ..[lunchIdentity] = lunchGate;

    await tester.pumpWidget(
      _testApp(
        recipeRepository: _StaticRecipeRepository(<Recipe>[porridge, soup]),
        mealPlanRepository: repository,
      ),
    );
    await tester.pumpAndSettle();

    final breakfast = _slot('2026-09-21', MealType.breakfast);
    final lunch = _slot('2026-09-21', MealType.lunch);
    await tester.tap(breakfast);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('select-recipe-card-porridge')),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(lunch);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('select-recipe-card-soup')),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(repository.setCalls, hasLength(2));
    expect(tester.widget<MealSlotTile>(breakfast).isMutating, isTrue);
    expect(tester.widget<MealSlotTile>(lunch).isMutating, isTrue);

    breakfastGate.complete();
    await tester.pump();

    expect(tester.widget<MealSlotTile>(breakfast).isMutating, isFalse);
    expect(tester.widget<MealSlotTile>(lunch).isMutating, isTrue);
    final lunchInkWell = find.descendant(
      of: lunch,
      matching: find.byType(InkWell),
    );
    expect(tester.widget<InkWell>(lunchInkWell).onTap, isNull);
    expect(repository.setCalls, hasLength(2));

    lunchGate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Morning Porridge'), findsOneWidget);
    expect(find.text('Tomato Soup'), findsOneWidget);
    expect(tester.widget<MealSlotTile>(lunch).isMutating, isFalse);
  });

  testWidgets('changes an assignment and accepts the same recipe again', (
    tester,
  ) async {
    final porridge = _recipe('porridge', 'Morning Porridge');
    final pancakes = _recipe('pancakes', 'Banana Pancakes');
    final repository = _RecordingMealPlanRepository(
      assignments: <MealAssignment>[
        MealAssignment(
          date: DateTime(2026, 9, 21),
          mealType: MealType.breakfast,
          recipeId: porridge.id,
        ),
      ],
    );
    await tester.pumpWidget(
      _testApp(
        recipeRepository: _StaticRecipeRepository(<Recipe>[porridge, pancakes]),
        mealPlanRepository: repository,
      ),
    );
    await tester.pumpAndSettle();

    final breakfast = _slot('2026-09-21', MealType.breakfast);
    await tester.tap(breakfast);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change recipe'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(repository.setCalls, isEmpty);
    expect(find.text('Morning Porridge'), findsOneWidget);

    await tester.tap(breakfast);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change recipe'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('select-recipe-card-pancakes')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Banana Pancakes'), findsOneWidget);
    expect(repository.setCalls.single.recipeId, pancakes.id);

    await tester.tap(breakfast);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change recipe'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('select-recipe-card-pancakes')),
    );
    await tester.pumpAndSettle();

    expect(repository.setCalls, hasLength(2));
    expect(repository.assignments, hasLength(1));
    expect(repository.assignments.single.recipeId, pancakes.id);
  });

  testWidgets('an unavailable assignment can be changed and removed', (
    tester,
  ) async {
    final replacement = _recipe('replacement', 'Replacement Dinner');
    final repository = _RecordingMealPlanRepository(
      assignments: <MealAssignment>[
        MealAssignment(
          date: DateTime(2026, 9, 21),
          mealType: MealType.dinner,
          recipeId: 'deleted-recipe',
        ),
      ],
    );
    await tester.pumpWidget(
      _testApp(
        recipeRepository: _StaticRecipeRepository(<Recipe>[replacement]),
        mealPlanRepository: repository,
      ),
    );
    await tester.pumpAndSettle();

    final dinner = _slot('2026-09-21', MealType.dinner);
    await tester.tap(dinner);
    await tester.pumpAndSettle();
    expect(find.text('Change recipe'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);
    await tester.tap(find.text('Change recipe'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('select-recipe-card-replacement')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Replacement Dinner'), findsOneWidget);

    await tester.tap(dinner);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(repository.removeCalls, hasLength(1));
    expect(find.text('Replacement Dinner'), findsNothing);
    expect(tester.widget<MealSlotTile>(dinner).recipe, isNull);
    expect(tester.widget<MealSlotTile>(dinner).isUnavailable, isFalse);
  });

  testWidgets('assignment failure retains the slot and supports retry', (
    tester,
  ) async {
    final recipe = _recipe('soup', 'Tomato Soup');
    final repository = _RecordingMealPlanRepository(setFailuresRemaining: 1);
    await tester.pumpWidget(
      _testApp(
        recipeRepository: _StaticRecipeRepository(<Recipe>[recipe]),
        mealPlanRepository: repository,
      ),
    );
    await tester.pumpAndSettle();

    final lunch = _slot('2026-09-21', MealType.lunch);
    await tester.tap(lunch);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('select-recipe-card-soup')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Assignment failed.'), findsOneWidget);
    expect(tester.widget<MealSlotTile>(lunch).recipe, isNull);

    await tester.tap(find.widgetWithText(TextButton, 'Retry'));
    await tester.pumpAndSettle();

    expect(repository.setCalls, hasLength(2));
    expect(find.text('Tomato Soup'), findsOneWidget);
  });

  testWidgets('removal failure retains the assignment and supports retry', (
    tester,
  ) async {
    final recipe = _recipe('soup', 'Tomato Soup');
    final repository = _RecordingMealPlanRepository(
      assignments: <MealAssignment>[
        MealAssignment(
          date: DateTime(2026, 9, 21),
          mealType: MealType.lunch,
          recipeId: recipe.id,
        ),
      ],
      removeFailuresRemaining: 1,
    );
    await tester.pumpWidget(
      _testApp(
        recipeRepository: _StaticRecipeRepository(<Recipe>[recipe]),
        mealPlanRepository: repository,
      ),
    );
    await tester.pumpAndSettle();

    final lunch = _slot('2026-09-21', MealType.lunch);
    await tester.tap(lunch);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('Removal failed.'), findsOneWidget);
    expect(find.text('Tomato Soup'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Retry'));
    await tester.pumpAndSettle();

    expect(repository.removeCalls, hasLength(2));
    expect(find.text('Tomato Soup'), findsNothing);
    expect(tester.widget<MealSlotTile>(lunch).recipe, isNull);
  });

  for (final width in <double>[320, 412]) {
    testWidgets('lays out at ${width.toInt()} dp with 200% text scaling', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        _testApp(
          recipeRepository: _StaticRecipeRepository(<Recipe>[
            _recipe(
              'long-name',
              'A Deliberately Long Family Dinner Recipe Name',
            ),
          ]),
          mealPlanRepository: _StaticMealPlanRepository(
            assignments: <MealAssignment>[
              MealAssignment(
                date: DateTime(2026, 9, 21),
                mealType: MealType.dinner,
                recipeId: 'long-name',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MealSlotTile), findsNWidgets(21));
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(MealSlotTile).first).height,
        greaterThanOrEqualTo(72),
      );
    });
  }
}

Widget _testApp({
  required RecipeRepository recipeRepository,
  required MealPlanRepository mealPlanRepository,
  DateTime? currentDate,
}) {
  return MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
    ),
    home: WeeklyMealPlannerScreen(
      recipeRepository: recipeRepository,
      mealPlanRepository: mealPlanRepository,
      currentDateProvider: () => currentDate ?? DateTime(2026, 9, 22, 18),
    ),
  );
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

Finder _slot(String date, MealType mealType) {
  return find.byKey(
    ValueKey<String>('meal-slot-$date-${mealType.storedValue}'),
  );
}

class _StaticRecipeRepository implements RecipeRepository {
  _StaticRecipeRepository(this.recipes);

  final List<Recipe> recipes;
  int callCount = 0;

  @override
  Future<List<Recipe>> getAllRecipes() async {
    callCount++;
    return recipes;
  }
}

class _PendingRecipeRepository implements RecipeRepository {
  const _PendingRecipeRepository(this.completer);

  final Completer<List<Recipe>> completer;

  @override
  Future<List<Recipe>> getAllRecipes() => completer.future;
}

class _StaticMealPlanRepository implements MealPlanRepository {
  _StaticMealPlanRepository({this.assignments = const <MealAssignment>[]});

  final List<MealAssignment> assignments;
  final List<DateTime> loadedWeeks = <DateTime>[];

  @override
  Future<List<MealAssignment>> loadWeek(DateTime weekStart) async {
    loadedWeeks.add(weekStart);
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
  }) async {}

  @override
  Future<void> setAssignment(MealAssignment assignment) async {}
}

class _RecordingMealPlanRepository implements MealPlanRepository {
  _RecordingMealPlanRepository({
    List<MealAssignment> assignments = const <MealAssignment>[],
    this.setFailuresRemaining = 0,
    this.removeFailuresRemaining = 0,
  }) : assignments = List<MealAssignment>.of(assignments);

  final List<MealAssignment> assignments;
  final List<MealAssignment> setCalls = <MealAssignment>[];
  final List<MealAssignmentIdentity> removeCalls = <MealAssignmentIdentity>[];
  int setFailuresRemaining;
  int removeFailuresRemaining;
  Completer<void>? setGate;
  Completer<void>? removeGate;
  final Map<MealAssignmentIdentity, Completer<void>> setGates =
      <MealAssignmentIdentity, Completer<void>>{};

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
  Future<void> setAssignment(MealAssignment assignment) async {
    setCalls.add(assignment);
    if (setFailuresRemaining > 0) {
      setFailuresRemaining--;
      throw MealPlanRepositoryException(
        message: 'Assignment failed.',
        cause: const FormatException('Set failed.'),
        stackTrace: StackTrace.current,
      );
    }
    await setGates[assignment.identity]?.future;
    await setGate?.future;
    assignments
      ..removeWhere((existing) => existing.identity == assignment.identity)
      ..add(assignment);
  }

  @override
  Future<void> removeAssignment({
    required DateTime date,
    required MealType mealType,
  }) async {
    final identity = MealAssignmentIdentity(date: date, mealType: mealType);
    removeCalls.add(identity);
    if (removeFailuresRemaining > 0) {
      removeFailuresRemaining--;
      throw MealPlanRepositoryException(
        message: 'Removal failed.',
        cause: const FormatException('Remove failed.'),
        stackTrace: StackTrace.current,
      );
    }
    await removeGate?.future;
    assignments.removeWhere((assignment) => assignment.identity == identity);
  }
}

class _ControlledMealPlanRepository extends _StaticMealPlanRepository {
  final Map<DateTime, Completer<List<MealAssignment>>> _loads =
      <DateTime, Completer<List<MealAssignment>>>{};

  void complete(DateTime weekStart, List<MealAssignment> assignments) {
    (_loads[weekStart] ??= Completer<List<MealAssignment>>()).complete(
      assignments,
    );
  }

  @override
  Future<List<MealAssignment>> loadWeek(DateTime weekStart) {
    return (_loads[weekStart] ??= Completer<List<MealAssignment>>()).future;
  }
}

class _FailThenSucceedMealPlanRepository extends _StaticMealPlanRepository {
  int callCount = 0;

  @override
  Future<List<MealAssignment>> loadWeek(DateTime weekStart) async {
    callCount++;
    if (callCount == 1) {
      throw MealPlanRepositoryException(
        message: 'Meal plan unavailable.',
        cause: const FormatException('Invalid meal plan.'),
        stackTrace: StackTrace.current,
      );
    }
    return const <MealAssignment>[];
  }
}
