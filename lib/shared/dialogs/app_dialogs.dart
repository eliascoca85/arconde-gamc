import 'package:flutter/material.dart';
import '../../app/theme/index.dart';
import '../../core/animations/motion.dart';
import '../widgets/basic_widgets.dart';

class AppDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
    Color? barrierColor,
    bool useSafeArea = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? AppColors.overlayColor,
      useSafeArea: useSafeArea,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surfacePrimary,
        surfaceTintColor: Colors.transparent,
        elevation: AppSpacing.elevationXl,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusXl),
        ),
        child: child,
      ),
    );
  }

  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    bool isDestructive = false,
    IconData? icon,
    Color? iconColor,
  }) {
    return show<bool>(
      context: context,
      child: _ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        icon: icon,
        iconColor: iconColor,
      ),
    );
  }

  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'Entendido',
    VoidCallback? onPressed,
  }) {
    return show<void>(
      context: context,
      child: _SuccessDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onPressed: onPressed,
      ),
    );
  }

  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'Entendido',
    VoidCallback? onPressed,
  }) {
    return show<void>(
      context: context,
      child: _ErrorDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onPressed: onPressed,
      ),
    );
  }

  static Future<void> showLoading({
    required BuildContext context,
    required String message,
  }) {
    return show<void>(
      context: context,
      barrierDismissible: false,
      child: _LoadingDialog(message: message),
    );
  }
}

class _ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;
  final IconData? icon;
  final Color? iconColor;

  const _ConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    this.isDestructive = false,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: (iconColor ?? (isDestructive ? AppColors.error : AppColors.primaryBlue)).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: AppSpacing.iconXl, color: iconColor ?? (isDestructive ? AppColors.error : AppColors.primaryBlue)),
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
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: confirmText,
                  onPressed: () => Navigator.pop(context, true),
                  backgroundColor: isDestructive ? AppColors.error : AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onPressed;

  const _SuccessDialog({
    required this.title,
    required this.message,
    required this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppSuccessCheck(color: AppColors.resolvedGreen, icon: Icons.check),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTextStyles.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: AppTextStyles.bodyMediumSecondary, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: buttonText,
            onPressed: () {
              Navigator.pop(context);
              onPressed?.call();
            },
            isExpanded: true,
          ),
        ],
      ),
    );
  }
}

class _ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onPressed;

  const _ErrorDialog({
    required this.title,
    required this.message,
    required this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppSuccessCheck(color: AppColors.error, icon: Icons.close),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTextStyles.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: AppTextStyles.bodyMediumSecondary, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: buttonText,
            onPressed: () {
              Navigator.pop(context);
              onPressed?.call();
            },
            isExpanded: true,
            backgroundColor: AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _LoadingDialog extends StatelessWidget {
  final String message;

  const _LoadingDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLoadingIndicator(size: 48),
          const SizedBox(height: AppSpacing.lg),
          Text(message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class AppActionSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required List<AppActionSheetItem> items,
    String? title,
    String? message,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ActionSheetBottomSheet(
        items: items,
        title: title,
        message: message,
      ),
    );
  }
}

class AppActionSheetItem {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool isDisabled;

  const AppActionSheetItem({
    required this.label,
    this.icon,
    this.onTap,
    this.isDestructive = false,
    this.isDisabled = false,
  });
}

class _ActionSheetBottomSheet extends StatelessWidget {
  final List<AppActionSheetItem> items;
  final String? title;
  final String? message;

  const _ActionSheetBottomSheet({
    required this.items,
    this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundPrimary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.borderRadiusXl)),
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
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSecondary,
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
                ),
              ),
              if (title != null || message != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    children: [
                      if (title != null)
                        Text(title!, style: AppTextStyles.titleLarge, textAlign: TextAlign.center),
                      if (message != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(message!, style: AppTextStyles.bodyMediumSecondary, textAlign: TextAlign.center),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(height: 1, color: AppColors.divider),
              ],
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider, indent: AppSpacing.md, endIndent: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      leading: item.icon != null ? Icon(item.icon, color: item.isDestructive ? AppColors.error : AppColors.textTertiary) : null,
                      title: Text(
                        item.label,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: item.isDestructive ? AppColors.error : (item.isDisabled ? AppColors.textDisabled : AppColors.textPrimary),
                        ),
                      ),
                      enabled: !item.isDisabled,
                      onTap: item.onTap != null
                          ? () {
                              Navigator.pop(context);
                              item.onTap!();
                            }
                          : null,
                    );
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }
}