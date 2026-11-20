import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../domain/models/forecast.dart';
import '../../../domain/models/units.dart';
import '../../core/l10n.dart';
import '../../core/weather_condition_ui.dart';

/// The forecast as the screen shows it: every value already rounded, worded
/// and laid out, so the widgets only place it.
@immutable
class ForecastUiModel {
  const ForecastUiModel({required this.current, required this.days});

  /// Translates a domain [Forecast] for display in [units], worded by [l10n].
  factory ForecastUiModel.from(
    Forecast forecast,
    Units units,
    AppLocalizations l10n,
  ) {
    final days = forecast.days;
    // The whole week's range, so each day's bar shows where it sits in it.
    final weekLow = days.isEmpty
        ? 0.0
        : days.map((d) => d.low).reduce((a, b) => a < b ? a : b);
    final weekHigh = days.isEmpty
        ? 0.0
        : days.map((d) => d.high).reduce((a, b) => a > b ? a : b);

    return ForecastUiModel(
      current: CurrentUiModel.from(forecast.current, units, l10n),
      days: [
        for (final day in days)
          DayUiModel.from(
            day,
            l10n,
            isToday: forecast.isToday(day),
            weekLow: weekLow,
            weekHigh: weekHigh,
          ),
      ],
    );
  }

  final CurrentUiModel current;
  final List<DayUiModel> days;
}

/// The "right now" block at the top of the forecast.
@immutable
class CurrentUiModel {
  const CurrentUiModel({
    required this.icon,
    required this.temperature,
    required this.condition,
    required this.feelsLike,
    required this.wind,
    required this.semanticLabel,
  });

  factory CurrentUiModel.from(
    CurrentConditions current,
    Units units,
    AppLocalizations l10n,
  ) {
    final temperature = current.temperature.round();
    final feelsLike = current.feelsLike.round();
    final wind = current.windSpeed.round();
    final (shown, spoken, speed) = switch (units) {
      Units.metric => (
        l10n.temperatureCelsius(temperature),
        l10n.spokenCelsius(temperature),
        l10n.speedKmh(wind),
      ),
      Units.imperial => (
        l10n.temperatureFahrenheit(temperature),
        l10n.spokenFahrenheit(temperature),
        l10n.speedMph(wind),
      ),
    };
    final condition = current.condition.label(l10n);

    return CurrentUiModel(
      icon: current.condition.icon(isDay: current.isDay),
      temperature: shown,
      condition: condition,
      feelsLike: l10n.feelsLike(feelsLike),
      wind: l10n.wind(speed),
      semanticLabel: l10n.currentSemantics(condition, spoken, feelsLike, speed),
    );
  }

  final IconData icon;

  /// "34°F". The one place the scale is spelled out; the rest of the forecast
  /// is in the same one.
  final String temperature;

  /// "Overcast".
  final String condition;

  /// "Feels like 28°".
  final String feelsLike;

  /// "Wind 2 mph".
  final String wind;

  /// The whole block as one sentence for a screen reader.
  final String semanticLabel;
}

/// One row of the week.
@immutable
class DayUiModel {
  const DayUiModel({
    required this.dayLabel,
    required this.icon,
    required this.chance,
    required this.low,
    required this.high,
    required this.barStart,
    required this.barEnd,
    required this.semanticLabel,
  });

  factory DayUiModel.from(
    DailyForecast day,
    AppLocalizations l10n, {
    required bool isToday,
    required double weekLow,
    required double weekHigh,
  }) {
    final low = day.low.round();
    final high = day.high.round();
    final chance = day.precipitationChance ?? 0;
    final span = weekHigh - weekLow;
    final locale = l10n.localeName;
    final dayName = isToday
        ? l10n.today
        : DateFormat.EEEE(locale).format(day.date);
    final condition = day.condition.label(l10n);

    return DayUiModel(
      dayLabel: isToday ? l10n.today : DateFormat.E(locale).format(day.date),
      icon: day.condition.icon(),
      chance: chance > 0 ? l10n.precipitationChance(chance) : '',
      low: l10n.temperature(low),
      high: l10n.temperature(high),
      // A week with one temperature throughout fills the whole bar.
      barStart: span <= 0 ? 0 : (day.low - weekLow) / span,
      barEnd: span <= 0 ? 1 : (day.high - weekLow) / span,
      semanticLabel: chance > 0
          ? l10n.daySemanticsWithChance(dayName, condition, low, high, chance)
          : l10n.daySemantics(dayName, condition, low, high),
    );
  }

  /// "Today" for the day the forecast was made on, otherwise a short weekday:
  /// "Sat".
  final String dayLabel;
  final IconData icon;

  /// "47%", or empty when there is no chance worth showing.
  final String chance;

  /// "30°".
  final String low;

  /// "68°".
  final String high;

  /// Where this day's low and high fall within the week's range, each from 0
  /// (the week's lowest) to 1 (its highest).
  final double barStart;
  final double barEnd;

  /// The whole row as one sentence for a screen reader.
  final String semanticLabel;
}
