import 'package:cookbook/features/meal_planner/models/meal_assignment.dart';
import 'package:cookbook/features/meal_planner/models/meal_type.dart';

abstract interface class MealPlanRepository {
  Future<List<MealAssignment>> loadWeek(DateTime weekStart);

  Future<void> setAssignment(MealAssignment assignment);

  Future<void> removeAssignment({
    required DateTime date,
    required MealType mealType,
  });
}

class MealPlanRepositoryException implements Exception {
  const MealPlanRepositoryException({
    required this.message,
    required this.cause,
    required this.stackTrace,
  });

  final String message;
  final Object cause;
  final StackTrace stackTrace;

  @override
  String toString() => message;
}
