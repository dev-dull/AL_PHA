// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$taskListHash() => r'dbe8a99d7d74744792d8972e3cfba9055715e6ae';

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

/// See also [taskList].
@ProviderFor(taskList)
const taskListProvider = TaskListFamily();

/// See also [taskList].
class TaskListFamily extends Family<AsyncValue<List<Task>>> {
  /// See also [taskList].
  const TaskListFamily();

  /// See also [taskList].
  TaskListProvider call(String boardId) {
    return TaskListProvider(boardId);
  }

  @override
  TaskListProvider getProviderOverride(covariant TaskListProvider provider) {
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
  String? get name => r'taskListProvider';
}

/// See also [taskList].
class TaskListProvider extends AutoDisposeStreamProvider<List<Task>> {
  /// See also [taskList].
  TaskListProvider(String boardId)
    : this._internal(
        (ref) => taskList(ref as TaskListRef, boardId),
        from: taskListProvider,
        name: r'taskListProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$taskListHash,
        dependencies: TaskListFamily._dependencies,
        allTransitiveDependencies: TaskListFamily._allTransitiveDependencies,
        boardId: boardId,
      );

  TaskListProvider._internal(
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
    Stream<List<Task>> Function(TaskListRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TaskListProvider._internal(
        (ref) => create(ref as TaskListRef),
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
  AutoDisposeStreamProviderElement<List<Task>> createElement() {
    return _TaskListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TaskListProvider && other.boardId == boardId;
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
mixin TaskListRef on AutoDisposeStreamProviderRef<List<Task>> {
  /// The parameter `boardId` of this provider.
  String get boardId;
}

class _TaskListProviderElement
    extends AutoDisposeStreamProviderElement<List<Task>>
    with TaskListRef {
  _TaskListProviderElement(super.provider);

  @override
  String get boardId => (origin as TaskListProvider).boardId;
}

String _$taskActionsHash() => r'2f99326583ea33c80cf60fbebfa4f2e1f67a2f1c';

/// Helper class for task mutations. Access via ref.read.
///
/// Copied from [taskActions].
@ProviderFor(taskActions)
final taskActionsProvider = AutoDisposeProvider<TaskActions>.internal(
  taskActions,
  name: r'taskActionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$taskActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TaskActionsRef = AutoDisposeProviderRef<TaskActions>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
