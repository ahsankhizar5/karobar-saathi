/// App shell with bottom navigation between Dashboard, Ledger and Lender View.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../l10n/app_localizations.dart';
import '../l10n/app_strings.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../providers/locale_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/transaction_sheet.dart';
import 'dashboard_screen.dart';
import 'ledger_screen.dart';
import 'lender_view_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  int _index = 0;
  Timer? _keepWarmTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The hosted backend sleeps after idle; kick it awake while the user is
    // still looking at the loading screen so their first real request is fast.
    unawaited(ref.read(apiServiceProvider).warmUp());
    // Render's free tier sleeps after ~15 idle minutes — a quiet health ping
    // every 10 minutes keeps it awake for as long as the user is in the app,
    // so a voice entry is never met with a cold start.
    _keepWarmTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      unawaited(ref.read(apiServiceProvider).warmUp());
    });
  }

  @override
  void dispose() {
    _keepWarmTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back to the app after any stretch away — wake the backend
    // before the user can ask it for anything.
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(apiServiceProvider).warmUp());
    }
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

  Future<void> _showAbout() async {
    final AppStrings s = context.l10n;
    final PackageInfo info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    final AppUser? user = ref.read(sessionProvider).signedInUser;
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(s.aboutTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(s.aboutBody),
            const SizedBox(height: 12),
            Text(
              s.aboutPrivacy,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              '${s.aboutVersion} ${info.version}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (user != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                user.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
        actions: <Widget>[
          if (user != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _confirmSignOut();
              },
              child: Text(s.signOut),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.close),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final AppStrings s = context.l10n;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(s.signOutConfirmTitle),
        content: Text(s.signOutConfirmBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.keep),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.signOut),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(sessionProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.l10n;
    // Spins whenever the dashboard is being (re)loaded, so the refresh
    // button itself acknowledges the tap instead of flashing the screen.
    final bool refreshing = ref.watch(dashboardProvider).isLoading;
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
            onPressed: refreshing ? null : () => refreshShopData(ref),
            tooltip: s.actionRefresh,
            icon: _SpinningIcon(
              spinning: refreshing,
              icon: Icons.refresh_rounded,
            ),
          ),
          IconButton(
            onPressed: _showAbout,
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

/// An icon that continuously rotates while [spinning] is true.
class _SpinningIcon extends StatefulWidget {
  const _SpinningIcon({required this.spinning, required this.icon});

  final bool spinning;
  final IconData icon;

  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns:
          widget.spinning ? _controller : const AlwaysStoppedAnimation<double>(0),
      child: Icon(widget.icon),
    );
  }
}
