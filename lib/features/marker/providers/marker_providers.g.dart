// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marker_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$markersByBoardHash() => r'b0a189fd0fe5e862cbc1fec3b8d7ff69705c6ece';

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

/// See also [markersByBoard].
@ProviderFor(markersByBoard)
const markersByBoardProvider = MarkersByBoardFamily();

/// See also [markersByBoard].
class MarkersByBoardFamily extends Family<AsyncValue<Map<String, Marker>>> {
  /// See also [markersByBoard].
  const MarkersByBoardFamily();

  /// See also [markersByBoard].
  MarkersByBoardProvider call(String boardId) {
    return MarkersByBoardProvider(boardId);
  }

  @override
  MarkersByBoardProvider getProviderOverride(
    covariant MarkersByBoardProvider provider,
  ) {
    return call(provider.boardId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'markersByBoardProvider';
}

/// See also [markersByBoard].
class MarkersByBoardProvider
    extends AutoDisposeStreamProvider<Map<String, Marker>> {
  /// See also [markersByBoard].
  MarkersByBoardProvider(String boardId)
    : this._internal(
        (ref) => markersByBoard(ref as MarkersByBoardRef, boardId),
        from: markersByBoardProvider,
        name: r'markersByBoardProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$markersByBoardHash,
        dependencies: MarkersByBoardFamily._dependencies,
        allTransitiveDependencies:
            MarkersByBoardFamily._allTransitiveDependencies,
        boardId: boardId,
      );

  MarkersByBoardProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.boardId,
  }) : super.internal();

  final String boardId;

