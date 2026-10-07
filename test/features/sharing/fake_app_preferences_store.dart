import 'package:cookbook/features/sharing/data/app_preferences_store.dart';

class FakeAppPreferencesStore implements AppPreferencesStore {
  FakeAppPreferencesStore([
    this._preferences = const AppPreferences.firstLaunch(),
  ]);

  AppPreferences _preferences;
  Object? loadError;
  Object? saveError;
  int loadCount = 0;
  int saveCount = 0;

  AppPreferences get preferences => _preferences;

  @override
  Future<AppPreferences> load() async {
    loadCount++;
    final error = loadError;
    if (error != null) {
      throw error;
    }
    return _preferences;
  }

  @override
  Future<void> save(AppPreferences preferences) async {
    saveCount++;
    final error = saveError;
    if (error != null) {
      throw error;
    }
    _preferences = preferences;
  }
}
