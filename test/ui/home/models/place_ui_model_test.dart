import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/domain/models/place.dart';
import 'package:flutter_weather/ui/home/models/place_ui_model.dart';

import '../../../support/fakes.dart';

void main() {
  test('a searched place shows its name and where it is', () {
    final model = PlaceUiModel.from(asheville, en);

    expect(model.title, 'Asheville');
    expect(model.subtitle, 'North Carolina, United States');
    expect(model.hasSubtitle, isTrue);
    expect((model.latitude, model.longitude), (35.6, -82.55));
  });

  test('the subtitle is made of whichever parts are known', () {
    const somewhere = Place(name: 'Somewhere', latitude: 1, longitude: 2);
    const inFrance = Place(
      name: 'Somewhere',
      latitude: 1,
      longitude: 2,
      country: 'France',
    );

    expect(PlaceUiModel.from(somewhere, en).hasSubtitle, isFalse);
    expect(PlaceUiModel.from(inFrance, en).subtitle, 'France');
  });

  test('a place with no name is called by its coordinates', () {
    String title(double latitude, double longitude) =>
        PlaceUiModel.from(Place.fromCoordinates(latitude, longitude), en).title;

    expect(title(35.6, -82.554), '35.60°N, 82.55°W');
    expect(title(-33.87, 151.21), '33.87°S, 151.21°E');
    // Too near the equator and the meridian to show: not "0.00°S, 0.00°W".
    expect(title(-0.001, -0.004), '0.00°N, 0.00°E');
    expect(
      PlaceUiModel.from(Place.fromCoordinates(-33.87, 151.21), en).hasSubtitle,
      isFalse,
    );
  });

  test('two models of the same place are equal', () {
    expect(PlaceUiModel.from(ashford, en), PlaceUiModel.from(ashford, en));
    expect(
      PlaceUiModel.from(ashford, en),
      isNot(PlaceUiModel.from(asheville, en)),
    );
  });
}
