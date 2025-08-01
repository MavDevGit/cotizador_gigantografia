import 'package:flutter/material.dart';
import '../core/design_system/app_spacing.dart';

// Función de prueba para verificar sintaxis
Widget _buildContinueButton() {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.arrow_forward_rounded),
      label: const Text('Continuar a Finalizar'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
    ),
  );
}
