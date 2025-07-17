
import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= mobile &&
        MediaQuery.of(context).size.width < tablet;
  }

  static double getContentWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < mobile) return screenWidth;
    if (screenWidth < tablet) return screenWidth * 0.95;
    return screenWidth * 0.9; // Para tablets
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveBreakpoints.isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
}

// Utilidades para espaciado consistente
class FormSpacing {
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double extraLarge = 32.0;

  static Widget verticalSmall() => const SizedBox(height: small);
  static Widget verticalMedium() => const SizedBox(height: medium);
  static Widget verticalLarge() => const SizedBox(height: large);
  static Widget verticalExtraLarge() => const SizedBox(height: extraLarge);

  static Widget horizontalSmall() => const SizedBox(width: small);
  static Widget horizontalMedium() => const SizedBox(width: medium);
  static Widget horizontalLarge() => const SizedBox(width: large);
  static Widget horizontalExtraLarge() => const SizedBox(width: extraLarge);
}
