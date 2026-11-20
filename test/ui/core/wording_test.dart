import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/domain/models/weather_condition.dart';
import 'package:flutter_weather/domain/repositories/weather_repository.dart';
import 'package:flutter_weather/ui/core/failure_messages.dart';
import 'package:flutter_weather/ui/core/weather_condition_ui.dart';

import '../../support/fakes.dart';

void main() {
  test('every condition has its own wording', () {
    final labels = {for (final c in WeatherCondition.values) c.label(en)};

    expect(labels, hasLength(WeatherCondition.values.length));
    expect(labels.every((label) => label.isNotEmpty), isTrue);
    expect(WeatherCondition.partlyCloudy.label(en), 'Partly cloudy');
  });

  test('clear and partly cloudy skies have a different icon at night', () {
    for (final condition in [
      WeatherCondition.clear,
      WeatherCondition.mostlyClear,
      WeatherCondition.partlyCloudy,
    ]) {
      expect(
        condition.icon(isDay: false),
        isNot(condition.icon()),
        reason: condition.name,
      );
    }
    expect(
      WeatherCondition.rain.icon(isDay: false),
      WeatherCondition.rain.icon(),
    );
  });

  test('every kind of failure has its own sentence', () {
    final messages = {for (final f in WeatherFailure.values) f.message(en)};
    expect(messages, hasLength(WeatherFailure.values.length));
  });

  test("an error's message never shows the service's own words", () {
    const refused = WeatherException(
      WeatherFailure.rejected,
      detail: 'Latitude must be in range of -90 to 90°.',
    );

    expect(messageForError(refused, en), en.failureRejected);
    expect(messageForError(refused, en), isNot(contains('Latitude')));
    expect(
      messageForError(StateError('boom'), en),
      'Something went wrong. Please try again.',
    );
  });
}
