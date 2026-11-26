import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/domain/models/forecast.dart';
import 'package:flutter_weather/domain/models/place.dart';
import 'package:flutter_weather/domain/models/units.dart';
import 'package:flutter_weather/domain/models/weather_condition.dart';

import '../support/fakes.dart';

void main() {
  group('Place', () {
    test('a point picked on the map has no name', () {
      expect(
        Place.fromCoordinates(35.6, -82.55),
        const Place(latitude: 35.6, longitude: -82.55),
      );
    });

    test('a point from a map dragged round the world keeps a real '
        'longitude', () {
      final place = Place.fromCoordinates(35.6, -82.55 + 360);

      expect(place.longitude, closeTo(-82.55, 1e-9));
      expect(Place.normalizeLongitude(180), -180);
      expect(Place.normalizeLongitude(-180), -180);
      expect(Place.normalizeLongitude(0), 0);
    });

    test('two places are the same only if every part matches', () {
      const springfieldIllinois = Place(
        name: 'Springfield',
        latitude: 39.8,
        longitude: -89.6,
        region: 'Illinois',
      );
      const sameSpot = Place(
        name: 'Springfield',
        latitude: 39.8,
        longitude: -89.6,
        region: 'Missouri',
      );

      expect(springfieldIllinois, isNot(sameSpot));
      expect(springfieldIllinois.hashCode, isNot(sameSpot.hashCode));
      expect(
        springfieldIllinois,
        const Place(
          name: 'Springfield',
          latitude: 39.8,
          longitude: -89.6,
          region: 'Illinois',
        ),
      );
    });
  });

  test('units follow the country', () {
    expect(Units.forCountry('US'), Units.imperial);
    expect(Units.forCountry('DE'), Units.metric);
    expect(Units.forCountry(null), Units.metric);
  });

  test("today is the day on the place's clock, not the first in the list", () {
    final forecast = sampleForecast(
      observedAt: DateTime(2026, 11, 21, 23, 30),
      days: [day(20, 1, 2), day(21, 1, 2), day(22, 1, 2)],
    );

    expect(forecast.days.map(forecast.isToday), [false, true, false]);
  });

  group('a forecast in other units', () {
    /// A metric forecast: [celsius] now and as both ends of one day, wind at
    /// [kmh], and a 40% chance of rain.
    Forecast metric(double celsius, {double kmh = 0}) => Forecast(
      current: CurrentConditions(
        observedAt: DateTime(2026, 11, 20, 9),
        temperature: celsius,
        feelsLike: celsius,
        windSpeed: kmh,
        condition: WeatherCondition.rain,
        isDay: false,
      ),
      days: [day(20, celsius, celsius, chance: 40)],
    );

    test('turns degrees Celsius into Fahrenheit', () {
      for (final (celsius, fahrenheit) in [
        (10.0, 50.0),
        (0.0, 32.0),
        (-40.0, -40.0),
        (37.0, 98.6),
      ]) {
        final imperial = metric(celsius).inUnits(Units.imperial);
        expect(imperial.current.temperature, closeTo(fahrenheit, 1e-9));
        expect(imperial.current.feelsLike, closeTo(fahrenheit, 1e-9));
        expect(imperial.days.single.low, closeTo(fahrenheit, 1e-9));
        expect(imperial.days.single.high, closeTo(fahrenheit, 1e-9));
      }
    });

    test('turns kilometres an hour into miles an hour', () {
      final imperial = metric(10, kmh: 20).inUnits(Units.imperial);
      expect(imperial.current.windSpeed, closeTo(12.42742, 1e-9));
    });

    test('keeps everything that is not a temperature or a speed', () {
      final before = metric(10, kmh: 20);
      final after = before.inUnits(Units.imperial);

      expect(after.current.observedAt, before.current.observedAt);
      expect(after.current.condition, WeatherCondition.rain);
      expect(after.current.isDay, isFalse);
      expect(after.days.single.date, before.days.single.date);
      expect(after.days.single.condition, before.days.single.condition);
      // A chance is a percentage in either system.
      expect(after.days.single.precipitationChance, 40);
    });

    test('in metric is the forecast as it is', () {
      final forecast = metric(10);
      expect(forecast.inUnits(Units.metric), same(forecast));
    });
  });
}
