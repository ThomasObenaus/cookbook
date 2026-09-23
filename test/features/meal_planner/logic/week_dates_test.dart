import 'package:cookbook/features/meal_planner/logic/week_dates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes and compares calendar dates without time of day', () {
    final morning = DateTime(2026, 9, 22, 8, 15);
    final evening = DateTime(2026, 9, 22, 21, 45);

    expect(normalizeLocalDate(morning), DateTime(2026, 9, 22));
    expect(isSameCalendarDate(morning, evening), isTrue);
    expect(isSameCalendarDate(morning, DateTime(2026, 9, 23)), isFalse);
  });

  test('finds Monday for every weekday', () {
    final monday = DateTime(2026, 9, 21);

    for (var offset = 0; offset < DateTime.daysPerWeek; offset++) {
      final date = DateTime(monday.year, monday.month, monday.day + offset, 12);
      expect(mondayOfWeek(date), monday, reason: '$date');
    }
  });

  test('generates immutable Monday-to-Sunday dates across year boundary', () {
    final dates = datesInWeek(DateTime(2025, 12, 31));

    expect(dates, <DateTime>[
      DateTime(2025, 12, 29),
      DateTime(2025, 12, 30),
      DateTime(2025, 12, 31),
      DateTime(2026, 1, 1),
      DateTime(2026, 1, 2),
      DateTime(2026, 1, 3),
      DateTime(2026, 1, 4),
    ]);
    expect(() => dates.add(DateTime(2026, 1, 5)), throwsUnsupportedError);
  });

  test('navigates leap-day and daylight-saving calendar boundaries', () {
    expect(nextWeek(DateTime(2024, 2, 26)), DateTime(2024, 3, 4));
    expect(previousWeek(DateTime(2024, 3, 4)), DateTime(2024, 2, 26));

    expect(nextWeek(DateTime(2026, 3, 2)), DateTime(2026, 3, 9));
    expect(previousWeek(DateTime(2026, 11, 2)), DateTime(2026, 10, 26));
  });

  test('formats and parses strict calendar dates', () {
    expect(formatCalendarDate(DateTime(2026, 1, 2, 23)), '2026-01-02');
    expect(parseCalendarDate('2024-02-29'), DateTime(2024, 2, 29));

    for (final invalidValue in <Object?>[
      null,
      20260921,
      '2026-9-21',
      '2026-02-29',
      '0000-01-01',
      '2026-13-01',
      '2026-01-32',
    ]) {
      expect(
        () => parseCalendarDate(invalidValue),
        throwsFormatException,
        reason: '$invalidValue',
      );
    }
  });
}
