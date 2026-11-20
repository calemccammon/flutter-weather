import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/app.dart';
import 'package:flutter_weather/di/providers.dart';
import 'package:flutter_weather/domain/models/units.dart';
import 'package:flutter_weather/domain/repositories/weather_repository.dart';
import 'package:flutter_weather/ui/home/view_models/home_view_model.dart';
import 'package:flutter_weather/ui/home/view_models/search_view_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/fakes.dart';

const desktop = Size(1200, 900);
const phone = Size(400, 800);

/// Starts the app over a repository that answers at once, unless the test
/// clears `placesToReturn` or `forecastToReturn` to answer by hand.
Future<FakeWeatherRepository> pumpApp(
  WidgetTester tester, {
  Size size = desktop,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);

  final settings = FakeSettingsRepository(Units.imperial);
  final repository = FakeWeatherRepository()
    ..placesToReturn = const [asheville]
    ..forecastToReturn = sampleForecast();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        weatherRepositoryProvider.overrideWithValue(repository),
        mapTileUrlProvider.overrideWithValue(null),
        settingsRepositoryProvider.overrideWithValue(settings),
      ],
      child: const WeatherApp(),
    ),
  );
  return repository;
}

HomeViewModel homeViewModel(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(WeatherApp)))
        .read(homeViewModelProvider.notifier);

/// Opens the search view and types [text], waiting out the typing pause.
Future<void> searchFor(WidgetTester tester, String text) async {
  await tester.tap(find.byType(SearchBar));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).last, text);
  await tester.pump(SearchViewModel.debounce);
  await tester.pumpAndSettle();
}

final hint = find.textContaining('Search for a place, or press');
final inSearchBar = find.byType(SearchBar);

