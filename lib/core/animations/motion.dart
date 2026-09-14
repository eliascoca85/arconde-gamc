import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Shared motion language for the app: consistent entrance, stagger and
/// pulse effects built on flutter_animate, plus a few small immersive
/// widgets (tap feedback, success check, background texture) reused across
/// features instead of duplicating hand-rolled AnimationControllers.
extension MotionExtensions on Widget {
  /// Standard entrance: a soft fade + gentle rise, like a page settling.
  /// Use for cards, sections and any standalone block appearing on screen.
  Widget immersiveEntrance({
    Duration delay = Duration.zero,
    double distance = 0.08,
    Duration duration = const Duration(milliseconds: 320),
  }) {
    return animate(delay: delay)
        .fadeIn(duration: duration, curve: Curves.easeOutCubic)
        .slideY(begin: distance, end: 0, duration: duration, curve: Curves.easeOutCubic);
  }

  /// Same entrance as [immersiveEntrance] but with a delay derived from
  /// [index], for items inside a list/grid so they settle in sequence.
  Widget staggerChild(
    int index, {
    Duration step = const Duration(milliseconds: 60),
    double distance = 0.08,
    Duration duration = const Duration(milliseconds: 320),
  }) {
    return immersiveEntrance(delay: step * index, distance: distance, duration: duration);
  }

  /// Slow, looping scale + opacity breathing effect. Use sparingly, for the
  /// one or two elements per screen that should read as "live" — an urgent
  /// map marker, an unread dot, a primary FAB.
  Widget pulseGlow({
    double minScale = 1.0,
    double maxScale = 1.15,
    double minOpacity = 0.55,
    double maxOpacity = 1.0,
    Duration duration = const Duration(milliseconds: 900),
  }) {
    return animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: Offset(minScale, minScale),
          end: Offset(maxScale, maxScale),
          duration: duration,
          curve: Curves.easeInOut,
        )
        .fade(begin: minOpacity, end: maxOpacity, duration: duration, curve: Curves.easeInOut);
  }
}

/// Wraps [child] with consistent tap-down feedback (a subtle scale-down),
/// so tappable cards/buttons feel physically pressable instead of inert.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double downScale;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.downScale = 0.97,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    // Listener observes raw pointer events without joining the gesture
    // arena, so it never steals taps from an inner InkWell/button — it only
    // drives the visual scale. When `onTap` is supplied (e.g. plain
    // containers like AppCard with no tap handling of their own) a
    // GestureDetector on top provides the actual tap.
    Widget content = Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.downScale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );

    if (widget.onTap != null) {
      content = GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}

/// Circular checkmark (or custom icon) that scales in with an elastic pop —
/// the app's one deliberate "big" motion accent, reserved for confirmation
/// moments (report submitted, action confirmed).
class AppSuccessCheck extends StatelessWidget {
  final double size;
  final Color color;
  final IconData icon;

  const AppSuccessCheck({
    super.key,
    this.size = 72,
    this.color = const Color(0xFF2AA476),
    this.icon = Icons.check_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 24, spreadRadius: 2),
        ],
      ),
      child: Icon(icon, size: size * 0.5, color: color),
    ).animate().scale(
          begin: const Offset(0.0, 0.0),
          end: const Offset(1.0, 1.0),
          duration: 550.ms,
          curve: Curves.elasticOut,
        );
  }
}

/// Counts up from 0 to [value] when first built — flutter_animate has no
/// text-value tween, so this wraps a small [TweenAnimationBuilder] instead.
/// Use for headline stats (report counts, totals) that should feel "alive"
/// on entrance rather than just appearing.
class AppCountUp extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;

  const AppCountUp({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) => Text('$animatedValue', style: style),
    );
  }
}

/// Faint grid texture used behind "hero" surfaces (incident detail header,
/// profile header) for visual cohesion. Extracted from a single-use
/// CustomPainter so it can be reused without duplicating paint logic.
class AppBackgroundPattern extends StatelessWidget {
  final Color color;
  final double spacing;
  final double opacity;

  const AppBackgroundPattern({
    super.key,
    required this.color,
    this.spacing = 30,
    this.opacity = 0.05,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _BackgroundPatternPainter(color: color, spacing: spacing, opacity: opacity),
      ),
    );
  }
}

class _BackgroundPatternPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double opacity;

  _BackgroundPatternPainter({required this.color, required this.spacing, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPatternPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.spacing != spacing || oldDelegate.opacity != opacity;
}
