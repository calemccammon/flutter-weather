import '../models/units.dart';
import '../repositories/settings_repository.dart';

/// Records the units the user chose, for this launch and later ones.
class SetUnits {
  const SetUnits(this._repository);

  final SettingsRepository _repository;

  Future<void> call(Units units) => _repository.saveUnits(units);
}
