import 'package:cookbook/features/meal_planner/logic/week_dates.dart';
import 'package:cookbook/features/meal_planner/models/meal_type.dart';

class MealAssignmentIdentity {
  MealAssignmentIdentity({required DateTime date, required this.mealType})
    : date = normalizeLocalDate(date);

  final DateTime date;
  final MealType mealType;

  @override
  bool operator ==(Object other) {
    return other is MealAssignmentIdentity &&
        date == other.date &&
        mealType == other.mealType;
  }

  @override
  int get hashCode => Object.hash(date, mealType);
}

class MealAssignment {
  MealAssignment({
    required DateTime date,
    required this.mealType,
    required String recipeId,
  }) : date = normalizeLocalDate(date),
       recipeId = _requiredRecipeId(recipeId);

  factory MealAssignment.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('MealAssignment must be a JSON object.');
    }

    return MealAssignment(
      date: parseCalendarDate(json['date']),
      mealType: MealType.fromStoredValue(json['mealType']),
      recipeId: _recipeIdFromJson(json['recipeId']),
    );
  }

  final DateTime date;
  final MealType mealType;
  final String recipeId;

  MealAssignmentIdentity get identity =>
      MealAssignmentIdentity(date: date, mealType: mealType);

  Map<String, Object?> toJson() => <String, Object?>{
    'date': formatCalendarDate(date),
    'mealType': mealType.storedValue,
    'recipeId': recipeId,
  };

  @override
  bool operator ==(Object other) {
    return other is MealAssignment &&
        date == other.date &&
        mealType == other.mealType &&
        recipeId == other.recipeId;
  }

  @override
  int get hashCode => Object.hash(date, mealType, recipeId);
}

String _recipeIdFromJson(Object? value) {
  if (value is! String) {
    throw const FormatException('MealAssignment.recipeId must be a string.');
  }
  return _requiredRecipeId(value);
}

String _requiredRecipeId(String value) {
  final recipeId = value.trim();
  if (recipeId.isEmpty) {
    throw const FormatException('MealAssignment.recipeId must not be empty.');
  }
  return recipeId;
}
