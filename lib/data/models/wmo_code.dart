import '../../domain/models/weather_condition.dart';

/// What a WMO weather code, as Open-Meteo reports it, means.
///
/// The table is on https://open-meteo.com/en/docs under "WMO Weather
/// interpretation codes". A code outside it is [WeatherCondition.unknown].
WeatherCondition weatherConditionFromWmo(int? code) => switch (code) {
  0 => WeatherCondition.clear,
  1 => WeatherCondition.mostlyClear,
  2 => WeatherCondition.partlyCloudy,
  3 => WeatherCondition.overcast,
  45 || 48 => WeatherCondition.fog,
  51 || 53 || 55 => WeatherCondition.drizzle,
  56 || 57 => WeatherCondition.freezingDrizzle,
  61 || 63 || 65 => WeatherCondition.rain,
  66 || 67 => WeatherCondition.freezingRain,
  71 || 73 || 75 || 77 => WeatherCondition.snow,
  80 || 81 || 82 => WeatherCondition.rainShowers,
  85 || 86 => WeatherCondition.snowShowers,
  95 || 96 || 99 => WeatherCondition.thunderstorm,
  _ => WeatherCondition.unknown,
};
