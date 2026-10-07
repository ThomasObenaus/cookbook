import 'package:cookbook/features/sharing/data/entitlement_source.dart';
import 'package:cookbook/features/sharing/logic/entitlement_controller.dart';
import 'package:cookbook/features/sharing/models/entitlement_status.dart';
import 'package:cookbook/features/sharing/models/sharing_entitlement.dart';
import 'package:cookbook/features/sharing/ui/onboarding_screen.dart';
import 'package:flutter/material.dart';

class DebugEntitlementSimulator extends StatelessWidget {
  const DebugEntitlementSimulator({
    required this.source,
    required this.controller,
    required this.currentTimeProvider,
    super.key,
  });

  final DebugEntitlementSource source;
  final EntitlementController controller;
  final CurrentTimeProvider currentTimeProvider;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey<String>(
        'debug-entitlement-state-${controller.entitlement.status.name}',
      ),
      child: DropdownButtonFormField<EntitlementStatus>(
        key: const ValueKey<String>('debug-entitlement-simulator'),
        initialValue: controller.entitlement.status,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Simulate sharing state'),
        items: <DropdownMenuItem<EntitlementStatus>>[
          for (final status in EntitlementStatus.values)
            DropdownMenuItem<EntitlementStatus>(
              value: status,
              child: Text(_statusLabel(status)),
            ),
        ],
        onChanged: controller.loading
            ? null
            : (status) async {
                if (status == null) {
                  return;
                }
                source.setEntitlement(
                  _entitlementFor(status, currentTimeProvider()),
                );
                await controller.refresh();
              },
      ),
    );
  }
}

SharingEntitlement _entitlementFor(EntitlementStatus status, DateTime now) {
  final expiration = now.toUtc().add(const Duration(days: 7));
  return switch (status) {
    EntitlementStatus.unknown => SharingEntitlement.unknown(),
    EntitlementStatus.sharingUnavailable =>
      SharingEntitlement.sharingUnavailable(),
    EntitlementStatus.notEntitled => SharingEntitlement.notEntitled(),
    EntitlementStatus.purchasePending => SharingEntitlement.purchasePending(),
    EntitlementStatus.active => SharingEntitlement.active(),
    EntitlementStatus.cancelledUntilExpiration =>
      SharingEntitlement.cancelledUntilExpiration(expiresAt: expiration),
    EntitlementStatus.gracePeriod => SharingEntitlement.gracePeriod(
      expiresAt: expiration,
    ),
    EntitlementStatus.onHold => SharingEntitlement.onHold(),
    EntitlementStatus.expired => SharingEntitlement.expired(),
    EntitlementStatus.verificationUnavailable =>
      SharingEntitlement.verificationUnavailable(),
  };
}

String _statusLabel(EntitlementStatus status) {
  return switch (status) {
    EntitlementStatus.unknown => 'Unknown',
    EntitlementStatus.sharingUnavailable => 'Sharing unavailable',
    EntitlementStatus.notEntitled => 'Not entitled',
    EntitlementStatus.purchasePending => 'Purchase pending',
    EntitlementStatus.active => 'Active',
    EntitlementStatus.cancelledUntilExpiration => 'Cancelled until expiration',
    EntitlementStatus.gracePeriod => 'Grace period',
    EntitlementStatus.onHold => 'On hold',
    EntitlementStatus.expired => 'Expired',
    EntitlementStatus.verificationUnavailable => 'Verification unavailable',
  };
}
