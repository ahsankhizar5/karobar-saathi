/// Concept-only Lender View.
///
/// This screen is a *demonstration* of what a partner lender or government
/// department would see through the public evidence API. It is labelled as a
/// concept throughout so it is never mistaken for a live lending product.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../l10n/app_strings.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/ledger_entry_tile.dart';
import '../widgets/state_views.dart';

class LenderViewScreen extends ConsumerWidget {
  const LenderViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String selectedId = ref.watch(lenderSelectedShopProvider);
    final EvidenceState state = ref.watch(lenderEvidenceProvider);
    final LenderEvidenceController controller =
        ref.read(lenderEvidenceProvider.notifier);
    final DemoShop shop = kDemoShops.firstWhere(
      (DemoShop s) => s.id == selectedId,
      orElse: () => kDemoShops.first,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: <Widget>[
        const _ConceptBanner(),
        const SizedBox(height: 12),
        _ApplicantCard(
          selectedId: selectedId,
          shop: shop,
          consented: controller.consentSwitchValue,
          busy: state is EvidenceLoading,
          onConsentChanged: (bool value) => controller.setConsent(value),
        ),
        const SizedBox(height: 16),
        switch (state) {
          EvidenceLoading() => Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: LoadingView(message: context.l10n.callingApi),
            ),
          EvidenceGranted(profile: final EvidenceProfile profile) =>
            _ProfileView(profile: profile, shop: shop),
          EvidenceConsentDenied(message: final String message) =>
            _ConsentDeniedCard(message: message, shop: shop),
          EvidenceFailure(message: final String message) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: ErrorView(
                message: message,
                onRetry: controller.load,
              ),
            ),
        },
      ],
    );
  }
}

/// Prominent, permanent "this is a concept" disclosure — kept to two lines so
/// it stays visible without burying the screen in text.
class _ConceptBanner extends StatelessWidget {
  const _ConceptBanner();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppStrings s = context.l10n;

    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.science_outlined,
              size: 18,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    s.conceptBadge,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.conceptShort,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The three seeded demo shops plus the consent switch that gates the API —
/// one container, one decision flow: pick an applicant, flip their consent.
class _ApplicantCard extends ConsumerWidget {
  const _ApplicantCard({
    required this.selectedId,
    required this.shop,
    required this.consented,
    required this.busy,
    required this.onConsentChanged,
  });

