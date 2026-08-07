import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../generated/app_localizations.dart';
import 'tolgee_app_localizations.g.dart';

/// Context-free equivalent of `context.l10n`, for code that resolves strings
/// without a `BuildContext` (notification scheduling, background work).
///
/// Drop-in replacement for `lookupAppLocalizations`.
AppLocalizations tolgeeAppLocalizationsFor(Locale locale) =>
    TolgeeAppLocalizations(lookupAppLocalizations(locale));

/// Drop-in replacement for `AppLocalizations.delegate` that wraps the bundled
/// translations in [TolgeeAppLocalizations].
///
/// Everything resolved through `context.l10n` therefore consults Tolgee first
/// and falls back to the generated ARB value, with no changes at call sites.
class TolgeeAppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const TolgeeAppLocalizationsDelegate({this.revision = 0});

  /// Bumped whenever new translations are available. `Localizations` only
  /// reloads when this changes, so unrelated widget rebuilds stay cheap.
  final int revision;

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.delegate.isSupported(locale);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(
      TolgeeAppLocalizations(lookupAppLocalizations(locale)),
    );
  }

  @override
  bool shouldReload(TolgeeAppLocalizationsDelegate old) =>
      old.revision != revision;
}
