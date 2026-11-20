import 'package:meta/meta.dart';

/// A point on the map with a name to show for it.
@immutable
class Place {
  const Place({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.region,
    this.country,
  });

  /// A place picked straight off the map, which has no name.
  ///
  /// A map that has been dragged round the world more than once reports
  /// longitudes past 180 degrees, so the longitude is brought back into range.
  factory Place.fromCoordinates(double latitude, double rawLongitude) {
    final longitude = normalizeLongitude(rawLongitude);
    final lat = latitude.abs().toStringAsFixed(2);
    final lon = longitude.abs().toStringAsFixed(2);
    return Place(
      name:
          '$lat°${latitude >= 0 ? 'N' : 'S'}, $lon°${longitude >= 0 ? 'E' : 'W'}',
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// [longitude] as the same meridian between -180 (inclusive) and 180.
  static double normalizeLongitude(double longitude) =>
      (longitude + 180) % 360 - 180;

  final String name;
  final double latitude;
  final double longitude;

  /// State, province or similar. Tells two places of one name apart.
  final String? region;
  final String? country;

  /// "North Carolina, United States", or whichever parts are known.
  String get subtitle => [region, country].nonNulls.join(', ');

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
  String toString() => 'Place($name, $latitude, $longitude)';
}
