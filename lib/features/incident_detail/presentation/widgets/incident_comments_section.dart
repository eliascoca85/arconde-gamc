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
              const AppIconBadge(
                icon: Icons.forum_outlined,
                gradient: AppColors.primaryGradient,
                size: 36,
                iconSize: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Comentarios', style: AppTextStyles.titleMedium),
              const Spacer(),
              if (visible.isNotEmpty)
                Text(
                  '${visible.length}',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (visible.isEmpty)
            Text('Sé el primero en comentar sobre este suceso.', style: AppTextStyles.bodySmallSecondary)
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
                    hintText: 'Escribe un comentario...',
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
                  color: AppColors.primaryBlue,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isCitizen
                ? AppColors.primaryBlue.withValues(alpha: 0.15)
                : AppColors.secondaryTeal.withValues(alpha: 0.15),
            child: Icon(
              isCitizen ? Icons.person : Icons.local_police_outlined,
              size: 16,
              color: isCitizen ? AppColors.primaryBlue : AppColors.secondaryTeal,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        message.senderName,
                        style: AppTextStyles.labelMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      Formatters.formatRelativeTime(message.createdAt),
                      style: AppTextStyles.bodySmallTertiary,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(message.message, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
