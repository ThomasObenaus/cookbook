import 'package:cookbook/features/sharing/models/sharing_entitlement.dart';
import 'package:flutter/foundation.dart';

abstract interface class EntitlementSource {
  Future<SharingEntitlement> fetch();
}

class SharingUnavailableEntitlementSource implements EntitlementSource {
  const SharingUnavailableEntitlementSource();

  @override
  Future<SharingEntitlement> fetch() async {
    return SharingEntitlement.sharingUnavailable();
  }
}

class DebugEntitlementSource implements EntitlementSource {
  DebugEntitlementSource({SharingEntitlement? initialEntitlement})
    : _entitlement =
          initialEntitlement ?? SharingEntitlement.sharingUnavailable() {
    if (!kDebugMode) {
      throw UnsupportedError(
        'The debug entitlement source is unavailable in release builds.',
      );
    }
  }

  SharingEntitlement _entitlement;

  void setEntitlement(SharingEntitlement entitlement) {
    _entitlement = entitlement;
  }

  @override
  Future<SharingEntitlement> fetch() async => _entitlement;
}

class EntitlementSourceException implements Exception {
  const EntitlementSourceException({
    required this.message,
    required this.cause,
    required this.stackTrace,
  });

  final String message;
  final Object cause;
  final StackTrace stackTrace;

  @override
  String toString() => message;
}
