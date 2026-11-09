import 'package:flutter/widgets.dart';
import 'package:geuralunas/l10n/gen/app_localizations.dart';

export 'package:geuralunas/l10n/gen/app_localizations.dart';

/// Shortcut: `context.l10n.appName`.
extension L10nX on BuildContext {
  /// Localized strings for the current locale.
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
