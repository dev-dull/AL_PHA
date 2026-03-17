// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$boardListHash() => r'0e2c7e3c3beb08e0d89567460f3732a9572b684c';

/// See also [boardList].
@ProviderFor(boardList)
final boardListProvider = AutoDisposeStreamProvider<List<Board>>.internal(
  boardList,
  name: r'boardListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$boardListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BoardListRef = AutoDisposeStreamProviderRef<List<Board>>;
String _$boardHash() => r'e3208b373f0b4b12f1afa65ca6496254c902b8a6';

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

/// See also [board].
@ProviderFor(board)
const boardProvider = BoardFamily();

/// See also [board].
class BoardFamily extends Family<AsyncValue<Board?>> {
  /// See also [board].
  const BoardFamily();

  /// See also [board].
  BoardProvider call(String boardId) {
    return BoardProvider(boardId);
  }

  @override
  BoardProvider getProviderOverride(covariant BoardProvider provider) {
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
  String? get name => r'boardProvider';
}

/// See also [board].
class BoardProvider extends AutoDisposeFutureProvider<Board?> {
  /// See also [board].
  BoardProvider(String boardId)
    : this._internal(
        (ref) => board(ref as BoardRef, boardId),
        from: boardProvider,
        name: r'boardProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$boardHash,
        dependencies: BoardFamily._dependencies,
        allTransitiveDependencies: BoardFamily._allTransitiveDependencies,
        boardId: boardId,
      );

  BoardProvider._internal(
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
  Override overrideWith(FutureOr<Board?> Function(BoardRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: BoardProvider._internal(
        (ref) => create(ref as BoardRef),
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
  AutoDisposeFutureProviderElement<Board?> createElement() {
    return _BoardProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BoardProvider && other.boardId == boardId;
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
mixin BoardRef on AutoDisposeFutureProviderRef<Board?> {
  /// The parameter `boardId` of this provider.
  String get boardId;
}

class _BoardProviderElement extends AutoDisposeFutureProviderElement<Board?>
    with BoardRef {
  _BoardProviderElement(super.provider);

  @override
  String get boardId => (origin as BoardProvider).boardId;
}

String _$boardActionsHash() => r'fee1d18c4cd78763d1d3e6d9130c21e3f13f1987';

/// Helper class for board mutations. Access via ref.read.
///
/// Copied from [boardActions].
@ProviderFor(boardActions)
final boardActionsProvider = AutoDisposeProvider<BoardActions>.internal(
  boardActions,
  name: r'boardActionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$boardActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BoardActionsRef = AutoDisposeProviderRef<BoardActions>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
