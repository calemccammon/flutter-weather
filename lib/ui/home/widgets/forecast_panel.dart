import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/app_tokens.dart';
import '../../core/l10n.dart';
import '../models/forecast_ui_model.dart';
import '../models/home_state.dart';
import '../models/units_ui_model.dart';
import '../view_models/home_view_model.dart';

/// Current conditions and the week ahead for the selected place.
///
/// Scrolls with [scrollController] so it can live inside a draggable bottom
/// sheet; [showDragHandle] draws the sheet's handle above the content.
class ForecastPanel extends ConsumerWidget {
  const ForecastPanel({
    super.key,
    this.scrollController,
    this.showDragHandle = false,
  });

  final ScrollController? scrollController;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);
    final place = state.place;
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final sheet = theme.bottomSheetTheme;
    final handle = sheet.dragHandleSize ?? const Size(32, 4);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(spacing.xl, 0, spacing.xl, spacing.xl),
      children: [
        if (showDragHandle)
          Center(
            child: Container(
              width: handle.width,
              height: handle.height,
              margin: EdgeInsets.symmetric(vertical: spacing.md),
              decoration: ShapeDecoration(
                color: sheet.dragHandleColor,
                shape: const StadiumBorder(),
              ),
            ),
          )
        else
          SizedBox(height: spacing.xl),
        if (place != null) ...[
          Text(place.title, style: theme.textTheme.headlineSmall),
          if (place.hasSubtitle) Text(place.subtitle, style: muted),
          SizedBox(height: spacing.lg),
        ],
        ...switch (state.forecast) {
          // What is happening is read out by a screen reader as it changes:
          // loading, then failed.
          ForecastIdle() => const [_Status(child: _Hint())],
          ForecastLoading() => [
            _Status(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: spacing.xl),
                child: LinearProgressIndicator(
                  semanticsLabel: context.l10n.forecastLoading,
                ),
              ),
            ),
          ],
          ForecastFailed(:final message) => [
            _Status(
              child: _Failure(
                message: message,
                onRetry: ref.read(homeViewModelProvider.notifier).retryForecast,
              ),
            ),
          ],
          ForecastLoaded(:final forecast) => [
            _Current(forecast.current),
            SizedBox(height: spacing.xl),
            // The units choice drops below the heading when the text is too
            // large for both on one line.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: spacing.lg,
              runSpacing: spacing.sm,
              children: [
                Text(
                  context.l10n.forecastThisWeek,
                  style: theme.textTheme.titleMedium,
                ),
                _UnitsChoice(
                  selected: state.units,
                  onChanged: ref.read(homeViewModelProvider.notifier).setUnits,
                ),
              ],
            ),
            SizedBox(height: spacing.sm),
            _Week(forecast.days),
            SizedBox(height: spacing.lg),
            Text(
              context.l10n.forecastCredit,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        },
      ],
    );
  }
}

/// Something a screen reader announces when it appears or changes.
class _Status extends StatelessWidget {
  const _Status({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Semantics(container: true, liveRegion: true, child: child);
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.touch_app_outlined, color: theme.colorScheme.primary),
        SizedBox(width: theme.spacing.lg),
        Expanded(
          child: Text(
            context.l10n.forecastHint,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.cloud_off, color: theme.colorScheme.error),
            SizedBox(width: theme.spacing.lg),
            Expanded(child: Text(message, style: theme.textTheme.bodyLarge)),
          ],
        ),
        SizedBox(height: theme.spacing.lg),
        FilledButton.tonalIcon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(context.l10n.tryAgain),
        ),
      ],
    );
  }
}

class _Current extends StatelessWidget {
  const _Current(this.current);

  final CurrentUiModel current;

