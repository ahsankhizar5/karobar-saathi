/// Shopkeeper dashboard — today's profit, cash position, 7-day trend, insight.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../l10n/app_strings.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard_cards.dart';
import '../widgets/shimmer.dart';
import '../widgets/state_views.dart';
import '../widgets/weekly_trend_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Dashboard> dashboard = ref.watch(dashboardProvider);
    final AsyncValue<AppUser> user = ref.watch(currentUserProvider);

    return RefreshIndicator(
      onRefresh: () => refreshShopData(ref),
      // Keep last data on screen while a refresh is in flight — no flash.
      child: dashboard.when(
        skipLoadingOnReload: true,
        loading: () => const _DashboardSkeleton(),
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

/// Loading placeholder shaped like the dashboard it is standing in for.
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: const <Widget>[
        Shimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ShimmerBox(width: 220, height: 20, radius: 10),
              SizedBox(height: 8),
              ShimmerBox(width: 130, height: 12),
            ],
          ),
        ),
        SizedBox(height: 20),
        Shimmer(child: ShimmerBox(height: 208, radius: 20)),
        SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(child: Shimmer(child: ShimmerBox(height: 168, radius: 20))),
            SizedBox(width: 14),
            Expanded(child: Shimmer(child: ShimmerBox(height: 168, radius: 20))),
          ],
        ),
        SizedBox(height: 14),
        Shimmer(child: ShimmerBox(height: 230, radius: 20)),
        SizedBox(height: 14),
        Shimmer(child: ShimmerBox(height: 120, radius: 20)),
      ],
    );
  }
}

class _DashboardBody extends StatefulWidget {
  const _DashboardBody({
    required this.data,
    this.userName,
    this.businessName,
  });

  final Dashboard data;
  final String? userName;
  final String? businessName;

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.l10n;
    final Dashboard data = widget.data;
    final double runway = data.cashPosition;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: <Widget>[
        if (widget.userName != null) ...<Widget>[
          _StaggerIn(index: 0, animation: _entrance, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                s.greeting(widget.userName!),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (widget.businessName != null &&
                  widget.businessName!.isNotEmpty)
                Text(
                  widget.businessName!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          )),
          const SizedBox(height: 16),
        ],

        _StaggerIn(
          index: 1,
          animation: _entrance,
          child: ProfitHeroCard(
            profit: data.todayProfit,
            sales: data.todaySales,
            expenses: data.todayExpenses,
            entryCount: data.totalEntriesToday,
          ),
        ),
        const SizedBox(height: 14),

        _StaggerIn(
          index: 2,
          animation: _entrance,
          // IntrinsicHeight bounds the Row so CrossAxisAlignment.stretch has
          // a finite height to fill — inside a ListView the cross axis is
          // otherwise unbounded, which breaks layout of this section and
          // everything below it.
          child: IntrinsicHeight(
            child: Row(
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
                    value: (data.topCategory == null ||
                            data.topCategory!.isEmpty)
                        ? '—'
                        : data.topCategory!,
                    icon: Icons.category_outlined,
                    caption: data.topCategoryMargin == null
                        ? s.recordMoreSales
                        : s.marginPct(
                            data.topCategoryMargin!.toStringAsFixed(1)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        _StaggerIn(
          index: 3,
          animation: _entrance,
          child: WeeklyTrendChart(days: data.weeklyTrend),
        ),
        const SizedBox(height: 14),

        if (data.killerInsight.isNotEmpty)
          _StaggerIn(
            index: 4,
            animation: _entrance,
            child: InsightCard(insight: data.killerInsight),
          ),
      ],
    );
  }
}

/// Fades and lifts [child] into place as part of the dashboard's entrance
/// cascade — each section lands ~90 ms after the one above it.
class _StaggerIn extends StatelessWidget {
  const _StaggerIn({
    required this.index,
    required this.animation,
    required this.child,
  });

  final int index;
  final Animation<double> animation;
  final Widget child;

  static const int _sections = 5;
  static const double _step = 1 / _sections;

  @override
  Widget build(BuildContext context) {
    final double start = index * _step;
    final Animation<double> curved = CurvedAnimation(
      parent: animation,
      curve: Interval(
        start,
        math.min(start + _step * 1.8, 1),
        curve: Curves.easeOutCubic,
      ),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
