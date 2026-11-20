import 'dart:async';
import 'dart:ui';

import 'package:flutter_weather/domain/models/forecast.dart';
import 'package:flutter_weather/domain/models/place.dart';
import 'package:flutter_weather/domain/models/units.dart';
import 'package:flutter_weather/domain/models/weather_condition.dart';
import 'package:flutter_weather/domain/repositories/settings_repository.dart';
import 'package:flutter_weather/domain/repositories/weather_repository.dart';
import 'package:flutter_weather/l10n/generated/app_localizations_en.dart';
import 'package:flutter_weather/ui/core/l10n.dart';

/// The app's English wording, for tests to compare against.
final en = lookupAppLocalizations(const Locale('en'));

const asheville = Place(
  name: 'Asheville',
  latitude: 35.6,
  longitude: -82.55,
  region: 'North Carolina',
  country: 'United States',
);
const ashford = Place(name: 'Ashford', latitude: 51.15, longitude: 0.87);

/// A week starting Friday 20 November 2026, measured that morning.
Forecast sampleForecast({
  List<DailyForecast>? days,
  bool isDay = true,
  DateTime? observedAt,
}) => Forecast(
  current: CurrentConditions(
    observedAt: observedAt ?? DateTime(2026, 11, 20, 9),
    temperature: 35.8,
    feelsLike: 31.3,
    windSpeed: 4.4,
    condition: WeatherCondition.clear,
    isDay: isDay,
  ),
  days:
      days ??
      [
        for (var i = 0; i < 7; i++)
          DailyForecast(
            date: DateTime(2026, 11, 20 + i),
            low: 27.0 + i,
            high: 62.0 + i,
            condition: i == 2 ? WeatherCondition.rain : WeatherCondition.clear,
            precipitationChance: i == 2 ? 80 : 0,
          ),
      ],
);

DailyForecast day(
  int dayOfMonth,
  double low,
  double high, {
  int? chance,
  WeatherCondition condition = WeatherCondition.overcast,
}) => DailyForecast(
  date: DateTime(2026, 11, dayOfMonth),
  low: low,
  high: high,
  condition: condition,
  precipitationChance: chance,
);

/// A repository whose every answer the test decides.
///
/// Each call waits on a [Completer] the test completes, unless a ready answer
/// has been set with [placesToReturn] or [forecastToReturn].
class FakeWeatherRepository implements WeatherRepository {
  final searchQueries = <String>[];

  /// The newest unanswered search for each query.
  final searches = <String, Completer<List<Place>>>{};

  /// Every unanswered search, in the order they were sent.
  final searchCalls = <Completer<List<Place>>>[];
  final forecasts = <Completer<Forecast>>[];
  final forecastRequests = <(double, double, Units)>[];

  /// When set, searches answer with this at once.
  List<Place>? placesToReturn;

  /// When set, forecasts answer with this at once.
  Forecast? forecastToReturn;

  /// When set, both kinds of call fail with this at once.
  Exception? failure;

  @override
  Future<List<Place>> searchPlaces(String query) {
    searchQueries.add(query);
    if (failure case final failure?) return Future.error(failure);
    if (placesToReturn case final places?) return Future.value(places);
    final completer = Completer<List<Place>>();
    searches[query] = completer;
    searchCalls.add(completer);
    return completer.future;
  }

  @override
  Future<Forecast> forecast({
    required double latitude,
    required double longitude,
    required Units units,
  }) {
    forecastRequests.add((latitude, longitude, units));
    if (failure case final failure?) return Future.error(failure);
    if (forecastToReturn case final forecast?) return Future.value(forecast);
    final completer = Completer<Forecast>();
    forecasts.add(completer);
    return completer.future;
  }
}

/// Settings held in memory, starting from [units].
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([this.units]);

  @override
  Units? units;

  /// Every choice saved, in order.
  final saved = <Units>[];

  /// When set, saving fails with this.
  Exception? failure;

  @override
  Future<void> saveUnits(Units units) async {
    if (failure case final failure?) throw failure;
    saved.add(units);
    this.units = units;
  }
}

/// Stands in for a second language: English, but for the words the tests
/// look at.
class OtherWording extends AppLocalizationsEn {
  @override
  String get today => 'Heute';

  @override
  String get failureTimeout => 'Zu langsam.';

  @override
  String get failureNoConnection => 'Keine Verbindung.';
}
