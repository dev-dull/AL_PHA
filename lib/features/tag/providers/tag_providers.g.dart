// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tagListHash() => r'445e08312b329ebd2ee3e1398fac019ca0924838';

/// See also [tagList].
@ProviderFor(tagList)
final tagListProvider = AutoDisposeStreamProvider<List<Tag>>.internal(
  tagList,
  name: r'tagListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$tagListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TagListRef = AutoDisposeStreamProviderRef<List<Tag>>;
String _$tagsByBoardHash() => r'065f426bb1226f4321a8dfed869af7636994ec39';

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

/// See also [tagsByBoard].
@ProviderFor(tagsByBoard)
const tagsByBoardProvider = TagsByBoardFamily();

/// See also [tagsByBoard].
class TagsByBoardFamily extends Family<AsyncValue<Map<String, List<Tag>>>> {
  /// See also [tagsByBoard].
  const TagsByBoardFamily();

  /// See also [tagsByBoard].
  TagsByBoardProvider call(String boardId) {
    return TagsByBoardProvider(boardId);
  }

  @override
  TagsByBoardProvider getProviderOverride(
    covariant TagsByBoardProvider provider,
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
  String? get name => r'tagsByBoardProvider';
}

/// See also [tagsByBoard].
class TagsByBoardProvider
    extends AutoDisposeStreamProvider<Map<String, List<Tag>>> {
  /// See also [tagsByBoard].
  TagsByBoardProvider(String boardId)
    : this._internal(
        (ref) => tagsByBoard(ref as TagsByBoardRef, boardId),
        from: tagsByBoardProvider,
        name: r'tagsByBoardProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$tagsByBoardHash,
        dependencies: TagsByBoardFamily._dependencies,
        allTransitiveDependencies: TagsByBoardFamily._allTransitiveDependencies,
        boardId: boardId,
      );

  TagsByBoardProvider._internal(
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
    Stream<Map<String, List<Tag>>> Function(TagsByBoardRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TagsByBoardProvider._internal(
        (ref) => create(ref as TagsByBoardRef),
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
  AutoDisposeStreamProviderElement<Map<String, List<Tag>>> createElement() {
    return _TagsByBoardProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TagsByBoardProvider && other.boardId == boardId;
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
mixin TagsByBoardRef on AutoDisposeStreamProviderRef<Map<String, List<Tag>>> {
  /// The parameter `boardId` of this provider.
  String get boardId;
}

class _TagsByBoardProviderElement
    extends AutoDisposeStreamProviderElement<Map<String, List<Tag>>>
    with TagsByBoardRef {
  _TagsByBoardProviderElement(super.provider);

  @override
  String get boardId => (origin as TagsByBoardProvider).boardId;
}

String _$tagActionsHash() => r'ccc5b17f21a89532923eb4ddae0cd704cecf9306';

/// See also [tagActions].
@ProviderFor(tagActions)
final tagActionsProvider = AutoDisposeProvider<TagActions>.internal(
  tagActions,
  name: r'tagActionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$tagActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TagActionsRef = AutoDisposeProviderRef<TagActions>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
