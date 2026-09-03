/// List tile rendering one saved ledger entry, including its raw transcript.
library;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

class LedgerEntryTile extends StatelessWidget {
  const LedgerEntryTile({
    super.key,
    required this.entry,
    this.onDelete,
    this.showTranscript = true,
  });

  final LedgerEntry entry;
  final VoidCallback? onDelete;
  final bool showTranscript;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final EntryVisuals visuals = EntryVisuals.of(entry.entryType, scheme);
    final DateTime? created = entry.createdAtLocal;
    final bool outflow = entry.entryType.isOutflow;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: visuals.color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(visuals.icon, color: visuals.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          entry.entryType.label,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${outflow ? '−' : '+'}${Formats.money(entry.amount)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: outflow ? scheme.error : visuals.color,
                        ),
                      ),
                    ],
                  ),
                  if (entry.note != null && entry.note!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      entry.note!,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                  if (showTranscript &&
                      entry.rawTranscript != null &&
                      entry.rawTranscript!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest
                            .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(Icons.format_quote_rounded,
                              size: 16, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              entry.rawTranscript!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      if (created != null)
                        _MetaLabel(
                          icon: Icons.schedule_rounded,
                          text: Formats.dayMonthTime(created),
                        ),
                      if (entry.category != null && entry.category!.isNotEmpty)
                        _MetaLabel(
                          icon: Icons.label_outline_rounded,
                          text: entry.category!,
                        ),
                      if (!entry.confirmed)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Unconfirmed',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onErrorContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete entry',
              ),
          ],
        ),
      ),
    );
  }
}

class _MetaLabel extends StatelessWidget {
  const _MetaLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
