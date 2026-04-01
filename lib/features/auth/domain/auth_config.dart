/// Cognito configuration — matches the deployed Terraform outputs.
class AuthConfig {
  static const userPoolId = 'us-west-2_0XUQCSZTQ';
  static const clientId = '6dlbd25ui97rt3b4bcosmc5tmp';
  static const region = 'us-west-2';

  /// Cognito hosted UI sign-out URL.
  static const domain = 'alpha-dev-773469078444';
  static String get hostedUiBase =>
      'https://$domain.auth.$region.amazoncognito.com';
}
