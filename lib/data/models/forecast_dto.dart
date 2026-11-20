import '../../domain/models/forecast.dart';
import 'json_reading.dart';
import 'wmo_code.dart';

/// The forecast response as Open-Meteo sends it: one `current` object and a
/// `daily` object of parallel columns.
class ForecastDto {
  const ForecastDto({required this.current, required this.daily});

  /// Throws a [FormatException] if [json] is not shaped like a forecast.
  factory ForecastDto.fromJson(Map<String, dynamic> json) => ForecastDto(
    current: CurrentDto.fromJson(readObject(json['current'], 'current')),
    daily: DailyDto.fromJson(readObject(json['daily'], 'daily')),
  );

  final CurrentDto current;
  final DailyDto daily;

  /// Translates the wire shape into what the app works with: codes become
  /// conditions, columns become one entry per day, and a day the weather
  /// model has no temperatures for is left out.
  ///
  /// Throws a [FormatException] if a date or time is not ISO 8601.
  Forecast toDomain() => Forecast(
    current: CurrentConditions(
      observedAt: DateTime.parse(current.time),
      temperature: current.temperature.toDouble(),
      feelsLike: current.apparentTemperature.toDouble(),
      windSpeed: current.windSpeed.toDouble(),
      condition: weatherConditionFromWmo(current.weatherCode.toInt()),
      isDay: current.isDay == 1,
    ),
    days: [
      for (var i = 0; i < daily.time.length; i++)
        if (daily.temperatureMax[i] != null && daily.temperatureMin[i] != null)
          DailyForecast(
            date: DateTime.parse(daily.time[i]),
            high: daily.temperatureMax[i]!.toDouble(),
            low: daily.temperatureMin[i]!.toDouble(),
            condition: weatherConditionFromWmo(daily.weatherCode[i]?.toInt()),
            precipitationChance: daily.precipitationProbabilityMax?[i]?.round(),
          ),
    ],
  );
}

/// The response's `current` object.
class CurrentDto {
  const CurrentDto({
    required this.time,
    required this.temperature,
    required this.apparentTemperature,
    required this.weatherCode,
    required this.windSpeed,
    required this.isDay,
  });

  factory CurrentDto.fromJson(Map<String, dynamic> json) => CurrentDto(
    time: readValue<String>(json, 'time'),
    temperature: readValue<num>(json, 'temperature_2m'),
    apparentTemperature: readValue<num>(json, 'apparent_temperature'),
    weatherCode: readValue<num>(json, 'weather_code'),
    windSpeed: readValue<num>(json, 'wind_speed_10m'),
    isDay: readValue<num>(json, 'is_day'),
  );

  /// ISO date and time, local to the place: `2026-11-18T09:00`.
  final String time;
  final num temperature;
  final num apparentTemperature;
  final num weatherCode;
  final num windSpeed;

  /// 1 in daylight, 0 at night.
  final num isDay;
}

/// The response's `daily` object: a list of dates and one list per variable,
/// all the same length. A value the weather model lacks is null.
class DailyDto {
  DailyDto({
    required this.time,
    required this.weatherCode,
    required this.temperatureMax,
    required this.temperatureMin,
    this.precipitationProbabilityMax,
  }) {
    final columns = [
      weatherCode,
      temperatureMax,
      temperatureMin,
      ?precipitationProbabilityMax,
    ];
    if (columns.any((column) => column.length != time.length)) {
      throw const FormatException('daily columns differ in length');
    }
  }

  factory DailyDto.fromJson(Map<String, dynamic> json) {
    final chances = json['precipitation_probability_max'];
    return DailyDto(
      time: readList<String>(json['time'], 'daily.time'),
      weatherCode: readList<num?>(json['weather_code'], 'weather_code'),
      temperatureMax: readList<num?>(json['temperature_2m_max'], 'max'),
      temperatureMin: readList<num?>(json['temperature_2m_min'], 'min'),
      precipitationProbabilityMax: chances == null
          ? null
          : readList<num?>(chances, 'precipitation_probability_max'),
    );
  }

  /// ISO dates, local to the place: `2026-11-18`.
  final List<String> time;
  final List<num?> weatherCode;
  final List<num?> temperatureMax;
  final List<num?> temperatureMin;
  final List<num?>? precipitationProbabilityMax;
}
