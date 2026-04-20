import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/providers/theme_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Punto de entrada visual de la aplicación.
///
/// Responsabilidades:
/// - Leer el router global.
/// - Leer el tema global.
/// - Construir MaterialApp.router.
///
/// Esta clase no contiene lógica de negocio.
class HunterSystemApp extends ConsumerWidget {
  const HunterSystemApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Hunter System',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}