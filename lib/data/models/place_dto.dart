import '../../domain/models/place.dart';
import 'json_reading.dart';

/// One entry of the geocoding response's `results`, as Open-Meteo sends it.
class PlaceDto {
  const PlaceDto({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.admin1,
    this.country,
  });

  /// Throws a [FormatException] if [json] is not shaped like a place.
  factory PlaceDto.fromJson(Object? json) {
    final object = readObject(json, 'place');
    return PlaceDto(
      name: readValue<String>(object, 'name'),
      latitude: readValue<num>(object, 'latitude'),
      longitude: readValue<num>(object, 'longitude'),
      admin1: readValue<String?>(object, 'admin1'),
      country: readValue<String?>(object, 'country'),
    );
  }

  final String name;
  final num latitude;
  final num longitude;

  /// First-level administrative area: a state, province or similar.
  final String? admin1;
  final String? country;

  Place toDomain() => Place(
    name: name,
    latitude: latitude.toDouble(),
    longitude: longitude.toDouble(),
    region: admin1,
    country: country,
  );
}
