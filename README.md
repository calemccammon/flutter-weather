# flutter-weather

A weather app in Flutter. One screen: a map with a Material 3 search bar over
it. Search for a place, or press and hold on the map, and the forecast for the
week appears.

**Live demo:** <https://calemccammon.github.io/flutter-weather/>

| Wide window | Phone |
| --- | --- |
| ![The app on a wide window: a side panel with the week's forecast beside the map](docs/screenshot-wide.png) | ![The app on a phone: the forecast in a bottom sheet over the map](docs/screenshot-phone.png) |

It is one of six cross-platform builds of the same app, written to compare
the frameworks. The others are
[kmp-weather](https://github.com/calemccammon/kmp-weather),
[react-native-weather](https://github.com/calemccammon/react-native-weather),
[maui-weather](https://github.com/calemccammon/maui-weather),
[ionic-weather](https://github.com/calemccammon/ionic-weather) and
[capacitor-weather](https://github.com/calemccammon/capacitor-weather).
[android-weather](https://github.com/calemccammon/android-weather) is the
native Android build in Kotlin and Jetpack Compose, which goes further with
saved places, offline forecasts and a home-screen widget.

## What it does

- **Search as you type**, debounced; a late response to an older query never
  overwrites a newer one.
- **Pick a point** by pressing and holding on the map.
- **Forecast**: current conditions, then seven days with the chance of
  precipitation and a bar placing each day's low and high within the week's
  range.
- **Adapts to the window**: a draggable bottom sheet on a phone, a side panel
  from 840 px wide. The map keeps the chosen place clear of both.
- **Celsius or Fahrenheit**, switched from the forecast and saved between
  launches. The default follows the device's region.
- **Light and dark** themes from one seed colour, following the system.
- **Accessible**: screen readers read each forecast block as one sentence,
  and the layout holds up to three times the default text size.
- **Errors**: a timeout, no connection, a refused request and an
  overloaded service each get their own message and a Try again button.

## Architecture

Clean Architecture in three layers. Dependencies point inward only: `data`
and `ui` import `domain`, and `domain` imports neither. `flutter test` fails
on an import that breaks this (`test/architecture_test.dart`).

| Path | What it holds |
| --- | --- |
| `lib/domain` | The app's own types (`Place`, `Forecast`, `WeatherCondition`, `Units`), the repository interfaces (`WeatherRepository` with its failure kinds, `SettingsRepository`), and the use cases (`SearchPlaces`, `GetForecast`, `GetUnits`, `SetUnits`) that hold the rules. Pure Dart. |
| `lib/data` | Open-Meteo: the wire-shaped models (`*_dto.dart`), their translation into domain types, and the repository implementation. Settings are kept with `shared_preferences`. |
| `lib/l10n` | All user-facing strings, in `app_en.arb`. `flutter gen-l10n` generates the typed `AppLocalizations` class from it on `flutter pub get` and on each build. |
| `lib/ui` | `core` has the theme, its design tokens and the mapping from domain values to wording and icons. `home` has `models` (what the screen shows, already worded and rounded), `view_models` (call use cases and produce those models) and `widgets` (render the models and never import the domain). |
| `lib/di` | The composition root: binds each repository interface to its implementation and supplies the use-case providers declared in `lib/ui/core/dependencies.dart`. Within `lib`, only `main.dart` imports it. |
| `test` | Mirrors `lib`, with shared fakes in `test/support`. |

Each layer has its own model, with a mapping between them:

| | Data | Domain | UI |
| --- | --- | --- | --- |
| Type | `ForecastDto` | `Forecast` | `ForecastUiModel` |
| A day's high | `temperature_2m_max[1] = 64.3` | `high: 64.3` | `high: "64°"`, `barEnd: 0.75` |
| Conditions | `weather_code: 3` | `WeatherCondition.overcast` | an icon and `"Overcast"` |
| A failure | HTTP 400, a timeout | `WeatherFailure.rejected` | `l10n.failureRejected`: "The weather service refused the request." |

State is held by two Riverpod `Notifier` view models, `HomeViewModel` and
`SearchViewModel`, each exposing one sealed state type.

## Running

Flutter 3.50.0 (stable). Targets: Android, Linux desktop, web, iOS.

```sh
flutter pub get
flutter run            # pick the emulator or a connected phone
flutter run -d linux   # desktop window
flutter run -d chrome  # web; needs CHROME_EXECUTABLE set to a Chromium browser
```

iOS builds need a Mac and have not been run.

## Checks

```sh
flutter analyze        # rules in analysis_options.yaml; any finding fails CI
dart format .          # CI checks formatting too
flutter test
```

`.github/workflows/ci.yml` runs these on pushes to `main` and on pull
requests, then builds a debug APK, a web build and a Linux desktop bundle,
each uploaded as a workflow artifact.

`.github/workflows/pages.yml` builds the web app and publishes the live
demo. It runs only when started by hand from the Actions tab.

## Data and credits

- Place search and forecasts: [Open-Meteo](https://open-meteo.com/) (no key;
  free for non-commercial use; CC BY 4.0).
- Map: © [OpenStreetMap](https://www.openstreetmap.org/copyright)
  contributors, drawn with [`flutter_map`](https://pub.dev/packages/flutter_map).

## Known limits

- **Map tiles** come from OpenStreetMap's own servers, which are for
  development and light use only
  ([tile usage policy](https://operations.osmfoundation.org/policies/tiles/)).
  The live demo uses them too; anything with real traffic would need its own
  tile provider.
- **English only.** All strings are in `lib/l10n/app_en.arb` and weekday
  names follow the app's locale, so adding a language means adding one
  `.arb` file.
- **Places are not saved**: the chosen place is forgotten when the app
  closes. Only the choice of units is kept.

## Not built

Ideas that were considered and left out, roughly in the order they would be
worth doing:

- **Saved places** shown when the app opens.
- **Forecast for the current location**, which needs the location permission
  on each platform.
- **A second language**, to exercise the localisation set-up.
- **Rain radar** as a layer over the map.
- **A signed release build** from CI.
