import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/questions/presentation/screens/category_screen.dart';
import '../../features/questions/presentation/screens/question_screen.dart';
import '../../features/game/presentation/screens/game_setup_screen.dart';
import '../../features/game/presentation/screens/game_play_screen.dart';
import '../../features/game/presentation/screens/game_result_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/stats/presentation/screens/stats_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/badges/presentation/screens/badges_screen.dart';
import '../../domain/models/game_session.dart';
import '../../shared/widgets/main_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRoutes {
  static const String home = '/';
  static const String category = '/category/:categoryId';
  static const String questions = '/questions/:categoryId';
  static const String gameSetup = '/game/setup';
  static const String gamePlay = '/game/play';
  static const String gameResult = '/game/result';
  static const String favorites = '/favorites';
  static const String stats = '/stats';
  static const String profile = '/profile';
  static const String search = '/search';
  static const String history = '/history';
  static const String badges = '/badges';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: false,
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => _fadeTransition(
              state,
              const HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.favorites,
            pageBuilder: (context, state) => _fadeTransition(
              state,
              const FavoritesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.stats,
            pageBuilder: (context, state) => _fadeTransition(
              state,
              const StatsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => _fadeTransition(
              state,
              const ProfileScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.category,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final categoryId = state.pathParameters['categoryId']!;
          return _slideTransition(state, CategoryScreen(categoryId: categoryId));
        },
      ),
      GoRoute(
        path: '/questions/:categoryId',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final categoryId = state.pathParameters['categoryId']!;
          final mode = state.uri.queryParameters['mode'];
          return _slideTransition(
            state,
            QuestionScreen(
              categoryId: categoryId,
              mode: mode != null
                  ? GameMode.values.firstWhere(
                      (m) => m.name == mode,
                      orElse: () => GameMode.classic,
                    )
                  : GameMode.classic,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.gameSetup,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideTransition(
          state,
          const GameSetupScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.gamePlay,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final sessionId = extra?['sessionId'] as String?;
          return _fadeTransition(
            state,
            GamePlayScreen(sessionId: sessionId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.gameResult,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final sessionId = extra?['sessionId'] as String?;
          return _fadeTransition(
            state,
            GameResultScreen(sessionId: sessionId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.search,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeTransition(
          state,
          const SearchScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.history,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideTransition(
          state,
          const HistoryScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.badges,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideTransition(
          state,
          const BadgesScreen(),
        ),
      ),
    ],
  );
});

CustomTransitionPage<void> _fadeTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

CustomTransitionPage<void> _slideTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}
