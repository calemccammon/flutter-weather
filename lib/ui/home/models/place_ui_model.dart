import 'package:material_ui/material_ui.dart';

import '../../../domain/models/place.dart';
import '../../core/l10n.dart';

/// A place as the screen shows it: in a search result, in the search bar, as
/// the forecast's heading and as the pin on the map.
@immutable
class PlaceUiModel {
  const PlaceUiModel({
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
  });

  factory PlaceUiModel.from(Place place, AppLocalizations l10n) => PlaceUiModel(
    title: place.name ?? _coordinates(place.latitude, place.longitude, l10n),
    subtitle: [place.region, place.country].nonNulls.join(', '),
    latitude: place.latitude,
    longitude: place.longitude,
  );

  /// How many decimal places of a degree are shown: about a kilometre.
  static const _coordinateDecimals = 2;

  /// "35.60°N, 82.55°W": what a place with no name is called.
  static String _coordinates(
    double latitude,
    double longitude,
    AppLocalizations l10n,
  ) {
    String shown(double value) =>
        value.abs().toStringAsFixed(_coordinateDecimals);
    // The side is read off the rounded figure, so a point a hair south of
    // the equator is "0.00°N" like the equator itself.
    bool isPositive(double value) =>
        double.parse(shown(value)) == 0 || value > 0;

    return l10n.placeCoordinates(
      isPositive(latitude)
          ? l10n.placeNorth(shown(latitude))
          : l10n.placeSouth(shown(latitude)),
      isPositive(longitude)
          ? l10n.placeEast(shown(longitude))
          : l10n.placeWest(shown(longitude)),
    );
  }

  /// "Asheville", or "35.60°N, 82.55°W" for a place with no name.
  final String title;

  /// "North Carolina, United States", or empty when nothing more is known.
  final String subtitle;

  /// Where the pin goes.
  final double latitude;
  final double longitude;

  bool get hasSubtitle => subtitle.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is PlaceUiModel &&
      other.title == title &&
      other.subtitle == subtitle &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(title, subtitle, latitude, longitude);

  @override
  String toString() => 'PlaceUiModel($title, $latitude, $longitude)';
}
