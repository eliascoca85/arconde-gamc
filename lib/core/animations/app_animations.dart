import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

class AppAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration verySlow = Duration(milliseconds: 500);

  static const Curve standardEase = Curves.easeInOut;
  static const Curve decelerate = Curves.decelerate;
  static const Curve accelerate = Curves.easeIn;
  static const Curve sharp = Curves.easeInOutCubic;
  static const Curve spring = Curves.elasticOut;

  static Widget fadeIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = standardEase,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: child,
    );
  }

  static Widget slideUp({
    required Widget child,
    Duration duration = normal,
    Curve curve = decelerate,
    double beginOffset = 50.0,
    double endOffset = 0.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: beginOffset, end: endOffset),
      duration: duration,
      curve: curve,
      builder: (context, value, child) => Transform.translate(offset: Offset(0, value), child: child),
      child: child,
    );
  }

  static Widget slideDown({
    required Widget child,
    Duration duration = normal,
    Curve curve = decelerate,
    double beginOffset = -50.0,
    double endOffset = 0.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: beginOffset, end: endOffset),
      duration: duration,
      curve: curve,
      builder: (context, value, child) => Transform.translate(offset: Offset(0, value), child: child),
      child: child,
    );
  }

  static Widget slideFromLeft({
    required Widget child,
    Duration duration = normal,
    Curve curve = decelerate,
    double beginOffset = -50.0,
    double endOffset = 0.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: beginOffset, end: endOffset),
      duration: duration,
      curve: curve,
      builder: (context, value, child) => Transform.translate(offset: Offset(value, 0), child: child),
      child: child,
    );
  }

  static Widget slideFromRight({
    required Widget child,
    Duration duration = normal,
    Curve curve = decelerate,
    double beginOffset = 50.0,
    double endOffset = 0.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: beginOffset, end: endOffset),
      duration: duration,
      curve: curve,
      builder: (context, value, child) => Transform.translate(offset: Offset(value, 0), child: child),
      child: child,
    );
  }

  static Widget scaleIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = standardEase,
    double begin = 0.8,
    double end = 1.0,
    Alignment alignment = Alignment.center,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) => Transform.scale(scale: value, alignment: alignment, child: child),
      child: child,
    );
  }

  static Widget scaleOut({
    required Widget child,
    Duration duration = normal,
    Curve curve = standardEase,
    double begin = 1.0,
    double end = 0.8,
    Alignment alignment = Alignment.center,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) => Transform.scale(scale: value, alignment: alignment, child: child),
      child: child,
    );
  }

  static Widget rotate({
    required Widget child,
    Duration duration = normal,
    Curve curve = standardEase,
    double beginTurns = 0.0,
    double endTurns = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: beginTurns, end: endTurns),
      duration: duration,
      curve: curve,
      builder: (context, value, child) => Transform.rotate(angle: value * 2 * 3.14159, child: child),
      child: child,
    );
  }

  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: minScale, end: maxScale),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) => Transform.scale(scale: value, child: child),
      child: child,
      onEnd: () {},
    );
  }

  static Widget shimmer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
    Color? baseColor,
    Color? highlightColor,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -1.0, end: 2.0),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) => ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            baseColor ?? AppColors.surfaceSecondary,
            highlightColor ?? AppColors.surfaceTertiary,
            baseColor ?? AppColors.surfaceSecondary,
          ],
          stops: [value - 0.3, value, value + 0.3],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(bounds),
        blendMode: BlendMode.srcATop,
        child: child,
      ),
      child: child,
    );
  }

  static Widget stagger({
    required List<Widget> children,
    Duration duration = normal,
    Curve curve = standardEase,
    Duration delay = const Duration(milliseconds: 100),
    Offset beginOffset = const Offset(0, 30),
    Offset endOffset = Offset.zero,
    double beginOpacity = 0.0,
    double endOpacity = 1.0,
    double beginScale = 0.9,
    double endScale = 1.0,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        final itemDelay = delay * index;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: duration + itemDelay,
          curve: curve,
          builder: (context, value, child) {
            final delayedValue = (value - itemDelay.inMilliseconds / (duration + itemDelay).inMilliseconds).clamp(0.0, 1.0);
            return Transform.translate(
              offset: Offset.lerp(beginOffset, endOffset, delayedValue)!,
              child: Opacity(
                opacity: lerpDouble(beginOpacity, endOpacity, delayedValue)!,
                child: Transform.scale(
                  scale: lerpDouble(beginScale, endScale, delayedValue)!,
                  child: child,
                ),
              ),
            );
          },
          child: child,
        );
      }).toList(),
    );
  }

  static PageRouteBuilder<T> fadeTransition<T>({
    required Widget page,
    Duration duration = normal,
    Curve curve = standardEase,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: curve).animate(animation),
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  static PageRouteBuilder<T> slideTransition<T>({
    required Widget page,
    Duration duration = normal,
    Curve curve = standardEase,
    Offset beginOffset = const Offset(1.0, 0.0),
    Offset endOffset = Offset.zero,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: beginOffset, end: endOffset).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: duration,
    );
  }

  static PageRouteBuilder<T> scaleTransition<T>({
    required Widget page,
    Duration duration = normal,
    Curve curve = standardEase,
    double begin = 0.9,
    double end = 1.0,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween(begin: begin, end: end).chain(CurveTween(curve: curve)).animate(animation),
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  static PageRouteBuilder<T> heroTransition<T>({
    required Widget page,
    Duration duration = normal,
    Curve curve = standardEase,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: curve).animate(animation),
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }
}

double lerpDouble(double a, double b, double t) => a + (b - a) * t;