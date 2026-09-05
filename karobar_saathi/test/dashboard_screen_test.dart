import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karobar_saathi/l10n/app_localizations.dart';
import 'package:karobar_saathi/models/models.dart';
import 'package:karobar_saathi/providers/app_providers.dart';
import 'package:karobar_saathi/screens/dashboard_screen.dart';

const Dashboard _dashboard = Dashboard(
  todayProfit: 0,
  todaySales: 0,
  todayExpenses: 0,
  weeklyTrend: <TrendDay>[
    TrendDay(day: 'Sun', date: '2026-08-30', sales: 5077, expenses: 2405, profit: 2672),
    TrendDay(day: 'Mon', date: '2026-08-31', sales: 3595, expenses: 1624, profit: 1971),
    TrendDay(day: 'Tue', date: '2026-09-01', sales: 4724, expenses: 2205, profit: 2519),
    TrendDay(day: 'Wed', date: '2026-09-02', sales: 4470, expenses: 2280, profit: 2190),
    TrendDay(day: 'Thu', date: '2026-09-03', sales: 5298, expenses: 2652, profit: 2646),
    TrendDay(day: 'Fri', date: '2026-09-04', sales: 4869, expenses: 1310, profit: 3559),
    TrendDay(day: 'Sat', date: '2026-09-05', sales: 0, expenses: 0, profit: 0),
  ],
  cashPosition: 57854,
  killerInsight: 'Biscuits are your most profitable line.',
  totalEntriesToday: 0,
  topCategory: 'biscuits',
  topCategoryMargin: 90.7,
);

void main() {
  testWidgets('all dashboard sections become fully visible after entrance cascade',
      (WidgetTester tester) async {
    // The dashboard is a lazy ListView — a taller surface ensures every
    // section (including the insight card at the bottom) gets built.
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          dashboardProvider.overrideWith((ref) async => _dashboard),
          currentUserProvider.overrideWith(
            (ref) async => const AppUser(
              id: 'shop_001',
              name: 'Ahmad Chai Wala',
              businessType: 'tea_stall',
              businessName: 'Ahmad Tea Stall',
            ),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: DashboardScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(tester.takeException(), isNull);
    expect(find.byType(DashboardScreen), findsOneWidget);

    final List<FadeTransition> fades =
        tester.widgetList<FadeTransition>(find.byType(FadeTransition)).toList();
    // 5 staggered sections; each has exactly one FadeTransition.
    expect(fades.length, 5, reason: 'expected one FadeTransition per section');
    for (int i = 0; i < fades.length; i++) {
      expect(fades[i].opacity.value, 1.0,
          reason: 'section $i never reached full opacity');
    }
    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('Biscuits are your most profitable line.'), findsOneWidget);
  });
}
