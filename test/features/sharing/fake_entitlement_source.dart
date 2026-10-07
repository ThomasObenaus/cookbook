import 'package:cookbook/features/sharing/data/entitlement_source.dart';
import 'package:cookbook/features/sharing/models/sharing_entitlement.dart';

typedef EntitlementFetcher = Future<SharingEntitlement> Function();

class FakeEntitlementSource implements EntitlementSource {
  FakeEntitlementSource(this.fetcher);

  EntitlementFetcher fetcher;
  int fetchCount = 0;

  @override
  Future<SharingEntitlement> fetch() {
    fetchCount++;
    return fetcher();
  }
}
