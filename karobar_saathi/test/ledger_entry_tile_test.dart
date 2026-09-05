import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karobar_saathi/l10n/app_localizations.dart';
import 'package:karobar_saathi/models/models.dart';
import 'package:karobar_saathi/widgets/ledger_entry_tile.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: ListView(children: <Widget>[child])),
    );

const LedgerEntry _saleEntry = LedgerEntry(
  id: 1,
  userId: 'shop_001',
  entryType: EntryType.sale,
  amount: 4500,
  confirmed: true,
  note: 'Tea sales',
  rawTranscript: 'aaj 4500 ki sale hui',
  category: 'tea',
  createdAt: '2026-08-15 12:30:00',
);

void main() {
  testWidgets('transcript stays collapsed until the tile is tapped',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const LedgerEntryTile(entry: _saleEntry)));
    // Our localization delegate loads asynchronously; give it a frame.
    await tester.pump();

    expect(find.text('Tea sales'), findsOneWidget);
    expect(find.text('+Rs 4,500'), findsOneWidget);
    expect(find.text('aaj 4500 ki sale hui'), findsNothing);

    await tester.tap(find.text('Tea sales'));
    await tester.pumpAndSettle();
    expect(find.text('aaj 4500 ki sale hui'), findsOneWidget);

    await tester.tap(find.text('Tea sales'));
    await tester.pumpAndSettle();
    expect(find.text('aaj 4500 ki sale hui'), findsNothing);
  });

  testWidgets('meta line joins type label and category when a note exists',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const LedgerEntryTile(entry: _saleEntry)));
    await tester.pump();

    expect(find.textContaining('Sale / Bikri'), findsOneWidget);
    expect(find.textContaining('tea'), findsOneWidget);
  });

  testWidgets('falls back to type label and flags unconfirmed entries',
      (WidgetTester tester) async {
    const LedgerEntry entry = LedgerEntry(
      id: 2,
      userId: 'shop_001',
      entryType: EntryType.expense,
      amount: 600,
      confirmed: false,
    );
    await tester.pumpWidget(_wrap(const LedgerEntryTile(entry: entry)));
    await tester.pump();

    expect(find.text('Expense / Kharcha'), findsOneWidget);
    expect(find.textContaining('Unconfirmed'), findsOneWidget);
    expect(find.text('−Rs 600'), findsOneWidget);
    // No transcript on this entry: no chevron, nothing to expand.
    expect(find.byIcon(Icons.expand_more_rounded), findsNothing);
  });
}
