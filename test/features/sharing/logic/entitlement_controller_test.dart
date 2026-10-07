import 'dart:async';

import 'package:cookbook/features/sharing/data/entitlement_source.dart';
import 'package:cookbook/features/sharing/logic/entitlement_controller.dart';
import 'package:cookbook/features/sharing/models/entitlement_status.dart';
import 'package:cookbook/features/sharing/models/sharing_entitlement.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_entitlement_source.dart';

void main() {
  test('loads an entitlement and notifies around the request', () async {
    final source = FakeEntitlementSource(
      () async => SharingEntitlement.notEntitled(),
    );
    final controller = EntitlementController(source: source);
    final snapshots = <({bool loading, EntitlementStatus status})>[];
    controller.addListener(() {
      snapshots.add((
        loading: controller.loading,
        status: controller.entitlement.status,
      ));
    });

    expect(await controller.load(), isTrue);

    expect(source.fetchCount, 1);
    expect(controller.error, isNull);
    expect(controller.entitlement.status, EntitlementStatus.notEntitled);
    expect(snapshots, <({bool loading, EntitlementStatus status})>[
      (loading: true, status: EntitlementStatus.unknown),
      (loading: false, status: EntitlementStatus.notEntitled),
    ]);
  });

  test('reports an initial source failure without granting access', () async {
    final source = FakeEntitlementSource(
      () async => throw StateError('offline'),
    );
    final controller = EntitlementController(source: source);

    expect(await controller.load(), isFalse);

    expect(
      controller.entitlement.status,
      EntitlementStatus.verificationUnavailable,
    );
    expect(controller.entitlement.lastKnownStatus, isNull);
    expect(
      controller.entitlement.allowsSharingOwnership(DateTime.now()),
      isFalse,
    );
    expect(
      controller.error,
      'Sharing status could not be checked. Please try again.',
    );
  });

  test('uses a source error message and clears it before retry', () async {
    final retry = Completer<SharingEntitlement>();
    var attempts = 0;
    final source = FakeEntitlementSource(() {
      attempts++;
      if (attempts == 1) {
        throw EntitlementSourceException(
          message: 'Specific failure.',
          cause: StateError('offline'),
          stackTrace: StackTrace.current,
        );
      }
      return retry.future;
    });
    final controller = EntitlementController(source: source);
    await controller.load();
    expect(controller.error, 'Specific failure.');

    final refresh = controller.refresh();

    expect(controller.loading, isTrue);
    expect(controller.error, isNull);
    retry.complete(SharingEntitlement.active());
    expect(await refresh, isTrue);
    expect(controller.entitlement.status, EntitlementStatus.active);
  });

  test('ignores an overlapping refresh', () async {
    final result = Completer<SharingEntitlement>();
    final source = FakeEntitlementSource(() => result.future);
    final controller = EntitlementController(source: source);

    final first = controller.refresh();
    expect(await controller.refresh(), isFalse);
    expect(source.fetchCount, 1);

    result.complete(SharingEntitlement.active());
    expect(await first, isTrue);
  });

  test('preserves the last known entitlement after failure', () async {
    var shouldFail = false;
    final source = FakeEntitlementSource(() async {
      if (shouldFail) {
        throw StateError('offline');
      }
      return SharingEntitlement.active();
    });
    final controller = EntitlementController(source: source);
    await controller.load();
    shouldFail = true;

    expect(await controller.refresh(), isFalse);

    expect(
      controller.entitlement.status,
      EntitlementStatus.verificationUnavailable,
    );
    expect(controller.entitlement.lastKnownStatus, EntitlementStatus.active);
    expect(
      controller.entitlement.allowsSharingOwnership(DateTime.now()),
      isTrue,
    );
  });

  test('repeated failures retain the last successful entitlement', () async {
    var shouldFail = false;
    final source = FakeEntitlementSource(() async {
      if (shouldFail) {
        throw StateError('offline');
      }
      return SharingEntitlement.notEntitled();
    });
    final controller = EntitlementController(source: source);
    await controller.load();
    shouldFail = true;

    await controller.refresh();
    await controller.refresh();

    expect(
      controller.entitlement.lastKnownStatus,
      EntitlementStatus.notEntitled,
    );
  });

  test('discards completion after disposal', () async {
    final result = Completer<SharingEntitlement>();
    final source = FakeEntitlementSource(() => result.future);
    final controller = EntitlementController(source: source);
    var notifications = 0;
    controller.addListener(() {
      notifications++;
    });
    final refresh = controller.refresh();
    expect(notifications, 1);

    controller.dispose();
    result.complete(SharingEntitlement.active());

    expect(await refresh, isFalse);
    expect(notifications, 1);
    expect(controller.entitlement.status, EntitlementStatus.unknown);
  });
}
