import 'package:meta/meta.dart';

/// A point on the map.
@immutable
class Place {
  const Place({
    this.name,
    required this.latitude,
    required this.longitude,
    this.region,
    this.country,
  });

  /// A place picked straight off the map, which has no name.
  ///
  /// A map that has been dragged round the world more than once reports
  /// longitudes past 180 degrees, so the longitude is brought back into range.
  factory Place.fromCoordinates(double latitude, double rawLongitude) =>
      Place(latitude: latitude, longitude: normalizeLongitude(rawLongitude));

  /// [longitude] as the same meridian between -180 (inclusive) and 180.
  static double normalizeLongitude(double longitude) =>
      (longitude + 180) % 360 - 180;

  /// What the place is called. A point picked straight off the map has none.
  final String? name;
  final double latitude;
  final double longitude;

  /// State, province or similar. Tells two places of one name apart.
  final String? region;
  final String? country;

  @override
  bool operator ==(Object other) =>
      other is Place &&
      other.name == name &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.region == region &&
      other.country == country;

  @override
  int get hashCode => Object.hash(name, latitude, longitude, region, country);

  @override
  String toString() => 'Place(${name ?? 'unnamed'}, $latitude, $longitude)';
}
