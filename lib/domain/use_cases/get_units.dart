import '../models/units.dart';
import '../repositories/settings_repository.dart';

/// Decides which units to show a forecast in.
class GetUnits {
  const GetUnits(this._repository);

  final SettingsRepository _repository;

  /// The user's own choice if they have made one; otherwise the units of the
  /// country the device is set to ([deviceCountry], such as "US").
  Units call({String? deviceCountry}) =>
      _repository.units ?? Units.forCountry(deviceCountry);
}
