import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dependencies.dart';
import '../../core/l10n.dart';
import '../view_models/home_view_model.dart';

/// The map behind everything else. A long press picks the point under it.
class WeatherMap extends ConsumerWidget {
  const WeatherMap({super.key, required this.controller});

  final MapController controller;

  static const _initialCenter = LatLng(25, 0);
  static const _initialZoom = 2.5;
  static const _minZoom = 2.0;
  static const _maxZoom = 18.0;
  static const _pinSize = 48.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref.watch(homeViewModelProvider.select((s) => s.place));
    final tileUrl = ref.watch(mapTileUrlProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: _initialCenter,
        initialZoom: _initialZoom,
        minZoom: _minZoom,
        maxZoom: _maxZoom,
        backgroundColor: theme.colorScheme.surfaceContainer,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onLongPress: (_, point) => ref
            .read(homeViewModelProvider.notifier)
            .selectPoint(point.latitude, point.longitude),
      ),
      children: [
        if (tileUrl != null)
          TileLayer(
            urlTemplate: tileUrl,
            userAgentPackageName: 'com.calemccammon.weather.flutter_weather',
            tileBuilder: isDark ? darkModeTileBuilder : null,
          ),
        if (place != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(place.latitude, place.longitude),
                width: _pinSize,
                height: _pinSize,
                // The pin's tip, not its middle, sits on the point.
                alignment: Alignment.topCenter,
                child: Icon(
                  Icons.location_pin,
                  size: _pinSize,
                  color: theme.colorScheme.primary,
                  semanticLabel: context.l10n.selectedPlace,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
