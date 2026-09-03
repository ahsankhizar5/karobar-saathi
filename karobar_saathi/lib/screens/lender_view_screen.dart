/// Concept-only Lender View.
///
/// This screen is a *demonstration* of what a partner lender or government
/// department would see through the public evidence API. It is labelled as a
/// concept throughout so it is never mistaken for a live lending product.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        const SizedBox(height: 16),
        _ShopSelector(selectedId: selectedId),
        const SizedBox(height: 16),
        _ConsentControl(
          shop: shop,
          consented: controller.consentSwitchValue,
          busy: state is EvidenceLoading,
          onChanged: (bool value) => controller.setConsent(value),
        ),
        const SizedBox(height: 16),
        switch (state) {
          EvidenceLoading() => const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: LoadingView(message: 'Calling the evidence API…'),
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

/// Prominent, permanent "this is a concept" disclosure.
class _ConceptBanner extends StatelessWidget {
  const _ConceptBanner();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.science_outlined, color: scheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'CONCEPT DEMO — NOT A LENDING PRODUCT',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'An illustration of what a partner lender or government '
                    'department would receive from the consent-gated evidence '
                    'API. No credit decision, score, or loan offer is made '
                    'here, and the shops below are seeded sample data.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                      height: 1.4,
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

/// The three seeded demo shops.
class _ShopSelector extends ConsumerWidget {
  const _ShopSelector({required this.selectedId});

  final String selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Sample applicant',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
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
                subtitle: Text('${shop.description} • ${shop.id}'),
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Consent switch that PATCHes the backend and re-requests the profile.
class _ConsentControl extends StatelessWidget {
  const _ConsentControl({
    required this.shop,
    required this.consented,
    required this.busy,
    required this.onChanged,
  });

  final DemoShop shop;
  final bool consented;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SwitchListTile(
              value: consented,
              onChanged: busy ? null : onChanged,
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${shop.name} shares their data',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                consented
                    ? 'Consent granted — the API returns the evidence profile.'
                    : 'Consent revoked — the API returns HTTP 403.',
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.lock_outline_rounded,
                      size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The shopkeeper owns this switch. Flip it to see the '
                      'API refuse access in real time.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
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

/// The 403 state, presented as a feature rather than a failure.
class _ConsentDeniedCard extends StatelessWidget {
  const _ConsentDeniedCard({required this.message, required this.shop});

  final String message;
  final DemoShop shop;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

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
                    'HTTP 403 — Access refused',
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
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: scheme.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Turn the consent switch back on to restore access.',
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
class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.profile, required this.shop});

  final EvidenceProfile profile;
  final DemoShop shop;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final EvidenceMetrics m = profile.metrics;

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
                        'Consent verified — profile released',
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
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Generated ${Formats.timestamp(profile.profileGeneratedAt)}',
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
                  'Verified metrics (last 30 days)',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _MetricRow(
                  icon: Icons.show_chart_rounded,
                  label: 'Average daily sales',
                  value: Formats.money(m.avgDailySales),
                ),
                _MetricRow(
                  icon: Icons.waves_rounded,
                  label: 'Sales volatility',
                  value: m.salesVolatility,
                ),
                _MetricRow(
                  icon: Icons.event_available_rounded,
                  label: 'Days with transactions',
                  value: '${m.daysWithTransactions}',
                ),
                _MetricRow(
                  icon: Icons.savings_outlined,
                  label: 'Cash buffer',
                  value: '${m.cashBufferDays} days',
                  isLast: true,
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
                  'Why this profile looks like this',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Every factor is traceable to recorded transactions — no '
                  'opaque score.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                if (profile.explainableFactors.isEmpty)
                  Text(
                    'No factors available yet.',
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
          label: const Text('View underlying ledger records'),
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
                        'Underlying records',
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
                  tooltip: 'Close',
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
                  message: '$error',
                  onRetry: () => ref.invalidate(lenderLedgerProvider),
                ),
              ),
              data: (List<LedgerEntry> entries) {
                if (entries.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: EmptyView(
                      title: 'No records',
                      message: 'This sample shop has no ledger entries.',
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
