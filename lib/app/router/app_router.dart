import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../bootstrap/presentation/providers/app_bootstrap_controller.dart';
import '../bootstrap/presentation/screens/app_bootstrap_screen.dart';
import '../layout/hunter_shell_screen.dart';
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
import '../../features/profile/presentation/screens/hunter_profile_screen.dart';
import '../../features/quests/presentation/screens/daily_missions_screen.dart';
import '../../features/rpg/presentation/screens/rpg_achievements_screen.dart';
import '../../features/rpg/presentation/screens/rpg_overview_screen.dart';
import '../../features/rpg/presentation/screens/rpg_titles_screen.dart';
import '../../features/system/presentation/screens/system_diagnostics_screen.dart';
import '../../features/workout/presentation/screens/routine_form_screen.dart';
import '../../features/workout/presentation/screens/workout_history_detail_screen.dart';
import '../../features/workout/presentation/screens/workout_history_screen.dart';
import '../../features/workout/presentation/screens/workout_routines_screen.dart';
import '../../features/workout/presentation/screens/workout_session_screen.dart';

/// Router principal de Hunter System.
///
/// ¿Qué hace?
/// Define:
/// - bootstrap inicial
/// - rutas públicas de auth
/// - rutas principales con barra inferior
/// - rutas secundarias internas
///
/// ¿Para qué sirve?
/// Para mantener navegación clara, protegida y escalable.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final bootstrapState = ref.watch(appBootstrapControllerProvider);

  return GoRouter(
    initialLocation: '/bootstrap',
    routes: [
      GoRoute(
        path: '/bootstrap',
        builder: (context, state) => const AppBootstrapScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      /// Rutas principales con barra inferior fija.
      ShellRoute(
        builder: (context, state, child) {
          return HunterShellScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/workouts',
            builder: (context, state) => const WorkoutRoutinesScreen(),
          ),
          GoRoute(
            path: '/nutrition',
            builder: (context, state) => const NutritionScreen(),
          ),
          GoRoute(
            path: '/habits',
            builder: (context, state) => const HabitsScreen(),
          ),

          /// Visualmente ahora se llama STATS.
          /// Internamente seguimos usando el módulo rpg para no romper arquitectura.
          GoRoute(
            path: '/stats',
            builder: (context, state) => const RpgOverviewScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const HunterProfileScreen(),
          ),
        ],
      ),

      /// Rutas secundarias sin tab principal obligatorio.
      GoRoute(
        path: '/system/diagnostics',
        builder: (context, state) => const SystemDiagnosticsScreen(),
      ),
      GoRoute(
        path: '/missions',
        builder: (context, state) => const DailyMissionsScreen(),
      ),
      GoRoute(
        path: '/health',
        builder: (context, state) => const HealthScreen(),
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

      /// Compatibilidad temporal: si algo viejo manda a /rpg,
      /// lo redirigimos a /stats.
      GoRoute(path: '/rpg', redirect: (context, state) => '/stats'),
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
      final currentPath = state.uri.path;
      final goingToBootstrap = currentPath == '/bootstrap';
      final goingToAuth = currentPath == '/login' || currentPath == '/register';

      if (!bootstrapState.hasValue) {
        return goingToBootstrap ? null : '/bootstrap';
      }

      if (goingToBootstrap) {
        return authState.isAuthenticated ? '/home' : '/login';
      }

      if (!authState.isAuthenticated && !goingToAuth) {
        return '/login';
      }

      if (authState.isAuthenticated && goingToAuth) {
        return '/home';
      }

      return null;
    },
  );
});
