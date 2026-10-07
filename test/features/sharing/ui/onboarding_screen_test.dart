import 'dart:async';

import 'package:cookbook/features/sharing/data/app_preferences_store.dart';
import 'package:cookbook/features/sharing/ui/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_app_preferences_store.dart';

void main() {
  testWidgets('explains local use and future sharing', (tester) async {
    await tester.pumpWidget(_testApp(store: FakeAppPreferencesStore()));

    expect(find.text('Welcome to Cookbook'), findsOneWidget);
    expect(find.textContaining('works offline'), findsOneWidget);
    expect(find.textContaining('needs no account or payment'), findsOneWidget);
    expect(find.textContaining('will require a subscription'), findsOneWidget);
    expect(find.text('Use locally for free'), findsOneWidget);
    expect(find.text('Learn about sharing'), findsOneWidget);
  });

  testWidgets('persists local use before completing onboarding', (
    tester,
  ) async {
    final store = FakeAppPreferencesStore();
    var completed = false;
    final completedAt = DateTime.utc(2026, 10, 7, 20);
    await tester.pumpWidget(
      _testApp(
        store: store,
        currentTimeProvider: () => completedAt,
        onCompleted: () {
          completed = true;
        },
      ),
    );

    await tester.tap(find.text('Use locally for free'));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(store.saveCount, 1);
    expect(store.preferences.onboardingCompletedAt, completedAt);
  });

  testWidgets('shows that sharing and purchases are unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(store: FakeAppPreferencesStore()));

    await tester.tap(find.text('Learn about sharing'));
    await tester.pumpAndSettle();

    expect(find.text('Sharing is coming later'), findsOneWidget);
    expect(
      find.textContaining('purchases are not available yet'),
      findsOneWidget,
    );
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Sharing is coming later'), findsNothing);
  });

  testWidgets('shows a retryable persistence failure', (tester) async {
    final store = FakeAppPreferencesStore()
      ..saveError = StateError('unavailable');
    var completions = 0;
    await tester.pumpWidget(
      _testApp(
        store: store,
        onCompleted: () {
          completions++;
        },
      ),
    );

    await tester.tap(find.text('Use locally for free'));
    await tester.pumpAndSettle();

    expect(completions, 0);
    expect(
      find.byKey(const ValueKey<String>('onboarding-save-error')),
      findsOneWidget,
    );
    expect(
      find.text('Your choice could not be saved. Please try again.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);

    store.saveError = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(completions, 1);
    expect(store.saveCount, 2);
    expect(store.preferences.onboardingCompleted, isTrue);
  });

  testWidgets('prevents duplicate saves while persistence is pending', (
    tester,
  ) async {
    final store = _PendingPreferencesStore();
    await tester.pumpWidget(_testApp(store: store));

    await tester.tap(find.text('Use locally for free'));
    await tester.pump();

    expect(store.saveCount, 1);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey<String>('use-locally-action')),
          )
          .onPressed,
      isNull,
    );

    store.completeSave();
    await tester.pump();
  });

  testWidgets('remains usable at narrow width and large text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(_testApp(store: FakeAppPreferencesStore()));

    expect(tester.takeException(), isNull);
    expect(find.text('Use locally for free'), findsOneWidget);
    await tester.ensureVisible(find.text('Learn about sharing'));
    expect(tester.takeException(), isNull);
  });
}

Widget _testApp({
  required AppPreferencesStore store,
  CurrentTimeProvider? currentTimeProvider,
  VoidCallback? onCompleted,
}) {
  return MaterialApp(
    home: OnboardingScreen(
      preferencesStore: store,
      currentTimeProvider:
          currentTimeProvider ?? () => DateTime.utc(2026, 10, 7),
      onCompleted: onCompleted ?? () {},
    ),
  );
}

class _PendingPreferencesStore implements AppPreferencesStore {
  final Completer<void> _saveCompleter = Completer<void>();
  int saveCount = 0;

  @override
  Future<AppPreferences> load() async {
    return const AppPreferences.firstLaunch();
  }

  @override
  Future<void> save(AppPreferences preferences) {
    saveCount++;
    return _saveCompleter.future;
  }

  void completeSave() => _saveCompleter.complete();
}
