import 'package:material_ui/material_ui.dart';

import 'app_tokens.dart';

/// Every colour in the app is derived from this one, as Material 3 intends.
const _seed = Color(0xFF2E6FB7);

ThemeData appTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  const shapes = AppShapes();

  return ThemeData(
    colorScheme: scheme,
    extensions: const [AppSpacing(), shapes, AppBreakpoints()],
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(3),
      backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
    ),
    searchViewTheme: SearchViewThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
    ),
    // The forecast's bottom sheet and side panel both take their colour,
    // elevation and drag handle from here.
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(shapes.extraLarge),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      dragHandleColor: scheme.onSurfaceVariant.withValues(alpha: 0.4),
      dragHandleSize: const Size(32, 4),
    ),
    cardTheme: const CardThemeData(margin: EdgeInsets.zero),
  );
}
