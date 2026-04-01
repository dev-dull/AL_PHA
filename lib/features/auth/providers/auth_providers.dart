import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:alpha/features/auth/data/auth_repository.dart';
import 'package:alpha/features/auth/domain/auth_config.dart';
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

  /// Open the Cognito hosted UI for sign-in.
  Future<void> signIn() async {
    final uri = AuthConfig.signInUri();
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Open the Cognito hosted UI for sign-up.
  Future<void> signUp() async {
    final uri = AuthConfig.signUpUri();
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Handle the OAuth callback redirect with authorization code.
  Future<void> handleCallback(String code) async {
    final tokens = await _repo.exchangeCode(code);
    final user = _repo.parseIdToken(tokens.idToken);

    if (user == null) {
      throw Exception('Failed to parse user from ID token');
    }

    await _repo.saveTokens(tokens);
    await _repo.saveUser(user);
    state = (user: user, tokens: tokens);
  }

  /// Sign out: clear local state and open Cognito logout.
  Future<void> signOut() async {
    await _repo.clear();
    state = (user: null, tokens: null);

    final uri = AuthConfig.signOutUri();
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
    try {
      final refreshed = await _repo.refreshTokens(tokens.refreshToken);
      final user = _repo.parseIdToken(refreshed.idToken) ?? state.user;

      await _repo.saveTokens(refreshed);
      if (user != null) await _repo.saveUser(user);
      state = (user: user, tokens: refreshed);

      return refreshed.accessToken;
    } catch (_) {
      // Refresh failed — clear auth state.
      await _repo.clear();
      state = (user: null, tokens: null);
      return null;
    }
  }
}
