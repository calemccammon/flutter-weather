import '../models/forecast.dart';
import '../models/place.dart';

/// Where the app gets places and forecasts from.
///
/// The domain only says what it needs. Which service answers, and what that
/// service's responses look like, is the data layer's business.
abstract interface class WeatherRepository {
  /// Places whose name matches [query], best match first.
  Future<List<Place>> searchPlaces(String query);

  /// Current conditions and the days ahead at a point, in metric units.
  Future<Forecast> forecast({
    required double latitude,
    required double longitude,
  });
}

/// The ways getting weather can fail, as far as the app cares.
enum WeatherFailure {
  /// No answer in time.
  timeout,

  /// The service could not be reached at all.
  noConnection,

  /// An answer came, but not one the app understands.
  badResponse,

  /// The service refused the request.
  rejected,

  /// The service is in trouble or too busy; trying later may work.
  unavailable,

  /// The place asked about is not a point on the globe.
  invalidPlace,
}

/// Thrown when a place search or a forecast cannot be had.
///
/// It says what kind of failure it was; wording that for the user is the UI's
/// job.
class WeatherException implements Exception {
  const WeatherException(this.failure, {this.detail});

  final WeatherFailure failure;

  /// Anything more the source said, for logs. Not for showing to the user.
  final String? detail;

  @override
  String toString() =>
      'WeatherException(${failure.name}${detail == null ? '' : ': $detail'})';
}
