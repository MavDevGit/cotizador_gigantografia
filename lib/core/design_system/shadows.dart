import 'package:flutter/material.dart';

/// Sistema de sombras básico de la aplicación
/// Solo contiene sombras básicas de Flutter
class AppShadows {
  // Prevenir instanciación
  AppShadows._();

  // ========== SOMBRAS BÁSICAS ==========
  static const List<BoxShadow> none = [];
  
  static const List<BoxShadow> light = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black26,
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> heavy = [
    BoxShadow(
      color: Colors.black38,
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
}