  @override
  Override overrideWith(
    Stream<Map<String, Marker>> Function(MarkersByBoardRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MarkersByBoardProvider._internal(
        (ref) => create(ref as MarkersByBoardRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        boardId: boardId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<Map<String, Marker>> createElement() {
    return _MarkersByBoardProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MarkersByBoardProvider && other.boardId == boardId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, boardId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MarkersByBoardRef on AutoDisposeStreamProviderRef<Map<String, Marker>> {
  /// The parameter `boardId` of this provider.
  String get boardId;
}

class _MarkersByBoardProviderElement
    extends AutoDisposeStreamProviderElement<Map<String, Marker>>
    with MarkersByBoardRef {
  _MarkersByBoardProviderElement(super.provider);

  @override
  String get boardId => (origin as MarkersByBoardProvider).boardId;
}

String _$markerHash() => r'e4e7b385c9b9595e8fb6c643d55bbc863f597ce2';

/// See also [marker].
@ProviderFor(marker)
const markerProvider = MarkerFamily();

/// See also [marker].
class MarkerFamily extends Family<Marker?> {
  /// See also [marker].
  const MarkerFamily();

  /// See also [marker].
  MarkerProvider call(String taskId, String columnId) {
    return MarkerProvider(taskId, columnId);
  }

  @override
  MarkerProvider getProviderOverride(covariant MarkerProvider provider) {
    return call(provider.taskId, provider.columnId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'markerProvider';
}

/// See also [marker].
class MarkerProvider extends AutoDisposeProvider<Marker?> {
  /// See also [marker].
  MarkerProvider(String taskId, String columnId)
    : this._internal(
        (ref) => marker(ref as MarkerRef, taskId, columnId),
        from: markerProvider,
        name: r'markerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$markerHash,
        dependencies: MarkerFamily._dependencies,
        allTransitiveDependencies: MarkerFamily._allTransitiveDependencies,
        taskId: taskId,
        columnId: columnId,
      );

  MarkerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.taskId,
    required this.columnId,
  }) : super.internal();

  final String taskId;
  final String columnId;

  @override
  Override overrideWith(Marker? Function(MarkerRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: MarkerProvider._internal(
        (ref) => create(ref as MarkerRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        taskId: taskId,
        columnId: columnId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<Marker?> createElement() {
    return _MarkerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MarkerProvider &&
        other.taskId == taskId &&
        other.columnId == columnId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, taskId.hashCode);
    hash = _SystemHash.combine(hash, columnId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MarkerRef on AutoDisposeProviderRef<Marker?> {
  /// The parameter `taskId` of this provider.
  String get taskId;

  /// The parameter `columnId` of this provider.
  String get columnId;
}

class _MarkerProviderElement extends AutoDisposeProviderElement<Marker?>
    with MarkerRef {
  _MarkerProviderElement(super.provider);

  @override
  String get taskId => (origin as MarkerProvider).taskId;
  @override
  String get columnId => (origin as MarkerProvider).columnId;
}

String _$markerFromBoardHash() => r'c377e6bf92d1dc419ce1850bceeee5c1e757604f';

/// Derived provider for a single cell marker, keyed off the
/// board-level markers map for granular rebuilds.
///
/// Copied from [markerFromBoard].
@ProviderFor(markerFromBoard)
const markerFromBoardProvider = MarkerFromBoardFamily();

/// Derived provider for a single cell marker, keyed off the
/// board-level markers map for granular rebuilds.
///
/// Copied from [markerFromBoard].
class MarkerFromBoardFamily extends Family<Marker?> {
  /// Derived provider for a single cell marker, keyed off the
  /// board-level markers map for granular rebuilds.
  ///
  /// Copied from [markerFromBoard].
  const MarkerFromBoardFamily();

  /// Derived provider for a single cell marker, keyed off the
  /// board-level markers map for granular rebuilds.
  ///
  /// Copied from [markerFromBoard].
  MarkerFromBoardProvider call(String boardId, String taskId, String columnId) {
    return MarkerFromBoardProvider(boardId, taskId, columnId);
  }

  @override
  MarkerFromBoardProvider getProviderOverride(
    covariant MarkerFromBoardProvider provider,
  ) {
    return call(provider.boardId, provider.taskId, provider.columnId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'markerFromBoardProvider';
}

/// Derived provider for a single cell marker, keyed off the
/// board-level markers map for granular rebuilds.
///
/// Copied from [markerFromBoard].
class MarkerFromBoardProvider extends AutoDisposeProvider<Marker?> {
  /// Derived provider for a single cell marker, keyed off the
  /// board-level markers map for granular rebuilds.
  ///
  /// Copied from [markerFromBoard].
  MarkerFromBoardProvider(String boardId, String taskId, String columnId)
    : this._internal(
        (ref) => markerFromBoard(
          ref as MarkerFromBoardRef,
          boardId,
          taskId,
          columnId,
        ),
        from: markerFromBoardProvider,
        name: r'markerFromBoardProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$markerFromBoardHash,
        dependencies: MarkerFromBoardFamily._dependencies,
        allTransitiveDependencies:
            MarkerFromBoardFamily._allTransitiveDependencies,
        boardId: boardId,
        taskId: taskId,
        columnId: columnId,
      );

  MarkerFromBoardProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.boardId,
    required this.taskId,
    required this.columnId,
  }) : super.internal();

  final String boardId;
  final String taskId;
  final String columnId;

  @override
  Override overrideWith(Marker? Function(MarkerFromBoardRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: MarkerFromBoardProvider._internal(
        (ref) => create(ref as MarkerFromBoardRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        boardId: boardId,
        taskId: taskId,
        columnId: columnId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<Marker?> createElement() {
    return _MarkerFromBoardProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MarkerFromBoardProvider &&
        other.boardId == boardId &&
        other.taskId == taskId &&
        other.columnId == columnId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, boardId.hashCode);
    hash = _SystemHash.combine(hash, taskId.hashCode);
    hash = _SystemHash.combine(hash, columnId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MarkerFromBoardRef on AutoDisposeProviderRef<Marker?> {
  /// The parameter `boardId` of this provider.
  String get boardId;

  /// The parameter `taskId` of this provider.
  String get taskId;

  /// The parameter `columnId` of this provider.
  String get columnId;
}

class _MarkerFromBoardProviderElement
    extends AutoDisposeProviderElement<Marker?>
    with MarkerFromBoardRef {
  _MarkerFromBoardProviderElement(super.provider);

  @override
  String get boardId => (origin as MarkerFromBoardProvider).boardId;
  @override
  String get taskId => (origin as MarkerFromBoardProvider).taskId;
  @override
  String get columnId => (origin as MarkerFromBoardProvider).columnId;
}

String _$markerActionsHash() => r'3279ac6fedbd010c8fdc7b9f51ac9e809fd71925';

/// Helper class for marker mutations. Access via ref.read.
///
/// Copied from [markerActions].
@ProviderFor(markerActions)
final markerActionsProvider = AutoDisposeProvider<MarkerActions>.internal(
  markerActions,
  name: r'markerActionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$markerActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MarkerActionsRef = AutoDisposeProviderRef<MarkerActions>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
