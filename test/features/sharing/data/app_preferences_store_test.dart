import 'dart:convert';
import 'dart:io';

import 'package:cookbook/features/sharing/data/app_preferences_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_app_preferences_store.dart';

void main() {
  late Directory supportDirectory;

  setUp(() async {
    supportDirectory = await Directory.systemTemp.createTemp(
      'cookbook-preferences-',
    );
  });

  tearDown(() async {
    if (await supportDirectory.exists()) {
      await supportDirectory.delete(recursive: true);
    }
  });

  test('treats missing storage as first launch', () async {
    final preferences = await _store(supportDirectory).load();

    expect(preferences.onboardingCompleted, isFalse);
    expect(preferences.onboardingCompletedAt, isNull);
  });

  test('saves and reloads onboarding completion', () async {
    final completedAt = DateTime.utc(2026, 10, 7, 17, 30);
    final store = _store(supportDirectory);

    await store.save(AppPreferences.onboardingCompleted(completedAt));

    final preferences = await _store(supportDirectory).load();
    expect(preferences.onboardingCompleted, isTrue);
    expect(preferences.onboardingCompletedAt, completedAt);
    expect(
      jsonDecode(await _preferencesFile(supportDirectory).readAsString()),
      <String, Object?>{
        'schemaVersion': 1,
        'onboardingCompletedAt': '2026-10-07T17:30:00.000Z',
      },
    );
  });

  test('normalizes completion time to UTC', () {
    final localTime = DateTime(2026, 10, 7, 17, 30);

    final preferences = AppPreferences.onboardingCompleted(localTime);

    expect(preferences.onboardingCompletedAt, localTime.toUtc());
    expect(preferences.onboardingCompletedAt?.isUtc, isTrue);
  });

  test('treats malformed and unsupported documents as first launch', () async {
    final invalidDocuments = <String>[
      '{broken',
      jsonEncode(<String, Object?>{'schemaVersion': 2}),
      jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'onboardingCompletedAt': 42,
      }),
      jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'onboardingCompletedAt': 'not-a-date',
      }),
      jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'onboardingCompletedAt': '2026-10-07T17:30:00',
      }),
    ];

    for (final document in invalidDocuments) {
      final file = _preferencesFile(supportDirectory);
      await file.parent.create(recursive: true);
      await file.writeAsString(document);

      final preferences = await _store(supportDirectory).load();

      expect(preferences.onboardingCompleted, isFalse, reason: document);
    }
  });

  test('overwrites malformed preferences on the next save', () async {
    final file = _preferencesFile(supportDirectory);
    await file.parent.create(recursive: true);
    await file.writeAsString('{broken');
    final store = _store(supportDirectory);

    expect((await store.load()).onboardingCompleted, isFalse);
    await store.save(
      AppPreferences.onboardingCompleted(DateTime.utc(2026, 10, 7)),
    );

    expect((await store.load()).onboardingCompleted, isTrue);
  });

  test('wraps storage read failures with diagnostic context', () async {
    await Directory(_preferencesFile(supportDirectory).path)
        .create(recursive: true);

    await expectLater(
      _store(supportDirectory).load(),
      throwsA(
        isA<AppPreferencesStoreException>()
            .having(
              (error) => error.message,
              'message',
              'App preferences could not be loaded. Please try again.',
            )
            .having((error) => error.cause, 'cause', isA<FileSystemException>())
            .having(
              (error) => error.stackTrace,
              'stackTrace',
              isA<StackTrace>(),
            ),
      ),
    );
  });

  test(
    'failed atomic write preserves valid data and cleans temporary path',
    () async {
      final store = _store(supportDirectory);
      final originalTime = DateTime.utc(2026, 10, 7);
      await store.save(AppPreferences.onboardingCompleted(originalTime));
      final temporaryPath = '${_preferencesFile(supportDirectory).path}.tmp';
      await Directory(temporaryPath).create();

      await expectLater(
        store.save(
          AppPreferences.onboardingCompleted(
            originalTime.add(const Duration(days: 1)),
          ),
        ),
        throwsA(
          isA<AppPreferencesStoreException>()
              .having(
                (error) => error.message,
                'message',
                'App preferences could not be saved. Please try again.',
              )
              .having(
                (error) => error.cause,
                'cause',
                isA<FileSystemException>(),
              ),
        ),
      );

      expect(
        (await _store(supportDirectory).load()).onboardingCompletedAt,
        originalTime,
      );
      expect(
        await FileSystemEntity.type(temporaryPath),
        FileSystemEntityType.notFound,
      );
    },
  );

  test('in-memory fake supports stored values and injected failures', () async {
    final fake = FakeAppPreferencesStore();
    final completed = AppPreferences.onboardingCompleted(
      DateTime.utc(2026, 10, 7),
    );

    await fake.save(completed);
    expect(await fake.load(), same(completed));
    expect(fake.preferences, same(completed));
    expect(fake.saveCount, 1);
    expect(fake.loadCount, 1);

    fake.loadError = StateError('load failed');
    fake.saveError = StateError('save failed');
    await expectLater(fake.load(), throwsStateError);
    await expectLater(
      fake.save(const AppPreferences.firstLaunch()),
      throwsStateError,
    );
    expect(fake.preferences, same(completed));
  });
}

LocalAppPreferencesStore _store(Directory supportDirectory) {
  return LocalAppPreferencesStore(
    applicationSupportDirectory: supportDirectory,
  );
}

File _preferencesFile(Directory supportDirectory) {
  return File.fromUri(
    supportDirectory.uri.resolve('cookbook/app_preferences.json'),
  );
}
