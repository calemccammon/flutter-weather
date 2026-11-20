import 'package:material_ui/material_ui.dart';

import 'place_ui_model.dart';

/// What the search view is showing.
@immutable
sealed class SearchState {
  const SearchState();
}

/// Nothing typed yet, or too little to search for.
class SearchIdle extends SearchState {
  const SearchIdle();
}

/// Waiting, either for the user to stop typing or for the answer.
class SearchLoading extends SearchState {
  const SearchLoading(this.query);
  final String query;
}

class SearchResults extends SearchState {
  const SearchResults(this.query, this.places);
  final String query;
  final List<PlaceUiModel> places;
}

class SearchEmpty extends SearchState {
  const SearchEmpty(this.query);
  final String query;
}

class SearchFailed extends SearchState {
  const SearchFailed(this.query, this.message);
  final String query;
  final String message;
}
