import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/domain/models/units.dart';
import 'package:flutter_weather/domain/models/weather_condition.dart';
import 'package:flutter_weather/ui/core/weather_condition_ui.dart';
import 'package:flutter_weather/ui/home/models/forecast_ui_model.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../support/fakes.dart';

Future<void> main() async {
  await initializeDateFormatting();

  group('current conditions', () {
    test('are rounded, worded and marked with their scale', () {
      final imperial = CurrentUiModel.from(
        sampleForecast().current,
        Units.imperial,
        en,
      );

      expect(imperial.temperature, '36°F');
      expect(imperial.condition, 'Clear');
      expect(imperial.feelsLike, 'Feels like 31°');
      expect(imperial.wind, 'Wind 4 mph');
      expect(
        imperial.semanticLabel,
        'Now: Clear, 36 degrees Fahrenheit, feels like 31, wind 4 mph',
      );

      final metric = CurrentUiModel.from(
        sampleForecast().current,
        Units.metric,
        en,
      );
      expect(metric.temperature, '36°C');
      expect(metric.wind, 'Wind 4 km/h');
      expect(metric.semanticLabel, contains('36 degrees Celsius'));
    });

    test('use the night icon after dark', () {
      expect(
        CurrentUiModel.from(
          sampleForecast(isDay: false).current,
          Units.metric,
          en,
        ).icon,
        WeatherCondition.clear.icon(isDay: false),
      );
      expect(
        CurrentUiModel.from(sampleForecast().current, Units.metric, en).icon,
        WeatherCondition.clear.icon(),
      );
    });
  });

  group('the week', () {
    // Friday 20 November 2026, with a week running from 30 to 70 degrees.
    final model = ForecastUiModel.from(
      sampleForecast(
        days: [
          day(20, 30, 70),
          day(21, 40, 60, chance: 21, condition: WeatherCondition.rain),
          day(22, 50, 50, chance: 0),
          day(23, 70, 70),
        ],
      ),
      Units.imperial,
      en,
    );

    test("labels the place's own today, and the rest by weekday", () {
      expect(model.days.map((d) => d.dayLabel), ['Today', 'Sat', 'Sun', 'Mon']);
    });

    test('rounds temperatures and shows a chance only above zero', () {
      expect(model.days[1].low, '40°');
      expect(model.days[1].high, '60°');
      expect(model.days.map((d) => d.chance), ['', '21%', '', '']);
    });

    test("places each day's bar within the week's range", () {
      expect((model.days[0].barStart, model.days[0].barEnd), (0.0, 1.0));
      expect((model.days[1].barStart, model.days[1].barEnd), (0.25, 0.75));
      expect((model.days[2].barStart, model.days[2].barEnd), (0.5, 0.5));
      expect((model.days[3].barStart, model.days[3].barEnd), (1.0, 1.0));
    });

    test('reads each row out as a sentence', () {
      expect(
        model.days[0].semanticLabel,
        'Today: Overcast, low 30, high 70 degrees',
      );
      expect(
        model.days[1].semanticLabel,
        'Saturday: Rain, low 40, high 60 degrees, '
        '21 percent chance of precipitation',
      );
    });
  });

  test('when today is missing from the list, no other day is called Today', () {
    // Measured on the 20th, but the list starts on the 21st.
    final model = ForecastUiModel.from(
      sampleForecast(days: [day(21, 40, 60), day(22, 40, 60)]),
      Units.metric,
      en,
    );

    expect(model.days.map((d) => d.dayLabel), ['Sat', 'Sun']);
  });

  test('a week of one temperature fills every bar', () {
    final model = ForecastUiModel.from(
      sampleForecast(days: [day(20, 50, 50), day(21, 50, 50)]),
      Units.metric,
      en,
    );

    for (final d in model.days) {
      expect((d.barStart, d.barEnd), (0.0, 1.0));
    }
  });

  test('a forecast with no days has no rows', () {
    final model = ForecastUiModel.from(
      sampleForecast(days: const []),
      Units.metric,
      en,
    );
    expect(model.days, isEmpty);
  });
}
