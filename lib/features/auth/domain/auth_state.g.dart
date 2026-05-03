// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthTokens _$AuthTokensFromJson(Map<String, dynamic> json) => _AuthTokens(
  accessToken: json['accessToken'] as String,
  idToken: json['idToken'] as String,
  refreshToken: json['refreshToken'] as String,
  expiresAt: const _UtcEpochConverter().fromJson(json['expiresAt'] as Object),
);

Map<String, dynamic> _$AuthTokensToJson(_AuthTokens instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'idToken': instance.idToken,
      'refreshToken': instance.refreshToken,
      'expiresAt': const _UtcEpochConverter().toJson(instance.expiresAt),
    };

_AuthUser _$AuthUserFromJson(Map<String, dynamic> json) =>
    _AuthUser(userId: json['userId'] as String, email: json['email'] as String);

Map<String, dynamic> _$AuthUserToJson(_AuthUser instance) => <String, dynamic>{
  'userId': instance.userId,
  'email': instance.email,
};
