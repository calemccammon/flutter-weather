import '../../domain/repositories/weather_repository.dart';
import 'l10n.dart';

/// What to tell the user about each kind of failure.
extension WeatherFailureMessage on WeatherFailure {
  String message(AppLocalizations l10n) => switch (this) {
    WeatherFailure.timeout => l10n.failureTimeout,
    WeatherFailure.noConnection => l10n.failureNoConnection,
    WeatherFailure.badResponse => l10n.failureBadResponse,
    WeatherFailure.rejected => l10n.failureRejected,
    WeatherFailure.unavailable => l10n.failureUnavailable,
    WeatherFailure.invalidPlace => l10n.failureInvalidPlace,
  };
}

/// The message for whatever was thrown: a [WeatherException]'s own, or a
/// general one for anything unexpected.
String messageForError(Object error, AppLocalizations l10n) =>
    error is WeatherException
    ? error.failure.message(l10n)
    : l10n.failureUnexpected;
