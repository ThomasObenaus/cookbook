import 'package:cookbook/features/meal_planner/data/meal_plan_repository.dart';
import 'package:cookbook/features/meal_planner/logic/week_dates.dart';
import 'package:cookbook/features/meal_planner/models/meal_assignment.dart';
import 'package:cookbook/features/meal_planner/models/meal_type.dart';
import 'package:cookbook/features/meal_planner/ui/meal_slot_tile.dart';
import 'package:cookbook/features/meal_planner/ui/recipe_selection_screen.dart';
import 'package:cookbook/features/recipe_catalog/data/recipe_repository.dart';
import 'package:cookbook/features/recipe_catalog/models/recipe.dart';
import 'package:flutter/material.dart';

typedef CurrentDateProvider = DateTime Function();

class WeeklyMealPlannerScreen extends StatefulWidget {
  const WeeklyMealPlannerScreen({
    required this.recipeRepository,
    required this.mealPlanRepository,
    required this.currentDateProvider,
    super.key,
  });

  final RecipeRepository recipeRepository;
  final MealPlanRepository mealPlanRepository;
  final CurrentDateProvider currentDateProvider;

  @override
  State<WeeklyMealPlannerScreen> createState() =>
      _WeeklyMealPlannerScreenState();
}

enum _PlannerStatus { loading, success, failure }

enum _AssignedSlotAction { change, remove }

class _WeeklyMealPlannerScreenState extends State<WeeklyMealPlannerScreen> {
  late final DateTime _today;
  late final DateTime _currentWeekStart;
  late DateTime _visibleWeekStart;
  late final ScrollController _scrollController;
  _PlannerStatus _status = _PlannerStatus.loading;
  Map<String, Recipe> _recipesById = const <String, Recipe>{};
  List<MealAssignment> _assignments = const <MealAssignment>[];
  String _errorMessage = '';
  int _loadGeneration = 0;
  bool _recipesLoaded = false;
  final Set<MealAssignmentIdentity> _mutatingSlots = <MealAssignmentIdentity>{};

