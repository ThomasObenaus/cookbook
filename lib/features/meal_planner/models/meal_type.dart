enum MealType {
  breakfast(label: 'Breakfast', storedValue: 'breakfast'),
  lunch(label: 'Lunch', storedValue: 'lunch'),
  dinner(label: 'Dinner', storedValue: 'dinner');

  const MealType({required this.label, required this.storedValue});

  final String label;
  final String storedValue;

  static MealType fromStoredValue(Object? value) {
    if (value is! String) {
      throw const FormatException('MealAssignment.mealType must be a string.');
    }

    for (final mealType in values) {
      if (mealType.storedValue == value) {
        return mealType;
      }
    }

    throw FormatException('Unknown meal type: $value.');
  }
}
