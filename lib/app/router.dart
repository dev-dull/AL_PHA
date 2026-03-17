import 'package:go_router/go_router.dart';
import 'package:alpha/features/board/presentation/board_list_screen.dart';
import 'package:alpha/features/board/presentation/board_detail_screen.dart';
import 'package:alpha/features/board/presentation/board_create_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'boardList',
      builder: (context, state) => const BoardListScreen(),
    ),
    GoRoute(
      path: '/board/create',
      name: 'boardCreate',
      builder: (context, state) => const BoardCreateScreen(),
    ),
    GoRoute(
      path: '/board/:id',
      name: 'boardDetail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return BoardDetailScreen(boardId: id);
      },
    ),
  ],
);
