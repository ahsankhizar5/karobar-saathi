/// Holds the selected UI language and persists it across launches.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_strings.dart';

const String _prefsKey = 'app_locale_code';

/// The active [AppLocale]. Defaults to English until the stored choice loads.
class LocaleController extends StateNotifier<AppLocale> {
  LocaleController() : super(AppLocale.en) {
    _restore();
  }

  Future<void> _restore() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? code = prefs.getString(_prefsKey);
    if (code != null) {
      state = AppLocale.fromCode(code);
    }
  }

  /// Switches language and remembers it for next launch.
  Future<void> setLocale(AppLocale locale) async {
    if (locale == state) return;
    state = locale;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.code);
  }
}

final StateNotifierProvider<LocaleController, AppLocale> localeProvider =
    StateNotifierProvider<LocaleController, AppLocale>(
        (ref) => LocaleController());
