import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:alpha/features/auth/data/auth_repository.dart';
import 'package:alpha/features/auth/domain/auth_state.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  final _repo = AuthRepository();

  @override
  ({AuthUser? user, AuthTokens? tokens}) build() {
    return (user: null, tokens: null);
  }

  bool get isSignedIn => state.user != null && state.tokens != null;

  /// Load persisted auth state on app start.
  Future<void> init() async {
    final tokens = await _repo.loadTokens();
    final user = await _repo.loadUser();

    if (tokens != null && user != null) {
      if (tokens.isExpired) {
        await _tryRefresh(tokens);
      } else {
        state = (user: user, tokens: tokens);
      }
    }
  }

  /// Sign in with email + password.
  Future<void> signIn(String email, String password) async {
    final result = await _repo.signIn(email, password);
    await _repo.saveTokens(result.tokens);
    await _repo.saveUser(result.user);
    state = (user: result.user, tokens: result.tokens);
  }

  /// Sign up with email + password. Returns the email for
  /// the confirmation step.
  Future<String> signUp(String email, String password) async {
    return await _repo.signUp(email, password);
  }

  /// Confirm sign-up with verification code, then auto sign-in.
  Future<void> confirmAndSignIn(
    String email,
    String password,
    String code,
  ) async {
    await _repo.confirmSignUp(email, code);
    await signIn(email, password);
  }

  /// Resend confirmation code.
  Future<void> resendCode(String email) async {
    await _repo.resendCode(email);
  }

  /// Sign out: clear local state.
  Future<void> signOut() async {
    await _repo.clear();
    state = (user: null, tokens: null);
  }

  /// Get a valid access token, refreshing if needed.
  Future<String?> getAccessToken() async {
    final tokens = state.tokens;
    if (tokens == null) return null;

    if (tokens.isExpired) {
      return await _tryRefresh(tokens);
    }
    return tokens.accessToken;
  }

  Future<String?> _tryRefresh(AuthTokens tokens) async {
    final refreshed = await _repo.refreshSession(tokens);
    if (refreshed == null) {
      await _repo.clear();
      state = (user: null, tokens: null);
      return null;
    }

    final user = state.user;
    await _repo.saveTokens(refreshed);
    state = (user: user, tokens: refreshed);
    return refreshed.accessToken;
  }
}