  @override
  void initState() {
    super.initState();
    _today = normalizeLocalDate(widget.currentDateProvider());
    _currentWeekStart = mondayOfWeek(_today);
    _visibleWeekStart = _currentWeekStart;
    _scrollController = ScrollController();
    _loadVisibleWeek();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadVisibleWeek() async {
    final generation = ++_loadGeneration;
    final requestedWeek = _visibleWeekStart;

    try {
      Map<String, Recipe>? loadedRecipes;
      if (!_recipesLoaded) {
        final recipes = await widget.recipeRepository.getAllRecipes();
        loadedRecipes = <String, Recipe>{
          for (final recipe in recipes) recipe.id: recipe,
        };
      }
      final assignments = await widget.mealPlanRepository.loadWeek(
        requestedWeek,
      );
      if (!mounted || generation != _loadGeneration) {
        return;
      }

      setState(() {
        if (loadedRecipes != null) {
          _recipesById = Map<String, Recipe>.unmodifiable(loadedRecipes);
          _recipesLoaded = true;
        }
        _assignments = List<MealAssignment>.unmodifiable(assignments);
        _status = _PlannerStatus.success;
        _errorMessage = '';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            generation == _loadGeneration &&
            _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    } on RecipeRepositoryException catch (error) {
      _showLoadFailure(generation, error.message);
    } on MealPlanRepositoryException catch (error) {
      _showLoadFailure(generation, error.message);
    } catch (_) {
      _showLoadFailure(
        generation,
        'The meal plan could not be loaded. Please try again.',
      );
    }
  }

  void _showLoadFailure(int generation, String message) {
    if (!mounted || generation != _loadGeneration) {
      return;
    }
    setState(() {
      _status = _PlannerStatus.failure;
      _errorMessage = message;
    });
  }

  void _changeWeek(DateTime weekStart) {
    setState(() {
      _visibleWeekStart = mondayOfWeek(weekStart);
      _status = _PlannerStatus.loading;
      _errorMessage = '';
    });
    _loadVisibleWeek();
  }

  void _showPreviousWeek() {
    _changeWeek(previousWeek(_visibleWeekStart));
  }

  void _showNextWeek() {
    _changeWeek(nextWeek(_visibleWeekStart));
  }

  void _showCurrentWeek() {
    _changeWeek(_currentWeekStart);
  }

  void _retry() {
    setState(() {
      _status = _PlannerStatus.loading;
      _errorMessage = '';
    });
    _loadVisibleWeek();
  }

  Future<void> _handleSlotTap(
    DateTime date,
    MealType mealType,
    MealAssignment? assignment,
  ) async {
    final identity = MealAssignmentIdentity(date: date, mealType: mealType);
    if (_mutatingSlots.contains(identity)) {
      return;
    }

    if (assignment == null) {
      await _selectRecipe(date, mealType);
      return;
    }

    final action = await showModalBottomSheet<_AssignedSlotAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Change recipe'),
              onTap: () =>
                  Navigator.of(context).pop(_AssignedSlotAction.change),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove'),
              onTap: () =>
                  Navigator.of(context).pop(_AssignedSlotAction.remove),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _AssignedSlotAction.change:
        await _selectRecipe(date, mealType);
      case _AssignedSlotAction.remove:
        await _removeAssignment(date, mealType);
    }
  }

  Future<void> _selectRecipe(DateTime date, MealType mealType) async {
    final recipe = await Navigator.of(context).push<Recipe>(
      MaterialPageRoute<Recipe>(
        builder: (context) =>
            RecipeSelectionScreen(repository: widget.recipeRepository),
      ),
    );
    if (!mounted || recipe == null) {
      return;
    }

    await _setAssignment(
      MealAssignment(date: date, mealType: mealType, recipeId: recipe.id),
      recipe,
    );
  }

  Future<void> _setAssignment(MealAssignment assignment, Recipe recipe) async {
    final identity = assignment.identity;
    if (_mutatingSlots.contains(identity)) {
      return;
    }
    setState(() {
      _mutatingSlots.add(identity);
    });

    try {
      await widget.mealPlanRepository.setAssignment(assignment);
      if (!mounted) {
        return;
      }
      setState(() {
        _recipesById = Map<String, Recipe>.unmodifiable(<String, Recipe>{
          ..._recipesById,
          recipe.id: recipe,
        });
        if (_dateIsInVisibleWeek(assignment.date)) {
          _assignments = List<MealAssignment>.unmodifiable(<MealAssignment>[
            for (final existing in _assignments)
              if (existing.identity != identity) existing,
            assignment,
          ]);
        }
        _mutatingSlots.remove(identity);
      });
    } on MealPlanRepositoryException catch (error) {
      _finishFailedMutation(
        identity,
        error.message,
        () => _setAssignment(assignment, recipe),
      );
    } catch (_) {
      _finishFailedMutation(
        identity,
        'The meal assignment could not be saved. Please try again.',
        () => _setAssignment(assignment, recipe),
      );
    }
  }

  Future<void> _removeAssignment(DateTime date, MealType mealType) async {
    final identity = MealAssignmentIdentity(date: date, mealType: mealType);
    if (_mutatingSlots.contains(identity)) {
      return;
    }
    setState(() {
      _mutatingSlots.add(identity);
    });

    try {
      await widget.mealPlanRepository.removeAssignment(
        date: date,
        mealType: mealType,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        if (_dateIsInVisibleWeek(date)) {
          _assignments = List<MealAssignment>.unmodifiable(
            _assignments.where((assignment) => assignment.identity != identity),
          );
        }
        _mutatingSlots.remove(identity);
      });
    } on MealPlanRepositoryException catch (error) {
      _finishFailedMutation(
        identity,
        error.message,
        () => _removeAssignment(date, mealType),
      );
    } catch (_) {
      _finishFailedMutation(
        identity,
        'The meal assignment could not be removed. Please try again.',
        () => _removeAssignment(date, mealType),
      );
    }
  }

  void _finishFailedMutation(
    MealAssignmentIdentity identity,
    String message,
    VoidCallback retry,
  ) {
    if (!mounted || !_mutatingSlots.contains(identity)) {
      return;
    }
    setState(() {
      _mutatingSlots.remove(identity);
    });
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(label: 'Retry', onPressed: retry),
      ),
    );
  }

  bool _dateIsInVisibleWeek(DateTime date) {
    return !date.isBefore(_visibleWeekStart) &&
        date.isBefore(nextWeek(_visibleWeekStart));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meal plan')),
      body: FocusTraversalGroup(
        key: const ValueKey<String>('meal-plan-focus-traversal'),
        policy: ReadingOrderTraversalPolicy(),
        child: Column(
          children: <Widget>[
            _WeekHeader(
              weekStart: _visibleWeekStart,
              isCurrentWeek: _visibleWeekStart == _currentWeekStart,
              onPrevious: _showPreviousWeek,
              onToday: _showCurrentWeek,
              onNext: _showNextWeek,
            ),
            const Divider(height: 1),
            Expanded(
              child: switch (_status) {
                _PlannerStatus.loading => const Center(
                  child: CircularProgressIndicator(
                    key: ValueKey<String>('meal-plan-loading-indicator'),
                  ),
                ),
                _PlannerStatus.failure => _FailureState(
                  message: _errorMessage,
                  onRetry: _retry,
                ),
                _PlannerStatus.success => _buildWeek(),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeek() {
    final assignmentsByIdentity = <MealAssignmentIdentity, MealAssignment>{
      for (final assignment in _assignments) assignment.identity: assignment,
    };

    return SingleChildScrollView(
      key: const PageStorageKey<String>('meal-plan-week-list'),
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        children: <Widget>[
          for (final date in datesInWeek(_visibleWeekStart)) ...<Widget>[
            _DaySection(
              date: date,
              isToday: isSameCalendarDate(date, _today),
              assignmentsByIdentity: assignmentsByIdentity,
              recipesById: _recipesById,
              mutatingSlots: _mutatingSlots,
              onSlotTap: _handleSlotTap,
            ),
            if (date.weekday != DateTime.sunday) const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.weekStart,
    required this.isCurrentWeek,
    required this.onPrevious,
    required this.onToday,
    required this.onNext,
  });

  final DateTime weekStart;
  final bool isCurrentWeek;
  final VoidCallback onPrevious;
  final VoidCallback onToday;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final weekEnd = datesInWeek(weekStart).last;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: <Widget>[
          Text(
            '${localizations.formatMediumDate(weekStart)} - '
            '${localizations.formatMediumDate(weekEnd)}',
            key: const ValueKey<String>('meal-plan-week-range'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                key: const ValueKey<String>('previous-week-action'),
                onPressed: onPrevious,
                tooltip: 'Previous week',
                constraints: const BoxConstraints.tightFor(
                  width: 48,
                  height: 48,
                ),
                icon: const Icon(Icons.chevron_left),
              ),
              const SizedBox(width: 8),
              TextButton(
                key: const ValueKey<String>('today-action'),
                onPressed: isCurrentWeek ? null : onToday,
                style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
                child: const Text('Today'),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: const ValueKey<String>('next-week-action'),
                onPressed: onNext,
                tooltip: 'Next week',
                constraints: const BoxConstraints.tightFor(
                  width: 48,
                  height: 48,
                ),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.date,
    required this.isToday,
    required this.assignmentsByIdentity,
    required this.recipesById,
    required this.mutatingSlots,
    required this.onSlotTap,
  });

  final DateTime date;
  final bool isToday;
  final Map<MealAssignmentIdentity, MealAssignment> assignmentsByIdentity;
  final Map<String, Recipe> recipesById;
  final Set<MealAssignmentIdentity> mutatingSlots;
  final void Function(
    DateTime date,
    MealType mealType,
    MealAssignment? assignment,
  )
  onSlotTap;

  @override
  Widget build(BuildContext context) {
    final formattedDate = MaterialLocalizations.of(context)
        .formatFullDate(date);

    return Column(
      key: ValueKey<String>('meal-plan-day-${formatCalendarDate(date)}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                formattedDate,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (isToday) ...<Widget>[
              const SizedBox(width: 8),
              Semantics(
                label: 'Today',
                child: Text(
                  'Today',
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        for (final mealType in MealType.values) ...<Widget>[
          _buildSlot(mealType),
          if (mealType != MealType.dinner) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildSlot(MealType mealType) {
    final identity = MealAssignmentIdentity(date: date, mealType: mealType);
    final assignment = assignmentsByIdentity[identity];
    final recipe = assignment == null ? null : recipesById[assignment.recipeId];

    return MealSlotTile(
      key: ValueKey<String>(
        'meal-slot-${formatCalendarDate(date)}-${mealType.storedValue}',
      ),
      date: date,
      mealType: mealType,
      recipe: recipe,
      isUnavailable: assignment != null && recipe == null,
      isMutating: mutatingSlots.contains(identity),
      onTap: () => onSlotTap(date, mealType, assignment),
    );
  }
}

class _FailureState extends StatelessWidget {
  const _FailureState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey<String>('meal-plan-error-state'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
