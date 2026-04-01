// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authHash() => r'2fdbb85a66131f555b142b751c8eeb0a1db35ce0';

/// See also [Auth].
@ProviderFor(Auth)
final authProvider =
    NotifierProvider<Auth, ({AuthUser? user, AuthTokens? tokens})>.internal(
      Auth.new,
      name: r'authProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Auth = Notifier<({AuthUser? user, AuthTokens? tokens})>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
