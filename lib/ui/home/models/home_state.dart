import 'package:material_ui/material_ui.dart';

import 'forecast_ui_model.dart';
import 'place_ui_model.dart';
import 'units_ui_model.dart';

/// What the forecast area is showing.
@immutable
sealed class ForecastState {
  const ForecastState();
}

/// No place is selected, so there is nothing to forecast.
class ForecastIdle extends ForecastState {
  const ForecastIdle();
}

class ForecastLoading extends ForecastState {
  const ForecastLoading();
}

class ForecastLoaded extends ForecastState {
  const ForecastLoaded(this.forecast);
  final ForecastUiModel forecast;
}

class ForecastFailed extends ForecastState {
  const ForecastFailed(this.message);
  final String message;
}

/// What the home screen is showing: the selected place, if any, where its
/// forecast has got to, and the units it is in.
@immutable
class HomeState {
  const HomeState({
    required this.units,
    this.place,
    this.forecast = const ForecastIdle(),
  });

  final UnitsUiModel units;

  final PlaceUiModel? place;
  final ForecastState forecast;
}
