import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/data/repositories/open_meteo_weather_repository.dart';
import 'package:flutter_weather/domain/models/units.dart';
import 'package:flutter_weather/domain/models/weather_condition.dart';
import 'package:flutter_weather/domain/repositories/weather_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

OpenMeteoWeatherRepository repositoryAnswering(
  Object? body, {
  int status = 200,
  void Function(Uri uri)? onRequest,
}) => OpenMeteoWeatherRepository(
  MockClient((request) async {
    onRequest?.call(request.url);
    return http.Response(
      body is String ? body : jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }),
);

Matcher failsWith(WeatherFailure failure) => throwsA(
  isA<WeatherException>().having((e) => e.failure, 'failure', failure),
);

const currentBody = {
  'time': '2026-11-18T09:00',
  'temperature_2m': 35.8,
  'apparent_temperature': 31.3,
  'weather_code': 0,
  'wind_speed_10m': 0.4,
  'is_day': 1,
};

const forecastBody = {
  'current': currentBody,
  'daily': {
    'time': ['2026-11-18', '2026-11-19', '2026-11-20'],
    'weather_code': [0, 3, 61],
    'temperature_2m_max': [62.6, 64.3, null],
    'temperature_2m_min': [27.0, 35.7, 40.1],
    'precipitation_probability_max': [0, 1, 80],
  },
};

void main() {
  group('searchPlaces', () {
    test('reads places and sends the query', () async {
      Uri? asked;
      final repository = repositoryAnswering({
        'results': [
          {
            'id': 4453066,
            'name': 'Asheville',
            'latitude': 35.60095,
            'longitude': -82.55402,
            'country': 'United States',
            'admin1': 'North Carolina',
          },
          {'name': 'Nowhere', 'latitude': 1, 'longitude': 2},
        ],
      }, onRequest: (uri) => asked = uri);

      final places = await repository.searchPlaces('ashev');

      expect(asked?.host, 'geocoding-api.open-meteo.com');
      expect(asked?.queryParameters['name'], 'ashev');
      expect(places, hasLength(2));
      expect(places.first.name, 'Asheville');
      expect(places.first.region, 'North Carolina');
      expect(places.first.country, 'United States');
      expect(places.first.longitude, -82.55402);
      expect((places.last.region, places.last.country), (null, null));
      expect(places.last.latitude, 1.0);
    });

    test('a response with no results key is an empty list', () async {
      final repository = repositoryAnswering({'generationtime_ms': 0.1});
      expect(await repository.searchPlaces('qqqqzzzz'), isEmpty);
    });

    test('results of the wrong shape are a bad response', () async {
      const bodies = [
        {'results': 'none'},
        {
          'results': [3],
        },
        {
          'results': [
            {'name': 'No coordinates'},
          ],
        },
        {
          'results': [
            {'name': 7, 'latitude': 1, 'longitude': 2},
          ],
        },
      ];
      for (final body in bodies) {
        await expectLater(
          repositoryAnswering(body).searchPlaces('ashev'),
          failsWith(WeatherFailure.badResponse),
          reason: '$body',
        );
      }
    });
  });

  group('forecast', () {
    test('turns the daily columns into one row per day', () async {
      Uri? asked;
      final repository = repositoryAnswering(
        forecastBody,
        onRequest: (uri) => asked = uri,
      );

      final forecast = await repository.forecast(
        latitude: 35.6,
        longitude: -82.55,
        units: Units.imperial,
      );

      expect(asked?.queryParameters['temperature_unit'], 'fahrenheit');
      expect(asked?.queryParameters['wind_speed_unit'], 'mph');
      expect(asked?.queryParameters['timezone'], 'auto');
      expect(forecast.current.observedAt, DateTime(2026, 11, 18, 9));
      expect(forecast.current.temperature, 35.8);
      expect(forecast.current.condition, WeatherCondition.clear);
      expect(forecast.current.isDay, isTrue);
      // The third day has no high, so it is left out.
      expect(forecast.days, hasLength(2));
      expect(forecast.days[1].date, DateTime(2026, 11, 19));
      expect(forecast.days[1].high, 64.3);
      expect(forecast.days[1].low, 35.7);
      expect(forecast.days[1].condition, WeatherCondition.overcast);
      expect(forecast.days[1].precipitationChance, 1);
    });

    test('asks in metric units when told to', () async {
      Uri? asked;
      await repositoryAnswering(
        forecastBody,
        onRequest: (uri) => asked = uri,
      ).forecast(latitude: 1, longitude: 2, units: Units.metric);

      expect(asked?.queryParameters['temperature_unit'], 'celsius');
      expect(asked?.queryParameters['wind_speed_unit'], 'kmh');
    });

    test("a refusal carries the service's reason as detail", () async {
      final repository = repositoryAnswering({
        'error': true,
        'reason': 'Latitude must be in range of -90 to 90°. Given: 999.0.',
      }, status: 400);

      await expectLater(
        repository.forecast(latitude: 999, longitude: 0, units: Units.metric),
        throwsA(
          isA<WeatherException>()
              .having((e) => e.failure, 'failure', WeatherFailure.rejected)
              .having((e) => e.detail, 'detail', contains('Latitude must be')),
        ),
      );
    });

    test('an error status with no reason to read is still a refusal', () async {
      for (final Object body in [
        <String, Object>{},
        '<html>Not found</html>',
      ]) {
        await expectLater(
          repositoryAnswering(body, status: 404).searchPlaces('ash'),
          throwsA(
            isA<WeatherException>()
                .having((e) => e.failure, 'failure', WeatherFailure.rejected)
                .having((e) => e.detail, 'detail', 'HTTP 404'),
          ),
          reason: '$body',
        );
      }
    });

    test("a server error or a full queue is the service's own trouble, "
        'whatever its body says', () async {
      const answers = <(int, Object)>[
        (503, '<html>Service unavailable</html>'),
        (502, {'error': true, 'reason': 'Upstream failed.'}),
        (429, {'error': true, 'reason': 'Minutely limit exceeded.'}),
      ];
      for (final (status, body) in answers) {
        await expectLater(
          repositoryAnswering(
            body,
            status: status,
          ).forecast(latitude: 1, longitude: 2, units: Units.metric),
          throwsA(
            isA<WeatherException>()
                .having((e) => e.failure, 'failure', WeatherFailure.unavailable)
                .having((e) => e.detail, 'detail', 'HTTP $status'),
          ),
          reason: '$status',
        );
      }
    });

    test('a body of the wrong shape is a bad response', () async {
      final bodies = <Object>[
        '<html>busy</html>',
        '[]',
        {'current': 3},
        {'current': currentBody},
        // Columns of different lengths.
        {
          'current': currentBody,
          'daily': {
            'time': ['2026-11-18'],
            'weather_code': <int>[],
            'temperature_2m_max': [1],
            'temperature_2m_min': [1],
          },
        },
        // A date that is not a date.
        {
          'current': currentBody,
          'daily': {
            'time': ['soon'],
            'weather_code': [0],
            'temperature_2m_max': [1],
            'temperature_2m_min': [1],
          },
        },
        // A temperature that is not a number.
        {
          'current': {...currentBody, 'temperature_2m': 'warm'},
          'daily': <String, Object>{},
        },
      ];
      for (final body in bodies) {
        await expectLater(
          repositoryAnswering(body)
              .forecast(latitude: 1, longitude: 2, units: Units.metric),
          failsWith(WeatherFailure.badResponse),
          reason: '$body',
        );
      }
    });

    test('a dropped connection is reported as no connection', () async {
      for (final Exception error in [
        http.ClientException('gone'),
        const FormatException('a failed handshake, say'),
      ]) {
        final repository = OpenMeteoWeatherRepository(
          MockClient((_) async => throw error),
        );
        await expectLater(
          repository.forecast(latitude: 1, longitude: 2, units: Units.metric),
          failsWith(WeatherFailure.noConnection),
        );
      }
    });

    test('an answer that never comes is a timeout', () {
      fakeAsync((async) {
        final repository = OpenMeteoWeatherRepository(
          MockClient((_) => Completer<http.Response>().future),
        );
        Object? error;
        unawaited(
          repository
              .forecast(latitude: 1, longitude: 2, units: Units.metric)
              .then<void>((_) {}, onError: (Object e) => error = e),
        );

        async.elapse(
          OpenMeteoWeatherRepository.defaultTimeout -
              const Duration(seconds: 1),
        );
        expect(error, isNull);

        async.elapse(const Duration(seconds: 1));
        expect(
          error,
          isA<WeatherException>().having(
            (e) => e.failure,
            'failure',
            WeatherFailure.timeout,
          ),
        );
      });
    });
  });
}
