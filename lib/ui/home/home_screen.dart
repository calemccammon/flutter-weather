import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../core/app_tokens.dart';
import '../core/l10n.dart';
import 'view_models/home_view_model.dart';
import 'widgets/forecast_panel.dart';
import 'widgets/place_search_bar.dart';
import 'widgets/weather_map.dart';

/// The app's one screen: a map, a search bar over it, and the forecast for
/// the selected place.
///
/// On a phone the forecast is a bottom sheet that drags up over the map. From
/// Material's "expanded" window width up, it is a panel at the side.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _sidePanelWidth = 400.0;

  /// How far in the map goes when a place is chosen from further out.
  static const _placeZoom = 10.0;

  // The bottom sheet's resting heights, as fractions of the screen: tucked
  // away, at rest, and pulled right up.
  static const _sheetCollapsed = 0.12;
  static const _sheetResting = 0.3;
  static const _sheetExpanded = 0.88;

  final _mapController = MapController();

  // The layout the screen was last drawn in, for placing a point on the map.
  bool _isWide = false;
  Size _size = Size.zero;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Moves the map so [point] sits in the middle of the part of it that the
  /// forecast does not cover.
  void _showOnMap(LatLng point) {
    final spacing = Theme.of(context).spacing;
    final zoom = _mapController.camera.zoom;
    _mapController.move(
      point,
      zoom < _placeZoom ? _placeZoom : zoom,
      // Where the point should land, measured from the middle of the map.
      offset: _isWide
          ? Offset((_sidePanelWidth + spacing.lg * 2) / 2, 0)
          : Offset(0, -_size.height * _sheetResting / 2),
    );
  }

  /// When the window crosses between the phone and wide layouts (a rotated
  /// phone, a resized window), the forecast covers a different part of the
  /// map, so the selected place is put back in the clear.
  void _recentreAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final place = ref.read(homeViewModelProvider).place;
      if (place != null) _showOnMap(LatLng(place.latitude, place.longitude));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final sheet = theme.bottomSheetTheme;

    // Selecting a place moves the map to it.
    ref.listen(homeViewModelProvider.select((s) => s.place), (_, place) {
      if (place != null) _showOnMap(LatLng(place.latitude, place.longitude));
    });

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= theme.breakpoints.expanded;
          final layoutChanged = isWide != _isWide && _size != Size.zero;
          _isWide = isWide;
          _size = constraints.biggest;
          if (layoutChanged) _recentreAfterLayout();

          return Stack(
            children: [
              WeatherMap(controller: _mapController),
              _MapCredit(belowSearchBar: !isWide),
              if (isWide)
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(spacing.lg),
                    child: SizedBox(
                      width: _sidePanelWidth,
                      child: Column(
                        children: [
                          const PlaceSearchBar(),
                          SizedBox(height: spacing.md),
                          Expanded(
                            // The sheet's look, rounded on every corner since
                            // it floats clear of the window's edges.
                            child: Material(
                              color: sheet.backgroundColor,
                              elevation: sheet.elevation ?? 0,
                              borderRadius: BorderRadius.circular(
                                theme.shapes.extraLarge,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: const ForecastPanel(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                DraggableScrollableSheet(
                  initialChildSize: _sheetResting,
                  minChildSize: _sheetCollapsed,
                  maxChildSize: _sheetExpanded,
                  snap: true,
                  builder: (context, scrollController) => Material(
                    color: sheet.backgroundColor,
                    elevation: sheet.elevation ?? 0,
                    shape: sheet.shape,
                    clipBehavior: sheet.clipBehavior ?? Clip.none,
                    child: ForecastPanel(
                      scrollController: scrollController,
                      showDragHandle: true,
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(spacing.lg),
                    child: const Align(
                      alignment: Alignment.topCenter,
                      child: PlaceSearchBar(),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// OpenStreetMap asks for its credit to stay visible on the map.
///
/// On a phone it sits just under the search bar, clear of the forecast sheet
/// ([belowSearchBar]). On a wide window nothing covers the map's bottom
/// corner, so it goes there.
class _MapCredit extends StatelessWidget {
  const _MapCredit({required this.belowSearchBar});

  final bool belowSearchBar;

  /// Material 3's search bar height.
  static const _searchBarHeight = 56.0;
  static const _backgroundOpacity = 0.8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    return SafeArea(
      child: Align(
        alignment: belowSearchBar ? Alignment.topRight : Alignment.bottomRight,
        child: Container(
          margin: belowSearchBar
              ? EdgeInsets.only(
                  top: spacing.lg + _searchBarHeight + spacing.md,
                  right: spacing.sm,
                )
              : EdgeInsets.all(spacing.sm),
          padding: EdgeInsets.symmetric(
            horizontal: spacing.xs,
            vertical: spacing.xxs,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(
              alpha: _backgroundOpacity,
            ),
            borderRadius: BorderRadius.circular(theme.shapes.extraSmall),
          ),
          child: Text(
            context.l10n.mapCredit,
            style: theme.textTheme.labelSmall,
          ),
        ),
      ),
    );
  }
}
