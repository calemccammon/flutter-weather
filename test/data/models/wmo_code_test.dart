import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/data/models/wmo_code.dart';
import 'package:flutter_weather/domain/models/weather_condition.dart';

void main() {
  test('every WMO code Open-Meteo documents has a meaning', () {
    const documented = [
      0, 1, 2, 3, 45, 48, 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, //
      71, 73, 75, 77, 80, 81, 82, 85, 86, 95, 96, 99,
    ];
    for (final code in documented) {
      expect(
        weatherConditionFromWmo(code),
        isNot(WeatherCondition.unknown),
        reason: 'code $code',
      );
    }
  });

  test('a code outside the table, or none, is unknown and not a crash', () {
    expect(weatherConditionFromWmo(4), WeatherCondition.unknown);
    expect(weatherConditionFromWmo(-1), WeatherCondition.unknown);
    expect(weatherConditionFromWmo(null), WeatherCondition.unknown);
  });
}
