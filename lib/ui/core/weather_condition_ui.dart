import 'package:material_ui/material_ui.dart';

import '../../domain/models/weather_condition.dart';
import 'l10n.dart';

/// How each weather condition is worded and drawn.
extension WeatherConditionUi on WeatherCondition {
  String label(AppLocalizations l10n) => switch (this) {
    WeatherCondition.clear => l10n.conditionClear,
    WeatherCondition.mostlyClear => l10n.conditionMostlyClear,
    WeatherCondition.partlyCloudy => l10n.conditionPartlyCloudy,
    WeatherCondition.overcast => l10n.conditionOvercast,
    WeatherCondition.fog => l10n.conditionFog,
    WeatherCondition.drizzle => l10n.conditionDrizzle,
    WeatherCondition.freezingDrizzle => l10n.conditionFreezingDrizzle,
    WeatherCondition.rain => l10n.conditionRain,
    WeatherCondition.freezingRain => l10n.conditionFreezingRain,
    WeatherCondition.snow => l10n.conditionSnow,
    WeatherCondition.rainShowers => l10n.conditionRainShowers,
    WeatherCondition.snowShowers => l10n.conditionSnowShowers,
    WeatherCondition.thunderstorm => l10n.conditionThunderstorm,
    WeatherCondition.unknown => l10n.conditionUnknown,
  };

  IconData icon({bool isDay = true}) => switch (this) {
    WeatherCondition.clear || WeatherCondition.mostlyClear =>
      isDay ? Icons.wb_sunny : Icons.nightlight_round,
    WeatherCondition.partlyCloudy =>
      isDay ? Icons.wb_cloudy : Icons.nights_stay,
    WeatherCondition.overcast => Icons.cloud,
    WeatherCondition.fog => Icons.foggy,
    WeatherCondition.drizzle || WeatherCondition.freezingDrizzle => Icons.grain,
    WeatherCondition.rain || WeatherCondition.freezingRain => Icons.water_drop,
    WeatherCondition.rainShowers => Icons.umbrella,
    WeatherCondition.snow || WeatherCondition.snowShowers => Icons.ac_unit,
    WeatherCondition.thunderstorm => Icons.thunderstorm,
    WeatherCondition.unknown => Icons.help_outline,
  };
}
