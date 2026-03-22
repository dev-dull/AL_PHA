// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_board_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$weeklyBoardHash() => r'd978c9efa700fee16fd1f85e81a78fa5d1ceb92f';

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

/// Looks up a weekly board by its week-start date, creating one
/// (with columns) if none exists. Returns the board ID.
///
/// Copied from [weeklyBoard].
@ProviderFor(weeklyBoard)
const weeklyBoardProvider = WeeklyBoardFamily();

/// Looks up a weekly board by its week-start date, creating one
/// (with columns) if none exists. Returns the board ID.
///
/// Copied from [weeklyBoard].
class WeeklyBoardFamily extends Family<AsyncValue<String>> {
  /// Looks up a weekly board by its week-start date, creating one
  /// (with columns) if none exists. Returns the board ID.
  ///
  /// Copied from [weeklyBoard].
  const WeeklyBoardFamily();

  /// Looks up a weekly board by its week-start date, creating one
  /// (with columns) if none exists. Returns the board ID.
  ///
  /// Copied from [weeklyBoard].
  WeeklyBoardProvider call(DateTime weekStart) {
    return WeeklyBoardProvider(weekStart);
  }

  @override
  WeeklyBoardProvider getProviderOverride(
    covariant WeeklyBoardProvider provider,
  ) {
    return call(provider.weekStart);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'weeklyBoardProvider';
}

/// Looks up a weekly board by its week-start date, creating one
/// (with columns) if none exists. Returns the board ID.
///
/// Copied from [weeklyBoard].
class WeeklyBoardProvider extends AutoDisposeFutureProvider<String> {
  /// Looks up a weekly board by its week-start date, creating one
  /// (with columns) if none exists. Returns the board ID.
  ///
  /// Copied from [weeklyBoard].
  WeeklyBoardProvider(DateTime weekStart)
    : this._internal(
        (ref) => weeklyBoard(ref as WeeklyBoardRef, weekStart),
        from: weeklyBoardProvider,
        name: r'weeklyBoardProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$weeklyBoardHash,
        dependencies: WeeklyBoardFamily._dependencies,
        allTransitiveDependencies: WeeklyBoardFamily._allTransitiveDependencies,
        weekStart: weekStart,
      );

  WeeklyBoardProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.weekStart,
  }) : super.internal();

  final DateTime weekStart;

  @override
  Override overrideWith(
    FutureOr<String> Function(WeeklyBoardRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WeeklyBoardProvider._internal(
        (ref) => create(ref as WeeklyBoardRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        weekStart: weekStart,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<String> createElement() {
    return _WeeklyBoardProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WeeklyBoardProvider && other.weekStart == weekStart;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, weekStart.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WeeklyBoardRef on AutoDisposeFutureProviderRef<String> {
  /// The parameter `weekStart` of this provider.
  DateTime get weekStart;
}

class _WeeklyBoardProviderElement
    extends AutoDisposeFutureProviderElement<String>
    with WeeklyBoardRef {
  _WeeklyBoardProviderElement(super.provider);

  @override
  DateTime get weekStart => (origin as WeeklyBoardProvider).weekStart;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
