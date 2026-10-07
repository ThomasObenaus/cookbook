import 'package:cookbook/features/sharing/data/entitlement_source.dart';
import 'package:cookbook/features/sharing/models/entitlement_status.dart';
import 'package:cookbook/features/sharing/models/sharing_entitlement.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_entitlement_source.dart';

void main() {
  test('production source reports sharing unavailable', () async {
    final source = SharingUnavailableEntitlementSource();

    final entitlement = await source.fetch();

    expect(entitlement.status, EntitlementStatus.sharingUnavailable);
  });

  test('debug source returns its current simulated entitlement', () async {
    final source = DebugEntitlementSource();
    expect((await source.fetch()).status, EntitlementStatus.sharingUnavailable);

    source.setEntitlement(SharingEntitlement.active());

    expect((await source.fetch()).status, EntitlementStatus.active);
  });

  test('a new debug source does not retain simulated state', () async {
    final firstSource = DebugEntitlementSource();
    firstSource.setEntitlement(SharingEntitlement.active());

    final restartedSource = DebugEntitlementSource();

    expect(
      (await restartedSource.fetch()).status,
      EntitlementStatus.sharingUnavailable,
    );
  });

  test('fake source supports success and failure injection', () async {
    final source = FakeEntitlementSource(
      () async => SharingEntitlement.notEntitled(),
    );

    expect((await source.fetch()).status, EntitlementStatus.notEntitled);

    source.fetcher = () async => throw StateError('unavailable');
    await expectLater(source.fetch(), throwsStateError);
    expect(source.fetchCount, 2);
  });
}
