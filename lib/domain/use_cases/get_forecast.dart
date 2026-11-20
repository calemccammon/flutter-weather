import '../models/forecast.dart';
import '../models/place.dart';
import '../models/units.dart';
import '../repositories/weather_repository.dart';

/// Gets the forecast for a place.
class GetForecast {
  const GetForecast(this._repository);

  final WeatherRepository _repository;

  /// The forecast at [place] in [units].
  ///
  /// The longitude is brought into range first (see
  /// [Place.normalizeLongitude]). A point off the globe fails with
  /// [WeatherFailure.invalidPlace] without asking the repository.
  Future<Forecast> call(Place place, Units units) async {
    // Written so that a NaN fails the check too.
    final onGlobe = place.latitude.abs() <= 90 && place.longitude.isFinite;
    if (!onGlobe) throw const WeatherException(WeatherFailure.invalidPlace);

    return _repository.forecast(
      latitude: place.latitude,
      longitude: Place.normalizeLongitude(place.longitude),
      units: units,
    );
  }
}
