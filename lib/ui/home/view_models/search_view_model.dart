import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/place.dart';
import '../../../domain/use_cases/search_places.dart';
import '../../core/dependencies.dart';
import '../../core/failure_messages.dart';
import '../../core/l10n.dart';
import '../models/place_ui_model.dart';
import '../models/search_state.dart';
import 'home_view_model.dart';

/// Turns what the user types into search results.
///
/// It waits for a pause in typing before searching, and an answer that comes
/// back after a newer search has been sent is thrown away.
class SearchViewModel extends Notifier<SearchState> {
  /// How long typing must pause before a search is sent.
  static const debounce = Duration(milliseconds: 350);

  Timer? _debounce;

  /// The text last asked about; what [retry] asks about again.
  String _latestQuery = '';

  /// Counts changes of the query, so an answer can tell whether it is still
  /// wanted. The text alone cannot: the same text can be searched for twice.
  int _request = 0;

  /// The places behind the rows of the current [SearchResults], in order.
  List<Place> _results = const [];

  /// What the current [SearchFailed] is reporting.
  Exception? _error;

  @override
  SearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    // A failure's message is finished wording, so it is worded again when
    // the device's language changes.
    ref.listen(appLocalizationsProvider, (_, l10n) {
      final error = _error;
      if (state case SearchFailed(:final query) when error != null) {
        state = SearchFailed(query, messageForError(error, l10n));
      }
    });
    return const SearchIdle();
  }

  void queryChanged(String text) {
    final query = text.trim();
    if (query == _latestQuery) return;
    _latestQuery = query;
    _request++;
    _debounce?.cancel();

    if (!SearchPlaces.isSearchable(query)) {
      state = const SearchIdle();
      return;
    }
    state = SearchLoading(query);
    _debounce = Timer(debounce, () => unawaited(_search(query)));
  }

  /// Forgets the current query and results, as when the search view opens.
  void reset() {
    _debounce?.cancel();
    _latestQuery = '';
    _request++;
    _results = const [];
    state = const SearchIdle();
  }

  /// Makes the result in row [index] the selected place.
  void choose(int index) {
    if (state is! SearchResults || index < 0 || index >= _results.length) {
      return;
    }
    ref.read(homeViewModelProvider.notifier).select(_results[index]);
  }

  /// Runs the last search again after a failure.
  void retry() {
    final query = _latestQuery;
    if (!SearchPlaces.isSearchable(query)) return;
    _debounce?.cancel();
    _request++;
    state = SearchLoading(query);
    unawaited(_search(query));
  }

  Future<void> _search(String query) async {
    final request = _request;
    final l10n = ref.read(appLocalizationsProvider);
    SearchState result;
    var places = const <Place>[];
    Exception? error;
    try {
      places = await ref.read(searchPlacesProvider)(query);
      result = places.isEmpty
          ? SearchEmpty(query)
          : SearchResults(query, [
              for (final place in places) PlaceUiModel.from(place, l10n),
            ]);
    } on Exception catch (e) {
      error = e;
      result = SearchFailed(query, messageForError(e, l10n));
    }
    if (!ref.mounted || request != _request) return;
    _results = places;
    _error = error;
    state = result;
  }
}

final searchViewModelProvider = NotifierProvider<SearchViewModel, SearchState>(
  SearchViewModel.new,
);
