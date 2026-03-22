// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_note_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$taskNoteListHash() => r'4e7ec068f5c790d6f2954c198866bae811f37e96';

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

/// See also [taskNoteList].
@ProviderFor(taskNoteList)
const taskNoteListProvider = TaskNoteListFamily();

/// See also [taskNoteList].
class TaskNoteListFamily extends Family<AsyncValue<List<TaskNote>>> {
  /// See also [taskNoteList].
  const TaskNoteListFamily();

  /// See also [taskNoteList].
  TaskNoteListProvider call(String taskId) {
    return TaskNoteListProvider(taskId);
  }

  @override
  TaskNoteListProvider getProviderOverride(
    covariant TaskNoteListProvider provider,
  ) {
    return call(provider.taskId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'taskNoteListProvider';
}

/// See also [taskNoteList].
class TaskNoteListProvider extends AutoDisposeStreamProvider<List<TaskNote>> {
  /// See also [taskNoteList].
  TaskNoteListProvider(String taskId)
    : this._internal(
        (ref) => taskNoteList(ref as TaskNoteListRef, taskId),
        from: taskNoteListProvider,
        name: r'taskNoteListProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$taskNoteListHash,
        dependencies: TaskNoteListFamily._dependencies,
        allTransitiveDependencies:
            TaskNoteListFamily._allTransitiveDependencies,
        taskId: taskId,
      );

  TaskNoteListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.taskId,
  }) : super.internal();

  final String taskId;

  @override
  Override overrideWith(
    Stream<List<TaskNote>> Function(TaskNoteListRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TaskNoteListProvider._internal(
        (ref) => create(ref as TaskNoteListRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        taskId: taskId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<TaskNote>> createElement() {
    return _TaskNoteListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TaskNoteListProvider && other.taskId == taskId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, taskId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TaskNoteListRef on AutoDisposeStreamProviderRef<List<TaskNote>> {
  /// The parameter `taskId` of this provider.
  String get taskId;
}

class _TaskNoteListProviderElement
    extends AutoDisposeStreamProviderElement<List<TaskNote>>
    with TaskNoteListRef {
  _TaskNoteListProviderElement(super.provider);

  @override
  String get taskId => (origin as TaskNoteListProvider).taskId;
}

String _$taskNoteActionsHash() => r'c2d9c7f3b6742168ca4293c47312958cf5f60a2a';

/// See also [taskNoteActions].
@ProviderFor(taskNoteActions)
final taskNoteActionsProvider = AutoDisposeProvider<TaskNoteActions>.internal(
  taskNoteActions,
  name: r'taskNoteActionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$taskNoteActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TaskNoteActionsRef = AutoDisposeProviderRef<TaskNoteActions>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