  static const _iconSize = 56.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Semantics(
      container: true,
      label: current.semanticLabel,
      child: ExcludeSemantics(
        // Wraps onto a second line when the text is too large for one.
        child: Wrap(
          spacing: spacing.lg,
          runSpacing: spacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  current.icon,
                  size: _iconSize,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: spacing.lg),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      current.temperature,
                      style: theme.textTheme.displayMedium,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(current.condition, style: theme.textTheme.titleMedium),
                Text(current.feelsLike, style: muted),
                Text(current.wind, style: muted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitsChoice extends StatelessWidget {
  const _UnitsChoice({required this.selected, required this.onChanged});

  final UnitsUiModel selected;
  final ValueChanged<UnitsUiModel> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SegmentedButton<UnitsUiModel>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: [
        ButtonSegment(
          value: UnitsUiModel.celsius,
          label: Text(l10n.unitsCelsius),
          tooltip: l10n.unitsCelsiusName,
        ),
        ButtonSegment(
          value: UnitsUiModel.fahrenheit,
          label: Text(l10n.unitsFahrenheit),
          tooltip: l10n.unitsFahrenheitName,
        ),
      ],
      selected: {selected},
      onSelectionChanged: (choice) => onChanged(choice.single),
    );
  }
}

class _Week extends StatelessWidget {
  const _Week(this.days);

  final List<DayUiModel> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return Text(context.l10n.forecastNoDays);

    return Card.filled(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: Theme.of(context).spacing.sm),
        child: Column(children: [for (final day in days) _DayRow(day)]),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow(this.day);

  final DayUiModel day;

  // Column widths at the default text size: room for "Today", "100%" and
  // "-88°".
  static const _dayColumn = 52.0;
  static const _chanceColumn = 44.0;
  static const _temperatureColumn = 34.0;
  static const _iconSize = 24.0;

  /// The range bar is dropped when it would be shorter than this.
  static const _minBarWidth = 24.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final muted = theme.colorScheme.onSurfaceVariant;
    // Column widths grow with the user's text size, so nothing wraps.
    final scaler = MediaQuery.textScalerOf(context);
    final dayWidth = scaler.scale(_dayColumn);
    final chanceWidth = scaler.scale(_chanceColumn);
    final temperatureWidth = scaler.scale(_temperatureColumn);
    final fixedWidth =
        dayWidth +
        _iconSize +
        chanceWidth +
        temperatureWidth * 2 +
        spacing.sm +
        spacing.md;

    final dayLabel = SizedBox(
      width: dayWidth,
      child: Text(
        day.dayLabel,
        softWrap: false,
        style: theme.textTheme.bodyLarge,
      ),
    );
    final icon = Icon(
      day.icon,
      size: _iconSize,
      color: theme.colorScheme.primary,
    );
    final chance = SizedBox(
      width: chanceWidth,
      child: Text(
        day.chance,
        softWrap: false,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.tertiary,
        ),
      ),
    );
    final low = SizedBox(
      width: temperatureWidth,
      child: Text(
        day.low,
        softWrap: false,
        textAlign: TextAlign.end,
        style: theme.textTheme.bodyLarge?.copyWith(color: muted),
      ),
    );
    final high = SizedBox(
      width: temperatureWidth,
      child: Text(
        day.high,
        softWrap: false,
        textAlign: TextAlign.end,
        style: theme.textTheme.bodyLarge,
      ),
    );

    return Semantics(
      container: true,
      label: day.semanticLabel,
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.lg,
            vertical: spacing.sm,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final hasRoomForBar =
                  constraints.maxWidth - fixedWidth >= _minBarWidth;
              if (hasRoomForBar) {
                return Row(
                  children: [
                    dayLabel,
                    icon,
                    chance,
                    low,
                    SizedBox(width: spacing.sm),
                    Expanded(
                      child: _RangeBar(start: day.barStart, end: day.barEnd),
                    ),
                    SizedBox(width: spacing.md),
                    high,
                  ],
                );
              }
              // Very large text, or a very narrow window: the numbers matter
              // more than the bar, and shrink together if they still do not
              // fit.
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    dayLabel,
                    icon,
                    chance,
                    low,
                    SizedBox(width: spacing.md),
                    high,
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A track for the week's whole temperature range with one day's part of it
/// filled in, from [start] to [end] (each 0 to 1).
class _RangeBar extends StatelessWidget {
  const _RangeBar({required this.start, required this.end});

  final double start;
  final double end;

  static const _thickness = 6.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Never thinner than the bar is tall, or a day whose low and high
        // match would vanish; and never pushed off the end of the track.
        final fill = math.min(
          width,
          math.max(_thickness, width * (end - start)),
        );
        final left = math.min(width * start, width - fill);

        return Container(
          height: _thickness,
          decoration: ShapeDecoration(
            color: scheme.surfaceContainerHighest,
            shape: const StadiumBorder(),
          ),
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            margin: EdgeInsetsDirectional.only(start: left),
            width: fill,
            decoration: ShapeDecoration(
              color: scheme.primary,
              shape: const StadiumBorder(),
            ),
          ),
        );
      },
    );
  }
}
