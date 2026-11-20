import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/di/providers.dart';
import 'package:flutter_weather/domain/repositories/weather_repository.dart';
import 'package:flutter_weather/ui/core/l10n.dart';
import 'package:flutter_weather/ui/home/models/place_ui_model.dart';
import 'package:flutter_weather/ui/home/models/search_state.dart';
import 'package:flutter_weather/ui/home/view_models/home_view_model.dart';
import 'package:flutter_weather/ui/home/view_models/search_view_model.dart';

import '../../../support/fakes.dart';

/// The wording the app is using, so a test can change the language.
final wording = StateProvider<AppLocalizations>((ref) => en);

void main() {
  late FakeWeatherRepository repository;
  late ProviderContainer container;

  SearchState state() => container.read(searchViewModelProvider);
  SearchViewModel viewModel() =>
      container.read(searchViewModelProvider.notifier);

  /// Types [query] and waits out the pause before it is sent.
  void search(FakeAsync async, String query) {
    viewModel().queryChanged(query);
    async.elapse(SearchViewModel.debounce);
  }

  setUp(() {
    repository = FakeWeatherRepository();
    container = ProviderContainer.test(
      overrides: [
        ...dependencies,
        weatherRepositoryProvider.overrideWithValue(repository),
        settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
        appLocalizationsProvider.overrideWith((ref) => ref.watch(wording)),
      ],
    );
  });

  test('starts idle and stays idle for a query too short to search', () {
    expect(state(), isA<SearchIdle>());
    viewModel().queryChanged(' a ');
    expect(state(), isA<SearchIdle>());
  });

  test('waits for a pause in typing, then shows the results', () {
    fakeAsync((async) {
      viewModel().queryChanged('ash');
      async.elapse(const Duration(milliseconds: 200));
      viewModel().queryChanged('ashe');

      expect(state(), isA<SearchLoading>());
      async.elapse(SearchViewModel.debounce - const Duration(milliseconds: 1));
      expect(repository.searchQueries, isEmpty, reason: 'inside the pause');

      async.elapse(const Duration(milliseconds: 1));
      expect(repository.searchQueries, ['ashe'], reason: "'ash' is never sent");

      repository.searches['ashe']!.complete([asheville]);
      async.flushMicrotasks();

      expect(
        state(),
        isA<SearchResults>().having((s) => s.query, 'query', 'ashe').having(
          (s) => s.places,
          'places',
          [PlaceUiModel.from(asheville, en)],
        ),
      );
    });
  });

  test('an answer to an older query does not replace a newer one', () {
    fakeAsync((async) {
      search(async, 'ashe');
      search(async, 'ashf');

      // The newer answer arrives first, the older one after it.
      repository.searches['ashf']!.complete([ashford]);
      async.flushMicrotasks();
      repository.searches['ashe']!.complete([asheville]);
      async.flushMicrotasks();

      expect(
        state(),
        isA<SearchResults>().having((s) => s.places, 'places', [
          PlaceUiModel.from(ashford, en),
        ]),
      );
      // And the row still leads to the newer answer's place.
      viewModel().choose(0);
      expect(
        container.read(homeViewModelProvider).place,
        PlaceUiModel.from(ashford, en),
      );
    });
  });

  test('no matches is its own state, naming the query', () {
    fakeAsync((async) {
      search(async, 'zzzz');
      repository.searches['zzzz']!.complete(const []);
      async.flushMicrotasks();

      expect(state(), isA<SearchEmpty>().having((s) => s.query, 'q', 'zzzz'));
    });
  });

  test('a failure shows its message and can be retried at once', () {
    fakeAsync((async) {
      search(async, 'ashe');
      repository.searches['ashe']!.completeError(
        const WeatherException(WeatherFailure.noConnection),
      );
      async.flushMicrotasks();

      expect(
        state(),
        isA<SearchFailed>().having(
          (s) => s.message,
          'message',
          en.failureNoConnection,
        ),
      );

      viewModel().retry();
      expect(state(), isA<SearchLoading>());
      // No pause this time: the request is already out.
      repository.searches['ashe']!.complete([asheville]);
      async.flushMicrotasks();

      expect(state(), isA<SearchResults>());
    });
  });

  test('a failure nobody planned for still ends the wait', () {
    fakeAsync((async) {
      search(async, 'ashe');
      repository.searches['ashe']!.completeError(Exception('unplanned'));
      async.flushMicrotasks();

      expect(
        state(),
        isA<SearchFailed>().having(
          (s) => s.message,
          'message',
          'Something went wrong. Please try again.',
        ),
      );
    });
  });

  test('choosing a row selects the place behind it', () {
    fakeAsync((async) {
      search(async, 'ash');
      repository.searches['ash']!.complete([asheville, ashford]);
      async.flushMicrotasks();

      viewModel().choose(5);
      expect(container.read(homeViewModelProvider).place, isNull);

      viewModel().choose(1);
      expect(
        container.read(homeViewModelProvider).place,
        PlaceUiModel.from(ashford, en),
      );
    });
  });

  test('an old answer for text that has since been typed again is ignored', () {
    fakeAsync((async) {
      search(async, 'ash');
      search(async, 'ashe');
      search(async, 'ash');
      final [first, _, second] = repository.searchCalls;

      second.complete([asheville]);
      async.flushMicrotasks();
      first.completeError(const WeatherException(WeatherFailure.timeout));
      async.flushMicrotasks();

      expect(
        state(),
        isA<SearchResults>().having((s) => s.places, 'places', [
          PlaceUiModel.from(asheville, en),
        ]),
      );
      viewModel().choose(0);
      expect(
        container.read(homeViewModelProvider).place,
        PlaceUiModel.from(asheville, en),
      );
    });
  });

  test('clearing the text while a search is out returns to idle', () {
    fakeAsync((async) {
      search(async, 'ashe');
      viewModel().queryChanged('');
      repository.searches['ashe']!.complete([asheville]);
      async.flushMicrotasks();

      expect(state(), isA<SearchIdle>());
    });
  });

  test('reset forgets the query, so the same text searches afresh', () {
    fakeAsync((async) {
      search(async, 'ashe');
      repository.searches['ashe']!.complete([asheville]);
      async.flushMicrotasks();

      viewModel().reset();
      expect(state(), isA<SearchIdle>());
      viewModel().choose(0);
      expect(container.read(homeViewModelProvider).place, isNull);

      search(async, 'ashe');
      expect(repository.searchQueries, ['ashe', 'ashe']);
    });
  });

  test('a change of language re-words a failure on screen', () {
    fakeAsync((async) {
      search(async, 'ashe');
      repository.searches['ashe']!.completeError(
        const WeatherException(WeatherFailure.noConnection),
      );
      async.flushMicrotasks();

      container.read(wording.notifier).state = OtherWording();

      expect(
        state(),
        isA<SearchFailed>()
            .having((s) => s.message, 'message', 'Keine Verbindung.')
            .having((s) => s.query, 'query', 'ashe'),
      );
    });
  });
}
