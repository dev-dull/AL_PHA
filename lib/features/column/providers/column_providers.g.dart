// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'column_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$columnListHash() => r'f8b29a8f0b3b5340cad725417c89fb6475302562';

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

/// See also [columnList].
@ProviderFor(columnList)
const columnListProvider = ColumnListFamily();

/// See also [columnList].
class ColumnListFamily extends Family<AsyncValue<List<BoardColumn>>> {
  /// See also [columnList].
  const ColumnListFamily();

  /// See also [columnList].
  ColumnListProvider call(String boardId) {
    return ColumnListProvider(boardId);
  }

  @override
  ColumnListProvider getProviderOverride(
    covariant ColumnListProvider provider,
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
  String? get name => r'columnListProvider';
}

/// See also [columnList].
class ColumnListProvider extends AutoDisposeStreamProvider<List<BoardColumn>> {
  /// See also [columnList].
  ColumnListProvider(String boardId)
    : this._internal(
        (ref) => columnList(ref as ColumnListRef, boardId),
        from: columnListProvider,
        name: r'columnListProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$columnListHash,
        dependencies: ColumnListFamily._dependencies,
        allTransitiveDependencies: ColumnListFamily._allTransitiveDependencies,
        boardId: boardId,
      );

  ColumnListProvider._internal(
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
    Stream<List<BoardColumn>> Function(ColumnListRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ColumnListProvider._internal(
        (ref) => create(ref as ColumnListRef),
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
  AutoDisposeStreamProviderElement<List<BoardColumn>> createElement() {
    return _ColumnListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ColumnListProvider && other.boardId == boardId;
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
mixin ColumnListRef on AutoDisposeStreamProviderRef<List<BoardColumn>> {
  /// The parameter `boardId` of this provider.
  String get boardId;
}

class _ColumnListProviderElement
    extends AutoDisposeStreamProviderElement<List<BoardColumn>>
    with ColumnListRef {
  _ColumnListProviderElement(super.provider);

  @override
  String get boardId => (origin as ColumnListProvider).boardId;
}

String _$columnActionsHash() => r'19c59335a21e0498b2e9b41ec04eade20cbca8c1';

/// Helper class for column mutations. Access via ref.read.
///
/// Copied from [columnActions].
@ProviderFor(columnActions)
final columnActionsProvider = AutoDisposeProvider<ColumnActions>.internal(
  columnActions,
  name: r'columnActionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$columnActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ColumnActionsRef = AutoDisposeProviderRef<ColumnActions>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
