import 'dart:convert';

import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:planyr/features/auth/domain/auth_config.dart';
import 'package:planyr/features/auth/domain/auth_state.dart';

/// Handles Cognito auth via the native Dart SDK.
/// No browser, deep links, or PKCE needed.
class AuthRepository {
  static const _tokensKey = 'auth_tokens';
  static const _userKey = 'auth_user';

  final _userPool = CognitoUserPool(
    AuthConfig.userPoolId,
    AuthConfig.clientId,
  );

  // ── Persistence ──────────────────────────────────────

  Future<AuthTokens?> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_tokensKey);
    if (json == null) return null;
    return AuthTokens.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }

  Future<AuthUser?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_userKey);
    if (json == null) return null;
    return AuthUser.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }

  Future<void> saveTokens(AuthTokens tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokensKey, jsonEncode(tokens.toJson()));
  }

  Future<void> saveUser(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokensKey);
    await prefs.remove(_userKey);
  }

  // ── Auth operations ──────────────────────────────────

  /// Sign in with email + password.
  Future<({AuthTokens tokens, AuthUser user})> signIn(
    String email,
    String password,
  ) async {
    final cognitoUser = CognitoUser(email, _userPool);
    final authDetails = AuthenticationDetails(
      username: email,
      password: password,
    );

    final session = await cognitoUser.authenticateUser(authDetails);
    if (session == null) {
      throw Exception('Authentication failed');
    }

    return _sessionToResult(session, email);
  }

  /// Sign up with email + password.
  Future<String> signUp(String email, String password) async {
    await _userPool.signUp(
      email,
      password,
      userAttributes: [
        AttributeArg(name: 'email', value: email),
      ],
    );
    return email;
  }

  /// Confirm sign-up with verification code.
  Future<void> confirmSignUp(String email, String code) async {
    final cognitoUser = CognitoUser(email, _userPool);
    await cognitoUser.confirmRegistration(code);
  }

  /// Resend confirmation code.
  Future<void> resendCode(String email) async {
    final cognitoUser = CognitoUser(email, _userPool);
    await cognitoUser.resendConfirmationCode();
  }

  /// Refresh tokens using persisted session.
  Future<AuthTokens?> refreshSession(AuthTokens tokens) async {
    // We need the username to refresh — extract from ID token.
    final user = _parseIdToken(tokens.idToken);
    if (user == null) return null;

    final cognitoUser = CognitoUser(user.email, _userPool);
    final refreshToken = CognitoRefreshToken(tokens.refreshToken);

    try {
      final session = await cognitoUser.refreshSession(refreshToken);
      if (session == null) return null;

      final result = _sessionToResult(session, user.email);
      return result.tokens;
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ──────────────────────────────────────────

  ({AuthTokens tokens, AuthUser user}) _sessionToResult(
    CognitoUserSession session,
    String email,
  ) {
    final idToken = session.getIdToken().getJwtToken() ?? '';
    final accessToken = session.getAccessToken().getJwtToken() ?? '';
    final refreshToken = session.getRefreshToken()?.getToken() ?? '';
    final expiry = session.getAccessToken().getExpiration();

    final tokens = AuthTokens(
      accessToken: accessToken,
      idToken: idToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expiry * 1000),
    );

    final user = _parseIdToken(idToken) ??
        AuthUser(userId: '', email: email);

    return (tokens: tokens, user: user);
  }

  AuthUser? _parseIdToken(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) return null;

      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final claims = jsonDecode(decoded) as Map<String, dynamic>;

      return AuthUser(
        userId: claims['sub'] as String,
        email: claims['email'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}
