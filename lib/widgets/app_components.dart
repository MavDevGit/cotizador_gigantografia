import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_constants.dart';

/// Card mejorada con animaciones y estados
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final bool isElevated;
  final bool isClickable;
  final VoidCallback? onTap;
  final bool isSelected;
  final double? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.isElevated = false,
    this.isClickable = false,
    this.onTap,
    this.isSelected = false,
    this.borderRadius,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.defaultCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isClickable) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.isClickable) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.isClickable) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          curve: AppAnimations.defaultCurve,
          padding: widget.padding ?? AppConstants.paddingAll,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(
              widget.borderRadius ?? AppConstants.borderRadius,
            ),
            border: Border.all(
              color: widget.isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withOpacity(0.2),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isElevated || _isPressed
                ? [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(
                        _isPressed ? 0.2 : 0.1,
                      ),
                      blurRadius: _isPressed ? 12 : 8,
                      offset: Offset(0, _isPressed ? 6 : 2),
                    ),
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Button mejorado con estados y animaciones
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final ButtonType type;
  final ButtonSize size;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.type = ButtonType.filled,
    this.size = ButtonSize.medium,
    this.backgroundColor,
    this.textColor,
    this.width,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.defaultCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = widget.onPressed == null || widget.isLoading;
    
    // Configurar tamaños
    double height;
    EdgeInsets padding;
    double fontSize;
    
    switch (widget.size) {
      case ButtonSize.small:
        height = 44;
        padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs);
        fontSize = 15;
        break;
      case ButtonSize.medium:
        height = 52;
        padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm);
        fontSize = 16;
        break;
      case ButtonSize.large:
        height = 60;
        padding = const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md);
        fontSize = 18;
        break;
    }

    Color backgroundColor;
    Color foregroundColor;
    
    switch (widget.type) {
      case ButtonType.filled:
        backgroundColor = widget.backgroundColor ?? theme.colorScheme.primary;
        foregroundColor = widget.textColor ?? theme.colorScheme.onPrimary;
        break;
      case ButtonType.outlined:
        backgroundColor = Colors.transparent;
        foregroundColor = widget.textColor ?? theme.colorScheme.onSurface;
        break;
      case ButtonType.text:
        backgroundColor = Colors.transparent;
        foregroundColor = widget.textColor ?? theme.colorScheme.onSurface;
        break;
    }

    if (isDisabled) {
      backgroundColor = backgroundColor.withOpacity(0.5);
      foregroundColor = foregroundColor.withOpacity(0.5);
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: SizedBox(
        width: widget.width,
        height: height,
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            onTap: isDisabled ? null : widget.onPressed,
            onTapDown: (_) {
              if (!isDisabled) {
                setState(() => _isPressed = true);
                _controller.forward();
              }
            },
            onTapUp: (_) {
              if (!isDisabled) {
                setState(() => _isPressed = false);
                _controller.reverse();
              }
            },
            onTapCancel: () {
              if (!isDisabled) {
                setState(() => _isPressed = false);
                _controller.reverse();
              }
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: widget.type == ButtonType.outlined
                  ? BoxDecoration(
                      border: Border.all(
                        color: isDisabled
                            ? theme.colorScheme.outline.withOpacity(0.3)
                            : theme.colorScheme.outline,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    )
                  : null,
              child: Center(
                child: Padding(
                  padding: padding,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                  if (widget.isLoading) ...[
                    SizedBox(
                      width: fontSize,
                      height: fontSize,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                      ),
                    ),
                    AppSpacing.horizontalSM,
                  ] else if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: fontSize,
                      color: foregroundColor,
                    ),
                    AppSpacing.horizontalSM,
                  ],
                  Text(
                    widget.text,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.25,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Input field mejorado con estados y validación
class AppTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.controller,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.focusNode,
    this.textInputAction,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<Color?>? _borderColorAnimation;
  late FocusNode _focusNode;
  String? _errorText;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = AnimationController(
      duration: AppAnimations.fast,
      vsync: this,
    );
    
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateBorderAnimation();
  }

  void _updateBorderAnimation() {
    _borderColorAnimation = ColorTween(
      begin: Theme.of(context).colorScheme.outline.withOpacity(0.3),
      end: Theme.of(context).colorScheme.primary,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.defaultCurve,
    ));
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    
    if (_isFocused) {
      _controller.forward();
    } else {
      _controller.reverse();
      _validateField();
    }
  }

  void _validateField() {
    if (widget.validator != null && widget.controller != null) {
      final error = widget.validator!(widget.controller!.text);
      setState(() {
        _errorText = error;
      });
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = _errorText != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _borderColorAnimation ?? _controller,
          builder: (context, child) {
            return TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              validator: widget.validator,
              onChanged: (value) {
                widget.onChanged?.call(value);
                if (hasError) {
                  _validateField();
                }
              },
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              obscureText: widget.obscureText,
              enabled: widget.enabled,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              textInputAction: widget.textInputAction,
              style: AppTextStyles.body1(context),
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: widget.hint,
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        color: _isFocused
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      )
                    : null,
                suffixIcon: widget.suffixIcon != null
                    ? IconButton(
                        icon: Icon(widget.suffixIcon),
                        onPressed: widget.onSuffixTap,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : null,
                filled: true,
                fillColor: widget.enabled
                    ? theme.colorScheme.surface
                    : theme.colorScheme.surface.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: BorderSide(
                    color: hasError
                        ? theme.colorScheme.error
                        : _borderColorAnimation?.value ?? 
                          (_isFocused 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.outline.withOpacity(0.3)),
                    width: _isFocused ? 2 : 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: BorderSide(
                    color: hasError
                        ? theme.colorScheme.error
                        : theme.colorScheme.outline.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: BorderSide(
                    color: hasError
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: BorderSide(
                    color: theme.colorScheme.error,
                    width: 1,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: BorderSide(
                    color: theme.colorScheme.error,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                labelStyle: AppTextStyles.body2(context).copyWith(
                  color: _isFocused
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                hintStyle: AppTextStyles.caption(context),
                errorStyle: AppTextStyles.caption(context).copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            );
          },
        ),
        if (hasError) ...[
          AppSpacing.verticalXS,
          Text(
            _errorText!,
            style: AppTextStyles.caption(context).copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

/// Chip de estado mejorado
class AppStatusChip extends StatelessWidget {
  final String label;
  final StatusType status;
  final IconData? icon;
  final VoidCallback? onTap;

  const AppStatusChip({
    super.key,
    required this.label,
    required this.status,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    
    switch (status) {
      case StatusType.success:
        backgroundColor = AppColors.getSuccess(context).withOpacity(0.1);
        textColor = AppColors.getSuccess(context);
        break;
      case StatusType.warning:
        backgroundColor = AppColors.getWarning(context).withOpacity(0.1);
        textColor = AppColors.getWarning(context);
        break;
      case StatusType.error:
        backgroundColor = AppColors.getError(context).withOpacity(0.1);
        textColor = AppColors.getError(context);
        break;
      case StatusType.info:
        backgroundColor = AppColors.getInfo(context).withOpacity(0.1);
        textColor = AppColors.getInfo(context);
        break;
      case StatusType.neutral:
        backgroundColor = Theme.of(context).colorScheme.surfaceVariant;
        textColor = Theme.of(context).colorScheme.onSurfaceVariant;
        break;
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: textColor,
                ),
                AppSpacing.horizontalXS,
              ],
              Text(
                label,
                style: AppTextStyles.caption(context).copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Estados vacíos mejorados
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppConstants.paddingAll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.verticalLG,
            Text(
              title,
              style: AppTextStyles.heading3(context),
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalSM,
            Text(
              subtitle,
              style: AppTextStyles.caption(context),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              AppSpacing.verticalLG,
              AppButton(
                text: buttonText!,
                onPressed: onButtonPressed,
                type: ButtonType.outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Enums para los componentes
enum ButtonType { filled, outlined, text }
enum ButtonSize { small, medium, large }
enum StatusType { success, warning, error, info, neutral } 