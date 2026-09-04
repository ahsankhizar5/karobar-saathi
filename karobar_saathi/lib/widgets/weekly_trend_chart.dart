/// A dependency-free 7-day sales/expenses bar chart.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/app_strings.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class WeeklyTrendChart extends StatelessWidget {
  const WeeklyTrendChart({super.key, required this.days});

  final List<TrendDay> days;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppStrings s = context.l10n;
    final Color salesColor = entryAccent(EntryType.sale, scheme);
    final Color expenseColor = entryAccent(EntryType.expense, scheme);

    if (days.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            s.noTrendData,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    // Scale bars against the largest single value in the window.
    double maxValue = 0;
    for (final TrendDay day in days) {
      maxValue = <double>[maxValue, day.sales, day.expenses].reduce(
        (double a, double b) => a > b ? a : b,
      );
    }
    if (maxValue <= 0) maxValue = 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              s.last7Days,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              s.salesVsOut,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 168,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: days
                    .map((TrendDay day) => Expanded(
                          child: _DayColumn(
                            day: day,
                            maxValue: maxValue,
                            salesColor: salesColor,
                            expenseColor: expenseColor,
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: <Widget>[
                _Legend(color: salesColor, label: s.legendSales),
                _Legend(color: expenseColor, label: s.legendMoneyOut),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.maxValue,
    required this.salesColor,
    required this.expenseColor,
  });

  final TrendDay day;
  final double maxValue;
  final Color salesColor;
  final Color expenseColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const double trackHeight = 120;
    final double salesHeight = (day.sales / maxValue) * trackHeight;
    final double expenseHeight = (day.expenses / maxValue) * trackHeight;

    return Semantics(
      label: '${day.day}: sales ${Formats.money(day.sales)}, '
          'money out ${Formats.money(day.expenses)}, '
          'profit ${Formats.money(day.profit)}',
      excludeSemantics: true,
      child: Tooltip(
        message: '${day.day} • ${day.date}\n'
            'Sales ${Formats.money(day.sales)}\n'
            'Out ${Formats.money(day.expenses)}\n'
            'Profit ${Formats.money(day.profit)}',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Text(
                Formats.compact(day.profit),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: day.profit >= 0
                      ? salesColor
                      : theme.colorScheme.error,
                ),
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: trackHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    _Bar(height: salesHeight, color: salesColor),
                    const SizedBox(width: 3),
                    _Bar(height: expenseHeight, color: expenseColor),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                day.day,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      width: 10,
      // Keep a visible stub for zero-value days.
      height: height.clamp(3.0, 120.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
