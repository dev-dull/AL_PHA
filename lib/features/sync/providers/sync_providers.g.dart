// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$syncHash() => r'ff5e1d28229c308ea285daea613aa5742ca59d32';

/// See also [Sync].
@ProviderFor(Sync)
final syncProvider =
    NotifierProvider<
      Sync,
      ({SyncState status, String? lastError, DateTime? lastSyncTime})
    >.internal(
      Sync.new,
      name: r'syncProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$syncHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Sync =
    Notifier<({SyncState status, String? lastError, DateTime? lastSyncTime})>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
