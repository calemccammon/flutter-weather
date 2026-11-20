import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/data/repositories/shared_preferences_settings_repository.dart';
import 'package:flutter_weather/domain/models/units.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SharedPreferencesSettingsRepository> repositoryOver(
    Map<String, Object> stored,
  ) async {
    SharedPreferences.setMockInitialValues(stored);
    return SharedPreferencesSettingsRepository(
      await SharedPreferences.getInstance(),
    );
  }

  test('has no units until some are saved', () async {
    final repository = await repositoryOver({});

    expect(repository.units, isNull);
  });

  test('a saved choice is there for the next launch', () async {
    final repository = await repositoryOver({});

    for (final units in Units.values) {
      await repository.saveUnits(units);
      expect(repository.units, units);

      // What a later launch would read from the same store.
      final later = SharedPreferencesSettingsRepository(
        await SharedPreferences.getInstance(),
      );
      expect(later.units, units);
    }
  });

  test('something unreadable in the store counts as no choice', () async {
    expect((await repositoryOver({'units': 'kelvin'})).units, isNull);
  });
}
