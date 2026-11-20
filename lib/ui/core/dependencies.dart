import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/use_cases/get_forecast.dart';
import '../../domain/use_cases/get_units.dart';
import '../../domain/use_cases/search_places.dart';
import '../../domain/use_cases/set_units.dart';

/// What the UI needs handed to it.
///
/// The view models ask for use cases by these names and nothing more. How a
/// use case is built, and over which repository, is decided in `lib/di`,
/// which supplies each one when the app starts. So nothing in `ui` imports
/// `di` or `data`.

Never _notSupplied(String name) => throw UnimplementedError(
  '$name has not been supplied. Add `dependencies` from di/providers.dart '
  "to the ProviderScope's overrides.",
);

final searchPlacesProvider = Provider<SearchPlaces>(
  (ref) => _notSupplied('searchPlacesProvider'),
);

final getForecastProvider = Provider<GetForecast>(
  (ref) => _notSupplied('getForecastProvider'),
);

final getUnitsProvider = Provider<GetUnits>(
  (ref) => _notSupplied('getUnitsProvider'),
);

final setUnitsProvider = Provider<SetUnits>(
  (ref) => _notSupplied('setUnitsProvider'),
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
