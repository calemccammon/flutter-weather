import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/domain/models/place.dart';
import 'package:flutter_weather/domain/models/units.dart';

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
}
