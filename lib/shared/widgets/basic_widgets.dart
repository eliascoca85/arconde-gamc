import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme/index.dart';
import '../../core/animations/motion.dart';
import '../../core/extensions/context_extensions.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final List<BoxShadow>? shadows;
  final BorderRadius? borderRadius;
  final Border? border;
  final VoidCallback? onTap;
  final bool isPressable;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.shadows,
    this.borderRadius,
    this.border,
    this.onTap,
    this.isPressable = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin ?? EdgeInsets.all(AppSpacing.md),
      padding: padding ?? EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color ?? context.theme.cardColor,
        borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: border ?? Border.all(color: AppColors.borderPrimary, width: 0.5),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: child,
    );

    if (onTap != null) {
      // Pressable's GestureDetector owns the tap; a nested InkWell.onTap
      // would compete with it in the gesture arena, so the scale feedback
      // here replaces the ripple rather than layering both.
      return Pressable(onTap: onTap, child: card);
    }

    return card;
  }
}

class AppSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final BorderRadius? borderRadius;
  final Border? border;

  const AppSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color ?? AppColors.surfacePrimary,
        borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: border ?? Border.all(color: AppColors.borderPrimary, width: 0.5),
      ),
      child: child,
    );
  }
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isExpanded;
  final ButtonStyle? style;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isExpanded = true,
    this.style,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: style ??
          FilledButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.secondaryTeal,
            foregroundColor: foregroundColor ?? AppColors.textOnPrimary,
            minimumSize: Size(isExpanded ? double.infinity : 88, 48),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
            ),
            textStyle: AppTextStyles.labelLarge,
          ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
              ),
            )
          : Row(
              mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppSpacing.iconSm),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                if (trailingIcon != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(trailingIcon, size: AppSpacing.iconSm),
                ],
              ],
            ),
    );

    return Pressable(child: button);
  }
}

class AppOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isExpanded;
  final Color? borderColor;
  final Color? textColor;

  const AppOutlinedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isExpanded = true,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor ?? AppColors.secondaryTeal,
        side: BorderSide(color: borderColor ?? AppColors.secondaryTeal, width: 1.5),
        minimumSize: Size(isExpanded ? double.infinity : 88, 48),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        ),
        textStyle: AppTextStyles.labelLarge,
      ),
      child: Row(
        mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSpacing.iconSm),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class AppTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? textColor;

  const AppTextButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: textColor ?? AppColors.secondaryTeal,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        ),
        textStyle: AppTextStyles.labelLarge,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSpacing.iconSm),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(label),
        ],
      ),
    );
  }
}

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double? size;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final String? tooltip;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size,
    this.padding,
    this.borderRadius,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: size ?? AppSpacing.iconMd, color: color ?? AppColors.textPrimary),
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.transparent,
        padding: padding ?? EdgeInsets.all(AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.borderRadiusMd),
        ),
      ),
      tooltip: tooltip,
    );

    return Pressable(child: button);
  }
}

class AppFAB extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? child;
  final String? label;
  final IconData? icon;
  final bool isExtended;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppFAB({
    super.key,
    this.onPressed,
    this.child,
    this.label,
    this.icon,
    this.isExtended = false,
    this.backgroundColor,
    this.foregroundColor,
  }) : assert(child != null || (label != null || icon != null));

  @override
  Widget build(BuildContext context) {
    if (isExtended) {
      return Pressable(child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: backgroundColor ?? AppColors.secondaryTeal,
        foregroundColor: foregroundColor ?? AppColors.textOnPrimary,
        elevation: AppSpacing.elevationMd,
        icon: icon != null ? Icon(icon, size: AppSpacing.iconMd) : const SizedBox.shrink(),
        label: child ??
            Text(
              label!,
              style: AppTextStyles.labelLarge.copyWith(color: foregroundColor ?? AppColors.textOnPrimary),
            ),
        extendedPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusXl),
        ),
      ));
    }

    return Pressable(
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: backgroundColor ?? AppColors.secondaryTeal,
        foregroundColor: foregroundColor ?? AppColors.textOnPrimary,
        elevation: AppSpacing.elevationMd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusXl),
        ),
        child: child ?? Icon(icon ?? Icons.add, size: AppSpacing.iconLg),
      ),
    );
  }
}

class AppChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? selectedColor;
  final Color? unselectedColor;
  final BorderRadius? borderRadius;

  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.isSelected = false,
    this.onTap,
    this.selectedColor,
    this.unselectedColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: AppTextStyles.labelMedium),
      avatar: icon != null ? Icon(icon, size: AppSpacing.iconSm) : null,
      selected: isSelected,
      onSelected: onTap != null ? (_) => onTap!() : null,
      selectedColor: selectedColor ?? AppColors.secondaryTeal.withValues(alpha: 0.22),
      backgroundColor: unselectedColor ?? AppColors.surfaceSecondary,
      labelStyle: AppTextStyles.labelMedium.copyWith(
        color: isSelected ? AppColors.secondaryTeal : AppColors.textPrimary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.secondaryTeal : AppColors.borderPrimary,
        width: isSelected ? 1.5 : 0.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.borderRadiusFull),
      ),
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class AppInput extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final int? maxLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;

  const AppInput({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      enabled: enabled,
      readOnly: readOnly,
      onTap: onTap,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: AppSpacing.iconMd) : null,
        suffixIcon: suffixIcon,
        counterText: '',
      ),
    );
  }
}

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 24,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: backgroundColor ?? AppColors.primaryBlue,
      );
    }

    final initials = name != null
        ? name!.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '?';

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppColors.primaryBlue,
      foregroundColor: foregroundColor ?? AppColors.textOnPrimary,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.6,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AppBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const AppBadge({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.icon,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color ?? AppColors.primaryBlue,
        borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.borderRadiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSpacing.iconXs, color: textColor ?? AppColors.textOnPrimary),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: textColor ?? AppColors.textOnPrimary),
          ),
        ],
      ),
    );
  }
}

class AppDivider extends StatelessWidget {
  final double? height;
  final double? thickness;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  const AppDivider({
    super.key,
    this.height,
    this.thickness,
    this.color,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final EdgeInsets resolvedMargin = margin?.resolve(Directionality.of(context)) ?? EdgeInsets.zero;
    return Padding(
      padding: EdgeInsets.only(top: resolvedMargin.top, bottom: resolvedMargin.bottom),
      child: Divider(
        height: height ?? AppSpacing.md,
        thickness: thickness ?? 0.5,
        color: color ?? AppColors.divider,
        indent: 0,
        endIndent: 0,
      ),
    );
  }
}

class AppSpace extends StatelessWidget {
  final double height;
  final double width;

  const AppSpace.v({super.key, this.height = AppSpacing.md, this.width = 0});
  const AppSpace.h({super.key, this.width = AppSpacing.md, this.height = 0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height, width: width);
  }
}

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: AppSpacing.iconXl, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppTextStyles.headlineSmall, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(subtitle!, style: AppTextStyles.bodyMediumSecondary, textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    ).immersiveEntrance();
  }
}

class AppLoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;
  final double strokeWidth;

  const AppLoadingIndicator({
    super.key,
    this.size,
    this.color,
    this.strokeWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size ?? AppSpacing.iconLg,
      height: size ?? AppSpacing.iconLg,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.secondaryTeal),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

class AppShimmer extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final Duration duration;

  const AppShimmer({
    super.key,
    required this.child,
    required this.isLoading,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    return child
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: duration,
          color: AppColors.surfaceTertiary,
        );
  }
}

/// Icon inside a soft gradient badge — replaces the repeated pattern of an
/// icon over a flat `color.withValues(alpha: 0.15)` container used across
/// cards, headers and chips.
class AppIconBadge extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final Color iconColor;
  final double size;
  final double iconSize;
  final bool pulse;

  const AppIconBadge({
    super.key,
    required this.icon,
    required this.gradient,
    this.iconColor = AppColors.textOnPrimary,
    this.size = 44,
    this.iconSize = 22,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        boxShadow: [
          BoxShadow(
            color: (gradient.colors.first).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: iconColor),
    );

    return pulse ? badge.pulseGlow(minScale: 1.0, maxScale: 1.08) : badge;
  }
}