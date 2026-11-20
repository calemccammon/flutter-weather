import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/domain/models/units.dart';
import 'package:flutter_weather/ui/home/models/units_ui_model.dart';

void main() {
  test('each system of units has its own choice, and back again', () {
    expect(UnitsUiModel.from(Units.metric), UnitsUiModel.celsius);
    expect(UnitsUiModel.from(Units.imperial), UnitsUiModel.fahrenheit);
    for (final units in Units.values) {
      expect(UnitsUiModel.from(units).toDomain(), units);
    }
  });
}
