/// Holds the signed-in shopkeeper and persists the choice across launches.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

const String _prefsKey = 'session_user_id';

sealed class SessionState {
  const SessionState();
}

/// SharedPreferences restore hasn't finished yet — keep showing the splash.
class SessionLoading extends SessionState {
  const SessionLoading();
}

class SessionSignedOut extends SessionState {
  const SessionSignedOut();
}

class SessionSignedIn extends SessionState {
  const SessionSignedIn(this.user);
  final AppUser user;
}

extension SessionStateX on SessionState {
  AppUser? get signedInUser => switch (this) {
        SessionSignedIn(:final user) => user,
        _ => null,
      };
}

/// Demo builds sign in as one of the seeded shops; the choice is remembered
/// so the app reopens straight into the books.
class SessionController extends StateNotifier<SessionState> {
  SessionController() : super(const SessionLoading()) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString(_prefsKey);
      for (final DemoShop shop in kDemoShops) {
        if (shop.id == userId) {
          state = SessionSignedIn(AppUser(
            id: shop.id,
            name: shop.name,
            businessType: shop.description,
          ));
          return;
        }
      }
      state = const SessionSignedOut();
    } catch (_) {
      // Corrupt or unavailable prefs should never block the login screen.
      state = const SessionSignedOut();
    }
  }

  /// Signs in as [user] and remembers the choice for next launch.
  Future<void> signIn(AppUser user) async {
    state = SessionSignedIn(user);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, user.id);
  }

  /// Signs out and forgets the stored choice.
  Future<void> signOut() async {
    state = const SessionSignedOut();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

final StateNotifierProvider<SessionController, SessionState> sessionProvider =
    StateNotifierProvider<SessionController, SessionState>(
        (ref) => SessionController());
