/// Ledger screen — the shopkeeper's confirmed raw entries, newest first.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../l10n/app_strings.dart';
import '../l10n/entry_type_l10n.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ledger_entry_tile.dart';
import '../widgets/state_views.dart';
import '../widgets/transaction_sheet.dart';

class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    LedgerEntry entry,
  ) async {
    final AppStrings s = context.l10n;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(s.deleteEntryTitle),
        content: Text(
          s.deleteEntryBody(
            entry.entryType.localizedLabel(s),
            Formats.money(entry.amount),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.keep),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(apiServiceProvider).deleteEntry(entry.id);
      await refreshShopData(ref);
      messenger.showSnackBar(SnackBar(content: Text(s.entryDeleted)));
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<LedgerEntry>> ledger = ref.watch(ledgerProvider);
    final AppStrings s = context.l10n;

    return RefreshIndicator(
      onRefresh: () => refreshShopData(ref),
      child: ledger.when(
        loading: () => LoadingView(message: s.loadingLedger),
        error: (Object error, StackTrace _) => ListView(
          children: <Widget>[
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: ErrorView(
                message: '$error',
                onRetry: () => ref.invalidate(ledgerProvider),
              ),
            ),
          ],
        ),
        data: (List<LedgerEntry> entries) {
          if (entries.isEmpty) {
            return ListView(
              children: <Widget>[
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: EmptyView(
                    icon: Icons.menu_book_outlined,
                    title: s.ledgerEmptyTitle,
                    message: s.ledgerEmptyBody,
                    action: FilledButton.icon(
                      onPressed: () async {
                        final bool saved = await showTransactionSheet(context);
                        if (saved) await refreshShopData(ref);
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: Text(s.addTransaction),
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: entries.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return _LedgerSummary(entries: entries);
              }
              final LedgerEntry entry = entries[index - 1];
              return LedgerEntryTile(
                entry: entry,
                onDelete: () => _delete(context, ref, entry),
              );
            },
          );
        },
      ),
    );
  }
}

class _LedgerSummary extends StatelessWidget {
  const _LedgerSummary({required this.entries});

  final List<LedgerEntry> entries;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.l10n;

    double inflow = 0;
    double outflow = 0;
    for (final LedgerEntry entry in entries) {
      if (entry.entryType.isInflow) {
        inflow += entry.amount;
      } else if (entry.entryType.isOutflow) {
        outflow += entry.amount;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            s.recordedEntries(entries.length),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            s.inOut(Formats.money(inflow), Formats.money(outflow)),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
