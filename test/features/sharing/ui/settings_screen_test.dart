import 'package:cookbook/features/sharing/data/entitlement_source.dart';
import 'package:cookbook/features/sharing/logic/entitlement_controller.dart';
import 'package:cookbook/features/sharing/models/entitlement_status.dart';
import 'package:cookbook/features/sharing/models/sharing_entitlement.dart';
import 'package:cookbook/features/sharing/ui/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_entitlement_source.dart';

void main() {
  testWidgets('shows local cookbook information', (tester) async {
    final controller = EntitlementController(
      source: const SharingUnavailableEntitlementSource(),
    );
    addTearDown(controller.dispose);
    await controller.load();

    await tester.pumpWidget(_testApp(controller));

    expect(find.text('Local cookbook'), findsOneWidget);
    expect(find.textContaining('stored on this device'), findsOneWidget);
    expect(find.textContaining('work offline'), findsOneWidget);
    expect(find.text('Sharing is not available yet'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('retry-entitlement-action')),
      findsNothing,
    );
  });

  testWidgets('shows every entitlement status', (tester) async {
    final expiration = DateTime.utc(2026, 10, 14, 12);
    final states = <SharingEntitlement, String>{
      SharingEntitlement.unknown(): 'Checking sharing status',
      SharingEntitlement.sharingUnavailable(): 'Sharing is not available yet',
      SharingEntitlement.notEntitled(): 'No sharing subscription',
      SharingEntitlement.purchasePending(): 'Purchase is being processed',
      SharingEntitlement.active(): 'Sharing subscription active',
      SharingEntitlement.cancelledUntilExpiration(expiresAt: expiration):
          'Active until',
      SharingEntitlement.gracePeriod(expiresAt: expiration):
          'Payment problem, access continues until',
      SharingEntitlement.onHold(): 'Subscription on hold',
      SharingEntitlement.expired(): 'Sharing subscription expired',
    };

    for (final entry in states.entries) {
      final source = FakeEntitlementSource(() async => entry.key);
      final controller = EntitlementController(source: source);
      await controller.load();
      await tester.pumpWidget(_testApp(controller));

      expect(
        find.textContaining(entry.value),
        findsOneWidget,
        reason: '${entry.key.status}',
      );
      if (entry.key.expiresAt != null) {
        expect(find.textContaining('October 14, 2026'), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    }
  });

  testWidgets('retries verification through the controller', (tester) async {
    var fail = true;
    final source = FakeEntitlementSource(() async {
      if (fail) {
        throw StateError('offline');
      }
      return SharingEntitlement.active();
    });
    final controller = EntitlementController(source: source);
    addTearDown(controller.dispose);
    await controller.load();
    await tester.pumpWidget(_testApp(controller));

    expect(find.text('Sharing status could not be checked'), findsOneWidget);
    expect(
      find.text('Sharing status could not be checked. Please try again.'),
      findsOneWidget,
    );

    fail = false;
    await tester.tap(
      find.byKey(const ValueKey<String>('retry-entitlement-action')),
    );
    await tester.pumpAndSettle();

    expect(source.fetchCount, 2);
    expect(find.text('Sharing subscription active'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('retry-entitlement-action')),
      findsNothing,
    );
  });

  testWidgets('keeps invitation preview disabled for every state', (
    tester,
  ) async {
    final states = <SharingEntitlement, String>{
      SharingEntitlement.unknown():
          'Sharing status must be available before inviting members.',
      SharingEntitlement.sharingUnavailable():
          'Sharing is coming in a future update.',
      SharingEntitlement.notEntitled():
          'An active sharing subscription is required.',
      SharingEntitlement.purchasePending():
          'Sharing status must be available before inviting members.',
      SharingEntitlement.active(): 'Invitations are not available yet.',
      SharingEntitlement.cancelledUntilExpiration(
        expiresAt: DateTime.utc(2026, 10, 14),
      ): 'Invitations are not available yet.',
      SharingEntitlement.gracePeriod(expiresAt: DateTime.utc(2026, 10, 14)):
          'Invitations are not available yet.',
      SharingEntitlement.onHold():
          'An active sharing subscription is required.',
      SharingEntitlement.expired():
          'An active sharing subscription is required.',
      SharingEntitlement.verificationUnavailable():
          'Sharing status must be available before inviting members.',
    };

    for (final entry in states.entries) {
      final source = FakeEntitlementSource(() async => entry.key);
      final controller = EntitlementController(source: source);
      await controller.load();
      await tester.pumpWidget(_testApp(controller));

      final tile = tester.widget<ListTile>(
        find.byKey(const ValueKey<String>('invite-members-action')),
      );
      expect(tile.enabled, isFalse, reason: '${entry.key.status}');
      expect(tile.onTap, isNull, reason: '${entry.key.status}');
      expect(find.text(entry.value), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    }
  });

  testWidgets('exposes disabled invitation semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    final controller = EntitlementController(
      source: const SharingUnavailableEntitlementSource(),
    );
    addTearDown(controller.dispose);
    await controller.load();

    await tester.pumpWidget(_testApp(controller));

    expect(find.bySemanticsLabel('Invite members, disabled'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('debug simulator lists and applies entitlement states', (
    tester,
  ) async {
    final source = DebugEntitlementSource();
    final controller = EntitlementController(source: source);
    addTearDown(controller.dispose);
    await controller.load();
    final now = DateTime.utc(2026, 10, 7, 12);
    await tester.pumpWidget(
      _testApp(
        controller,
        debugEntitlementSource: source,
        currentTimeProvider: () => now,
      ),
    );

    final simulator = find.byKey(
      const ValueKey<String>('debug-entitlement-simulator'),
    );
    await tester.ensureVisible(simulator);
    await tester.tap(simulator);
    await tester.pumpAndSettle();

    for (final label in <String>[
      'Unknown',
      'Sharing unavailable',
      'Not entitled',
      'Purchase pending',
      'Active',
      'Cancelled until expiration',
      'Grace period',
      'On hold',
      'Expired',
      'Verification unavailable',
    ]) {
      expect(find.text(label), findsWidgets);
    }

    await tester.tap(find.text('Cancelled until expiration').last);
    await tester.pumpAndSettle();

    expect(
      controller.entitlement.status,
      EntitlementStatus.cancelledUntilExpiration,
    );
    expect(controller.entitlement.expiresAt, DateTime.utc(2026, 10, 14, 12));
    expect(find.textContaining('October 14, 2026'), findsOneWidget);
  });

  testWidgets('hides simulator when debug tools are disabled', (tester) async {
    final source = DebugEntitlementSource();
    final controller = EntitlementController(source: source);
    addTearDown(controller.dispose);
    await controller.load();

    await tester.pumpWidget(
      _testApp(
        controller,
        debugEntitlementSource: source,
        debugToolsEnabled: false,
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('debug-entitlement-simulator')),
      findsNothing,
    );
    expect(find.text('Developer tools'), findsNothing);
  });
}

Widget _testApp(
  EntitlementController controller, {
  DebugEntitlementSource? debugEntitlementSource,
  bool? debugToolsEnabled,
  DateTime Function()? currentTimeProvider,
}) {
  return MaterialApp(
    home: SettingsScreen(
      entitlementController: controller,
      currentTimeProvider:
          currentTimeProvider ?? () => DateTime.utc(2026, 10, 7),
      debugEntitlementSource: debugEntitlementSource,
      debugToolsEnabled: debugToolsEnabled ?? debugEntitlementSource != null,
    ),
  );
}
