import 'package:flutter/material.dart';

/// Sistema de espaciado unificado
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Widgets de espaciado
  static Widget get verticalXS => const SizedBox(height: xs);
  static Widget get verticalSM => const SizedBox(height: sm);
  static Widget get verticalMD => const SizedBox(height: md);
  static Widget get verticalLG => const SizedBox(height: lg);
  static Widget get verticalXL => const SizedBox(height: xl);
  static Widget get verticalXXL => const SizedBox(height: xxl);
  static Widget get verticalXXXL => const SizedBox(height: xxxl);

  static Widget get horizontalXS => const SizedBox(width: xs);
  static Widget get horizontalSM => const SizedBox(width: sm);
  static Widget get horizontalMD => const SizedBox(width: md);
  static Widget get horizontalLG => const SizedBox(width: lg);
  static Widget get horizontalXL => const SizedBox(width: xl);
  static Widget get horizontalXXL => const SizedBox(width: xxl);
  static Widget get horizontalXXXL => const SizedBox(width: xxxl);
}

/// Sistema de colores semánticos extendido
class AppColors {
  // Colores primarios
  static const Color primary = Color(0xFF0AE98A);
  static const Color secondary = Color(0xFF1292EE);
  
  // Colores semánticos - Modo claro
  static const Color successLight = Color(0xFF059669);
  static const Color warningLight = Color(0xFFD97706);
  static const Color errorLight = Color(0xFFDC2626);
  static const Color infoLight = Color(0xFF2563EB);
  
  // Colores semánticos - Modo oscuro
  static const Color successDark = Color(0xFF10B981);
  static const Color warningDark = Color(0xFFF59E0B);
  static const Color errorDark = Color(0xFFEF4444);
  static const Color infoDark = Color(0xFF3B82F6);
  
  // Superficies
  static const Color surfaceLight = Color(0xFFF9FAFB);
  static const Color surfaceDark = Color(0xFF1E2229);
  
  // Métodos helper
  static Color getSuccess(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? successLight
        : successDark;
  }
  
  static Color getWarning(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? warningLight
        : warningDark;
  }
  
  static Color getError(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? errorLight
        : errorDark;
  }
  
  static Color getInfo(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? infoLight
        : infoDark;
  }
}

/// Sistema de tipografía mejorado
class AppTextStyles {
  static TextStyle heading1(BuildContext context) =>
      Theme.of(context).textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
      ) ?? const TextStyle();

  static TextStyle heading2(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        height: 1.3,
      ) ?? const TextStyle();

  static TextStyle heading3(BuildContext context) =>
      Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.3,
      ) ?? const TextStyle();

  static TextStyle subtitle1(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.4,
      ) ?? const TextStyle();

  static TextStyle subtitle2(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.4,
      ) ?? const TextStyle();

  static TextStyle body1(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge?.copyWith(
        height: 1.5,
      ) ?? const TextStyle();

  static TextStyle body2(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(
        height: 1.5,
      ) ?? const TextStyle();

  static TextStyle caption(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall?.copyWith(
        height: 1.4,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ) ?? const TextStyle();

  static TextStyle button(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.25,
      ) ?? const TextStyle();

  static TextStyle price(BuildContext context, {bool isLarge = false}) =>
      (isLarge 
        ? Theme.of(context).textTheme.headlineMedium
        : Theme.of(context).textTheme.titleLarge)?.copyWith(
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: -0.25,
      ) ?? const TextStyle();
}

/// Constantes de animación
class AppAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
  
  static const Curve defaultCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve slideCurve = Curves.easeOutCubic;
}

/// Constantes de UI
class AppConstants {
  static const double borderRadius = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusSmall = 8.0;
  
  static const double elevation = 2.0;
  static const double elevationLarge = 4.0;
  
  static const double iconSize = 24.0;
  static const double iconSizeSmall = 20.0;
  static const double iconSizeLarge = 32.0;
  
  static const EdgeInsets paddingAll = EdgeInsets.all(AppSpacing.md);
  static const EdgeInsets paddingHorizontal = EdgeInsets.symmetric(horizontal: AppSpacing.md);
  static const EdgeInsets paddingVertical = EdgeInsets.symmetric(vertical: AppSpacing.md);
} 