import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories/open_meteo_weather_repository.dart';
import '../data/repositories/shared_preferences_settings_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/weather_repository.dart';
import '../domain/use_cases/get_forecast.dart';
import '../domain/use_cases/get_units.dart';
import '../domain/use_cases/search_places.dart';
import '../domain/use_cases/set_units.dart';
import '../ui/core/dependencies.dart';

/// The one place that knows which implementation stands behind each domain
/// interface, and how each use case the UI asks for is built. Everything else
/// asks for the interface.

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final weatherRepositoryProvider = Provider<WeatherRepository>(
  (ref) => OpenMeteoWeatherRepository(ref.watch(httpClientProvider)),
);

/// The platform's key-value store. Opening it takes a moment, so `main` opens
/// it before the app starts and supplies it here.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Supplied by main() once it is open.'),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) =>
      SharedPreferencesSettingsRepository(ref.watch(sharedPreferencesProvider)),
);

/// Supplies the use cases named in `ui/core/dependencies.dart`, built over
/// the repositories above. Goes in the overrides of the app's `ProviderScope`,
/// and of a test's, which then swaps the repositories for fakes.
final List<Override> dependencies = [
  searchPlacesProvider.overrideWith(
    (ref) => SearchPlaces(ref.watch(weatherRepositoryProvider)),
  ),
  getForecastProvider.overrideWith(
    (ref) => GetForecast(ref.watch(weatherRepositoryProvider)),
  ),
  getUnitsProvider.overrideWith(
    (ref) => GetUnits(ref.watch(settingsRepositoryProvider)),
  ),
  setUnitsProvider.overrideWith(
    (ref) => SetUnits(ref.watch(settingsRepositoryProvider)),
  ),
];
