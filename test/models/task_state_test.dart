import 'package:flutter_test/flutter_test.dart';
import 'package:planyr/features/task/domain/task_state.dart';

void main() {
  group('TaskState', () {
    test('open and inProgress should not be terminal', () {
      expect(TaskState.open.isTerminal, isFalse);
      expect(TaskState.inProgress.isTerminal, isFalse);
    });

    test('complete, migrated, cancelled, wontDo should be terminal', () {
      expect(TaskState.complete.isTerminal, isTrue);
      expect(TaskState.migrated.isTerminal, isTrue);
      expect(TaskState.cancelled.isTerminal, isTrue);
      expect(TaskState.wontDo.isTerminal, isTrue);
    });

    test('all states should have display names', () {
      for (final state in TaskState.values) {
        expect(state.displayName, isNotEmpty);
      }
    });
  });
}
