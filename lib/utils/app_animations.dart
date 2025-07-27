import 'package:flutter/material.dart';
import 'app_constants.dart';

/// Transición personalizada con slide
class SlideRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;

  SlideRoute({
    required this.page,
    this.direction = SlideDirection.left,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: AppAnimations.medium,
          reverseTransitionDuration: AppAnimations.medium,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            Offset begin;
            
            switch (direction) {
              case SlideDirection.left:
                begin = const Offset(1.0, 0.0);
                break;
              case SlideDirection.right:
                begin = const Offset(-1.0, 0.0);
                break;
              case SlideDirection.up:
                begin = const Offset(0.0, 1.0);
                break;
              case SlideDirection.down:
                begin = const Offset(0.0, -1.0);
                break;
            }
            
            const end = Offset.zero;
            
            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: AppAnimations.slideCurve),
            );
            
            var offsetAnimation = animation.drive(tween);
            
            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        );
}

/// Transición con fade
class FadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: AppAnimations.medium,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}

/// Transición con scale
class ScaleRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ScaleRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: AppAnimations.medium,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale: Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: AppAnimations.bounceCurve,
              )),
              child: child,
            );
          },
        );
}

/// Widget animado para mostrar elementos con retraso
class DelayedAnimation extends StatefulWidget {
  final Widget child;
  final int delay;
  final AnimationType type;
  final Duration? duration;

  const DelayedAnimation({
    super.key,
    required this.child,
    this.delay = 0,
    this.type = AnimationType.fadeIn,
    this.duration,
  });

  @override
  State<DelayedAnimation> createState() => _DelayedAnimationState();
}

class _DelayedAnimationState extends State<DelayedAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? AppAnimations.medium,
      vsync: this,
    );

    switch (widget.type) {
      case AnimationType.fadeIn:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: AppAnimations.defaultCurve),
        );
        break;
      case AnimationType.slideUp:
        _animation = Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(parent: _controller, curve: AppAnimations.defaultCurve),
        );
        break;
      case AnimationType.scale:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: AppAnimations.bounceCurve),
        );
        break;
    }

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        switch (widget.type) {
          case AnimationType.fadeIn:
            return Opacity(
              opacity: _animation.value,
              child: widget.child,
            );
          case AnimationType.slideUp:
            return Transform.translate(
              offset: Offset(0, 50 * _animation.value),
              child: Opacity(
                opacity: 1 - _animation.value,
                child: widget.child,
              ),
            );
          case AnimationType.scale:
            return Transform.scale(
              scale: _animation.value,
              child: widget.child,
            );
        }
      },
    );
  }
}

/// Loading spinner personalizado
class AppLoadingSpinner extends StatefulWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const AppLoadingSpinner({
    super.key,
    this.size = 24.0,
    this.color,
    this.strokeWidth = 3.0,
  });

  @override
  State<AppLoadingSpinner> createState() => _AppLoadingSpinnerState();
}

class _AppLoadingSpinnerState extends State<AppLoadingSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _LoadingPainter(
              progress: _controller.value,
              color: widget.color ?? Theme.of(context).colorScheme.primary,
              strokeWidth: widget.strokeWidth,
            ),
          );
        },
      ),
    );
  }
}

class _LoadingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _LoadingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Dibujar círculo base
    paint.color = color.withOpacity(0.2);
    canvas.drawCircle(center, radius, paint);

    // Dibujar arco animado
    paint.color = color;
    final sweepAngle = 2 * 3.14159 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Widget para animaciones de skeleton loading
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(_animation.value),
            borderRadius: widget.borderRadius ?? 
                BorderRadius.circular(AppConstants.borderRadius),
          ),
        );
      },
    );
  }
}

/// Animación de shake para errores
class ShakeAnimation extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final double distance;
  final int count;

  const ShakeAnimation({
    super.key,
    required this.child,
    required this.trigger,
    this.distance = 5.0,
    this.count = 3,
  });

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.medium,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticIn),
    );
  }

  @override
  void didUpdateWidget(ShakeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _shake();
    }
  }

  void _shake() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final progress = _animation.value;
        final offsetMultiplier = (progress * widget.count * 2).round().isEven ? 1 : -1;
        final offset = widget.distance * offsetMultiplier;
        
        return Transform.translate(
          offset: Offset(offset * progress, 0),
          child: widget.child,
        );
      },
    );
  }
}

/// Helper para navegación con animaciones
class AppNavigator {
  static Future<T?> push<T>(
    BuildContext context,
    Widget page, {
    TransitionType type = TransitionType.slide,
    SlideDirection direction = SlideDirection.left,
  }) {
    PageRouteBuilder<T> route;
    
    switch (type) {
      case TransitionType.slide:
        route = SlideRoute<T>(page: page, direction: direction);
        break;
      case TransitionType.fade:
        route = FadeRoute<T>(page: page);
        break;
      case TransitionType.scale:
        route = ScaleRoute<T>(page: page);
        break;
    }
    
    return Navigator.of(context).push<T>(route);
  }

  static Future<T?> pushReplacement<T, TO>(
    BuildContext context,
    Widget page, {
    TransitionType type = TransitionType.slide,
    SlideDirection direction = SlideDirection.left,
  }) {
    PageRouteBuilder<T> route;
    
    switch (type) {
      case TransitionType.slide:
        route = SlideRoute<T>(page: page, direction: direction);
        break;
      case TransitionType.fade:
        route = FadeRoute<T>(page: page);
        break;
      case TransitionType.scale:
        route = ScaleRoute<T>(page: page);
        break;
    }
    
    return Navigator.of(context).pushReplacement<T, TO>(route);
  }
}

// Enums para animaciones
enum SlideDirection { left, right, up, down }
enum AnimationType { fadeIn, slideUp, scale }
enum TransitionType { slide, fade, scale } 