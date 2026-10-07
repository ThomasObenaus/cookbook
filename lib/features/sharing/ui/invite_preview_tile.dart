import 'package:cookbook/features/sharing/models/entitlement_status.dart';
import 'package:cookbook/features/sharing/models/sharing_entitlement.dart';
import 'package:flutter/material.dart';

class InvitePreviewTile extends StatelessWidget {
  const InvitePreviewTile({required this.entitlement, super.key});

  final SharingEntitlement entitlement;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      enabled: false,
      label: 'Invite members, disabled',
      child: ExcludeSemantics(
        child: Card(
          child: ListTile(
            key: const ValueKey<String>('invite-members-action'),
            enabled: false,
            leading: const Icon(Icons.person_add_alt_1_outlined),
            title: const Text('Invite members'),
            subtitle: Text(_explanation),
          ),
        ),
      ),
    );
  }

  String get _explanation {
    return switch (entitlement.status) {
      EntitlementStatus.sharingUnavailable =>
        'Sharing is coming in a future update.',
      EntitlementStatus.active ||
      EntitlementStatus.cancelledUntilExpiration ||
      EntitlementStatus.gracePeriod => 'Invitations are not available yet.',
      EntitlementStatus.notEntitled ||
      EntitlementStatus.onHold ||
      EntitlementStatus.expired =>
        'An active sharing subscription is required.',
      EntitlementStatus.unknown ||
      EntitlementStatus.purchasePending ||
      EntitlementStatus.verificationUnavailable =>
        'Sharing status must be available before inviting members.',
    };
  }
}
