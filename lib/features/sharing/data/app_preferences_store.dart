import 'dart:convert';
import 'dart:io';

class AppPreferences {
  const AppPreferences._({this.onboardingCompletedAt});

  const AppPreferences.firstLaunch() : this._();

  factory AppPreferences.onboardingCompleted(DateTime completedAt) {
    return AppPreferences._(onboardingCompletedAt: completedAt.toUtc());
  }

  factory AppPreferences.fromJson(Object? json) {
    if (json is! Map<String, Object?> || json['schemaVersion'] != 1) {
      throw const FormatException('Unsupported app preferences.');
    }
    final completedAtValue = json['onboardingCompletedAt'];
    if (completedAtValue == null) {
      return const AppPreferences.firstLaunch();
    }
    if (completedAtValue is! String) {
      throw const FormatException(
        'AppPreferences.onboardingCompletedAt must be a string.',
      );
    }
    final completedAt = DateTime.tryParse(completedAtValue);
    if (completedAt == null || !completedAt.isUtc) {
      throw const FormatException(
        'AppPreferences.onboardingCompletedAt must be a UTC timestamp.',
      );
    }
    return AppPreferences.onboardingCompleted(completedAt);
  }

  final DateTime? onboardingCompletedAt;

  bool get onboardingCompleted => onboardingCompletedAt != null;

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': 1,
    if (onboardingCompletedAt case final completedAt?)
      'onboardingCompletedAt': completedAt.toIso8601String(),
  };
}

abstract interface class AppPreferencesStore {
  Future<AppPreferences> load();

  Future<void> save(AppPreferences preferences);
}

class LocalAppPreferencesStore implements AppPreferencesStore {
  LocalAppPreferencesStore({required Directory applicationSupportDirectory})
    : _preferencesFile = File.fromUri(
        applicationSupportDirectory.uri.resolve(
          'cookbook/app_preferences.json',
        ),
      );

  static const _loadErrorMessage =
      'App preferences could not be loaded. Please try again.';
  static const _saveErrorMessage =
      'App preferences could not be saved. Please try again.';

  final File _preferencesFile;

  @override
  Future<AppPreferences> load() async {
    try {
      final type = await FileSystemEntity.type(
        _preferencesFile.path,
        followLinks: false,
      );
      if (type == FileSystemEntityType.notFound) {
        return const AppPreferences.firstLaunch();
      }
      if (type != FileSystemEntityType.file) {
        throw FileSystemException(
          'App preferences storage is not a file.',
          _preferencesFile.path,
        );
      }
      try {
        return AppPreferences.fromJson(
          jsonDecode(await _preferencesFile.readAsString()),
        );
      } on FormatException {
        return const AppPreferences.firstLaunch();
      }
    } on AppPreferencesStoreException {
      rethrow;
    } catch (error, stackTrace) {
      throw AppPreferencesStoreException(
        message: _loadErrorMessage,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> save(AppPreferences preferences) async {
    final temporaryFile = File('${_preferencesFile.path}.tmp');
    try {
      await _preferencesFile.parent.create(recursive: true);
      await temporaryFile.writeAsString(
        jsonEncode(preferences.toJson()),
        flush: true,
      );
      await temporaryFile.rename(_preferencesFile.path);
    } catch (error, stackTrace) {
      await _deleteTemporaryPath(temporaryFile.path);
      throw AppPreferencesStoreException(
        message: _saveErrorMessage,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}

class AppPreferencesStoreException implements Exception {
  const AppPreferencesStoreException({
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
