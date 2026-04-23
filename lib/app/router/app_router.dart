import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/habits/domain/habit_summary.dart';
import '../../features/habits/presentation/screens/habit_form_screen.dart';
import '../../features/habits/presentation/screens/habit_history_screen.dart';
import '../../features/habits/presentation/screens/habits_screen.dart';
import '../../features/health/presentation/screens/health_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/nutrition/domain/nutrition_search_result.dart';
import '../../features/nutrition/presentation/screens/nutrition_barcode_scanner_screen.dart';
import '../../features/nutrition/presentation/screens/nutrition_log_form_screen.dart';
import '../../features/nutrition/presentation/screens/nutrition_screen.dart';
import '../../features/nutrition/presentation/screens/nutrition_search_screen.dart';
import '../../features/quests/presentation/screens/daily_missions_screen.dart';
import '../../features/rpg/presentation/screens/rpg_achievements_screen.dart';
import '../../features/rpg/presentation/screens/rpg_overview_screen.dart';
import '../../features/rpg/presentation/screens/rpg_titles_screen.dart';
import '../../features/workout/presentation/screens/routine_form_screen.dart';
import '../../features/workout/presentation/screens/workout_history_detail_screen.dart';
import '../../features/workout/presentation/screens/workout_history_screen.dart';
import '../../features/workout/presentation/screens/workout_routines_screen.dart';
import '../../features/workout/presentation/screens/workout_session_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/missions',
        builder: (context, state) => const DailyMissionsScreen(),
      ),
      GoRoute(
        path: '/habits',
        builder: (context, state) => const HabitsScreen(),
      ),
      GoRoute(
        path: '/habits/form',
        builder: (context, state) =>
            HabitFormScreen(initialHabit: state.extra as HabitSummary?),
      ),
      GoRoute(
        path: '/habits/history',
        builder: (context, state) =>
            HabitHistoryScreen(initialHabit: state.extra as HabitSummary),
      ),
      GoRoute(
        path: '/workouts',
        builder: (context, state) => const WorkoutRoutinesScreen(),
      ),
      GoRoute(
        path: '/workouts/form',
        builder: (context, state) => const RoutineFormScreen(),
      ),
      GoRoute(
        path: '/workouts/session/:routineId',
        builder: (context, state) =>
            WorkoutSessionScreen(routineId: state.pathParameters['routineId']!),
      ),
      GoRoute(
        path: '/workouts/history',
        builder: (context, state) => const WorkoutHistoryScreen(),
      ),
      GoRoute(
        path: '/workouts/history/:workoutId',
        builder: (context, state) => WorkoutHistoryDetailScreen(
          workoutId: state.pathParameters['workoutId']!,
        ),
      ),
      GoRoute(
        path: '/nutrition',
        builder: (context, state) => const NutritionScreen(),
      ),
      GoRoute(
        path: '/nutrition/search',
        builder: (context, state) => const NutritionSearchScreen(),
      ),
      GoRoute(
        path: '/nutrition/barcode',
        builder: (context, state) => const NutritionBarcodeScannerScreen(),
      ),
      GoRoute(
        path: '/nutrition/log',
        builder: (context, state) => NutritionLogFormScreen(
          initialSearchResult: state.extra as NutritionSearchResult?,
        ),
      ),
      GoRoute(
        path: '/health',
        builder: (context, state) => const HealthScreen(),
      ),
      GoRoute(
        path: '/rpg',
        builder: (context, state) => const RpgOverviewScreen(),
      ),
      GoRoute(
        path: '/rpg/achievements',
        builder: (context, state) => const RpgAchievementsScreen(),
      ),
      GoRoute(
        path: '/rpg/titles',
        builder: (context, state) => const RpgTitlesScreen(),
      ),
    ],
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final currentPath = state.uri.path;
      final goingToAuth = currentPath == '/login' || currentPath == '/register';

      if (!isAuthenticated && !goingToAuth) {
        return '/login';
      }

      if (isAuthenticated && goingToAuth) {
        return '/home';
      }

      return null;
    },
  );
});
