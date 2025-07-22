import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Utilidades para UI consistente en toda la aplicación
class UIUtils {
  // Colores semánticos basados en el tema
  static Color getSuccessColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? const Color(0xFF059669)
        : const Color(0xFF10B981);
  }

  static Color getWarningColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? const Color(0xFFD97706)
        : const Color(0xFFF59E0B);
  }

  static Color getErrorColor(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }

  static Color getInfoColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  // Colores de superficie con opacidad
  static Color getSurfaceVariant(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceVariant;
  }

  static Color getOnSurfaceVariant(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  // Métodos para crear contenedores con estilo consistente
  static BoxDecoration cardDecoration(BuildContext context, {
    bool isHighlighted = false,
    Color? borderColor,
  }) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: isHighlighted 
          ? theme.colorScheme.primaryContainer.withOpacity(0.1)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: borderColor ?? theme.colorScheme.outline.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.shadow.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration inputDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: theme.colorScheme.outline.withOpacity(0.3),
        width: 1,
      ),
    );
  }

  static BoxDecoration highlightDecoration(BuildContext context, {
    Color? backgroundColor,
  }) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: backgroundColor ?? theme.colorScheme.primaryContainer.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: theme.colorScheme.primary.withOpacity(0.2),
        width: 1,
      ),
    );
  }

  // Estilos de texto consistentes
  static TextStyle getSubtitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ) ?? const TextStyle();
  }

  static TextStyle getTitleStyle(BuildContext context, {
    FontWeight? fontWeight,
    Color? color,
  }) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color,
    ) ?? const TextStyle();
  }

  static TextStyle getPriceStyle(BuildContext context, {
    bool isLarge = false,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return (isLarge ? theme.textTheme.titleLarge : theme.textTheme.titleMedium)?.copyWith(
      fontWeight: FontWeight.bold,
      color: color ?? theme.colorScheme.primary,
    ) ?? const TextStyle();
  }

  // Contenedores especializados
  static Widget buildInfoContainer({
    required BuildContext context,
    required Widget child,
    Color? backgroundColor,
    EdgeInsets? padding,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  static Widget buildSummaryContainer({
    required BuildContext context,
    required Widget child,
    bool isElevated = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: isElevated ? [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: child,
    );
  }

  // Métodos para iconos con colores temáticos
  static Widget buildThemedIcon({
    required IconData icon,
    required BuildContext context,
    bool isSelected = false,
    double? size,
  }) {
    final theme = Theme.of(context);
    return Icon(
      icon,
      color: isSelected 
          ? theme.colorScheme.primary 
          : theme.colorScheme.onSurfaceVariant,
      size: size ?? 20,
    );
  }

  // Separadores con tema
  static Widget buildSectionDivider(BuildContext context) {
    return Divider(
      height: 32,
      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
    );
  }
}

/// Widget personalizado para campos de entrada mejorados
class ThemedInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String hintText;
  final ValueChanged<String> onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const ThemedInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.hintText,
    required this.onChanged,
    this.inputFormatters,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: theme.colorScheme.primary,
        ),
        hintText: hintText,
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: UIUtils.getSubtitleStyle(context),
        hintStyle: UIUtils.getSubtitleStyle(context),
        floatingLabelStyle: TextStyle(
          color: theme.colorScheme.primary,
          fontSize: 14,
        ),
      ),
      keyboardType: keyboardType ?? TextInputType.text,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      validator: validator,
      style: UIUtils.getTitleStyle(context),
    );
  }
}

/// Widget para mostrar precios de manera consistente
class PriceDisplay extends StatelessWidget {
  final double amount;
  final String label;
  final bool isTotal;
  final Color? color;

  const PriceDisplay({
    super.key,
    required this.amount,
    required this.label,
    this.isTotal = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: UIUtils.getTitleStyle(
              context,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            'Bs ${amount.toStringAsFixed(2)}',
            style: UIUtils.getPriceStyle(
              context,
              isLarge: isTotal,
              color: color,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
