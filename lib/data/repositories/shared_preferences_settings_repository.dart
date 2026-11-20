import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/units.dart';
import '../../domain/repositories/settings_repository.dart';

/// Keeps settings in the platform's own small key-value store.
class SharedPreferencesSettingsRepository implements SettingsRepository {
  const SharedPreferencesSettingsRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _unitsKey = 'units';

  // The stored words are this file's own, so renaming the enum's values
  // cannot orphan a saved choice.
  static const _metric = 'metric';
  static const _imperial = 'imperial';

  @override
  Units? get units => switch (_preferences.getString(_unitsKey)) {
    _metric => Units.metric,
    _imperial => Units.imperial,
    // Never chosen, or written by a version with a choice this one lacks.
    _ => null,
  };

  @override
  Future<void> saveUnits(Units units) async {
    final saved = await _preferences.setString(_unitsKey, switch (units) {
      Units.metric => _metric,
      Units.imperial => _imperial,
    });
    if (!saved) throw const SettingsException();
  }
}

/// The platform would not store a setting.
class SettingsException implements Exception {
  const SettingsException();

  @override
  String toString() => 'SettingsException: the setting was not saved';
}
