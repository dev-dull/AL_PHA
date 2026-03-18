// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_board_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$weeklyBoardHash() => r'e5775526185e6128389a0410d1bc261f4790dfd8';

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

/// Looks up a weekly board by its Monday date, creating one
/// (with columns) if none exists. Returns the board ID.
///
/// Copied from [weeklyBoard].
@ProviderFor(weeklyBoard)
const weeklyBoardProvider = WeeklyBoardFamily();

/// Looks up a weekly board by its Monday date, creating one
/// (with columns) if none exists. Returns the board ID.
///
/// Copied from [weeklyBoard].
class WeeklyBoardFamily extends Family<AsyncValue<String>> {
  /// Looks up a weekly board by its Monday date, creating one
  /// (with columns) if none exists. Returns the board ID.
  ///
  /// Copied from [weeklyBoard].
  const WeeklyBoardFamily();

  /// Looks up a weekly board by its Monday date, creating one
  /// (with columns) if none exists. Returns the board ID.
  ///
  /// Copied from [weeklyBoard].
  WeeklyBoardProvider call(DateTime monday) {
    return WeeklyBoardProvider(monday);
  }

  @override
  WeeklyBoardProvider getProviderOverride(
    covariant WeeklyBoardProvider provider,
  ) {
    return call(provider.monday);
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

/// Looks up a weekly board by its Monday date, creating one
/// (with columns) if none exists. Returns the board ID.
///
/// Copied from [weeklyBoard].
class WeeklyBoardProvider extends AutoDisposeFutureProvider<String> {
  /// Looks up a weekly board by its Monday date, creating one
  /// (with columns) if none exists. Returns the board ID.
  ///
  /// Copied from [weeklyBoard].
  WeeklyBoardProvider(DateTime monday)
    : this._internal(
        (ref) => weeklyBoard(ref as WeeklyBoardRef, monday),
        from: weeklyBoardProvider,
        name: r'weeklyBoardProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$weeklyBoardHash,
        dependencies: WeeklyBoardFamily._dependencies,
        allTransitiveDependencies: WeeklyBoardFamily._allTransitiveDependencies,
        monday: monday,
      );

  WeeklyBoardProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.monday,
  }) : super.internal();

  final DateTime monday;

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
        monday: monday,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<String> createElement() {
    return _WeeklyBoardProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WeeklyBoardProvider && other.monday == monday;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, monday.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WeeklyBoardRef on AutoDisposeFutureProviderRef<String> {
  /// The parameter `monday` of this provider.
  DateTime get monday;
}

class _WeeklyBoardProviderElement
    extends AutoDisposeFutureProviderElement<String>
    with WeeklyBoardRef {
  _WeeklyBoardProviderElement(super.provider);

  @override
  DateTime get monday => (origin as WeeklyBoardProvider).monday;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
