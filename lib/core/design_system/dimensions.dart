import 'package:flutter/material.dart';

/// Sistema de dimensiones básico de la aplicación
/// Solo contiene valores básicos de tamaños
class AppDimensions {
  // Prevenir instanciación
  AppDimensions._();

  // ========== TAMAÑOS DE ICONOS BÁSICOS ==========
  static const double iconXS = 16.0;
  static const double iconSM = 18.0;
  static const double iconMD = 20.0;
  static const double iconLG = 24.0;
  static const double iconXL = 32.0;
  static const double iconXXL = 64.0;
  
  // ========== ALTURAS BÁSICAS ==========
  static const double buttonHeight = 48.0;
  static const double buttonHeightLG = 56.0;
  static const double textFieldHeight = 56.0;
  static const double appBarHeight = 56.0;
  
  // ========== ANCHOS Y ALTURAS ESPECÍFICOS ==========
  static const double dividerHeight = 1.0;
  static const double cardIndicatorWidth = 4.0;
  static const double cardIndicatorHeight = 50.0;
  
  // ========== BREAKPOINTS BÁSICOS ==========
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  
  // ========== MÉTODOS HELPER BÁSICOS ==========
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }
}
