import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/habits/domain/habit_summary.dart';
import '../../features/habits/presentation/screens/habit_form_screen.dart';
import '../../features/habits/presentation/screens/habit_history_screen.dart';
import '../../features/habits/presentation/screens/habits_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
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
