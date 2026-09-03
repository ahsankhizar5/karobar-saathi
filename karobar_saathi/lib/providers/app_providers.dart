/// Riverpod providers wiring the UI to [ApiService].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/recorder_service.dart';

/// Shared HTTP client.
final Provider<ApiService> apiServiceProvider = Provider<ApiService>((ref) {
  final ApiService service = ApiService();
  ref.onDispose(service.dispose);
  return service;
});

/// Shared microphone recorder.
final Provider<RecorderService> recorderServiceProvider =
    Provider<RecorderService>((ref) {
  final RecorderService service = RecorderService();
  ref.onDispose(service.dispose);
  return service;
});

/// The shopkeeper whose books the app is showing.
///
/// The prototype signs in as the first seeded demo shop.
final StateProvider<String> currentUserIdProvider =
    StateProvider<String>((ref) => kDemoShops.first.id);

/// Profile of [currentUserIdProvider].
final FutureProvider<AppUser> currentUserProvider =
    FutureProvider<AppUser>((ref) {
  final String userId = ref.watch(currentUserIdProvider);
  return ref.watch(apiServiceProvider).fetchUser(userId);
});

/// Dashboard summary for the signed-in shopkeeper.
final FutureProvider<Dashboard> dashboardProvider =
    FutureProvider<Dashboard>((ref) {
  final String userId = ref.watch(currentUserIdProvider);
  return ref.watch(apiServiceProvider).fetchDashboard(userId);
});

/// Confirmed + pending ledger rows for the signed-in shopkeeper.
final FutureProvider<List<LedgerEntry>> ledgerProvider =
    FutureProvider<List<LedgerEntry>>(
        (ref) {
  final String userId = ref.watch(currentUserIdProvider);
  return ref.watch(apiServiceProvider).fetchLedger(userId, limit: 100);
});

/// Re-reads every screen that depends on ledger data.
Future<void> refreshShopData(WidgetRef ref) async {
  ref.invalidate(dashboardProvider);
  ref.invalidate(ledgerProvider);
  await Future.wait<Object?>(<Future<Object?>>[
    ref.read(dashboardProvider.future),
    ref.read(ledgerProvider.future),
  ]).catchError((Object _) => <Object?>[]);
}

// ---------------------------------------------------------------- lender view

/// The demo shop selected in the concept Lender View.
final StateProvider<String> lenderSelectedShopProvider =
    StateProvider<String>((ref) => kDemoShops.first.id);

/// Outcome of calling the consent-gated evidence endpoint.
///
/// A 403 is not an error to hide — it is the demo's core trust signal, so it is
/// modelled explicitly.
sealed class EvidenceState {
  const EvidenceState();
}

class EvidenceLoading extends EvidenceState {
  const EvidenceLoading();
}

class EvidenceGranted extends EvidenceState {
  const EvidenceGranted(this.profile);
  final EvidenceProfile profile;
}

/// HTTP 403 — consent revoked by the shopkeeper.
class EvidenceConsentDenied extends EvidenceState {
  const EvidenceConsentDenied(this.message);
  final String message;
}

class EvidenceFailure extends EvidenceState {
  const EvidenceFailure(this.message);
  final String message;
}

/// Loads the evidence profile for the shop selected in the Lender View and
/// exposes the consent toggle.
class LenderEvidenceController extends StateNotifier<EvidenceState> {
  LenderEvidenceController(this._api, this._userId)
      : super(const EvidenceLoading()) {
    load();
  }

  final ApiService _api;
  final String _userId;

  /// Mirrors the consent switch so it stays correct even in the 403 state.
  bool consentSwitchValue = true;

  bool _busy = false;
  bool get isBusy => _busy;

  Future<void> load() async {
    state = const EvidenceLoading();
    try {
      final EvidenceProfile profile = await _api.fetchEvidenceProfile(_userId);
      consentSwitchValue = true;
      state = EvidenceGranted(profile);
    } on ApiException catch (error) {
      if (error.isConsentDenied) {
        consentSwitchValue =
            error.detail?['has_user_consented_to_share'] == true;
        state = EvidenceConsentDenied(error.message);
      } else {
        state = EvidenceFailure(error.message);
      }
    } catch (error) {
      state = EvidenceFailure('$error');
    }
  }

  /// PATCHes consent, then re-requests the profile so the UI shows the real
  /// server response (200 or 403).
  Future<void> setConsent(bool consented) async {
    if (_busy) return;
    _busy = true;
    consentSwitchValue = consented;
    // Force listeners to see the optimistic switch position.
    state = const EvidenceLoading();
    try {
      await _api.updateConsent(userId: _userId, consented: consented);
      await load();
    } on ApiException catch (error) {
      state = EvidenceFailure(error.message);
    } catch (error) {
      state = EvidenceFailure('$error');
    } finally {
      _busy = false;
    }
  }
}

final StateNotifierProvider<LenderEvidenceController, EvidenceState>
    lenderEvidenceProvider =
    StateNotifierProvider<LenderEvidenceController, EvidenceState>(
        (ref) {
  final String userId = ref.watch(lenderSelectedShopProvider);
  return LenderEvidenceController(ref.watch(apiServiceProvider), userId);
});

/// Raw ledger of the shop selected in the Lender View, shown in the
/// "underlying records" modal.
final FutureProvider<List<LedgerEntry>> lenderLedgerProvider =
    FutureProvider<List<LedgerEntry>>(
        (ref) {
  final String userId = ref.watch(lenderSelectedShopProvider);
  return ref.watch(apiServiceProvider).fetchLedger(userId, limit: 60);
});
