import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';

export '../../l10n/generated/app_localizations.dart';

/// The app's wording, from `lib/l10n/app_en.arb`. Widgets read it here.
extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// The same wording for code with no [BuildContext]: the view models, which
/// word the UI models they hand to the screen.
///
/// It follows the device's language, and is built again when that changes.
final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  final binding = WidgetsBinding.instance;
  final observer = _LocaleObserver(ref.invalidateSelf);
  binding.addObserver(observer);
  ref.onDispose(() => binding.removeObserver(observer));

  return lookupAppLocalizations(
    basicLocaleListResolution(
      binding.platformDispatcher.locales,
      AppLocalizations.supportedLocales,
    ),
  );
});

class _LocaleObserver with WidgetsBindingObserver {
  _LocaleObserver(this._onChange);

  final VoidCallback _onChange;

  @override
  void didChangeLocales(List<Locale>? locales) => _onChange();
}
