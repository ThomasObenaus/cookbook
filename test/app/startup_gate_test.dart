import 'dart:io';

import 'package:cookbook/app/startup_gate.dart';
import 'package:cookbook/features/sharing/data/app_preferences_store.dart';
import 'package:cookbook/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/sharing/fake_app_preferences_store.dart';

void main() {
  testWidgets('first launch shows onboarding and enters the cookbook', (
    tester,
  ) async {
    final store = FakeAppPreferencesStore();
    final completedAt = DateTime.utc(2026, 10, 7, 21);
    await tester.pumpWidget(
      _testApp(
        initialPreferences: const AppPreferences.firstLaunch(),
        store: store,
        currentTimeProvider: () => completedAt,
      ),
    );

    expect(find.text('Welcome to Cookbook'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('test-cookbook')), findsNothing);

    await tester.tap(find.text('Use locally for free'));
    await tester.pumpAndSettle();

    expect(store.preferences.onboardingCompletedAt, completedAt);
    expect(find.text('Welcome to Cookbook'), findsNothing);
    expect(find.byKey(const ValueKey<String>('test-cookbook')), findsOneWidget);
  });

  testWidgets('completed onboarding opens the cookbook directly', (
    tester,
  ) async {
    final preferences = AppPreferences.onboardingCompleted(
      DateTime.utc(2026, 10, 7),
    );

    await tester.pumpWidget(
      _testApp(
        initialPreferences: preferences,
        store: FakeAppPreferencesStore(preferences),
      ),
    );

    expect(find.text('Welcome to Cookbook'), findsNothing);
    expect(find.byKey(const ValueKey<String>('test-cookbook')), findsOneWidget);
  });

  test('malformed preferences produce first-launch preferences', () async {
    final supportDirectory = await Directory.systemTemp.createTemp(
      'cookbook-startup-gate-',
    );
    addTearDown(() async {
      if (await supportDirectory.exists()) {
        await supportDirectory.delete(recursive: true);
      }
    });
    final store = LocalAppPreferencesStore(
      applicationSupportDirectory: supportDirectory,
    );
    final file = File.fromUri(
      supportDirectory.uri.resolve('cookbook/app_preferences.json'),
    );
    await file.parent.create(recursive: true);
    await file.writeAsString('{broken');

    expect((await store.load()).onboardingCompleted, isFalse);
  });

  testWidgets('support-directory failure remains controlled', (tester) async {
    final root = await createCookbookApp(
      supportDirectoryProvider: () async => throw Exception('unavailable'),
    );

    await tester.pumpWidget(root);

    expect(
      find.byKey(const ValueKey<String>('cookbook-startup-error')),
      findsOneWidget,
    );
  });
}

Widget _testApp({
  required AppPreferences initialPreferences,
  required AppPreferencesStore store,
  DateTime Function()? currentTimeProvider,
}) {
  return MaterialApp(
    home: StartupGate(
      initialPreferences: initialPreferences,
      preferencesStore: store,
      currentTimeProvider:
          currentTimeProvider ?? () => DateTime.utc(2026, 10, 7),
      cookbook: const SizedBox(key: ValueKey<String>('test-cookbook')),
    ),
  );
}
