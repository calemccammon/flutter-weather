# flutter-weather

A weather app in Flutter: search for a place, see its forecast. One of three
builds of the same app, alongside
[kmp-weather](https://github.com/calemccammon/kmp-weather) and
[react-native-weather](https://github.com/calemccammon/react-native-weather),
to compare the frameworks.

The repository holds the project set-up only. `lib/main.dart` is the
`flutter create --empty` starter; the app is still to be written. The work is
laid out as [milestones](../../milestones) and [issues](../../issues).

## Data

- Place search and forecasts: [Open-Meteo](https://open-meteo.com/) (no key;
  free for non-commercial use; CC BY 4.0, attribution required).
- Map tiles (map milestone): [OpenFreeMap](https://openfreemap.org/) styles
  over OpenStreetMap data, drawn with MapLibre. No key.

## Libraries already added

| Purpose | Package |
| --- | --- |
| HTTP | `http` |
| State | `flutter_riverpod` |
| Navigation | `go_router` |
| JSON models | `json_annotation`, `json_serializable`, `build_runner` |
| Saved places and settings | `shared_preferences` |
| Device location | `geolocator` |
| Map | `maplibre_gl` |
| Dates and numbers | `intl` |
| Test fakes | `mocktail` |

Any of these can be swapped; nothing depends on them yet.

## Running

Flutter 3.50.0 (stable). Targets: Android, iOS, web.

```sh
flutter pub get
flutter run            # pick the emulator or a connected phone
flutter analyze
flutter test
```

Start the emulator first with `emulator -avd Pixel_API_36`, or from Android
Studio's Device Manager. iOS builds need a Mac.

## CI

`.github/workflows/ci.yml` runs on pushes to `main` and on pull requests:
format check, `flutter analyze`, tests (once a `test/` folder exists), then a
debug APK uploaded as a workflow artifact.
