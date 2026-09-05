/// Material 3 theme and shared formatting helpers.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';

/// Brand seed — a deep, calm emerald. Reads as trustworthy and bank-grade.
const Color kSeedColor = Color(0xFF0B6B5B);

/// Geometric sans used across the app; covers all weights via the variable
/// font file, and falls back to system fonts for Urdu script.
const String kFontFamily = 'Outfit';

/// Warm off-white canvas for light mode — softer on the eye than pure white.
const Color _kLightSurface = Color(0xFFF7F6F2);
const Color _kLightCard = Color(0xFFFFFFFF);

/// Entry accent palette, shared by [EntryVisuals] and chart widgets.
/// Light-mode values are tuned for white cards; the `…Dark` variants stay
/// readable on dark surfaces.
const Color kAccentSale = Color(0xFF1B7F5A); // green — money in
const Color kAccentPurchase = Color(0xFF2563A8); // blue — stock/buy
const Color kAccentExpense = Color(0xFFD98324); // amber — expense
const Color kAccentWithdrawal = Color(0xFF7A4FB0); // violet — household

const Color kAccentSaleDark = Color(0xFF6CC6A4);
const Color kAccentPurchaseDark = Color(0xFF82B7EE);
const Color kAccentExpenseDark = Color(0xFFEDB36A);
const Color kAccentWithdrawalDark = Color(0xFFC0A1E8);

ThemeData buildAppTheme(Brightness brightness) {
  final bool isLight = brightness == Brightness.light;
  ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: kSeedColor,
    brightness: brightness,
  );

  // Warm the light canvas so large surfaces feel calm rather than clinical.
  if (isLight) {
    scheme = scheme.copyWith(
      surface: _kLightSurface,
      surfaceContainerLowest: _kLightCard,
      surfaceContainerLow: _kLightCard,
      surfaceContainer: const Color(0xFFF1F0EB),
      surfaceContainerHigh: const Color(0xFFEBEAE4),
    );
  }

  final Color hairline = isLight
      ? scheme.outlineVariant.withOpacity(0.6)
      : scheme.outlineVariant.withOpacity(0.4);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: kFontFamily,
    scaffoldBackgroundColor: scheme.surface,
    visualDensity: VisualDensity.standard,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 3,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
        fontFamily: kFontFamily,
      ),
    ),
    cardTheme: CardTheme(
      elevation: isLight ? 1 : 0,
      shadowColor: Colors.black.withOpacity(isLight ? 0.06 : 0),
      clipBehavior: Clip.antiAlias,
      color: isLight ? _kLightCard : scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: hairline),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: kFontFamily,
        ),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: kFontFamily,
        ),
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withOpacity(0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: const DividerThemeData(space: 1, thickness: 1),
    listTileTheme: const ListTileThemeData(
      minVerticalPadding: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    ),
  );
}

/// Rupee and date formatting used across the app.
class Formats {
  Formats._();

  static final NumberFormat _rupees =
      NumberFormat.currency(locale: 'en_PK', symbol: 'Rs ', decimalDigits: 0);
  static final NumberFormat _compact = NumberFormat.compact(locale: 'en_PK');
  static final DateFormat _dayMonth = DateFormat('d MMM');
  static final DateFormat _dayMonthTime = DateFormat('d MMM, h:mm a');

  /// `Rs 4,500`
  static String money(double value) => _rupees.format(value);

  /// `Rs +4,500` / `Rs -900` — used for signed deltas such as profit.
  static String signedMoney(double value) {
    final String formatted = _rupees.format(value.abs());
    if (value == 0) return formatted;
    return value > 0 ? '+$formatted' : '-$formatted';
  }

  /// `4.5K` — for dense chart labels.
  static String compact(double value) => _compact.format(value);

  static String dayMonth(DateTime date) => _dayMonth.format(date);

  static String dayMonthTime(DateTime date) => _dayMonthTime.format(date);

  /// Formats a backend ISO timestamp, falling back to the raw string.
  static String timestamp(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final DateTime? parsed =
        DateTime.tryParse(iso.endsWith('Z') ? iso : '${iso}Z');
    if (parsed == null) return iso;
    return _dayMonthTime.format(parsed.toLocal());
  }
}

/// Accent color for [type] that stays readable in both brightnesses.
Color entryAccent(EntryType type, ColorScheme scheme) {
  final bool dark = scheme.brightness == Brightness.dark;
  switch (type) {
    case EntryType.sale:
      return dark ? kAccentSaleDark : kAccentSale;
    case EntryType.purchase:
      return dark ? kAccentPurchaseDark : kAccentPurchase;
    case EntryType.expense:
      return dark ? kAccentExpenseDark : kAccentExpense;
    case EntryType.withdrawal:
      return dark ? kAccentWithdrawalDark : kAccentWithdrawal;
    case EntryType.unclear:
      return scheme.error;
  }
}

/// Colour and icon per entry type, kept consistent everywhere.
class EntryVisuals {
  const EntryVisuals(this.color, this.icon);

  final Color color;
  final IconData icon;

  static EntryVisuals of(EntryType type, ColorScheme scheme) {
    switch (type) {
      case EntryType.sale:
        return EntryVisuals(
            entryAccent(type, scheme), Icons.trending_up_rounded);
      case EntryType.purchase:
        return EntryVisuals(
            entryAccent(type, scheme), Icons.inventory_2_outlined);
      case EntryType.expense:
        return EntryVisuals(
            entryAccent(type, scheme), Icons.receipt_long_outlined);
      case EntryType.withdrawal:
        return EntryVisuals(
            entryAccent(type, scheme), Icons.home_outlined);
      case EntryType.unclear:
        return EntryVisuals(scheme.error, Icons.help_outline_rounded);
    }
  }
}
