/// List tile rendering one saved ledger entry.
///
/// The raw voice transcript stays collapsed behind a tap so the ledger scans
/// like a clean statement; expanding a row reveals the evidence text.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/app_strings.dart';
import '../l10n/entry_type_l10n.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class LedgerEntryTile extends StatefulWidget {
  const LedgerEntryTile({
    super.key,
    required this.entry,
    this.onDelete,
  });

  final LedgerEntry entry;
  final VoidCallback? onDelete;

  @override
  State<LedgerEntryTile> createState() => _LedgerEntryTileState();
}

class _LedgerEntryTileState extends State<LedgerEntryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppStrings s = context.l10n;
    final LedgerEntry entry = widget.entry;
    final EntryVisuals visuals = EntryVisuals.of(entry.entryType, scheme);
    final DateTime? created = entry.createdAtLocal;
    final bool outflow = entry.entryType.isOutflow;
    final bool hasNote = entry.note != null && entry.note!.isNotEmpty;
    final bool hasTranscript =
        entry.rawTranscript != null && entry.rawTranscript!.isNotEmpty;

    final List<String> meta = <String>[
      if (hasNote) entry.entryType.localizedLabel(s),
      if (created != null) Formats.dayMonthTime(created),
      if (entry.category != null && entry.category!.isNotEmpty) entry.category!,
      if (!entry.confirmed) s.unconfirmed,
    ];

    return Card(
      child: InkWell(
        onTap: hasTranscript
            ? () => setState(() => _expanded = !_expanded)
            : null,
        borderRadius: BorderRadius.circular(20),
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
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              hasNote
                                  ? entry.note!
                                  : entry.entryType.localizedLabel(s),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${outflow ? '−' : '+'}${Formats.money(entry.amount)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: outflow ? scheme.onSurface : visuals.color,
                            ),
                          ),
                        ],
                      ),
                      if (meta.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 2),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                meta.join(' · '),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (hasTranscript)
                              Tooltip(
                                message: s.voiceNoteTooltip,
                                child: AnimatedRotation(
                                  turns: _expanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.expand_more_rounded,
                                    size: 18,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (hasTranscript && _expanded) ...<Widget>[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Icon(
                              Icons.format_quote_rounded,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                entry.rawTranscript!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: scheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (widget.onDelete != null)
                IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: s.deleteEntryTooltip,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
