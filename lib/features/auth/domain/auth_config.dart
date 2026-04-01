/// Cognito configuration — matches the deployed Terraform outputs.
class AuthConfig {
  static const userPoolId = 'us-west-2_0XUQCSZTQ';
  static const clientId = '6dlbd25ui97rt3b4bcosmc5tmp';
  static const region = 'us-west-2';
  static const domain = 'alpha-dev-773469078444';

  /// Base URL for the Cognito hosted UI.
  static String get hostedUiBase =>
      'https://$domain.auth.$region.amazoncognito.com';

  /// OAuth2 token endpoint.
  static Uri get tokenEndpoint =>
      Uri.parse('$hostedUiBase/oauth2/token');

  /// Redirect URI for the OAuth callback. Uses a custom scheme
  /// so the OS routes back to the app after sign-in.
  static const redirectUri = 'alpha://auth/callback';

  /// Sign-out redirect.
  static const signOutRedirectUri = 'alpha://auth/signout';

  /// Build the hosted UI sign-in URL.
  static Uri signInUri() {
    return Uri.parse('$hostedUiBase/login').replace(
      queryParameters: {
        'client_id': clientId,
        'response_type': 'code',
        'scope': 'openid email',
        'redirect_uri': redirectUri,
      },
    );
  }

  /// Build the hosted UI sign-up URL.
  /// Cognito hosted UI uses /login for both — the page has a
  /// "Sign up" link. There is no separate /signup endpoint.
  static Uri signUpUri() {
    return Uri.parse('$hostedUiBase/login').replace(
      queryParameters: {
        'client_id': clientId,
        'response_type': 'code',
        'scope': 'openid email',
        'redirect_uri': redirectUri,
      },
    );
  }

  /// Build the hosted UI sign-out URL.
  static Uri signOutUri() {
    return Uri.parse('$hostedUiBase/logout').replace(
      queryParameters: {
        'client_id': clientId,
        'logout_uri': signOutRedirectUri,
      },
    );
  }
}
