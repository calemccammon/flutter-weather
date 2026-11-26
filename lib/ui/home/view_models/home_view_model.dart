import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/forecast.dart';
import '../../../domain/models/place.dart';
import '../../../domain/models/units.dart';
import '../../core/dependencies.dart';
import '../../core/failure_messages.dart';
import '../../core/l10n.dart';
import '../models/forecast_ui_model.dart';
import '../models/home_state.dart';
import '../models/place_ui_model.dart';
import '../models/units_ui_model.dart';

/// Holds the selected place and the chosen units, and loads the forecast.
///
/// Selecting a place while an earlier forecast is still on its way throws the
/// earlier answer away when it arrives.
class HomeViewModel extends Notifier<HomeState> {
  Place? _place;
  late Units _units;

  /// How the newest forecast request ended, or null while it is under way.
  _Outcome? _outcome;

  /// Counts forecast requests, so an answer can tell whether it is still the
  /// newest one.
  int _request = 0;

  @override
  HomeState build() {
    // The state holds finished wording, so it is worded again when the
    // device's language changes.
    ref.listen(appLocalizationsProvider, (_, _) => _show());
    _units = ref.read(getUnitsProvider)(
      deviceCountry: ref.read(deviceCountryProvider),
    );
    return HomeState(units: UnitsUiModel.from(_units));
  }

  /// Makes [place] the selected place and loads its forecast.
  void select(Place place) {
    _place = place;
    unawaited(_load());
  }

  /// Selects a point picked straight off the map.
  void selectPoint(double latitude, double longitude) =>
      select(Place.fromCoordinates(latitude, longitude));

  void clear() {
    _place = null;
    _outcome = null;
    _request++;
    _show();
  }

  /// Shows forecasts in [units] from now on, and remembers the choice. The
  /// forecast already held is converted on the device, not asked for again.
  void setUnits(UnitsUiModel units) {
    final chosen = units.toDomain();
    if (chosen == _units) return;
    _units = chosen;
    unawaited(_saveUnits(chosen));
    _show();
  }

  Future<void> _saveUnits(Units units) async {
    try {
      await ref.read(setUnitsProvider)(units);
    } on Exception {
      // Not saved, so the next launch starts from the old choice; this one
      // carries on with the new.
    }
  }

  /// Asks for the selected place's forecast again, after a failure.
  void retryForecast() {
    if (_place != null) unawaited(_load());
  }

  Future<void> _load() async {
    final place = _place;
    if (place == null) return;
    final request = ++_request;
    _outcome = null;
    _show();

    _Outcome outcome;
    try {
      outcome = _Loaded(await ref.read(getForecastProvider)(place));
    } on Exception catch (e) {
      outcome = _Failed(e);
    }
    if (ref.mounted && request == _request) {
      _outcome = outcome;
      _show();
    }
  }

  /// Puts the place and the request's outcome on screen, in the app's
  /// current wording.
  void _show() {
    final place = _place;
    final units = _units;
    if (place == null) {
      state = HomeState(units: UnitsUiModel.from(units));
      return;
    }
    final l10n = ref.read(appLocalizationsProvider);
    state = HomeState(
      units: UnitsUiModel.from(units),
      place: PlaceUiModel.from(place, l10n),
      forecast: switch (_outcome) {
        null => const ForecastLoading(),
        _Loaded(:final forecast) => ForecastLoaded(
          ForecastUiModel.from(forecast.inUnits(units), units, l10n),
        ),
        _Failed(:final error) => ForecastFailed(messageForError(error, l10n)),
      },
    );
  }
}

sealed class _Outcome {}

class _Loaded extends _Outcome {
  _Loaded(this.forecast);

  /// In metric units, as fetched.
  final Forecast forecast;
}

class _Failed extends _Outcome {
  _Failed(this.error);
  final Exception error;
}

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(
  HomeViewModel.new,
);
