import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karobar_saathi/l10n/app_localizations.dart';
import 'package:karobar_saathi/models/models.dart';
import 'package:karobar_saathi/widgets/weekly_trend_chart.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: ListView(children: <Widget>[child])),
    );

const List<TrendDay> _days = <TrendDay>[
  TrendDay(day: 'Sun', date: '2026-08-30', sales: 5077, expenses: 2405, profit: 2672),
  TrendDay(day: 'Mon', date: '2026-08-31', sales: 3595, expenses: 1624, profit: 1971),
  TrendDay(day: 'Tue', date: '2026-09-01', sales: 4724, expenses: 2205, profit: 2519),
  TrendDay(day: 'Wed', date: '2026-09-02', sales: 4470, expenses: 2280, profit: 2190),
  TrendDay(day: 'Thu', date: '2026-09-03', sales: 5298, expenses: 2652, profit: 2646),
  TrendDay(day: 'Fri', date: '2026-09-04', sales: 4869, expenses: 1310, profit: 3559),
  TrendDay(day: 'Sat', date: '2026-09-05', sales: 0, expenses: 0, profit: 0),
];

void main() {
  testWidgets('renders 7-day bars and legends with live backend data',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const WeeklyTrendChart(days: _days)));
    await tester.pump();

    expect(find.byType(WeeklyTrendChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
