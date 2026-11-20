import '../../../domain/models/units.dart';

/// The choices the units control offers.
enum UnitsUiModel {
  celsius,
  fahrenheit;

  factory UnitsUiModel.from(Units units) => switch (units) {
    Units.metric => celsius,
    Units.imperial => fahrenheit,
  };

  Units toDomain() => switch (this) {
    celsius => Units.metric,
    fahrenheit => Units.imperial,
  };
}
