import 'package:go_router/go_router.dart';
import 'package:planyr/app/home_shell.dart';
import 'package:planyr/features/board/presentation/board_detail_screen.dart';
import 'package:planyr/features/board/presentation/board_create_screen.dart';
import 'package:planyr/features/preferences/presentation/preferences_screen.dart';
import 'package:planyr/features/task/presentation/event_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'boardList',
      builder: (context, state) => const HomeShell(),
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
    GoRoute(
      path: '/board/:id/event',
      name: 'eventCreate',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return EventScreen(boardId: id);
      },
    ),
    GoRoute(
      path: '/preferences',
      name: 'preferences',
      builder: (context, state) => const PreferencesScreen(),
    ),
  ],
);
