import 'package:flutter/material.dart';
import '../../../../../app/theme/index.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../data/dtos/emergency_message_dto.dart';
import '../../../../../shared/widgets/basic_widgets.dart';

class IncidentCommentsSection extends StatelessWidget {
  final List<EmergencyMessageDto> messages;
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const IncidentCommentsSection({
    super.key,
    required this.messages,
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final visible = messages.where((m) => m.message.trim().isNotEmpty).toList();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Canal del reporte', style: AppTextStyles.titleMedium),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
                ),
                child: Text(
                  'EN VIVO',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.secondaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${visible.length} mensajes',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('Actualizaciones y coordinación sobre este reporte', style: AppTextStyles.bodySmallSecondary),
          const SizedBox(height: AppSpacing.lg),
          if (visible.isEmpty)
            _buildEmptyChannel()
          else
            ...visible.map(_buildComment),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje al canal...',
                    hintStyle: AppTextStyles.bodySmallSecondary,
                    filled: true,
                    fillColor: AppColors.surfaceSecondary,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: isSending ? null : onSend,
                  icon: isSending
                      ? const SizedBox(
                          width: AppSpacing.iconSm,
                          height: AppSpacing.iconSm,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnPrimary),
                        )
                      : const Icon(Icons.send, color: AppColors.textOnPrimary, size: AppSpacing.iconSm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComment(EmergencyMessageDto message) {
    final isCitizen = message.senderRole == 'CITIZEN';
    final senderColor = isCitizen ? AppColors.primary : AppColors.secondaryDark;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isCitizen ? AppColors.primaryContainer : AppColors.secondaryContainer,
            child: Icon(
              isCitizen ? Icons.person_outline : Icons.shield_outlined,
              size: 16,
              color: senderColor,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isCitizen ? AppColors.surfaceSecondary : AppColors.secondaryContainer,
                border: Border.all(color: isCitizen ? AppColors.borderPrimary : AppColors.secondary),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(AppSpacing.borderRadiusMd),
                  bottomLeft: Radius.circular(AppSpacing.borderRadiusMd),
                  bottomRight: Radius.circular(AppSpacing.borderRadiusMd),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          message.senderName,
                          style: AppTextStyles.labelMedium.copyWith(color: senderColor, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      Text(Formatters.formatRelativeTime(message.createdAt), style: AppTextStyles.bodySmallTertiary),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(message.message, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChannel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border.all(color: AppColors.borderPrimary),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_outlined, color: AppColors.secondaryDark),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'El canal está listo. Envía el primer mensaje para iniciar la coordinación.',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
