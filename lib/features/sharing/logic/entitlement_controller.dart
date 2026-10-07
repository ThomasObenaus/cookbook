import 'package:cookbook/features/sharing/data/entitlement_source.dart';
import 'package:cookbook/features/sharing/models/entitlement_status.dart';
import 'package:cookbook/features/sharing/models/sharing_entitlement.dart';
import 'package:flutter/foundation.dart';

class EntitlementController extends ChangeNotifier {
  EntitlementController({required EntitlementSource source}) : this._(source);

  EntitlementController._(this._source);

  static const _defaultErrorMessage =
      'Sharing status could not be checked. Please try again.';

  final EntitlementSource _source;
  SharingEntitlement _entitlement = SharingEntitlement.unknown();
  SharingEntitlement? _lastKnownEntitlement;
  bool _loading = false;
  bool _disposed = false;
  int _generation = 0;
  String? _error;

  SharingEntitlement get entitlement => _entitlement;
  bool get loading => _loading;
  String? get error => _error;

  Future<bool> load() => refresh();

  Future<bool> refresh() async {
    if (_disposed || _loading) {
      return false;
    }

    final generation = ++_generation;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final entitlement = await _source.fetch();
      if (!_accepts(generation)) {
        return false;
      }
      _entitlement = entitlement;
      _lastKnownEntitlement = entitlement;
      return true;
    } catch (error) {
      if (!_accepts(generation)) {
        return false;
      }
      _entitlement = SharingEntitlement.verificationUnavailable(
        lastKnownEntitlement: _usableLastKnownEntitlement,
      );
      _error = error is EntitlementSourceException
          ? error.message
          : _defaultErrorMessage;
      return false;
    } finally {
      if (_accepts(generation)) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  SharingEntitlement? get _usableLastKnownEntitlement {
    final entitlement = _lastKnownEntitlement;
    if (entitlement == null ||
        entitlement.status == EntitlementStatus.unknown ||
        entitlement.status == EntitlementStatus.verificationUnavailable) {
      return null;
    }
    return entitlement;
  }

  bool _accepts(int generation) {
    return !_disposed && generation == _generation;
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
