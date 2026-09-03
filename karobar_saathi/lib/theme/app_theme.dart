/// Material 3 theme and shared formatting helpers.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';

/// Brand seed — a deep Pakistani green.
const Color kSeedColor = Color(0xFF00695C);

ThemeData buildAppTheme(Brightness brightness) {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: kSeedColor,
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
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
      ),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

/// Colour and icon per entry type, kept consistent everywhere.
class EntryVisuals {
  const EntryVisuals(this.color, this.icon);

  final Color color;
  final IconData icon;

  static EntryVisuals of(EntryType type, ColorScheme scheme) {
    switch (type) {
      case EntryType.sale:
        return const EntryVisuals(
            Color(0xFF2E7D32), Icons.trending_up_rounded);
      case EntryType.purchase:
        return const EntryVisuals(
            Color(0xFF1565C0), Icons.inventory_2_outlined);
      case EntryType.expense:
        return const EntryVisuals(
            Color(0xFFEF6C00), Icons.receipt_long_outlined);
      case EntryType.withdrawal:
        return const EntryVisuals(Color(0xFF6A1B9A), Icons.home_outlined);
      case EntryType.unclear:
        return EntryVisuals(scheme.error, Icons.help_outline_rounded);
    }
  }
}
