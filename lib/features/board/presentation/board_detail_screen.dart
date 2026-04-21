import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planyr/features/board/presentation/board_grid_body.dart';
import 'package:planyr/features/board/providers/board_providers.dart';
import 'package:planyr/features/migration/presentation/migration_wizard.dart';

/// Standalone screen for viewing a board by ID (used for deep
/// links and the router's /board/:id route).
class BoardDetailScreen extends ConsumerWidget {
  final String boardId;

  const BoardDetailScreen({super.key, required this.boardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardAsync = ref.watch(boardProvider(boardId));

    final boardName = boardAsync.when(
      data: (b) => b?.name ?? 'Board',
      loading: () => 'Loading...',
      error: (_, _) => 'Board',
    );

    final board = boardAsync.valueOrNull;
    final showBanner = board != null && isBoardPeriodEnded(board);

    return Scaffold(
      appBar: AppBar(title: Text(boardName)),
      body: Column(
        children: [
          if (showBanner)
            MigrationBanner(
              onMigrate: () =>
                  showMigrationWizard(context, sourceBoardId: boardId),
            ),
          Expanded(
            child: BoardGridBody(key: ValueKey(boardId), boardId: boardId),
          ),
        ],
      ),
    );
  }
}
