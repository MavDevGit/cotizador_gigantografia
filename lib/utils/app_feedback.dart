import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_constants.dart';
import 'app_animations.dart';

/// Sistema de feedback visual mejorado
class AppFeedback {
  /// Mostrar SnackBar de éxito
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: AppColors.getSuccess(context),
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Mostrar SnackBar de error
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.error_rounded,
      backgroundColor: AppColors.getError(context),
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Mostrar SnackBar de advertencia
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.warning_rounded,
      backgroundColor: AppColors.getWarning(context),
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Mostrar SnackBar de información
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.info_rounded,
      backgroundColor: AppColors.getInfo(context),
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Duration duration,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: AppConstants.iconSizeSmall,
            ),
            AppSpacing.horizontalMD,
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.body2(context).copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        margin: const EdgeInsets.all(AppSpacing.md),
        duration: duration,
        action: onAction != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  /// Mostrar dialog de confirmación
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    Color? confirmColor,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AppConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        icon: icon,
      ),
    );
  }

  /// Mostrar dialog de loading
  static void showLoadingDialog(
    BuildContext context, {
    String message = 'Cargando...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppLoadingDialog(message: message),
    );
  }

  /// Ocultar dialog de loading
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Mostrar toast personalizado
  static void showToast(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => AppToast(
        message: message,
        type: type,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  /// Trigger haptic feedback
  static void hapticFeedback(HapticType type) {
    switch (type) {
      case HapticType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticType.selection:
        HapticFeedback.selectionClick();
        break;
    }
  }
}

/// Dialog de confirmación personalizado
class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final IconData? icon;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirmar',
    this.cancelText = 'Cancelar',
    this.confirmColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: confirmColor ?? theme.colorScheme.primary,
                size: AppConstants.iconSizeLarge,
              ),
              AppSpacing.horizontalMD,
            ],
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.heading3(context),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: AppTextStyles.body2(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: AppTextStyles.button(context).copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          AppSpacing.horizontalSM,
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: Text(confirmText),
          ),
        ],
        actionsPadding: const EdgeInsets.all(AppSpacing.md),
      );
  }
}

/// Dialog de loading personalizado
class AppLoadingDialog extends StatelessWidget {
  final String message;

  const AppLoadingDialog({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLoadingSpinner(
              size: AppConstants.iconSizeLarge,
              color: theme.colorScheme.primary,
            ),
            AppSpacing.horizontalLG,
            Text(
              message,
              style: AppTextStyles.subtitle2(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Toast personalizado
class AppToast extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;

  const AppToast({
    super.key,
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<AppToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.medium,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.defaultCurve,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    IconData icon;
    
    switch (widget.type) {
      case ToastType.success:
        backgroundColor = AppColors.getSuccess(context);
        icon = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        backgroundColor = AppColors.getError(context);
        icon = Icons.error_rounded;
        break;
      case ToastType.warning:
        backgroundColor = AppColors.getWarning(context);
        icon = Icons.warning_rounded;
        break;
      case ToastType.info:
        backgroundColor = AppColors.getInfo(context);
        icon = Icons.info_rounded;
        break;
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + AppSpacing.md,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            elevation: 8,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: AppConstants.iconSizeSmall,
                  ),
                  AppSpacing.horizontalMD,
                  Expanded(
                    child: Text(
                      widget.message,
                      style: AppTextStyles.body2(context).copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      _controller.reverse().then((_) {
                        widget.onDismiss();
                      });
                    },
                    iconSize: AppConstants.iconSizeSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet personalizado
class AppBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
    double? height,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      builder: (context) => Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppConstants.borderRadiusLarge),
            topRight: Radius.circular(AppConstants.borderRadiusLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

// Enums para feedback
enum ToastType { success, error, warning, info }
enum HapticType { light, medium, heavy, selection } 