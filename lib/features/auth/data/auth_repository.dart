import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alpha/features/auth/domain/auth_config.dart';
import 'package:alpha/features/auth/domain/auth_state.dart';

/// Stores auth tokens in SharedPreferences and handles
/// the Cognito OAuth2 token exchange and refresh.
class AuthRepository {
  static const _tokensKey = 'auth_tokens';
  static const _userKey = 'auth_user';

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

  // ── OAuth2 token exchange ────────────────────────────

  /// Exchange an authorization code for tokens.
  Future<AuthTokens> exchangeCode(String code) async {
    final response = await http.post(
      AuthConfig.tokenEndpoint,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'client_id': AuthConfig.clientId,
        'code': code,
        'redirect_uri': AuthConfig.redirectUri,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Token exchange failed: ${response.body}');
    }

    return _parseTokenResponse(response.body);
  }

  /// Refresh tokens using the refresh token.
  Future<AuthTokens> refreshTokens(String refreshToken) async {
    final response = await http.post(
      AuthConfig.tokenEndpoint,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'refresh_token',
        'client_id': AuthConfig.clientId,
        'refresh_token': refreshToken,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Token refresh failed: ${response.body}');
    }

    final tokens = _parseTokenResponse(response.body);
    // Cognito doesn't return a new refresh token on refresh,
    // so carry the original forward.
    if (tokens.refreshToken.isEmpty) {
      return tokens.copyWith(refreshToken: refreshToken);
    }
    return tokens;
  }

  /// Parse the Cognito token response JSON.
  AuthTokens _parseTokenResponse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final expiresIn = json['expires_in'] as int? ?? 3600;

    return AuthTokens(
      accessToken: json['access_token'] as String,
      idToken: json['id_token'] as String,
      refreshToken: (json['refresh_token'] as String?) ?? '',
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
    );
  }

  /// Decode the JWT id_token to extract user info.
  /// This is a simple base64 decode — no signature verification
  /// (the server validates the token, not the client).
  AuthUser? parseIdToken(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      // JWT base64url → standard base64.
      final normalized = base64Url.normalize(payload);
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
