// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_board_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$monthlyBoardHash() => r'eb468e134ce56123f048c5da4f1ab2a2a46f35ae';

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

/// Looks up a monthly board by its period start date,
/// creating one (with columns) if none exists.
///
/// Copied from [monthlyBoard].
@ProviderFor(monthlyBoard)
const monthlyBoardProvider = MonthlyBoardFamily();

/// Looks up a monthly board by its period start date,
/// creating one (with columns) if none exists.
///
/// Copied from [monthlyBoard].
class MonthlyBoardFamily extends Family<AsyncValue<String>> {
  /// Looks up a monthly board by its period start date,
  /// creating one (with columns) if none exists.
  ///
  /// Copied from [monthlyBoard].
  const MonthlyBoardFamily();

  /// Looks up a monthly board by its period start date,
  /// creating one (with columns) if none exists.
  ///
  /// Copied from [monthlyBoard].
  MonthlyBoardProvider call(DateTime monthStart) {
    return MonthlyBoardProvider(monthStart);
  }

  @override
  MonthlyBoardProvider getProviderOverride(
    covariant MonthlyBoardProvider provider,
  ) {
    return call(provider.monthStart);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'monthlyBoardProvider';
}

/// Looks up a monthly board by its period start date,
/// creating one (with columns) if none exists.
///
/// Copied from [monthlyBoard].
class MonthlyBoardProvider extends AutoDisposeFutureProvider<String> {
  /// Looks up a monthly board by its period start date,
  /// creating one (with columns) if none exists.
  ///
  /// Copied from [monthlyBoard].
  MonthlyBoardProvider(DateTime monthStart)
    : this._internal(
        (ref) => monthlyBoard(ref as MonthlyBoardRef, monthStart),
        from: monthlyBoardProvider,
        name: r'monthlyBoardProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$monthlyBoardHash,
        dependencies: MonthlyBoardFamily._dependencies,
        allTransitiveDependencies:
            MonthlyBoardFamily._allTransitiveDependencies,
        monthStart: monthStart,
      );

  MonthlyBoardProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.monthStart,
  }) : super.internal();

  final DateTime monthStart;

  @override
  Override overrideWith(
    FutureOr<String> Function(MonthlyBoardRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MonthlyBoardProvider._internal(
        (ref) => create(ref as MonthlyBoardRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        monthStart: monthStart,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<String> createElement() {
    return _MonthlyBoardProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlyBoardProvider && other.monthStart == monthStart;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, monthStart.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MonthlyBoardRef on AutoDisposeFutureProviderRef<String> {
  /// The parameter `monthStart` of this provider.
  DateTime get monthStart;
}

class _MonthlyBoardProviderElement
    extends AutoDisposeFutureProviderElement<String>
    with MonthlyBoardRef {
  _MonthlyBoardProviderElement(super.provider);

  @override
  DateTime get monthStart => (origin as MonthlyBoardProvider).monthStart;
}

String _$quarterlyBoardHash() => r'58248b57c69f310b9940447bd0da8b827304b80b';

/// Looks up a quarterly board by its period start date,
/// creating one (with columns) if none exists.
///
/// Copied from [quarterlyBoard].
@ProviderFor(quarterlyBoard)
const quarterlyBoardProvider = QuarterlyBoardFamily();

/// Looks up a quarterly board by its period start date,
/// creating one (with columns) if none exists.
///
/// Copied from [quarterlyBoard].
class QuarterlyBoardFamily extends Family<AsyncValue<String>> {
  /// Looks up a quarterly board by its period start date,
  /// creating one (with columns) if none exists.
  ///
  /// Copied from [quarterlyBoard].
  const QuarterlyBoardFamily();

  /// Looks up a quarterly board by its period start date,
  /// creating one (with columns) if none exists.
  ///
  /// Copied from [quarterlyBoard].
  QuarterlyBoardProvider call(DateTime quarterStart) {
    return QuarterlyBoardProvider(quarterStart);
  }

  @override
  QuarterlyBoardProvider getProviderOverride(
    covariant QuarterlyBoardProvider provider,
  ) {
    return call(provider.quarterStart);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'quarterlyBoardProvider';
}

/// Looks up a quarterly board by its period start date,
/// creating one (with columns) if none exists.
///
/// Copied from [quarterlyBoard].
class QuarterlyBoardProvider extends AutoDisposeFutureProvider<String> {
  /// Looks up a quarterly board by its period start date,
  /// creating one (with columns) if none exists.
  ///
  /// Copied from [quarterlyBoard].
  QuarterlyBoardProvider(DateTime quarterStart)
    : this._internal(
        (ref) => quarterlyBoard(ref as QuarterlyBoardRef, quarterStart),
        from: quarterlyBoardProvider,
        name: r'quarterlyBoardProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$quarterlyBoardHash,
        dependencies: QuarterlyBoardFamily._dependencies,
        allTransitiveDependencies:
            QuarterlyBoardFamily._allTransitiveDependencies,
        quarterStart: quarterStart,
      );

  QuarterlyBoardProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.quarterStart,
  }) : super.internal();

  final DateTime quarterStart;

  @override
  Override overrideWith(
    FutureOr<String> Function(QuarterlyBoardRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: QuarterlyBoardProvider._internal(
        (ref) => create(ref as QuarterlyBoardRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        quarterStart: quarterStart,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<String> createElement() {
    return _QuarterlyBoardProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is QuarterlyBoardProvider &&
        other.quarterStart == quarterStart;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, quarterStart.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin QuarterlyBoardRef on AutoDisposeFutureProviderRef<String> {
  /// The parameter `quarterStart` of this provider.
  DateTime get quarterStart;
}

class _QuarterlyBoardProviderElement
    extends AutoDisposeFutureProviderElement<String>
    with QuarterlyBoardRef {
  _QuarterlyBoardProviderElement(super.provider);

  @override
  DateTime get quarterStart => (origin as QuarterlyBoardProvider).quarterStart;
}

String _$yearlyBoardHash() => r'3dca8f164c98911d5e31238897f1efb7b3fb7888';

/// Looks up a yearly board by its period start date,
/// creating one (with columns) if none exists.
///
/// Copied from [yearlyBoard].
@ProviderFor(yearlyBoard)
const yearlyBoardProvider = YearlyBoardFamily();

/// Looks up a yearly board by its period start date,
/// creating one (with columns) if none exists.
///
/// Copied from [yearlyBoard].
class YearlyBoardFamily extends Family<AsyncValue<String>> {
  /// Looks up a yearly board by its period start date,
  /// creating one (with columns) if none exists.
  ///
  /// Copied from [yearlyBoard].
  const YearlyBoardFamily();

  /// Looks up a yearly board by its period start date,
  /// creating one (with columns) if none exists.
  ///
  /// Copied from [yearlyBoard].
  YearlyBoardProvider call(DateTime yearStart) {
    return YearlyBoardProvider(yearStart);
  }

  @override
  YearlyBoardProvider getProviderOverride(
    covariant YearlyBoardProvider provider,
  ) {
    return call(provider.yearStart);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'yearlyBoardProvider';
}

/// Looks up a yearly board by its period start date,
/// creating one (with columns) if none exists.
///
/// Copied from [yearlyBoard].
class YearlyBoardProvider extends AutoDisposeFutureProvider<String> {
  /// Looks up a yearly board by its period start date,
  /// creating one (with columns) if none exists.
  ///
  /// Copied from [yearlyBoard].
  YearlyBoardProvider(DateTime yearStart)
    : this._internal(
        (ref) => yearlyBoard(ref as YearlyBoardRef, yearStart),
        from: yearlyBoardProvider,
        name: r'yearlyBoardProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$yearlyBoardHash,
        dependencies: YearlyBoardFamily._dependencies,
        allTransitiveDependencies: YearlyBoardFamily._allTransitiveDependencies,
        yearStart: yearStart,
      );

  YearlyBoardProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.yearStart,
  }) : super.internal();

  final DateTime yearStart;

  @override
  Override overrideWith(
    FutureOr<String> Function(YearlyBoardRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: YearlyBoardProvider._internal(
        (ref) => create(ref as YearlyBoardRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        yearStart: yearStart,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<String> createElement() {
    return _YearlyBoardProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is YearlyBoardProvider && other.yearStart == yearStart;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, yearStart.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin YearlyBoardRef on AutoDisposeFutureProviderRef<String> {
  /// The parameter `yearStart` of this provider.
  DateTime get yearStart;
}

class _YearlyBoardProviderElement
    extends AutoDisposeFutureProviderElement<String>
    with YearlyBoardRef {
  _YearlyBoardProviderElement(super.provider);

  @override
  DateTime get yearStart => (origin as YearlyBoardProvider).yearStart;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
