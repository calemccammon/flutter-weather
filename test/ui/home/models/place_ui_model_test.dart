import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/domain/models/place.dart';
import 'package:flutter_weather/ui/home/models/place_ui_model.dart';

import '../../../support/fakes.dart';

void main() {
  test('a searched place shows its name and where it is', () {
    final model = PlaceUiModel.from(asheville);

    expect(model.title, 'Asheville');
    expect(model.subtitle, 'North Carolina, United States');
    expect(model.hasSubtitle, isTrue);
    expect((model.latitude, model.longitude), (35.6, -82.55));
  });

  test('a point picked on the map shows its coordinates and no subtitle', () {
    final model = PlaceUiModel.from(Place.fromCoordinates(-33.87, 151.21));

    expect(model.title, '33.87°S, 151.21°E');
    expect(model.hasSubtitle, isFalse);
  });

  test('two models of the same place are equal', () {
    expect(PlaceUiModel.from(ashford), PlaceUiModel.from(ashford));
    expect(PlaceUiModel.from(ashford), isNot(PlaceUiModel.from(asheville)));
  });
}
