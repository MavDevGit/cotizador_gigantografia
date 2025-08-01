import 'package:flutter/material.dart';

/// Sistema de colores básico de la aplicación
/// Solo contiene referencias a colores nativos de Flutter
class AppColors {
  // Prevenir instanciación
  AppColors._();

  // ========== COLORES BÁSICOS ==========
  // Usar colores nativos de Flutter/Material Design
  static const Color primary = Colors.blue;
  static const Color secondary = Colors.blueAccent;
  static const Color surface = Colors.white;
  static const Color background = Colors.white;
  static const Color error = Colors.red;
  
  // Colores de texto básicos
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color onSurface = Colors.black;
  static const Color onBackground = Colors.black;
  static const Color onError = Colors.white;

  // ========== COLORES SEMÁNTICOS ==========
  /// Color para indicar éxito o confirmación
  static const Color success = Colors.green;
  
  /// Color para indicar advertencia o información importante
  static const Color warning = Colors.orange;
  
  /// Color blanco puro para contraste
  static const Color white = Colors.white;

  // ========== MÉTODOS HELPER BÁSICOS ==========
  /// Obtiene el color primario del contexto actual
  static Color getPrimary(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  /// Obtiene el color de error del contexto actual
  static Color getError(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }

  /// Obtiene el color de superficie del contexto actual
  static Color getSurface(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  /// Obtiene el color de fondo del contexto actual
  static Color getBackground(BuildContext context) {
    return Theme.of(context).colorScheme.surface; // surface instead of deprecated background
  }
}
