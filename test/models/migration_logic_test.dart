import 'package:flutter_test/flutter_test.dart';

import 'package:alpha/features/board/domain/board.dart';
import 'package:alpha/features/board/domain/board_type.dart';
import 'package:alpha/features/migration/presentation/migration_wizard.dart';

void main() {
  group('isBoardPeriodEnded', () {
    Board boardCreatedAt(BoardType type, DateTime createdAt) {
      return Board(
        id: 'test',
        name: 'Test',
        type: type,
        createdAt: createdAt,
        updatedAt: createdAt,
      );
    }

    test('daily board created yesterday returns true', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final board = boardCreatedAt(BoardType.daily, yesterday);
      expect(isBoardPeriodEnded(board), isTrue);
    });

    test('daily board created today returns false', () {
      final board = boardCreatedAt(BoardType.daily, DateTime.now());
      expect(isBoardPeriodEnded(board), isFalse);
    });

    test('weekly board past its Sunday returns true', () {
      // Create a board on a Monday two weeks ago
      final now = DateTime.now();
      final twoWeeksAgo = now.subtract(const Duration(days: 14));
      final board = boardCreatedAt(BoardType.weekly, twoWeeksAgo);
      expect(isBoardPeriodEnded(board), isTrue);
    });

    test('weekly board created this week returns false', () {
      // Create a board today (its Sunday hasn't passed yet or is today)
      final now = DateTime.now();
      // Go to Monday of this week
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final board = boardCreatedAt(BoardType.weekly, monday);

      // The Sunday of this week is monday + 6 days. If today is before
      // that Sunday, it should be false.
      final sunday = monday.add(const Duration(days: 6));
      final today = DateTime(now.year, now.month, now.day);
      if (today.isBefore(sunday) || today.isAtSameMomentAs(sunday)) {
        expect(isBoardPeriodEnded(board), isFalse);
      } else {
        // If today IS Sunday, then today.isAfter(sunday) is false
        // because sunday = Monday + 6 days and the comparison uses
        // dateOnly, so they'd be equal.
        expect(isBoardPeriodEnded(board), isFalse);
      }
    });

    test('monthly board from last month returns true', () {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      final board = boardCreatedAt(BoardType.monthly, lastMonth);
      expect(isBoardPeriodEnded(board), isTrue);
    });

    test('monthly board from this month returns false', () {
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);
      final board = boardCreatedAt(BoardType.monthly, thisMonth);
      expect(isBoardPeriodEnded(board), isFalse);
    });

    test('yearly board from last year returns true', () {
      final now = DateTime.now();
      final lastYear = DateTime(now.year - 1, 1, 1);
      final board = boardCreatedAt(BoardType.yearly, lastYear);
      expect(isBoardPeriodEnded(board), isTrue);
    });

    test('yearly board from this year returns false', () {
      final now = DateTime.now();
      final thisYear = DateTime(now.year, 1, 1);
      final board = boardCreatedAt(BoardType.yearly, thisYear);
      expect(isBoardPeriodEnded(board), isFalse);
    });

    test('custom board always returns false', () {
      final ancient = DateTime(2020, 1, 1);
      final board = boardCreatedAt(BoardType.custom, ancient);
      expect(isBoardPeriodEnded(board), isFalse);
    });
  });
}
