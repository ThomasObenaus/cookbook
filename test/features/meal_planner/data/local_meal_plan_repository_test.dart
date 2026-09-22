import 'dart:convert';
import 'dart:io';

import 'package:cookbook/features/meal_planner/data/local_meal_plan_repository.dart';
import 'package:cookbook/features/meal_planner/data/meal_plan_repository.dart';
import 'package:cookbook/features/meal_planner/models/meal_assignment.dart';
import 'package:cookbook/features/meal_planner/models/meal_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory supportDirectory;

  setUp(() async {
    supportDirectory = await Directory.systemTemp.createTemp(
      'cookbook-meal-plan-',
    );
  });

  tearDown(() async {
    if (await supportDirectory.exists()) {
      await supportDirectory.delete(recursive: true);
    }
  });

  test('treats missing storage as an immutable empty week', () async {
    final assignments = await _repository(supportDirectory)
        .loadWeek(DateTime(2026, 9, 21));

    expect(assignments, isEmpty);
    expect(
      () => assignments.add(_assignment(21, MealType.breakfast, 'porridge')),
      throwsUnsupportedError,
    );
  });

  test('sets, replaces, removes, and reloads assignments', () async {
    final repository = _repository(supportDirectory);
    await repository.setAssignment(
      _assignment(21, MealType.breakfast, 'porridge'),
    );
    await repository.setAssignment(
      _assignment(21, MealType.breakfast, 'pancakes'),
    );
    await repository.setAssignment(_assignment(22, MealType.lunch, 'soup'));

    expect(await repository.loadWeek(DateTime(2026, 9, 27)), <MealAssignment>[
      _assignment(21, MealType.breakfast, 'pancakes'),
      _assignment(22, MealType.lunch, 'soup'),
    ]);

    await repository.removeAssignment(
      date: DateTime(2026, 9, 21, 18),
      mealType: MealType.breakfast,
    );
    final restartedRepository = _repository(supportDirectory);
    expect(
      await restartedRepository.loadWeek(DateTime(2026, 9, 21)),
      <MealAssignment>[_assignment(22, MealType.lunch, 'soup')],
    );
  });

  test('preserves other weeks and writes deterministic order', () async {
    final repository = _repository(supportDirectory);
    await repository.setAssignment(
      _assignment(29, MealType.dinner, 'later-dinner'),
    );
    await repository.setAssignment(_assignment(21, MealType.lunch, 'lunch'));
    await repository.setAssignment(
      _assignment(21, MealType.breakfast, 'breakfast'),
    );

    expect(await repository.loadWeek(DateTime(2026, 9, 28)), <MealAssignment>[
      _assignment(29, MealType.dinner, 'later-dinner'),
    ]);

    final document = jsonDecode(
      await _mealPlanFile(supportDirectory).readAsString(),
    ) as Map<String, Object?>;
    expect(document, <String, Object?>{
      'version': 1,
      'assignments': <Object?>[
        _assignment(21, MealType.breakfast, 'breakfast').toJson(),
        _assignment(21, MealType.lunch, 'lunch').toJson(),
        _assignment(29, MealType.dinner, 'later-dinner').toJson(),
      ],
    });
  });

  test('rejects malformed and unsupported documents', () async {
    final validAssignment = _assignment(
      21,
      MealType.breakfast,
      'porridge',
    ).toJson();
    final invalidDocuments = <Object?>[
      '{broken',
      <String, Object?>{'version': 2, 'assignments': <Object?>[]},
      <String, Object?>{'version': 1, 'assignments': 'invalid'},
      <String, Object?>{
        'version': 1,
        'assignments': <Object?>[
          <String, Object?>{...validAssignment, 'date': '2026-02-29'},
        ],
      },
      <String, Object?>{
        'version': 1,
        'assignments': <Object?>[
          <String, Object?>{...validAssignment, 'mealType': 'snack'},
        ],
      },
      <String, Object?>{
        'version': 1,
        'assignments': <Object?>[
          <String, Object?>{...validAssignment, 'recipeId': ' '},
        ],
      },
      <String, Object?>{
        'version': 1,
        'assignments': <Object?>[validAssignment, validAssignment],
      },
    ];

    for (final document in invalidDocuments) {
      final file = _mealPlanFile(supportDirectory);
      await file.parent.create(recursive: true);
      await file.writeAsString(
        document is String ? document : jsonEncode(document),
      );

      await expectLater(
        _repository(supportDirectory).loadWeek(DateTime(2026, 9, 21)),
        throwsA(
          isA<MealPlanRepositoryException>().having(
            (error) => error.cause,
            'cause',
            isA<FormatException>(),
          ),
        ),
        reason: '$document',
      );
    }
  });

  test(
    'failed atomic write preserves valid data and cleans temporary path',
    () async {
      final repository = _repository(supportDirectory);
      final original = _assignment(21, MealType.breakfast, 'porridge');
      await repository.setAssignment(original);
      final temporaryPath = '${_mealPlanFile(supportDirectory).path}.tmp';
      await Directory(temporaryPath).create();

      await expectLater(
        repository.setAssignment(_assignment(22, MealType.lunch, 'soup')),
        throwsA(
          isA<MealPlanRepositoryException>().having(
            (error) => error.cause,
            'cause',
            isA<FileSystemException>(),
          ),
        ),
      );

      expect(
        await _repository(supportDirectory).loadWeek(DateTime(2026, 9, 21)),
        <MealAssignment>[original],
      );
      expect(
        await FileSystemEntity.type(temporaryPath),
        FileSystemEntityType.notFound,
      );
    },
  );

  test('serializes overlapping mutations without losing assignments', () async {
    final repository = _repository(supportDirectory);

    await Future.wait(<Future<void>>[
      repository.setAssignment(_assignment(21, MealType.breakfast, 'porridge')),
      repository.setAssignment(_assignment(21, MealType.lunch, 'soup')),
      repository.setAssignment(_assignment(21, MealType.dinner, 'pasta')),
    ]);

    expect(await repository.loadWeek(DateTime(2026, 9, 21)), <MealAssignment>[
      _assignment(21, MealType.breakfast, 'porridge'),
      _assignment(21, MealType.lunch, 'soup'),
      _assignment(21, MealType.dinner, 'pasta'),
    ]);
  });
}

LocalMealPlanRepository _repository(Directory supportDirectory) {
  return LocalMealPlanRepository(applicationSupportDirectory: supportDirectory);
}

MealAssignment _assignment(int day, MealType mealType, String recipeId) {
  return MealAssignment(
    date: DateTime(2026, 9, day),
    mealType: mealType,
    recipeId: recipeId,
  );
}

File _mealPlanFile(Directory supportDirectory) {
  return File.fromUri(supportDirectory.uri.resolve('cookbook/meal_plan.json'));
}
