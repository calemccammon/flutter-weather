import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n.dart';
import '../models/place_ui_model.dart';
import '../models/search_state.dart';
import '../view_models/home_view_model.dart';
import '../view_models/search_view_model.dart';

/// Material 3 search bar that opens into a list of matching places.
///
/// It draws what [SearchViewModel] says and tells it what was typed; it does
/// no searching itself.
class PlaceSearchBar extends ConsumerStatefulWidget {
  const PlaceSearchBar({super.key});

  @override
  ConsumerState<PlaceSearchBar> createState() => _PlaceSearchBarState();
}

class _PlaceSearchBarState extends ConsumerState<PlaceSearchBar> {
  final _controller = SearchController();

  @override
  void initState() {
    super.initState();
    // The bar is rebuilt from scratch when the window crosses between the
    // phone and wide layouts; start it showing the place already chosen.
    _controller.text = ref.read(homeViewModelProvider).place?.title ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The view opens showing the chosen place's name, which is a label and not
  /// something to search for. Select it, so typing replaces it, and start
  /// from an empty search.
  void _onOpen() {
    ref.read(searchViewModelProvider.notifier).reset();
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  void _choose(int index, PlaceUiModel place) {
    _controller.closeView(place.title);
    ref.read(searchViewModelProvider.notifier).choose(index);
  }

  @override
  Widget build(BuildContext context) {
    final place = ref.watch(homeViewModelProvider.select((s) => s.place));
    // A place picked on the map shows its name in the bar too.
    ref.listen(homeViewModelProvider.select((s) => s.place), (_, place) {
      final name = place?.title ?? '';
      if (_controller.text != name) _controller.text = name;
    });

    return SearchAnchor.bar(
      searchController: _controller,
      barHintText: context.l10n.searchHint,
      barLeading: const Icon(Icons.search),
      barTrailing: [
        if (place != null)
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: context.l10n.clearPlace,
            onPressed: ref.read(homeViewModelProvider.notifier).clear,
          ),
      ],
      onOpen: _onOpen,
      onChanged: ref.read(searchViewModelProvider.notifier).queryChanged,
      // The list comes from the view model, through viewBuilder, so the
      // anchor's own suggestions stay empty.
      suggestionsBuilder: (_, _) => const [],
      viewBuilder: (_) => _SearchResultsView(onChoose: _choose),
    );
  }
}

class _SearchResultsView extends ConsumerWidget {
  const _SearchResultsView({required this.onChoose});

  final void Function(int index, PlaceUiModel place) onChoose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchViewModelProvider);
    final l10n = context.l10n;

    return switch (state) {
      SearchIdle() => _Message(Icons.travel_explore, l10n.searchPrompt),
      SearchLoading() => const Align(
        alignment: Alignment.topCenter,
        child: LinearProgressIndicator(),
      ),
      SearchEmpty(:final query) => _Message(
        Icons.search_off,
        l10n.searchNothingFound(query),
      ),
      SearchFailed(:final message) => _Message(
        Icons.cloud_off,
        message,
        action: TextButton(
          onPressed: ref.read(searchViewModelProvider.notifier).retry,
          child: Text(l10n.tryAgain),
        ),
      ),
      SearchResults(:final places) => ListView(
        padding: EdgeInsets.zero,
        children: [
          for (final (index, place) in places.indexed)
            ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(place.title),
              subtitle: place.hasSubtitle ? Text(place.subtitle) : null,
              onTap: () => onChoose(index, place),
            ),
        ],
      ),
    };
  }
}

class _Message extends StatelessWidget {
  const _Message(this.icon, this.text, {this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        title: Text(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: action,
      ),
    );
  }
}
