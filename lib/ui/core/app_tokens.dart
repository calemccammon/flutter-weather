import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

/// The app's own design tokens, carried on the theme beside Material's.
///
/// Read them with `Theme.of(context).spacing`, `.shapes` and `.breakpoints`.
/// A number that only one widget cares about (a column width, an icon size)
/// is a named constant in that widget instead.

/// The steps every gap and padding is taken from.
@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    this.xxs = 2,
    this.xs = 4,
    this.sm = 8,
    this.md = 12,
    this.lg = 16,
    this.xl = 24,
  });

  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  @override
  AppSpacing copyWith({
    double? xxs,
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
  }) => AppSpacing(
    xxs: xxs ?? this.xxs,
    xs: xs ?? this.xs,
    sm: sm ?? this.sm,
    md: md ?? this.md,
    lg: lg ?? this.lg,
    xl: xl ?? this.xl,
  );

  @override
  AppSpacing lerp(AppSpacing? other, double t) => other == null
      ? this
      : AppSpacing(
          xxs: lerpDouble(xxs, other.xxs, t)!,
          xs: lerpDouble(xs, other.xs, t)!,
          sm: lerpDouble(sm, other.sm, t)!,
          md: lerpDouble(md, other.md, t)!,
          lg: lerpDouble(lg, other.lg, t)!,
          xl: lerpDouble(xl, other.xl, t)!,
        );
}

/// Corner radii, after Material 3's shape scale.
@immutable
class AppShapes extends ThemeExtension<AppShapes> {
  const AppShapes({this.extraSmall = 4, this.extraLarge = 28});

  /// Small labels laid over other content.
  final double extraSmall;

  /// Sheets and floating panels.
  final double extraLarge;

  @override
  AppShapes copyWith({double? extraSmall, double? extraLarge}) => AppShapes(
    extraSmall: extraSmall ?? this.extraSmall,
    extraLarge: extraLarge ?? this.extraLarge,
  );

  @override
  AppShapes lerp(AppShapes? other, double t) => other == null
      ? this
      : AppShapes(
          extraSmall: lerpDouble(extraSmall, other.extraSmall, t)!,
          extraLarge: lerpDouble(extraLarge, other.extraLarge, t)!,
        );
}

/// Window widths at which the layout changes, after Material 3's window size
/// classes.
@immutable
class AppBreakpoints extends ThemeExtension<AppBreakpoints> {
  const AppBreakpoints({this.expanded = 840});

  /// From this width up there is room for a panel beside the map.
  final double expanded;

  @override
  AppBreakpoints copyWith({double? expanded}) =>
      AppBreakpoints(expanded: expanded ?? this.expanded);

  @override
  AppBreakpoints lerp(AppBreakpoints? other, double t) => other == null
      ? this
      : AppBreakpoints(expanded: lerpDouble(expanded, other.expanded, t)!);
}

extension AppTokens on ThemeData {
  AppSpacing get spacing => extension<AppSpacing>() ?? const AppSpacing();
  AppShapes get shapes => extension<AppShapes>() ?? const AppShapes();
  AppBreakpoints get breakpoints =>
      extension<AppBreakpoints>() ?? const AppBreakpoints();
}
