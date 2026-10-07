import 'package:cookbook/features/sharing/data/entitlement_source.dart';
import 'package:cookbook/features/sharing/logic/entitlement_controller.dart';
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
}

Widget _testApp(EntitlementController controller) {
  return MaterialApp(home: SettingsScreen(entitlementController: controller));
}
