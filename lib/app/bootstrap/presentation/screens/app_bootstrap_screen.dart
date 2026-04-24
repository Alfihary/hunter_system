import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/providers/auth_controller.dart';
import '../../domain/app_bootstrap_result.dart';
import '../providers/app_bootstrap_controller.dart';

/// Pantalla de arranque técnico.
///
/// ¿Qué hace?
/// Corre el bootstrap del sistema y muestra:
/// - carga
/// - error
/// - advertencias
///
/// ¿Para qué sirve?
/// Para garantizar que la app no navegue a flujos normales
/// antes de tener su configuración mínima estable.
class AppBootstrapScreen extends ConsumerWidget {
  const AppBootstrapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrapAsync = ref.watch(appBootstrapControllerProvider);
    final authState = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<AppBootstrapResult>>(appBootstrapControllerProvider, (
      _,
      next,
    ) {
      next.whenData((result) {
        if (!result.isSuccessful) return;

        if (!context.mounted) return;

        final target = authState.isAuthenticated ? '/home' : '/login';
        context.go(target);
      });
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: bootstrapAsync.when(
                loading: () => const _BootstrapLoadingView(),
                error: (error, _) => _BootstrapErrorView(
                  message: error.toString(),
                  onRetry: () {
                    ref.read(appBootstrapControllerProvider.notifier).retry();
                  },
                ),
                data: (result) => _BootstrapResultView(
                  result: result,
                  onRetry: () {
                    ref.read(appBootstrapControllerProvider.notifier).retry();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BootstrapLoadingView extends StatelessWidget {
  const _BootstrapLoadingView();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Preparando Hunter System',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Verificando configuración base y estado mínimo del sistema.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BootstrapErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _BootstrapErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(
              'No se pudo completar el arranque',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BootstrapResultView extends StatelessWidget {
  final AppBootstrapResult result;
  final VoidCallback onRetry;

  const _BootstrapResultView({required this.result, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final color = result.isSuccessful ? Colors.green : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              result.isSuccessful ? Icons.verified : Icons.error_outline,
              size: 48,
              color: color,
            ),
            const SizedBox(height: 16),
            Text(
              result.isSuccessful
                  ? 'Sistema preparado'
                  : 'El sistema no quedó listo',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(result.summary, textAlign: TextAlign.center),
            if (result.warnings.isNotEmpty) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Advertencias',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              ...result.warnings.map(
                (warning) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(warning)),
                    ],
                  ),
                ),
              ),
            ],
            if (!result.isSuccessful) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ] else ...[
              const SizedBox(height: 12),
              const Text(
                'Continuando automáticamente...',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
