// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_summary_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$daySummariesHash() => r'8356c441ba3faf3fcb721bec151f44ae9900b2ac';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Loads day summaries for all days in a date range by reading
/// weekly board data. Returns a map of date → DaySummary.
///
/// Copied from [daySummaries].
@ProviderFor(daySummaries)
const daySummariesProvider = DaySummariesFamily();

/// Loads day summaries for all days in a date range by reading
/// weekly board data. Returns a map of date → DaySummary.
///
/// Copied from [daySummaries].
class DaySummariesFamily extends Family<AsyncValue<Map<DateTime, DaySummary>>> {
  /// Loads day summaries for all days in a date range by reading
  /// weekly board data. Returns a map of date → DaySummary.
  ///
  /// Copied from [daySummaries].
  const DaySummariesFamily();

  /// Loads day summaries for all days in a date range by reading
  /// weekly board data. Returns a map of date → DaySummary.
  ///
  /// Copied from [daySummaries].
  DaySummariesProvider call(DateTime rangeStart, DateTime rangeEnd) {
    return DaySummariesProvider(rangeStart, rangeEnd);
  }

  @override
  DaySummariesProvider getProviderOverride(
    covariant DaySummariesProvider provider,
  ) {
    return call(provider.rangeStart, provider.rangeEnd);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'daySummariesProvider';
}

/// Loads day summaries for all days in a date range by reading
/// weekly board data. Returns a map of date → DaySummary.
///
/// Copied from [daySummaries].
class DaySummariesProvider
    extends AutoDisposeFutureProvider<Map<DateTime, DaySummary>> {
  /// Loads day summaries for all days in a date range by reading
  /// weekly board data. Returns a map of date → DaySummary.
  ///
  /// Copied from [daySummaries].
  DaySummariesProvider(DateTime rangeStart, DateTime rangeEnd)
    : this._internal(
        (ref) => daySummaries(ref as DaySummariesRef, rangeStart, rangeEnd),
        from: daySummariesProvider,
        name: r'daySummariesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$daySummariesHash,
        dependencies: DaySummariesFamily._dependencies,
        allTransitiveDependencies:
            DaySummariesFamily._allTransitiveDependencies,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );

  DaySummariesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.rangeStart,
    required this.rangeEnd,
  }) : super.internal();

  final DateTime rangeStart;
  final DateTime rangeEnd;

  @override
  Override overrideWith(
    FutureOr<Map<DateTime, DaySummary>> Function(DaySummariesRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DaySummariesProvider._internal(
        (ref) => create(ref as DaySummariesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<DateTime, DaySummary>> createElement() {
    return _DaySummariesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DaySummariesProvider &&
        other.rangeStart == rangeStart &&
        other.rangeEnd == rangeEnd;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, rangeStart.hashCode);
    hash = _SystemHash.combine(hash, rangeEnd.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DaySummariesRef
    on AutoDisposeFutureProviderRef<Map<DateTime, DaySummary>> {
  /// The parameter `rangeStart` of this provider.
  DateTime get rangeStart;

  /// The parameter `rangeEnd` of this provider.
  DateTime get rangeEnd;
}

class _DaySummariesProviderElement
    extends AutoDisposeFutureProviderElement<Map<DateTime, DaySummary>>
    with DaySummariesRef {
  _DaySummariesProviderElement(super.provider);

  @override
  DateTime get rangeStart => (origin as DaySummariesProvider).rangeStart;
  @override
  DateTime get rangeEnd => (origin as DaySummariesProvider).rangeEnd;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
