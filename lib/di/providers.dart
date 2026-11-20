import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// The one place that knows which implementation stands behind each domain
/// interface, and what the app is configured with. Everything else asks for
/// the interface.

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final weatherRepositoryProvider = Provider<WeatherRepository>(
  (ref) => OpenMeteoWeatherRepository(ref.watch(httpClientProvider)),
);

final searchPlacesProvider = Provider<SearchPlaces>(
  (ref) => SearchPlaces(ref.watch(weatherRepositoryProvider)),
);

final getForecastProvider = Provider<GetForecast>(
  (ref) => GetForecast(ref.watch(weatherRepositoryProvider)),
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

final getUnitsProvider = Provider<GetUnits>(
  (ref) => GetUnits(ref.watch(settingsRepositoryProvider)),
);

final setUnitsProvider = Provider<SetUnits>(
  (ref) => SetUnits(ref.watch(settingsRepositoryProvider)),
);

/// The country the device is set to, such as "US", if it says.
final deviceCountryProvider = Provider<String?>(
  (ref) => PlatformDispatcher.instance.locale.countryCode,
);

/// Where map tiles come from, or null to draw no tiles (used by tests, which
/// must not reach the network).
///
/// These are OpenStreetMap's own servers, which are fine for development and
/// light use only: https://operations.osmfoundation.org/policies/tiles/
final mapTileUrlProvider = Provider<String?>(
  (ref) => 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
);
