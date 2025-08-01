import 'package:flutter/material.dart';

/// Tema básico de la aplicación
/// Solo contiene configuración básica de Flutter
class AppTheme {
  // Prevenir instanciación
  AppTheme._();

  /// Tema básico de la aplicación usando valores por defecto de Flutter
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      // Usar el colorScheme por defecto de Flutter
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    );
  }
  
  /// Getter para obtener el tema principal
  static ThemeData get theme => lightTheme;
}
