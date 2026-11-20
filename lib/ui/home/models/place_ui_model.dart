import 'package:material_ui/material_ui.dart';

import '../../../domain/models/place.dart';

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

  factory PlaceUiModel.from(Place place) => PlaceUiModel(
    title: place.name,
    subtitle: place.subtitle,
    latitude: place.latitude,
    longitude: place.longitude,
  );

  /// "Asheville".
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
