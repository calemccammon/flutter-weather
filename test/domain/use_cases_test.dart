import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/domain/models/place.dart';
import 'package:flutter_weather/domain/models/units.dart';
import 'package:flutter_weather/domain/repositories/weather_repository.dart';
import 'package:flutter_weather/domain/use_cases/get_forecast.dart';
import 'package:flutter_weather/domain/use_cases/get_units.dart';
import 'package:flutter_weather/domain/use_cases/search_places.dart';
import 'package:flutter_weather/domain/use_cases/set_units.dart';

import '../support/fakes.dart';

void main() {
  late FakeWeatherRepository repository;

  setUp(() {
    repository = FakeWeatherRepository()
      ..placesToReturn = const [asheville]
      ..forecastToReturn = sampleForecast();
  });

  group('SearchPlaces', () {
    test('trims the query before asking', () async {
      final places = await SearchPlaces(repository)('  ashev ');

      expect(repository.searchQueries, ['ashev']);
      expect(places, [asheville]);
    });

    test('does not ask for a query that is too short', () async {
      final search = SearchPlaces(repository);

      expect(await search(''), isEmpty);
      expect(await search(' a '), isEmpty);
      expect(repository.searchQueries, isEmpty);
      expect(SearchPlaces.isSearchable('ab'), isTrue);
      expect(SearchPlaces.isSearchable(' a '), isFalse);
    });
  });

  group('GetForecast', () {
    test("asks for the place's point", () async {
      await GetForecast(repository)(asheville);
      expect(repository.forecastRequests, [(35.6, -82.55)]);
    });

    test('brings a longitude from a wrapped map back into range', () async {
      final getForecast = GetForecast(repository);

      // Tokyo, reached by dragging the map a full turn east and west.
      for (final turn in [360.0, -360.0]) {
        await getForecast(
          Place(name: 'Tokyo', latitude: 35.68, longitude: 139.69 + turn),
        );
      }

      for (final (_, longitude) in repository.forecastRequests) {
        expect(longitude, closeTo(139.69, 1e-9));
      }
    });

    test('refuses a point off the globe without asking', () async {
      const offTheGlobe = [
        Place(name: 'too far north', latitude: 91, longitude: 0),
        Place(name: 'no latitude', latitude: double.nan, longitude: 0),
        Place(name: 'no longitude', latitude: 0, longitude: double.infinity),
      ];
      for (final place in offTheGlobe) {
        await expectLater(
          GetForecast(repository)(place),
          throwsA(
            isA<WeatherException>().having(
              (e) => e.failure,
              'failure',
              WeatherFailure.invalidPlace,
            ),
          ),
          reason: place.name,
        );
      }
      expect(repository.forecastRequests, isEmpty);
    });
  });

  group('GetUnits', () {
    test("follows the device's country until the user chooses", () {
      final getUnits = GetUnits(FakeSettingsRepository());

      expect(getUnits(deviceCountry: 'US'), Units.imperial);
      expect(getUnits(deviceCountry: 'FR'), Units.metric);
      expect(getUnits(), Units.metric);
    });

    test("puts the user's choice before the device's country", () {
      final getUnits = GetUnits(FakeSettingsRepository(Units.metric));

      expect(getUnits(deviceCountry: 'US'), Units.metric);
    });
  });

  test('SetUnits saves the choice, which GetUnits then returns', () async {
    final settings = FakeSettingsRepository();

    await SetUnits(settings)(Units.imperial);

    expect(settings.saved, [Units.imperial]);
    expect(GetUnits(settings)(deviceCountry: 'FR'), Units.imperial);
  });
}
