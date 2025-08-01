import 'package:flutter/material.dart';

/// Sistema de tipografía básico de la aplicación
/// Solo contiene referencias a estilos nativos de Flutter
class AppTypography {
  // Prevenir instanciación
  AppTypography._();

  // ========== VALORES BÁSICOS ==========
  static const String fontFamily = 'Roboto'; // Font por defecto de Flutter
  
  // Weights básicos
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight bold = FontWeight.w700;

  // ========== ESTILOS BÁSICOS ==========
  // Usando los estilos por defecto de Flutter
  static const TextStyle headline1 = TextStyle(fontSize: 32, fontWeight: bold);
  static const TextStyle headline2 = TextStyle(fontSize: 28, fontWeight: bold);
  static const TextStyle headline3 = TextStyle(fontSize: 24, fontWeight: bold);
  static const TextStyle headline4 = TextStyle(fontSize: 20, fontWeight: medium);
  static const TextStyle headline5 = TextStyle(fontSize: 18, fontWeight: medium);
  static const TextStyle headline6 = TextStyle(fontSize: 16, fontWeight: medium);
  
  static const TextStyle bodyText1 = TextStyle(fontSize: 16, fontWeight: regular);
  static const TextStyle bodyText2 = TextStyle(fontSize: 14, fontWeight: regular);
  static const TextStyle caption = TextStyle(fontSize: 12, fontWeight: regular);
  static const TextStyle button = TextStyle(fontSize: 14, fontWeight: medium);
  
  // ========== MÉTODOS HELPER BÁSICOS ==========
  /// Obtiene el color de texto primario del tema actual
  static Color getPrimaryTextColor(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  }
}
