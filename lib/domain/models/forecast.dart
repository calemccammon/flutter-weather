import 'package:meta/meta.dart';

import 'units.dart';
import 'weather_condition.dart';

/// The weather right now at a place.
@immutable
class CurrentConditions {
  const CurrentConditions({
    required this.observedAt,
    required this.temperature,
    required this.feelsLike,
    required this.windSpeed,
    required this.condition,
    required this.isDay,
  });

  /// When these conditions were measured, on the place's own clock. It says
  /// which calendar day is "today" there, whatever the device's clock says.
  final DateTime observedAt;
  final double temperature;
  final double feelsLike;
  final double windSpeed;
  final WeatherCondition condition;
  final bool isDay;
}

/// One day of the weekly forecast.
@immutable
class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.low,
    required this.high,
    required this.condition,
    this.precipitationChance,
  });

  /// The calendar day at the place, with no time or timezone attached.
  final DateTime date;
  final double low;
  final double high;
  final WeatherCondition condition;

  /// Highest chance of precipitation during the day, in percent.
  final int? precipitationChance;
}

/// Current conditions and the days ahead for one place.
///
/// A forecast is fetched and kept in metric units: degrees Celsius and
/// kilometres an hour. [inUnits] gives the same forecast in another system, so
/// changing units never needs the network.
@immutable
class Forecast {
  const Forecast({required this.current, required this.days});

  final CurrentConditions current;
  final List<DailyForecast> days;

  static const _milesPerKilometre = 0.621371;
  static const _fahrenheitPerCelsius = 1.8;
  static const _freezingFahrenheit = 32;

  static double _fahrenheit(double celsius) =>
      celsius * _fahrenheitPerCelsius + _freezingFahrenheit;

  /// This metric forecast with its temperatures and wind speed in [units].
  /// The chance of precipitation is a percentage, the same in both.
  Forecast inUnits(Units units) => switch (units) {
    Units.metric => this,
    Units.imperial => Forecast(
      current: CurrentConditions(
        observedAt: current.observedAt,
        temperature: _fahrenheit(current.temperature),
        feelsLike: _fahrenheit(current.feelsLike),
        windSpeed: current.windSpeed * _milesPerKilometre,
        condition: current.condition,
        isDay: current.isDay,
      ),
      days: [
        for (final day in days)
          DailyForecast(
            date: day.date,
            low: _fahrenheit(day.low),
            high: _fahrenheit(day.high),
            condition: day.condition,
            precipitationChance: day.precipitationChance,
          ),
      ],
    ),
  };

  /// Whether [day] is the day the current conditions were measured on.
  bool isToday(DailyForecast day) =>
      day.date.year == current.observedAt.year &&
      day.date.month == current.observedAt.month &&
      day.date.day == current.observedAt.day;
}
