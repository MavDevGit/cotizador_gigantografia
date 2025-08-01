import 'package:flutter/material.dart';

/// Sistema de bordes básico de la aplicación
/// Solo contiene valores básicos de BorderRadius y Border
class AppBorders {
  // Prevenir instanciación
  AppBorders._();

  // ========== BORDER RADIUS BÁSICOS ==========
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;

  // ========== BORDER RADIUS PRESETS ==========
  static const BorderRadius borderRadiusXS = BorderRadius.all(Radius.circular(radiusXS));
  static const BorderRadius borderRadiusSM = BorderRadius.all(Radius.circular(radiusSM));
  static const BorderRadius borderRadiusMD = BorderRadius.all(Radius.circular(radiusMD));
  static const BorderRadius borderRadiusLG = BorderRadius.all(Radius.circular(radiusLG));

  // ========== BORDER SIDES BÁSICOS ==========
  static const BorderSide borderSide = BorderSide(color: Colors.grey, width: 1.0);
  static const BorderSide borderSideThick = BorderSide(color: Colors.grey, width: 2.0);
  
  // ========== MÉTODOS HELPER BÁSICOS ==========
  static BorderRadius radius(double value) => BorderRadius.circular(value);
  static BorderSide side({Color color = Colors.grey, double width = 1.0}) => 
      BorderSide(color: color, width: width);
}
