import 'package:cookbook/features/sharing/models/entitlement_status.dart';
import 'package:cookbook/features/sharing/models/sharing_entitlement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 7, 17);

  test('exposes every entitlement status without ownership by default', () {
    final deniedEntitlements = <SharingEntitlement>[
      SharingEntitlement.unknown(),
      SharingEntitlement.sharingUnavailable(),
      SharingEntitlement.notEntitled(),
      SharingEntitlement.purchasePending(),
      SharingEntitlement.onHold(),
      SharingEntitlement.expired(),
      SharingEntitlement.verificationUnavailable(),
    ];

    expect(
      deniedEntitlements.map((entitlement) => entitlement.status),
      <EntitlementStatus>[
        EntitlementStatus.unknown,
        EntitlementStatus.sharingUnavailable,
        EntitlementStatus.notEntitled,
        EntitlementStatus.purchasePending,
        EntitlementStatus.onHold,
        EntitlementStatus.expired,
        EntitlementStatus.verificationUnavailable,
      ],
    );
    expect(
      deniedEntitlements.every(
        (entitlement) => !entitlement.allowsSharingOwnership(now),
      ),
      isTrue,
    );
  });

  test('active entitlement allows sharing ownership', () {
    expect(SharingEntitlement.active().allowsSharingOwnership(now), isTrue);
  });

  test('time-limited entitlement allows ownership only before expiration', () {
    final cancellation = SharingEntitlement.cancelledUntilExpiration(
      expiresAt: now.add(const Duration(hours: 1)),
    );
    final gracePeriod = SharingEntitlement.gracePeriod(
      expiresAt: now.add(const Duration(hours: 1)),
    );

    for (final entitlement in <SharingEntitlement>[cancellation, gracePeriod]) {
      expect(entitlement.expiresAt?.isUtc, isTrue);
      expect(entitlement.allowsSharingOwnership(now), isTrue);
      expect(
        entitlement.allowsSharingOwnership(now.add(const Duration(hours: 1))),
        isFalse,
      );
      expect(
        entitlement.allowsSharingOwnership(now.add(const Duration(hours: 2))),
        isFalse,
      );
    }
  });

  test('normalizes expiration to UTC', () {
    final localExpiration = DateTime(2026, 10, 8, 12);

    final entitlement = SharingEntitlement.cancelledUntilExpiration(
      expiresAt: localExpiration,
    );

    expect(entitlement.expiresAt, localExpiration.toUtc());
    expect(entitlement.expiresAt?.isUtc, isTrue);
  });

  test('verification failure preserves active ownership decision', () {
    final entitlement = SharingEntitlement.verificationUnavailable(
      lastKnownEntitlement: SharingEntitlement.active(),
    );

    expect(entitlement.status, EntitlementStatus.verificationUnavailable);
    expect(entitlement.lastKnownStatus, EntitlementStatus.active);
    expect(entitlement.allowsSharingOwnership(now), isTrue);
  });

  test('verification failure preserves time-limited entitlement', () {
    final expiration = now.add(const Duration(hours: 1));
    final entitlement = SharingEntitlement.verificationUnavailable(
      lastKnownEntitlement: SharingEntitlement.cancelledUntilExpiration(
        expiresAt: expiration,
      ),
    );

    expect(
      entitlement.lastKnownStatus,
      EntitlementStatus.cancelledUntilExpiration,
    );
    expect(entitlement.expiresAt, expiration);
    expect(entitlement.allowsSharingOwnership(now), isTrue);
    expect(entitlement.allowsSharingOwnership(expiration), isFalse);
  });

  test('verification failure does not grant a denied entitlement', () {
    for (final lastKnownEntitlement in <SharingEntitlement>[
      SharingEntitlement.unknown(),
      SharingEntitlement.sharingUnavailable(),
      SharingEntitlement.notEntitled(),
      SharingEntitlement.purchasePending(),
      SharingEntitlement.onHold(),
      SharingEntitlement.expired(),
    ]) {
      final entitlement = SharingEntitlement.verificationUnavailable(
        lastKnownEntitlement: lastKnownEntitlement,
      );

      expect(entitlement.allowsSharingOwnership(now), isFalse);
    }
  });

  test('rejects nested verification failures', () {
    expect(
      () => SharingEntitlement.verificationUnavailable(
        lastKnownEntitlement: SharingEntitlement.verificationUnavailable(),
      ),
      throwsArgumentError,
    );
  });
}
