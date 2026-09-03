/// App shell with bottom navigation between Dashboard, Ledger and Lender View.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../services/api_service.dart';
import '../widgets/transaction_sheet.dart';
import 'dashboard_screen.dart';
import 'ledger_screen.dart';
import 'lender_view_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const List<String> _titles = <String>[
    'Karobar Saathi',
    'My Ledger',
    'Lender View (Concept)',
  ];

  Future<void> _addTransaction() async {
    final bool saved = await showTransactionSheet(context);
    if (!saved || !mounted) return;
    await refreshShopData(ref);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to your ledger.')),
    );
  }

  void _showApiInfo() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('About this build'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Karobar Saathi turns spoken daily transactions into a '
              'structured, explainable financial record.',
            ),
            const SizedBox(height: 16),
            Text(
              'Backend: $kApiBaseUrl',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: <Widget>[
          IconButton(
            onPressed: () => refreshShopData(ref),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _showApiInfo,
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'About',
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const <Widget>[
          DashboardScreen(),
          LedgerScreen(),
          LenderViewScreen(),
        ],
      ),
      // The lender view is read-only; adding transactions belongs to the
      // shopkeeper's own screens.
      floatingActionButton: _index == 2
          ? null
          : FloatingActionButton.extended(
              onPressed: _addTransaction,
              icon: const Icon(Icons.mic_rounded),
              label: const Text('Add'),
              tooltip: 'Add a transaction by voice or text',
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int value) => setState(() => _index = value),
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Ledger',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance_rounded),
            label: 'Lender',
          ),
        ],
      ),
    );
  }
}
