import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/di/providers.dart';
import 'package:flutter_weather/domain/models/units.dart';
import 'package:flutter_weather/domain/repositories/weather_repository.dart';
import 'package:flutter_weather/ui/core/l10n.dart';
import 'package:flutter_weather/ui/home/models/home_state.dart';
import 'package:flutter_weather/ui/home/models/place_ui_model.dart';
import 'package:flutter_weather/ui/home/models/units_ui_model.dart';
import 'package:flutter_weather/ui/home/view_models/home_view_model.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../support/fakes.dart';

/// The wording the app is using, so a test can change the language.
final wording = StateProvider<AppLocalizations>((ref) => en);

Future<void> main() async {
  await initializeDateFormatting();

  late FakeWeatherRepository repository;
  late FakeSettingsRepository settings;
  late ProviderContainer container;

  HomeState state() => container.read(homeViewModelProvider);
  HomeViewModel viewModel() => container.read(homeViewModelProvider.notifier);
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    repository = FakeWeatherRepository();
    settings = FakeSettingsRepository(Units.imperial);
    container = ProviderContainer.test(
      overrides: [
        weatherRepositoryProvider.overrideWithValue(repository),
        appLocalizationsProvider.overrideWith((ref) => ref.watch(wording)),
        settingsRepositoryProvider.overrideWithValue(settings),
        deviceCountryProvider.overrideWithValue('FR'),
      ],
    );
  });

  test('starts with no place and nothing to forecast', () {
    expect(state().place, isNull);
    expect(state().forecast, isA<ForecastIdle>());
  });

  test('selecting a place shows it at once, then its forecast', () async {
    viewModel().select(asheville);

    expect(state().place, PlaceUiModel.from(asheville));
    expect(state().forecast, isA<ForecastLoading>());
    expect(repository.forecastRequests, [(35.6, -82.55, Units.imperial)]);

    repository.forecasts.single.complete(sampleForecast());
    await settle();

    expect(
      state().forecast,
      isA<ForecastLoaded>().having(
        (s) => s.forecast.current.temperature,
        'temperature',
        '36°F',
      ),
    );
  });

  test('a point picked on the map is selected by its coordinates', () {
    viewModel().selectPoint(35.6, -82.55 + 360);

    expect(state().place?.title, '35.60°N, 82.55°W');
    expect(repository.forecastRequests.single.$2, closeTo(-82.55, 1e-9));
  });

  test('a failure says why, and trying again shows the wait before the '
      'forecast', () async {
    viewModel().select(asheville);
    repository.forecasts[0].completeError(
      const WeatherException(WeatherFailure.timeout),
    );
    await settle();

    expect(
      state().forecast,
      isA<ForecastFailed>().having(
        (s) => s.message,
        'message',
        en.failureTimeout,
      ),
    );

    viewModel().retryForecast();
    expect(state().forecast, isA<ForecastLoading>());
    expect(state().place, PlaceUiModel.from(asheville));

    repository.forecasts[1].complete(sampleForecast());
    await settle();
    expect(state().forecast, isA<ForecastLoaded>());
  });

  test('a failure nobody planned for still ends the wait', () async {
    viewModel().select(asheville);
    repository.forecasts.single.completeError(Exception('unplanned'));
    await settle();

    expect(
      state().forecast,
      isA<ForecastFailed>().having(
        (s) => s.message,
        'message',
        en.failureUnexpected,
      ),
    );
  });

  test('a place off the globe fails without asking the repository', () async {
    viewModel().selectPoint(123, 0);
    await settle();

    expect(
      state().forecast,
      isA<ForecastFailed>().having(
        (s) => s.message,
        'message',
        en.failureInvalidPlace,
      ),
    );
    expect(repository.forecastRequests, isEmpty);
  });

  test(
    "an earlier place's forecast does not replace a later place's",
    () async {
      viewModel().select(asheville);
      viewModel().select(ashford);

      // The later place answers first, the earlier one after it.
      repository.forecasts[1].complete(sampleForecast());
      await settle();
      repository.forecasts[0].completeError(
        const WeatherException(WeatherFailure.timeout),
      );
      await settle();

      expect(state().place, PlaceUiModel.from(ashford));
      expect(state().forecast, isA<ForecastLoaded>());
    },
  );

  test('clearing drops the place, and a late forecast does not bring it '
      'back', () async {
    viewModel().select(asheville);
    viewModel().clear();
    repository.forecasts.single.complete(sampleForecast());
    await settle();

    expect(state().place, isNull);
    expect(state().forecast, isA<ForecastIdle>());

    viewModel().retryForecast();
    expect(repository.forecasts, hasLength(1), reason: 'nothing to retry');
  });

  test('a change of language re-words what is on screen, without asking '
      'again', () async {
    viewModel().select(asheville);
    repository.forecasts.single.complete(sampleForecast());
    await settle();
    String firstDay() =>
        (state().forecast as ForecastLoaded).forecast.days.first.dayLabel;
    expect(firstDay(), 'Today');

    container.read(wording.notifier).state = OtherWording();
    expect(firstDay(), 'Heute');
    expect(repository.forecasts, hasLength(1));

    viewModel().retryForecast();
    repository.forecasts[1].completeError(
      const WeatherException(WeatherFailure.timeout),
    );
    await settle();
    container.read(wording.notifier).state = en;
    expect(
      state().forecast,
      isA<ForecastFailed>().having(
        (s) => s.message,
        'message',
        en.failureTimeout,
      ),
    );
  });

  group('units', () {
    test("start from the user's saved choice", () {
      expect(state().units, UnitsUiModel.fahrenheit);
    });

    test("start from the device's country when nothing is saved", () {
      settings.units = null;

      // The device is set to France.
      expect(state().units, UnitsUiModel.celsius);
    });

    test('changing them saves the choice and asks for the forecast again in '
        'the new ones', () async {
      viewModel().select(asheville);
      repository.forecasts[0].complete(sampleForecast());
      await settle();

      viewModel().setUnits(UnitsUiModel.celsius);

      expect(state().units, UnitsUiModel.celsius);
      expect(state().forecast, isA<ForecastLoading>());
      expect(repository.forecastRequests.last.$3, Units.metric);
      expect(settings.saved, [Units.metric]);

      repository.forecasts[1].complete(sampleForecast());
      await settle();
      expect(
        state().forecast,
        isA<ForecastLoaded>().having(
          (s) => s.forecast.current.temperature,
          'temperature',
          '36°C',
        ),
      );
    });

    test('choosing the units already in use does nothing', () async {
      viewModel().select(asheville);
      repository.forecasts.single.complete(sampleForecast());
      await settle();

      viewModel().setUnits(UnitsUiModel.fahrenheit);

      expect(state().forecast, isA<ForecastLoaded>());
      expect(repository.forecasts, hasLength(1));
      expect(settings.saved, isEmpty);
    });

    test('with no place selected, only the choice changes', () {
      viewModel().setUnits(UnitsUiModel.celsius);

      expect(state().units, UnitsUiModel.celsius);
      expect(state().forecast, isA<ForecastIdle>());
      expect(repository.forecastRequests, isEmpty);

      viewModel().select(asheville);
      expect(repository.forecastRequests.single.$3, Units.metric);
    });

    test('a choice that could not be saved still applies', () async {
      settings.failure = Exception('disk full');

      viewModel().setUnits(UnitsUiModel.celsius);
      await settle();

      expect(state().units, UnitsUiModel.celsius);
    });

    test('a forecast in the old units does not replace one in the '
        'new', () async {
      viewModel().select(asheville);
      viewModel().setUnits(UnitsUiModel.celsius);

      repository.forecasts[1].complete(sampleForecast());
      await settle();
      repository.forecasts[0].complete(sampleForecast());
      await settle();

      expect(
        state().forecast,
        isA<ForecastLoaded>().having(
          (s) => s.forecast.current.temperature,
          'temperature',
          '36°C',
        ),
      );
    });
  });
}
