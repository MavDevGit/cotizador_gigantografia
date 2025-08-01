// ========== DESIGN SYSTEM EXPORTS ==========
// Este archivo centraliza todas las exportaciones del sistema de diseño básico

import 'package:flutter/material.dart';

// Tokens básicos
export 'colors.dart';
export 'typography.dart';
export 'spacing.dart';
export 'borders.dart';
export 'shadows.dart';
export 'dimensions.dart';

// Tema básico
export 'app_theme.dart';

// ========== CONSTANTES BÁSICAS ==========

/// Constantes básicas de la aplicación
class AppConstants {
  AppConstants._();

  // ========== VALORES BÁSICOS ==========
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double opacityDisabled = 0.38;
  
  // ========== BREAKPOINTS ==========
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  
  // ========== ALIASES BÁSICOS ==========
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  static const double borderRadius = 8.0;
  static const double iconSize = 24.0;
}

/// Utilidades básicas de responsive design
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();
  
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < AppConstants.mobileBreakpoint;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AppConstants.mobileBreakpoint && 
           width < AppConstants.tabletBreakpoint;
  }
}
