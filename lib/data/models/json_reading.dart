/// Helpers for reading decoded JSON whose shape cannot be trusted.
///
/// Each throws a [FormatException] when the value is not what was expected,
/// so a surprising response is reported as one and never as a cast error.
library;

Map<String, dynamic> readObject(Object? value, String what) =>
    value is Map<String, dynamic>
    ? value
    : throw FormatException('$what is not an object');

/// A list in which every item is a [T]. Use a nullable [T] for a column that
/// may have gaps.
List<T> readList<T>(Object? value, String what) {
  if (value is! List<dynamic> || value.any((item) => item is! T)) {
    throw FormatException('$what is not a list of $T');
  }
  return value.cast<T>();
}

T readValue<T>(Map<String, dynamic> object, String key) {
  final value = object[key];
  return value is T ? value : throw FormatException('$key is not a $T');
}