void main() {
  testWidgets('starts with a hint and no forecast', (tester) async {
    await pumpApp(tester);

    expect(hint, findsOneWidget);
    expect(find.text('This week'), findsNothing);
  });

  group('search', () {
    testWidgets('searching and choosing a place shows its week', (
      tester,
    ) async {
      await pumpApp(tester);

      await searchFor(tester, 'ashev');
      await tester.tap(find.text('North Carolina, United States'));
      await tester.pumpAndSettle();

      expect(find.text('This week'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('36°F'), findsOneWidget);
      expect(find.text('Feels like 31°'), findsOneWidget);
      expect(find.text('Wind 4 mph'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('Weather data by Open-Meteo.com'), findsOneWidget);
      expect(
        find.descendant(of: inSearchBar, matching: find.text('Asheville')),
        findsOneWidget,
      );
    });

    testWidgets('no matches says so', (tester) async {
      final repository = await pumpApp(tester);
      repository.placesToReturn = const [];

      await searchFor(tester, 'zzzz');

      expect(find.text('Nothing found for "zzzz"'), findsOneWidget);
    });

    testWidgets('a failure offers another try, which works', (tester) async {
      final repository = await pumpApp(tester);
      repository.failure = const WeatherException(WeatherFailure.noConnection);

      await searchFor(tester, 'ashev');
      expect(find.text(en.failureNoConnection), findsOneWidget);

      repository.failure = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('North Carolina, United States'), findsOneWidget);
    });

    testWidgets('opening search on a place picked from the map does not '
        'search for its coordinates', (tester) async {
      final repository = await pumpApp(tester);
      homeViewModel(tester).selectPoint(35.6, -82.55);
      await tester.pumpAndSettle();

      await tester.tap(inSearchBar);
      await tester.pumpAndSettle();

      expect(find.text('Type a city, town or postcode'), findsOneWidget);
      expect(repository.searchQueries, isEmpty);
    });
  });

  group('forecast', () {
    testWidgets('a failure offers another try, which shows it is working '
        'and then the week', (tester) async {
      final repository = await pumpApp(tester);
      repository.failure = const WeatherException(WeatherFailure.timeout);
      homeViewModel(tester).select(asheville);
      await tester.pumpAndSettle();

      expect(find.text(en.failureTimeout), findsOneWidget);
      expect(find.text('This week'), findsNothing);

      // The second answer is held back, as on a slow connection.
      repository
        ..failure = null
        ..forecastToReturn = null;
      await tester.tap(find.text('Try again'));
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text(en.failureTimeout), findsNothing);

      repository.forecasts.single.complete(sampleForecast());
      await tester.pumpAndSettle();

      expect(find.text('This week'), findsOneWidget);
    });

    testWidgets('clearing the place brings the hint back', (tester) async {
      await pumpApp(tester);
      homeViewModel(tester).select(asheville);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Clear place'));
      await tester.pumpAndSettle();

      expect(hint, findsOneWidget);
      expect(find.text('This week'), findsNothing);
    });
  });

  testWidgets('choosing Celsius shows the forecast in Celsius and '
      'remembers the choice', (tester) async {
    final repository = await pumpApp(tester);
    homeViewModel(tester).select(asheville);
    await tester.pumpAndSettle();
    expect(find.text('36°F'), findsOneWidget);

    await tester.tap(find.text('°C'));
    await tester.pumpAndSettle();

    expect(find.text('36°C'), findsOneWidget);
    expect(find.text('Wind 4 km/h'), findsOneWidget);
    expect(repository.forecastRequests.last.$3, Units.metric);
    final settings = ProviderScope.containerOf(
      tester.element(find.byType(WeatherApp)),
    ).read(settingsRepositoryProvider);
    expect(settings.units, Units.metric);
  });

  group('map', () {
    testWidgets('pressing and holding picks the point under the finger', (
      tester,
    ) async {
      final repository = await pumpApp(tester);

      // The middle of the window, which starts at 25°N on the prime meridian.
      await tester.longPressAt(desktop.center(Offset.zero));
      await tester.pumpAndSettle();

      final (latitude, longitude, _) = repository.forecastRequests.single;
      expect(latitude, closeTo(25, 1));
      expect(longitude, closeTo(0, 1));
      expect(find.text('This week'), findsOneWidget);
      expect(
        find.descendant(of: inSearchBar, matching: find.textContaining('°N')),
        findsOneWidget,
      );
    });

    for (final (name, size) in [('wide', desktop), ('phone', phone)]) {
      testWidgets('choosing a place puts its pin clear of the forecast on a '
          '$name window', (tester) async {
        await pumpApp(tester, size: size);
        homeViewModel(tester).select(asheville);
        await tester.pumpAndSettle();

        final camera = tester
            .widget<FlutterMap>(find.byType(FlutterMap))
            .mapController!
            .camera;
        final pin = camera.latLngToScreenOffset(
          LatLng(asheville.latitude, asheville.longitude),
        );
        // The scrolling area that holds the forecast, in either layout.
        final forecast = tester.getRect(
          find.ancestor(of: find.text('36°F'), matching: find.byType(ListView)),
        );

        expect(camera.zoom, greaterThanOrEqualTo(10));
        expect(forecast.contains(pin), isFalse, reason: 'pin at $pin');
        expect((Offset.zero & size).contains(pin), isTrue);
      });
    }
  });

  testWidgets('the pin stays clear of the forecast when a wide window is '
      'narrowed to a phone', (tester) async {
    await pumpApp(tester);
    homeViewModel(tester).select(asheville);
    await tester.pumpAndSettle();

    tester.view.physicalSize = phone;
    await tester.pumpAndSettle();

    final pin = tester
        .widget<FlutterMap>(find.byType(FlutterMap))
        .mapController!
        .camera
        .latLngToScreenOffset(LatLng(asheville.latitude, asheville.longitude));
    final sheet = tester.getRect(
      find.ancestor(of: find.text('36°F'), matching: find.byType(ListView)),
    );

    expect(pin.dx, closeTo(phone.width / 2, 1));
    expect(pin.dy, lessThan(sheet.top));
    expect(pin.dy, greaterThan(0));
  });

  group('layout', () {
    testWidgets('a phone-sized window shows the forecast in a bottom sheet', (
      tester,
    ) async {
      await pumpApp(tester, size: phone);
      homeViewModel(tester).select(asheville);
      await tester.pumpAndSettle();

      final inSheet = find.byType(DraggableScrollableSheet);
      expect(
        find.descendant(of: inSheet, matching: find.text('36°F')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: inSheet, matching: find.text('Asheville')),
        findsOneWidget,
      );
    });

    testWidgets('a wide window shows it in a side panel, with no sheet', (
      tester,
    ) async {
      await pumpApp(tester);
      homeViewModel(tester).select(asheville);
      await tester.pumpAndSettle();

      expect(find.byType(DraggableScrollableSheet), findsNothing);
      expect(find.text('This week'), findsOneWidget);
    });

    testWidgets('the search bar keeps the place name when the window '
        'narrows', (tester) async {
      await pumpApp(tester);
      homeViewModel(tester).select(asheville);
      await tester.pumpAndSettle();

      tester.view.physicalSize = phone;
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: inSearchBar, matching: find.text('Asheville')),
        findsOneWidget,
      );
    });

    // Nothing may overflow or throw, however small the window or large the
    // text. 3 is beyond what Android and iOS offer.
    for (final size in [const Size(320, 640), phone, desktop]) {
      for (final textScale in [1.0, 1.5, 2.0, 3.0]) {
        testWidgets('the forecast fits a ${size.width.round()}-wide window at '
            '$textScale times text size', (tester) async {
          final repository = await pumpApp(
            tester,
            size: size,
            textScale: textScale,
          );
          // Three-figure temperatures and a certain chance: the widest row.
          repository.forecastToReturn = sampleForecast(
            days: [
              for (var i = 0; i < 7; i++)
                day(20 + i, -104.0 - i, 104.0 + i, chance: 100),
            ],
          );
          homeViewModel(tester).select(asheville);
          await tester.pumpAndSettle();

          // Pull the sheet right up so every row is laid out.
          if (size.width < 840) {
            await tester.dragFrom(
              Offset(size.width / 2, size.height * 0.75),
              Offset(0, -size.height * 0.6),
            );
            await tester.pumpAndSettle();
          }

          // Scroll every row through view, a little at a time, so each one
          // is laid out.
          final list = find.descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          );
          await tester.scrollUntilVisible(
            find.text('Today'),
            60,
            scrollable: list,
          );
          expect(tester.takeException(), isNull);
          await tester.scrollUntilVisible(
            find.text('Weather data by Open-Meteo.com'),
            60,
            scrollable: list,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
