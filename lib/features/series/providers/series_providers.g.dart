// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'series_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeSeriesHash() => r'135af41e0334c8cc23b93c6fdf8223e46948e164';

/// See also [activeSeries].
@ProviderFor(activeSeries)
final activeSeriesProvider =
    AutoDisposeStreamProvider<List<RecurringSeries>>.internal(
      activeSeries,
      name: r'activeSeriesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeSeriesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveSeriesRef = AutoDisposeStreamProviderRef<List<RecurringSeries>>;
String _$seriesActionsHash() => r'e04a35848d6b08fd152f9050a09331914db0880f';

/// See also [seriesActions].
@ProviderFor(seriesActions)
final seriesActionsProvider = AutoDisposeProvider<SeriesActions>.internal(
  seriesActions,
  name: r'seriesActionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$seriesActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SeriesActionsRef = AutoDisposeProviderRef<SeriesActions>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
