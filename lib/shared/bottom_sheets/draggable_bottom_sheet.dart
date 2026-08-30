import 'package:flutter/material.dart';
import '../../app/theme/index.dart';
import '../../core/animations/app_animations.dart';
import '../../core/animations/motion.dart';
import '../widgets/basic_widgets.dart';

class DraggableBottomSheet extends StatefulWidget {
  final Widget Function(BuildContext context, ScrollController scrollController) builder;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final List<double> snapSizes;
  final bool expand;
  final VoidCallback? onExpanded;
  final VoidCallback? onCollapsed;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const DraggableBottomSheet({
    super.key,
    required this.builder,
    this.initialChildSize = 0.4,
    this.minChildSize = 0.15,
    this.maxChildSize = 0.9,
    this.snapSizes = const [],
    this.expand = false,
    this.onExpanded,
    this.onCollapsed,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  State<DraggableBottomSheet> createState() => _DraggableBottomSheetState();
}

class _DraggableBottomSheetState extends State<DraggableBottomSheet> with SingleTickerProviderStateMixin {
  late DraggableScrollableController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = DraggableScrollableController();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    final wasExpanded = _isExpanded;
    _isExpanded = _controller.size >= (widget.maxChildSize - 0.1);

    if (wasExpanded != _isExpanded) {
      if (_isExpanded) {
        widget.onExpanded?.call();
      } else {
        widget.onCollapsed?.call();
      }
    }
  }

  void expand() {
    _controller.animateTo(
      widget.maxChildSize,
      duration: AppAnimations.normal,
      curve: Curves.easeOutCubic,
    );
  }

  void collapse() {
    _controller.animateTo(
      widget.minChildSize,
      duration: AppAnimations.normal,
      curve: Curves.easeOutCubic,
    );
  }

  void snapTo(double size) {
    _controller.animateTo(
      size.clamp(widget.minChildSize, widget.maxChildSize),
      duration: AppAnimations.normal,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final snapSizes = widget.snapSizes.isEmpty
        ? [widget.minChildSize, widget.initialChildSize, widget.maxChildSize]
        : widget.snapSizes;

    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: widget.initialChildSize,
      minChildSize: widget.minChildSize,
      maxChildSize: widget.maxChildSize,
      snap: true,
      snapSizes: snapSizes,
      expand: widget.expand,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? AppColors.backgroundPrimary,
            borderRadius: widget.borderRadius ??
                const BorderRadius.vertical(top: Radius.circular(AppSpacing.borderRadiusXl)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: AppSpacing.elevationXl,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHandle(),
              Expanded(child: widget.builder(context, scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.borderSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
      ),
    );
  }
}

class ReportBottomSheet extends StatelessWidget {
  final Widget child;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool showDragHandle;

  const ReportBottomSheet({
    super.key,
    required this.child,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.showDragHandle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDragHandle)
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderSecondary,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              if (leading != null) leading!,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleLarge),
                    if (subtitle != null)
                      Text(subtitle!, style: AppTextStyles.bodySmallSecondary),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Divider(height: 1, color: AppColors.divider),
        Flexible(child: child),
      ],
    );
  }
}

class ConfirmationBottomSheet extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final IconData? icon;
  final Color? iconColor;

  const ConfirmationBottomSheet({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.onConfirm,
    this.cancelText = 'Cancelar',
    this.onCancel,
    this.isDestructive = false,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.borderRadiusXl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderSecondary,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
            ),
          ),
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primaryBlue).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: AppSpacing.iconXl, color: iconColor ?? AppColors.primaryBlue),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(title, style: AppTextStyles.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: AppTextStyles.bodyMediumSecondary, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: AppOutlinedButton(
                  label: cancelText,
                  onPressed: () {
                    Navigator.pop(context);
                    onCancel?.call();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: confirmText,
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  backgroundColor: isDestructive ? AppColors.error : AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class SuccessBottomSheet extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;
  final String? reportId;
  final String? status;

  const SuccessBottomSheet({
    super.key,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onButtonPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.reportId,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.borderRadiusXl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppSuccessCheck(size: 80, color: AppColors.resolvedGreen, icon: Icons.check),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTextStyles.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: AppTextStyles.bodyMediumSecondary, textAlign: TextAlign.center),
          if (reportId != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ID del reporte', style: AppTextStyles.bodySmallSecondary),
                      Text(reportId!, style: AppTextStyles.labelMedium.copyWith(fontFamily: 'monospace')),
                    ],
                  ),
                  if (status != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Estado', style: AppTextStyles.bodySmallSecondary),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
                          ),
                          child: Text(
                            status!,
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryBlue),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: buttonText,
            onPressed: () {
              Navigator.pop(context);
              onButtonPressed();
            },
            isExpanded: true,
          ),
          if (secondaryButtonText != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppOutlinedButton(
              label: secondaryButtonText!,
              onPressed: () {
                Navigator.pop(context);
                onSecondaryPressed?.call();
              },
              isExpanded: true,
            ),
          ],
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}