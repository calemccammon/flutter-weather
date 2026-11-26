import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/forecast.dart';
import '../../domain/models/place.dart';
import '../../domain/repositories/weather_repository.dart';
import '../models/forecast_dto.dart';
import '../models/json_reading.dart';
import '../models/place_dto.dart';

/// Places and forecasts from Open-Meteo. No API key is needed.
///
/// Asks the service, reads its answers into the wire-shaped models in
/// `data/models`, and hands back domain models. Every way this can go wrong
/// leaves as a [WeatherException].
///
/// Docs: https://open-meteo.com/en/docs and
/// https://open-meteo.com/en/docs/geocoding-api
class OpenMeteoWeatherRepository implements WeatherRepository {
  OpenMeteoWeatherRepository(this._client, {this.timeout = defaultTimeout});

  final http.Client _client;

  /// How long to wait for an answer before giving up.
  final Duration timeout;

  static const defaultTimeout = Duration(seconds: 15);
  static const _geocodingHost = 'geocoding-api.open-meteo.com';
  static const _forecastHost = 'api.open-meteo.com';

  @override
  Future<List<Place>> searchPlaces(String query) async {
    final body = await _get(
      Uri.https(_geocodingHost, '/v1/search', {
        'name': query,
        'count': '8',
        'language': 'en',
        'format': 'json',
      }),
    );
    return _read(() {
      // With no matches the `results` key is missing altogether.
      final results = body['results'];
      if (results == null) return const [];
      return [
        for (final result in readList<Object?>(results, 'results'))
          PlaceDto.fromJson(result).toDomain(),
      ];
    });
  }

  @override
  Future<Forecast> forecast({
    required double latitude,
    required double longitude,
  }) async {
    final body = await _get(
      Uri.https(_forecastHost, '/v1/forecast', {
        'latitude': '$latitude',
        'longitude': '$longitude',
        'current':
            'temperature_2m,apparent_temperature,weather_code,'
            'wind_speed_10m,is_day',
        'daily':
            'weather_code,temperature_2m_max,temperature_2m_min,'
            'precipitation_probability_max',
        'forecast_days': '7',
        'timezone': 'auto',
        // Always metric, as the domain's Forecast is; the app converts on the
        // device, so changing units needs no request.
        'temperature_unit': 'celsius',
        'wind_speed_unit': 'kmh',
      }),
    );
    return _read(() => ForecastDto.fromJson(body).toDomain());
  }

  /// Runs [parse], reporting a response of the wrong shape as a bad response.
  T _read<T>(T Function() parse) {
    try {
      return parse();
    } on FormatException catch (e) {
      throw WeatherException(WeatherFailure.badResponse, detail: e.message);
    }
  }

  /// HTTP statuses this repository tells apart.
  static const _ok = 200;
  static const _tooManyRequests = 429;
  static const _firstServerError = 500;

  Future<Map<String, dynamic>> _get(Uri uri) async {
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const WeatherException(WeatherFailure.timeout);
    } on Exception catch (e) {
      // A dropped socket, a failed TLS handshake, a refused connection.
      throw WeatherException(WeatherFailure.noConnection, detail: '$e');
    }

    final status = response.statusCode;
    // The service's own trouble, or too many requests: its answer, often a
    // proxy's error page, is not read at all.
    if (status >= _firstServerError || status == _tooManyRequests) {
      throw WeatherException(
        WeatherFailure.unavailable,
        detail: 'HTTP $status',
      );
    }

    Map<String, dynamic>? body;
    try {
      body = readObject(jsonDecode(response.body), 'response');
    } on FormatException catch (e) {
      if (status == _ok) {
        throw WeatherException(WeatherFailure.badResponse, detail: e.message);
      }
    }
    // Bad input comes back as HTTP 400 with {"error": true, "reason": "..."}.
    if (status != _ok || body == null || body['error'] == true) {
      final reason = body?['reason'];
      throw WeatherException(
        WeatherFailure.rejected,
        detail: reason is String ? reason : 'HTTP $status',
      );
    }
    return body;
  }
}
