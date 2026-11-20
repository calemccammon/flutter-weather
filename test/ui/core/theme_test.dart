import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/ui/core/app_tokens.dart';
import 'package:flutter_weather/ui/core/theme.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final brightness in Brightness.values) {
    test('the ${brightness.name} theme carries the app tokens and rounds the '
        'sheet as the shape token says', () {
      final theme = appTheme(brightness);

      expect(theme.brightness, brightness);
      expect(theme.extension<AppSpacing>(), isNotNull);
      expect(theme.extension<AppShapes>(), isNotNull);
      expect(theme.extension<AppBreakpoints>(), isNotNull);
      expect(
        theme.bottomSheetTheme.shape,
        RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(theme.shapes.extraLarge),
          ),
        ),
      );
      expect(theme.bottomSheetTheme.dragHandleColor, isNotNull);
    });
  }

  test('a theme without the tokens falls back to their defaults', () {
    expect(ThemeData().spacing.lg, const AppSpacing().lg);
    expect(ThemeData().breakpoints.expanded, 840);
  });
}
