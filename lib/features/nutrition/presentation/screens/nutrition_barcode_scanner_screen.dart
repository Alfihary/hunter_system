import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../providers/nutrition_controller.dart';

/// Pantalla de escaneo de código de barras.
///
/// ¿Qué hace?
/// Abre la cámara, detecta un barcode y consulta Open Food Facts.
///
/// ¿Para qué sirve?
/// Para acelerar el registro de alimentos empaquetados
/// sin capturar manualmente todos los macros.
class NutritionBarcodeScannerScreen extends ConsumerStatefulWidget {
  const NutritionBarcodeScannerScreen({super.key});

  @override
  ConsumerState<NutritionBarcodeScannerScreen> createState() =>
      _NutritionBarcodeScannerScreenState();
}

class _NutritionBarcodeScannerScreenState
    extends ConsumerState<NutritionBarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );

  bool _isProcessing = false;
  String? _lastBarcode;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  /// Procesa el barcode detectado.
  ///
  /// ¿Qué hace?
  /// - detiene temporalmente el scanner
  /// - consulta Open Food Facts
  /// - si encuentra producto, abre el formulario prellenado
  /// - si no encuentra, ofrece captura manual
  Future<void> _handleBarcode(String barcode) async {
    if (_isProcessing) return;

    final cleaned = barcode.trim();
    if (cleaned.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _lastBarcode = cleaned;
    });

    await _controller.stop();

    try {
      final result = await ref
          .read(nutritionRepositoryProvider)
          .getFoodByBarcode(cleaned);

      if (!mounted) return;

      if (result != null) {
        context.pushReplacement('/nutrition/log', extra: result);
        return;
      }

      final useManual = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Producto no encontrado'),
            content: Text(
              'No encontré el código $cleaned en Open Food Facts.\n\n¿Quieres registrarlo manualmente?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Seguir escaneando'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Manual'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      if (useManual == true) {
        context.pushReplacement('/nutrition/log');
        return;
      }

      await _controller.start();

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));

      await _controller.start();

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear código')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcodes = capture.barcodes;

              for (final barcode in barcodes) {
                final rawValue = barcode.rawValue;
                if (rawValue == null || rawValue.trim().isEmpty) continue;

                _handleBarcode(rawValue);
                break;
              }
            },
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 280,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isProcessing
                          ? 'Buscando producto...'
                          : 'Coloca el código de barras dentro del recuadro',
                      textAlign: TextAlign.center,
                    ),
                    if (_lastBarcode != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Último código: $_lastBarcode',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
