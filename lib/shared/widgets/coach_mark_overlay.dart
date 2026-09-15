import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/index.dart';
import 'basic_widgets.dart';

/// Shape of the spotlight cutout drawn around a coach mark step's target.
enum CoachMarkShape { rect, circle }

/// One stop of a coach mark tour: a widget to highlight (via [targetKey])
/// plus the copy explaining what it does. Each step carries its own
/// [gradient]/[accentColor] — matched to that button's real identity in the
/// app (e.g. red for the emergency report button) — so the spotlight ring,
/// icon badge and step indicator all pick up that color instead of one
/// generic tint repeated for every step.
class CoachMarkStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final IconData icon;
  final Gradient gradient;
  final Color accentColor;
  final CoachMarkShape shape;
  final EdgeInsets spotlightPadding;

  const CoachMarkStep({
    required this.targetKey,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    this.shape = CoachMarkShape.rect,
    this.spotlightPadding = const EdgeInsets.all(8),
  });
}

/// Shows a full-screen guided tour that spotlights each step's target
/// widget in turn, with a card explaining it. Targets must already be laid
/// out on screen (attach [CoachMarkStep.targetKey] to a visible widget)
/// before calling this. Returns once the user finishes or skips the tour.
Future<void> showCoachMarkTour(
  BuildContext context, {
  required List<CoachMarkStep> steps,
}) {
  if (steps.isEmpty) return Future.value();
  final completer = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _CoachMarkTourOverlay(
      steps: steps,
      onClose: () {
        entry.remove();
        if (!completer.isCompleted) completer.complete();
      },
    ),
  );
  Overlay.of(context, rootOverlay: true).insert(entry);
  return completer.future;
}

class _CoachMarkTourOverlay extends StatefulWidget {
  final List<CoachMarkStep> steps;
  final VoidCallback onClose;

  const _CoachMarkTourOverlay({required this.steps, required this.onClose});

  @override
  State<_CoachMarkTourOverlay> createState() => _CoachMarkTourOverlayState();
}

class _CoachMarkTourOverlayState extends State<_CoachMarkTourOverlay> {
  int _index = 0;

  Rect? _targetRect(GlobalKey key) {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return null;
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      widget.onClose();
    } else {
      setState(() => _index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final rawRect = _targetRect(step.targetKey);
    final screenSize = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // The target may not be laid out yet on this frame (e.g. a tab switch
    // mid-tour) — skip straight to the next step rather than showing a
    // broken/empty spotlight.
    if (rawRect == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _next());
      return const SizedBox.shrink();
    }

    final spotlightRect = step.spotlightPadding.inflateRect(rawRect);
    final tooltipAbove = spotlightRect.center.dy > screenSize.height / 2;

    return KeyedSubtree(
      key: ValueKey(_index),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  builder: (context, glow, _) => CustomPaint(
                    painter: _SpotlightPainter(
                      spotlightRect: spotlightRect,
                      isCircle: step.shape == CoachMarkShape.circle,
                      accentColor: step.accentColor,
                      glowStrength: glow,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: tooltipAbove ? null : spotlightRect.bottom + AppSpacing.md,
              bottom: tooltipAbove
                  ? screenSize.height -
                        spotlightRect.top +
                        AppSpacing.md +
                        bottomInset
                  : null,
              child: _CoachMarkCard(
                step: step,
                index: _index,
                total: widget.steps.length,
                onNext: _next,
                onSkip: widget.onClose,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect spotlightRect;
  final bool isCircle;
  final Color accentColor;
  final double glowStrength;

  _SpotlightPainter({
    required this.spotlightRect,
    required this.isCircle,
    required this.accentColor,
    required this.glowStrength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final screenPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = isCircle
        ? (Path()..addOval(spotlightRect))
        : (Path()..addRRect(
            RRect.fromRectAndRadius(
              spotlightRect,
              const Radius.circular(AppSpacing.borderRadiusMd),
            ),
          ));

    final scrimPath = Path.combine(
      PathOperation.difference,
      screenPath,
      holePath,
    );
    canvas.drawPath(scrimPath, Paint()..color = AppColors.overlayColor);

    // A soft, step-colored glow around the cutout — this is what makes each
    // spotlight read as "this button" rather than an identical generic hole,
    // e.g. a warm red halo around the emergency report button.
    canvas.drawPath(
      holePath,
      Paint()
        ..color = accentColor.withValues(alpha: 0.55 * glowStrength)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      holePath,
      Paint()
        ..color = AppColors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.spotlightRect != spotlightRect ||
      oldDelegate.isCircle != isCircle ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.glowStrength != glowStrength;
}

class _CoachMarkCard extends StatelessWidget {
  final CoachMarkStep step;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _CoachMarkCard({
    required this.step,
    required this.index,
    required this.total,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = index == total - 1;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          step.accentColor.withValues(alpha: 0.05),
          AppColors.surfacePrimary,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(
          color: step.accentColor.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Color.alphaBlend(
              step.accentColor.withValues(alpha: 0.18),
              AppColors.shadowColor,
            ),
            blurRadius: AppSpacing.elevationLg,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: step.gradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: step.accentColor.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  step.icon,
                  color: AppColors.textOnPrimary,
                  size: AppSpacing.iconSm,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: step.accentColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.borderRadiusFull,
                        ),
                      ),
                      child: Text(
                        'PASO ${index + 1} DE $total',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: step.accentColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(step.title, style: AppTextStyles.titleMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(step.description, style: AppTextStyles.bodyMediumSecondary),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Row(
                children: List.generate(total, (i) {
                  final isActive = i == index;
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: isActive ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? step.accentColor
                          : AppColors.borderPrimary,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.borderRadiusFull,
                      ),
                    ),
                  );
                }),
              ),
              const Spacer(),
              TextButton(
                onPressed: onSkip,
                child: Text(
                  'Saltar',
                  style: AppTextStyles.labelMediumSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppButton(
                label: isLast ? 'Entendido' : 'Siguiente',
                isExpanded: false,
                onPressed: onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
