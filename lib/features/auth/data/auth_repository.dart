import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_exception.dart';

/// All Supabase auth access goes through this repository — UI never touches
/// the client directly.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<void> signInWithPassword(
      {required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email.trim(), password: password);
    } catch (e) {
      throw mapError(e);
    }
  }

  /// Returns true when the account needs email confirmation before sign-in.
  Future<bool> signUp({required String email, required String password}) async {
    try {
      final res =
          await _client.auth.signUp(email: email.trim(), password: password);
      return res.session == null;
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw mapError(e);
    }
  }
}
