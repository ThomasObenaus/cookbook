import 'package:cookbook/features/sharing/logic/entitlement_controller.dart';
import 'package:cookbook/features/sharing/models/entitlement_status.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.entitlementController, super.key});

  final EntitlementController entitlementController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey<String>('settings-screen'),
      appBar: AppBar(title: const Text('Settings')),
      body: AnimatedBuilder(
        animation: entitlementController,
        builder: (context, _) {
          final entitlement = entitlementController.entitlement;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(
                'This cookbook',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.phone_android),
                  title: Text('Local cookbook'),
                  subtitle: Text(
                    'Recipes, meal plans, and shopping lists are stored on '
                    'this device and work offline.',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Sharing', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.group_outlined),
                  title: Text(
                    _statusText(context, entitlementController),
                    key: const ValueKey<String>('sharing-status'),
                  ),
                  subtitle: entitlementController.error == null
                      ? null
                      : Text(entitlementController.error!),
                  trailing:
                      entitlement.status ==
                          EntitlementStatus.verificationUnavailable
                      ? TextButton(
                          key: const ValueKey<String>(
                            'retry-entitlement-action',
                          ),
                          onPressed: entitlementController.loading
                              ? null
                              : entitlementController.refresh,
                          child: const Text('Retry'),
                        )
                      : entitlementController.loading
                      ? const SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _statusText(BuildContext context, EntitlementController controller) {
  final entitlement = controller.entitlement;
  return switch (entitlement.status) {
    EntitlementStatus.unknown => 'Checking sharing status',
    EntitlementStatus.sharingUnavailable => 'Sharing is not available yet',
    EntitlementStatus.notEntitled => 'No sharing subscription',
    EntitlementStatus.purchasePending => 'Purchase is being processed',
    EntitlementStatus.active => 'Sharing subscription active',
    EntitlementStatus.cancelledUntilExpiration =>
      'Active until ${_formatExpiration(context, entitlement.expiresAt)}',
    EntitlementStatus.gracePeriod =>
      'Payment problem, access continues until '
          '${_formatExpiration(context, entitlement.expiresAt)}',
    EntitlementStatus.onHold => 'Subscription on hold',
    EntitlementStatus.expired => 'Sharing subscription expired',
    EntitlementStatus.verificationUnavailable =>
      'Sharing status could not be checked',
  };
}

String _formatExpiration(BuildContext context, DateTime? expiration) {
  if (expiration == null) {
    return 'an unknown date';
  }
  return MaterialLocalizations.of(context).formatFullDate(expiration.toLocal());
}
