import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';
part 'auth_state.g.dart';

/// Persists [DateTime] as UTC epoch milliseconds (int).
///
/// The previous default — a TZ-naive ISO string with no offset
/// suffix — round-tripped wrong across host TZ changes: the wall
/// clock was preserved verbatim while the absolute instant shifted
/// by the new local offset. That caused `isExpired` to false-
/// positive on every TZ change and triggered an unnecessary token
/// refresh. If the refresh failed (no network during travel,
/// transient Cognito error), the user got signed out.
///
/// Backwards-compat: legacy tokens are still strings. We parse
/// them as local DateTime then convert to UTC; the result may be
/// off by the new-vs-old TZ offset for one boot, after which the
/// next refresh saves under the new int format.
class _UtcEpochConverter implements JsonConverter<DateTime, Object> {
  const _UtcEpochConverter();

  @override
  DateTime fromJson(Object json) {
    if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json, isUtc: true);
    }
    return DateTime.parse(json as String).toUtc();
  }

  @override
  Object toJson(DateTime value) =>
      value.toUtc().millisecondsSinceEpoch;
}

@freezed
abstract class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    required String accessToken,
    required String idToken,
    required String refreshToken,
    @_UtcEpochConverter() required DateTime expiresAt,
  }) = _AuthTokens;

  const AuthTokens._();

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt.toUtc());

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);
}

@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String userId,
    required String email,
  }) = _AuthUser;

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      _$AuthUserFromJson(json);
}
