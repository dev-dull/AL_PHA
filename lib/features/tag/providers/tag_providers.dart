import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:alpha/features/tag/domain/tag.dart';
import 'package:alpha/shared/providers.dart';

part 'tag_providers.g.dart';

@riverpod
Stream<List<Tag>> tagList(TagListRef ref) {
  return ref.watch(tagRepositoryProvider).watchAll();
}

@riverpod
Stream<Map<String, List<Tag>>> tagsByBoard(
  TagsByBoardRef ref,
  String boardId,
) {
  return ref.watch(taskTagRepositoryProvider).watchTagsByBoard(boardId);
}

@riverpod
TagActions tagActions(TagActionsRef ref) => TagActions(ref);

class TagActions {
  final TagActionsRef _ref;
  static const _uuid = Uuid();
  static const maxTags = 12;
  static const maxTagsPerTask = 4;

  TagActions(this._ref);

  Future<Tag> create({
    required String name,
    required int color,
  }) async {
    final repo = _ref.read(tagRepositoryProvider);
    final all = await repo.getAll();
    if (all.length >= maxTags) {
      throw StateError('Maximum of $maxTags tags allowed');
    }
    final tag = Tag(
      id: _uuid.v4(),
      name: name,
      color: color,
      position: all.length,
      createdAt: DateTime.now().toUtc(),
    );
    return repo.create(tag);
  }

  Future<Tag> update(Tag tag) async {
    return _ref.read(tagRepositoryProvider).update(tag);
  }

  Future<void> delete(String id) async {
    await _ref.read(tagRepositoryProvider).delete(id);
  }

  Future<void> setTagsForTask(
    String taskId,
    List<String> tagIds,
  ) async {
    if (tagIds.length > maxTagsPerTask) {
      tagIds = tagIds.sublist(0, maxTagsPerTask);
    }
    await _ref
        .read(taskTagRepositoryProvider)
        .setTagsForTask(taskId, tagIds);
  }
}
