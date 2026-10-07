import 'package:cookbook/features/sharing/models/entitlement_status.dart';

class SharingEntitlement {
  const SharingEntitlement._({
    required this.status,
    this.expiresAt,
    this.lastKnownStatus,
  });

  factory SharingEntitlement.unknown() {
    return const SharingEntitlement._(status: EntitlementStatus.unknown);
  }

  factory SharingEntitlement.sharingUnavailable() {
    return const SharingEntitlement._(
      status: EntitlementStatus.sharingUnavailable,
    );
  }

  factory SharingEntitlement.notEntitled() {
    return const SharingEntitlement._(status: EntitlementStatus.notEntitled);
  }

  factory SharingEntitlement.purchasePending() {
    return const SharingEntitlement._(
      status: EntitlementStatus.purchasePending,
    );
  }

  factory SharingEntitlement.active() {
    return const SharingEntitlement._(status: EntitlementStatus.active);
  }

  factory SharingEntitlement.cancelledUntilExpiration({
    required DateTime expiresAt,
  }) {
    return SharingEntitlement._(
      status: EntitlementStatus.cancelledUntilExpiration,
      expiresAt: expiresAt.toUtc(),
    );
  }

  factory SharingEntitlement.gracePeriod({required DateTime expiresAt}) {
    return SharingEntitlement._(
      status: EntitlementStatus.gracePeriod,
      expiresAt: expiresAt.toUtc(),
    );
  }

  factory SharingEntitlement.onHold() {
    return const SharingEntitlement._(status: EntitlementStatus.onHold);
  }

  factory SharingEntitlement.expired() {
    return const SharingEntitlement._(status: EntitlementStatus.expired);
  }

  factory SharingEntitlement.verificationUnavailable({
    SharingEntitlement? lastKnownEntitlement,
  }) {
    if (lastKnownEntitlement?.status ==
        EntitlementStatus.verificationUnavailable) {
      throw ArgumentError.value(
        lastKnownEntitlement,
        'lastKnownEntitlement',
        'A verification failure cannot contain another verification failure.',
      );
    }
    return SharingEntitlement._(
      status: EntitlementStatus.verificationUnavailable,
      expiresAt: lastKnownEntitlement?.expiresAt,
      lastKnownStatus: lastKnownEntitlement?.status,
    );
  }

  final EntitlementStatus status;
  final DateTime? expiresAt;
  final EntitlementStatus? lastKnownStatus;

  bool allowsSharingOwnership(DateTime now) {
    return switch (status) {
      EntitlementStatus.active => true,
      EntitlementStatus.cancelledUntilExpiration ||
      EntitlementStatus.gracePeriod => _hasNotExpired(now),
      EntitlementStatus.verificationUnavailable => switch (lastKnownStatus) {
        EntitlementStatus.active => true,
        EntitlementStatus.cancelledUntilExpiration ||
        EntitlementStatus.gracePeriod => _hasNotExpired(now),
        _ => false,
      },
      _ => false,
    };
  }

  bool _hasNotExpired(DateTime now) {
    final expiration = expiresAt;
    return expiration != null && now.toUtc().isBefore(expiration);
  }
}