  final String selectedId;
  final DemoShop shop;
  final bool consented;
  final bool busy;
  final ValueChanged<bool> onConsentChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppStrings s = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              s.sampleApplicant,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            ...kDemoShops.map((DemoShop shop) {
              final bool selected = shop.id == selectedId;
              return RadioListTile<String>(
                value: shop.id,
                groupValue: selectedId,
                onChanged: (String? value) {
                  if (value != null) {
                    ref.read(lenderSelectedShopProvider.notifier).state = value;
                  }
                },
                title: Text(
                  shop.name,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                subtitle: Text(s.shopDescription(shop.id, shop.description)),
                contentPadding: EdgeInsets.zero,
              );
            }),
            const Divider(height: 24),
            SwitchListTile(
              value: consented,
              onChanged: busy ? null : onConsentChanged,
              contentPadding: EdgeInsets.zero,
              title: Text(
                s.sharesData(shop.name),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                consented ? s.consentGrantedSub : s.consentRevokedSub,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.consentHint,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The 403 state, presented as a feature rather than a failure.
class _ConsentDeniedCard extends StatelessWidget {
  const _ConsentDeniedCard({required this.message, required this.shop});

  final String message;
  final DemoShop shop;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppStrings s = context.l10n;

    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.block_rounded, color: scheme.onErrorContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.http403Title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onErrorContainer,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.onErrorContainer.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'GET /api/v1/evidence-profile/${shop.id}\n'
                'X-User-Consent: true\n'
                '→ 403 consent_required',
                textDirection: TextDirection.ltr,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: scheme.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              s.restoreConsent,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onErrorContainer,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The granted evidence profile: metrics, explainable factors, readiness.
class _ProfileView extends ConsumerWidget {
  const _ProfileView({required this.profile, required this.shop});

  final EvidenceProfile profile;
  final DemoShop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppStrings s = context.l10n;
    final EvidenceMetrics m = profile.metrics;
    // Watching here pre-warms the fetch used by the raw-records modal and
    // lets the activity calendar appear as soon as the ledger arrives.
    final AsyncValue<List<LedgerEntry>> ledger =
        ref.watch(lenderLedgerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Card(
          color: scheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.verified_user_outlined,
                        color: scheme.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.consentVerified,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  profile.readinessSummary,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  s.generatedAt(Formats.timestamp(profile.profileGeneratedAt)),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  s.verifiedMetrics,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _MetricRow(
                  icon: Icons.show_chart_rounded,
                  label: s.avgDailySales,
                  value: Formats.money(m.avgDailySales),
                ),
                _MetricRow(
                  icon: Icons.waves_rounded,
                  label: s.salesVolatility,
                  value: s.volatility(m.salesVolatility),
                ),
                _MetricRow(
                  icon: Icons.event_available_rounded,
                  label: s.daysWithTransactions,
                  value: '${m.daysWithTransactions}',
                ),
                _MetricRow(
                  icon: Icons.savings_outlined,
                  label: s.cashBuffer,
                  value: s.daysValue(m.cashBufferDays),
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        if (ledger.hasValue) ...<Widget>[
          _ActivityCalendarCard(entries: ledger.value ?? const <LedgerEntry>[]),
          const SizedBox(height: 14),
        ],

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  s.whyProfile,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  s.whyProfileSub,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                if (profile.explainableFactors.isEmpty)
                  Text(
                    s.noFactors,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  )
                else
                  ...profile.explainableFactors.map(
                    (String factor) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(Icons.check_circle_outline_rounded,
                              size: 18, color: scheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              factor,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        OutlinedButton.icon(
          onPressed: () => showRawLedgerModal(context, shop),
          icon: const Icon(Icons.receipt_long_outlined),
          label: Text(s.viewUnderlying),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Semantics(
        label: '$label $value',
        excludeSemantics: true,
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: theme.textTheme.bodyMedium),
            ),
            Text(
              value,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// Day-by-day record of the last 30 days, derived from the same ledger rows
/// the "underlying records" modal shows — the visible proof behind the
/// "days with transactions" metric. Counts confirmed entries by UTC date,
/// matching how the backend evidence engine computes the metric.
class _ActivityCalendarCard extends StatelessWidget {
  const _ActivityCalendarCard({required this.entries});

  final List<LedgerEntry> entries;

  static DateTime? _utcDay(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final DateTime? parsed =
        DateTime.tryParse(iso.endsWith('Z') ? iso : '${iso}Z');
    if (parsed == null) return null;
    return DateTime.utc(parsed.year, parsed.month, parsed.day);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppStrings s = context.l10n;

    final DateTime nowUtc = DateTime.now().toUtc();
    final DateTime today =
        DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);

    final Map<DateTime, int> counts = <DateTime, int>{};
    for (final LedgerEntry entry in entries) {
      if (!entry.confirmed) continue;
      final DateTime? day = _utcDay(entry.createdAt);
      if (day == null || day.isAfter(today)) continue;
      if (today.difference(day).inDays >= 30) continue;
      counts[day] = (counts[day] ?? 0) + 1;
    }

    final List<DateTime> window = List<DateTime>.generate(
      30,
      (int i) => DateTime.utc(today.year, today.month, today.day - (29 - i)),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              s.activityTitle,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              s.activityDaysCount(counts.length),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                const double gap = 4;
                const int columns = 10;
                final double cell =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: <Widget>[
                    for (final DateTime day in window)
                      SizedBox(
                        width: cell,
                        height: cell,
                        child: _DayCell(
                          day: day,
                          count: counts[day] ?? 0,
                          isToday: day == today,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(s.activityLegendRecorded,
                    style: theme.textTheme.bodySmall),
                const SizedBox(width: 16),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                ),
                const SizedBox(width: 6),
                Text(s.activityLegendMissed, style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.count,
    required this.isToday,
  });

  final DateTime day;
  final int count;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppStrings s = context.l10n;
    final bool active = count > 0;
    final String label = Formats.dayMonth(day);

    final String message = count == 0
        ? s.dayNoRecords(label)
        : count == 1
            ? s.dayRecordsOne(label)
            : s.dayRecordsMany(label, count);

    return Tooltip(
      message: message,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          border: isToday
              ? Border.all(color: scheme.outline, width: 1.5)
              : null,
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color:
                  active ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal listing the shop's raw ledger rows behind the profile.
Future<void> showRawLedgerModal(BuildContext context, DemoShop shop) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => _RawLedgerModal(shop: shop),
  );
}

class _RawLedgerModal extends ConsumerWidget {
  const _RawLedgerModal({required this.shop});

  final DemoShop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.l10n;
    final AsyncValue<List<LedgerEntry>> ledger =
        ref.watch(lenderLedgerProvider);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        s.underlyingRecords,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${shop.name} • ${shop.id}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: s.close,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ledger.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: LoadingView(),
              ),
              error: (Object error, StackTrace _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: ErrorView(
                  message: errorText(context, error),
                  onRetry: () => ref.invalidate(lenderLedgerProvider),
                ),
              ),
              data: (List<LedgerEntry> entries) {
                if (entries.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: EmptyView(
                      title: s.noRecordsTitle,
                      message: s.noRecordsBody,
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (BuildContext context, int index) =>
                      LedgerEntryTile(entry: entries[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
