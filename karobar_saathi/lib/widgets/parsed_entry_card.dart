/// Editable card for one AI-parsed draft entry.
///
/// When the server flagged the entry as ambiguous, the clarification question is
/// shown prominently and the entry stays unsaveable until the user picks a real
/// transaction type and a positive amount.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

class ParsedEntryCard extends StatefulWidget {
  const ParsedEntryCard({
    super.key,
    required this.index,
    required this.entry,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final ParsedEntry entry;
  final ValueChanged<ParsedEntry> onChanged;
  final VoidCallback onRemove;

  @override
  State<ParsedEntryCard> createState() => _ParsedEntryCardState();
}

class _ParsedEntryCardState extends State<ParsedEntryCard> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.entry.amount > 0
          ? widget.entry.amount.toStringAsFixed(0)
          : '',
    );
    _noteController = TextEditingController(text: widget.entry.note ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ParsedEntryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The card may be recycled for a different draft (e.g. after a removal
    // shifts the list), so keep the fields in sync with the incoming entry.
    final String amountText = widget.entry.amount > 0
        ? widget.entry.amount.toStringAsFixed(0)
        : '';
    final double? shownAmount =
        double.tryParse(_amountController.text.replaceAll(',', ''));
    if (shownAmount != widget.entry.amount &&
        _amountController.text != amountText) {
      _amountController.text = amountText;
    }

    final String noteText = widget.entry.note ?? '';
    if (_noteController.text != noteText &&
        (oldWidget.entry.note ?? '') != noteText) {
      _noteController.text = noteText;
    }
  }

  /// Choosing a concrete type resolves the server's ambiguity flag.
  void _setType(EntryType type) {
    widget.onChanged(widget.entry.copyWith(
      entryType: type,
      needsClarification: false,
    ));
  }

  void _setAmount(String raw) {
    final double parsed = double.tryParse(raw.replaceAll(',', '')) ?? 0;
    widget.onChanged(widget.entry.copyWith(amount: parsed));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final ParsedEntry entry = widget.entry;
    final bool unclear = entry.isUnclear;
    final bool stillAmbiguous =
        entry.needsClarification || entry.entryType == EntryType.unclear;
    final EntryVisuals visuals = EntryVisuals.of(entry.entryType, scheme);

    return Card(
      color: unclear ? scheme.errorContainer.withOpacity(0.35) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: unclear ? scheme.error : scheme.outlineVariant,
          width: unclear ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  unclear ? Icons.help_outline_rounded : visuals.icon,
                  color: unclear ? scheme.error : visuals.color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Entry ${widget.index + 1}',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Discard entry ${widget.index + 1}',
                ),
              ],
            ),

            // The server's clarification question — the blocking state.
            if (stillAmbiguous) ...<Widget>[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.error.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.error),
                ),
                child: Semantics(
                  liveRegion: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(Icons.priority_high_rounded,
                              size: 18, color: scheme.error),
                          const SizedBox(width: 6),
                          Text(
                            'Needs your answer',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.clarificationQuestion ??
                            'Yeh transaction kya thi? Sale, khareed, kharcha ya ghar bheje?',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(height: 1.35),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pick the correct type below to save this entry.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),
            Text('Transaction type', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EntryType.selectable.map((EntryType type) {
                final bool selected = entry.entryType == type;
                return ChoiceChip(
                  selected: selected,
                  onSelected: (_) => _setType(type),
                  avatar: Icon(
                    EntryVisuals.of(type, scheme).icon,
                    size: 18,
                    color: selected
                        ? scheme.onSecondaryContainer
                        : EntryVisuals.of(type, scheme).color,
                  ),
                  label: Text(type.label),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              onChanged: _setAmount,
              decoration: InputDecoration(
                labelText: 'Amount (Rs)',
                prefixIcon: const Icon(Icons.payments_outlined),
                errorText: entry.amount <= 0 ? 'Enter an amount' : null,
              ),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (String value) =>
                  widget.onChanged(entry.copyWith(note: value)),
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),

            if (entry.category != null && entry.category!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Icon(Icons.label_outline_rounded,
                      size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Category: ${entry.category}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
