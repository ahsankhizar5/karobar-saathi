/// Shopkeeper dashboard — today's profit, cash position, 7-day trend, insight.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../l10n/app_strings.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard_cards.dart';
import '../widgets/state_views.dart';
import '../widgets/weekly_trend_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Dashboard> dashboard = ref.watch(dashboardProvider);
    final AsyncValue<AppUser> user = ref.watch(currentUserProvider);
    final AppStrings s = context.l10n;

    return RefreshIndicator(
      onRefresh: () => refreshShopData(ref),
      child: dashboard.when(
        loading: () => LoadingView(message: s.loadingBooks),
        error: (Object error, StackTrace _) => ListView(
          // Keep pull-to-refresh usable in the error state.
          children: <Widget>[
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: ErrorView(
                message: errorText(context, error),
                onRetry: () => ref.invalidate(dashboardProvider),
              ),
            ),
          ],
        ),
        data: (Dashboard data) => _DashboardBody(
          data: data,
          userName: user.value?.name,
          businessName: user.value?.businessName,
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.data,
    this.userName,
    this.businessName,
  });

  final Dashboard data;
  final String? userName;
  final String? businessName;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.l10n;
    final double runway = data.cashPosition;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: <Widget>[
        if (userName != null) ...<Widget>[
          Text(
            s.greeting(userName!),
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (businessName != null && businessName!.isNotEmpty)
            Text(
              businessName!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          const SizedBox(height: 16),
        ],

        ProfitHeroCard(
          profit: data.todayProfit,
          sales: data.todaySales,
          expenses: data.todayExpenses,
          entryCount: data.totalEntriesToday,
        ),
        const SizedBox(height: 14),

        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: StatCard(
                label: s.cashPosition,
                value: Formats.money(runway),
                icon: Icons.account_balance_wallet_outlined,
                caption: s.cashPositionCaption,
                color: runway >= 0
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: StatCard(
                label: s.bestCategory,
                value: (data.topCategory == null || data.topCategory!.isEmpty)
                    ? '—'
                    : data.topCategory!,
                icon: Icons.category_outlined,
                caption: data.topCategoryMargin == null
                    ? s.recordMoreSales
                    : s.marginPct(data.topCategoryMargin!.toStringAsFixed(1)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        WeeklyTrendChart(days: data.weeklyTrend),
        const SizedBox(height: 14),

        if (data.killerInsight.isNotEmpty)
          InsightCard(insight: data.killerInsight),
      ],
    );
  }
}
