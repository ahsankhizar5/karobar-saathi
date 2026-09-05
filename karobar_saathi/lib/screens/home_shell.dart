/// App shell with bottom navigation between Dashboard, Ledger and Lender View.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../l10n/app_strings.dart';
import '../providers/app_providers.dart';
import '../providers/locale_provider.dart';
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

  @override
  void initState() {
    super.initState();
    // The hosted backend sleeps after idle; kick it awake while the user is
    // still looking at the loading screen so their first real request is fast.
    unawaited(ref.read(apiServiceProvider).warmUp());
  }

  String _titleFor(AppStrings s) {
    switch (_index) {
      case 1:
        return s.titleLedger;
      case 2:
        return s.titleLender;
      default:
        return s.titleDashboard;
    }
  }

  Future<void> _addTransaction() async {
    final AppStrings s = context.l10n;
    final bool saved = await showTransactionSheet(context);
    if (!saved || !mounted) return;
    await refreshShopData(ref);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.savedToLedger)),
    );
  }

  Future<void> _showLanguageSheet() async {
    final AppStrings s = context.l10n;
    final AppLocale current = ref.read(localeProvider);
    final AppLocale? picked = await showModalBottomSheet<AppLocale>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      s.languageTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.languageSubtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              for (final AppLocale option in AppLocale.values)
                RadioListTile<AppLocale>(
                  value: option,
                  groupValue: current,
                  onChanged: (AppLocale? value) =>
                      Navigator.of(context).pop(value),
                  title: Text(
                    option.nativeName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(option == AppLocale.ur
                      ? s.languageUrdu
                      : s.languageEnglish),
                  secondary: Icon(option == current
                      ? Icons.check_circle_rounded
                      : Icons.translate_rounded),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      await ref.read(localeProvider.notifier).setLocale(picked);
    }
  }

  void _showApiInfo() {
    final AppStrings s = context.l10n;
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(s.aboutTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(s.aboutBody),
            const SizedBox(height: 16),
            Text(
              '${s.aboutBackendLabel}: $kApiBaseUrl',
              textDirection: TextDirection.ltr,
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
            child: Text(s.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(s)),
        actions: <Widget>[
          IconButton(
            onPressed: _showLanguageSheet,
            icon: const Icon(Icons.translate_rounded),
            tooltip: s.actionLanguage,
          ),
          IconButton(
            onPressed: () => refreshShopData(ref),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: s.actionRefresh,
          ),
          IconButton(
            onPressed: _showApiInfo,
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: s.actionAbout,
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
              label: Text(s.actionAdd),
              tooltip: s.actionAddTooltip,
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int value) => setState(() => _index = value),
        destinations: <Widget>[
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded),
            label: s.navDashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book_rounded),
            label: s.navLedger,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_outlined),
            selectedIcon: const Icon(Icons.account_balance_rounded),
            label: s.navLender,
          ),
        ],
      ),
    );
  }
}
