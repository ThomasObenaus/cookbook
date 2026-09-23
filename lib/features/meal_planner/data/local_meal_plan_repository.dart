import 'dart:convert';
import 'dart:io';

import 'package:cookbook/features/meal_planner/data/meal_plan_repository.dart';
import 'package:cookbook/features/meal_planner/logic/week_dates.dart';
import 'package:cookbook/features/meal_planner/models/meal_assignment.dart';
import 'package:cookbook/features/meal_planner/models/meal_type.dart';

class LocalMealPlanRepository implements MealPlanRepository {
  LocalMealPlanRepository({required Directory applicationSupportDirectory})
    : _dataDirectory = Directory.fromUri(
        applicationSupportDirectory.uri.resolve('cookbook/'),
      );

  static const _loadErrorMessage =
      'The meal plan could not be loaded. Please try again.';
  static const _saveErrorMessage =
      'The meal plan could not be saved. Please try again.';

  final Directory _dataDirectory;
  Future<void> _mutationTail = Future<void>.value();

  File get _mealPlanFile =>
      File.fromUri(_dataDirectory.uri.resolve('meal_plan.json'));

  @override
  Future<List<MealAssignment>> loadWeek(DateTime weekStart) async {
    try {
      final monday = mondayOfWeek(weekStart);
      final followingMonday = nextWeek(monday);
      final assignments = await _readAssignments();
      return List<MealAssignment>.unmodifiable(
        assignments.where(
          (assignment) =>
              !assignment.date.isBefore(monday) &&
              assignment.date.isBefore(followingMonday),
        ),
      );
    } on MealPlanRepositoryException {
      rethrow;
    } catch (error, stackTrace) {
      throw MealPlanRepositoryException(
        message: _loadErrorMessage,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> setAssignment(MealAssignment assignment) {
    return _serializeMutation(() async {
      final assignments = await _readAssignments();
      final updatedAssignments = <MealAssignment>[
        for (final existing in assignments)
          if (existing.identity != assignment.identity) existing,
        assignment,
      ];
      await _writeAssignments(updatedAssignments);
    });
  }

  @override
  Future<void> removeAssignment({
    required DateTime date,
    required MealType mealType,
  }) {
    final identity = MealAssignmentIdentity(date: date, mealType: mealType);
    return _serializeMutation(() async {
      final assignments = await _readAssignments();
      await _writeAssignments(<MealAssignment>[
        for (final assignment in assignments)
          if (assignment.identity != identity) assignment,
      ]);
    });
  }

  Future<void> _serializeMutation(Future<void> Function() mutation) {
    final result = _mutationTail.then((_) async {
      try {
        await mutation();
      } on MealPlanRepositoryException {
        rethrow;
      } catch (error, stackTrace) {
        throw MealPlanRepositoryException(
          message: _saveErrorMessage,
          cause: error,
          stackTrace: stackTrace,
        );
      }
    });
    _mutationTail = result.catchError((Object _) {});
    return result;
  }

  Future<List<MealAssignment>> _readAssignments() async {
    final mealPlanFile = _mealPlanFile;
    if (!await mealPlanFile.exists()) {
      return const <MealAssignment>[];
    }

    final Object? decoded = jsonDecode(await mealPlanFile.readAsString());
    if (decoded is! Map<String, Object?> || decoded['version'] != 1) {
      throw const FormatException('Unsupported meal-plan data.');
    }
    final values = decoded['assignments'];
    if (values is! List<Object?>) {
      throw const FormatException('Meal-plan assignments must be a list.');
    }

    final assignments = <MealAssignment>[];
    final identities = <MealAssignmentIdentity>{};
    for (var index = 0; index < values.length; index++) {
      final assignment = MealAssignment.fromJson(values[index]);
      if (!identities.add(assignment.identity)) {
        throw FormatException(
          'Duplicate meal-plan assignment at index $index.',
        );
      }
      assignments.add(assignment);
    }
    return assignments;
  }

  Future<void> _writeAssignments(List<MealAssignment> assignments) async {
    final sortedAssignments = List<MealAssignment>.of(assignments)
      ..sort(_compareAssignments);
    await _dataDirectory.create(recursive: true);
    final temporaryFile = File('${_mealPlanFile.path}.tmp');
    try {
      await temporaryFile.writeAsString(
        jsonEncode(<String, Object?>{
          'version': 1,
          'assignments': sortedAssignments
              .map((assignment) => assignment.toJson())
              .toList(growable: false),
        }),
        flush: true,
      );
      await temporaryFile.rename(_mealPlanFile.path);
    } catch (_) {
      await _deleteTemporaryPath(temporaryFile.path);
      rethrow;
    }
  }
}

int _compareAssignments(MealAssignment first, MealAssignment second) {
  final dateComparison = first.date.compareTo(second.date);
  if (dateComparison != 0) {
    return dateComparison;
  }
  return first.mealType.index.compareTo(second.mealType.index);
}

Future<void> _deleteTemporaryPath(String path) async {
  try {
    final type = await FileSystemEntity.type(path, followLinks: false);
    switch (type) {
      case FileSystemEntityType.file:
      case FileSystemEntityType.link:
      case FileSystemEntityType.pipe:
      case FileSystemEntityType.unixDomainSock:
        await File(path).delete();
      case FileSystemEntityType.directory:
        await Directory(path).delete(recursive: true);
      case FileSystemEntityType.notFound:
        return;
    }
  } on FileSystemException {
    return;
  }
}
