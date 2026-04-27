import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/providers/theme_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Punto de entrada visual de la aplicación.
class HunterSystemApp extends ConsumerWidget {
  const HunterSystemApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeState = ref.watch(themeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Hunter System',
      theme: AppTheme.lightTheme(themeState.preset),
      darkTheme: AppTheme.darkTheme(themeState.preset),
      themeMode: themeState.mode,
      routerConfig: router,
    );
  }
}