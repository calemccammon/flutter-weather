import '../models/place.dart';
import '../repositories/weather_repository.dart';

/// Finds places by name.
class SearchPlaces {
  const SearchPlaces(this._repository);

  final WeatherRepository _repository;

  /// A query shorter than this is not worth sending: one letter matches
  /// nothing useful.
  static const minQueryLength = 2;

  /// Whether [query] is long enough to search for, spaces around it aside.
  static bool isSearchable(String query) =>
      query.trim().length >= minQueryLength;

  /// Places matching [query], best match first. Empty, without asking the
  /// repository, when the query is too short.
  Future<List<Place>> call(String query) async {
    if (!isSearchable(query)) return const [];
    return _repository.searchPlaces(query.trim());
  }
}
