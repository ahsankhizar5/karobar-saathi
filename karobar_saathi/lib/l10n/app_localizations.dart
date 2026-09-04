/// Glue between Flutter's localization plumbing and our plain-map [AppStrings].
///
/// Register [AppLocalizations.delegate] in `MaterialApp.localizationsDelegates`
/// and read strings anywhere with `context.l10n`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_strings.dart';

/// Localized strings for the current [Locale], resolved from [AppStrings].
class AppLocalizations {
  const AppLocalizations(this.localeEnum, this.strings);

  final AppLocale localeEnum;
  final AppStrings strings;

  static AppLocalizations of(BuildContext context) {
    final AppLocalizations? instance =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(instance != null, 'No AppLocalizations found in context');
    return instance!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Delegates to register on `MaterialApp` — ours plus Flutter's built-ins
  /// (Material/Widgets/Cupertino) so stock widgets localize and lay out RTL.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = AppLocale.supportedLocales;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocale.values.any((AppLocale l) => l.code == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final AppLocale resolved = AppLocale.fromCode(locale.languageCode);
    return AppLocalizations(resolved, AppStrings.of(resolved));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// `context.l10n.<key>` — the ergonomic accessor used across the UI.
extension AppLocalizationsX on BuildContext {
  AppStrings get l10n => AppLocalizations.of(this).strings;
}
