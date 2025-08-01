import 'package:flutter/material.dart';

/// Sistema de espaciado básico de la aplicación
/// Solo contiene valores básicos de espaciado
class AppSpacing {
  // Prevenir instanciación
  AppSpacing._();

  // ========== VALORES BÁSICOS ==========
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  // ========== WIDGETS DE ESPACIADO ==========
  static Widget get verticalXS => const SizedBox(height: xs);
  static Widget get verticalSM => const SizedBox(height: sm);
  static Widget get verticalMD => const SizedBox(height: md);
  static Widget get verticalLG => const SizedBox(height: lg);
  static Widget get verticalXL => const SizedBox(height: xl);
  
  static Widget get horizontalXS => const SizedBox(width: xs);
  static Widget get horizontalSM => const SizedBox(width: sm);
  static Widget get horizontalMD => const SizedBox(width: md);
  static Widget get horizontalLG => const SizedBox(width: lg);
  static Widget get horizontalXL => const SizedBox(width: xl);

  // ========== EDGEINSETS BÁSICOS ==========
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);
  
  static const EdgeInsets marginXS = EdgeInsets.all(xs);
  static const EdgeInsets marginSM = EdgeInsets.all(sm);
  static const EdgeInsets marginMD = EdgeInsets.all(md);
  static const EdgeInsets marginLG = EdgeInsets.all(lg);
  static const EdgeInsets marginXL = EdgeInsets.all(xl);
}
