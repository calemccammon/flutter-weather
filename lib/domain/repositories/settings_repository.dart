import '../models/units.dart';

/// What the user has chosen for the app, kept between launches.
abstract interface class SettingsRepository {
  /// The units the user chose, or null if they have never chosen.
  Units? get units;

  Future<void> saveUnits(Units units);
}
