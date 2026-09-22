DateTime normalizeLocalDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

bool isSameCalendarDate(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

DateTime mondayOfWeek(DateTime value) {
  final date = normalizeLocalDate(value);
  return DateTime(date.year, date.month, date.day - (date.weekday - 1));
}

List<DateTime> datesInWeek(DateTime value) {
  final monday = mondayOfWeek(value);
  return List<DateTime>.unmodifiable(
    List<DateTime>.generate(
      DateTime.daysPerWeek,
      (index) => DateTime(monday.year, monday.month, monday.day + index),
    ),
  );
}

DateTime previousWeek(DateTime value) {
  final monday = mondayOfWeek(value);
  return DateTime(monday.year, monday.month, monday.day - DateTime.daysPerWeek);
}

DateTime nextWeek(DateTime value) {
  final monday = mondayOfWeek(value);
  return DateTime(monday.year, monday.month, monday.day + DateTime.daysPerWeek);
}

String formatCalendarDate(DateTime value) {
  final date = normalizeLocalDate(value);
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

DateTime parseCalendarDate(Object? value) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw const FormatException(
      'MealAssignment.date must use YYYY-MM-DD format.',
    );
  }

  final year = int.parse(value.substring(0, 4));
  final month = int.parse(value.substring(5, 7));
  final day = int.parse(value.substring(8, 10));
  if (year == 0) {
    throw const FormatException('MealAssignment.date is invalid.');
  }

  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    throw const FormatException('MealAssignment.date is invalid.');
  }
  return date;
}
