import 'package:flutter/material.dart';
import '../../../../../app/theme/index.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../data/dtos/emergency_message_dto.dart';
import '../../../../../shared/widgets/basic_widgets.dart';

class IncidentCommentsSection extends StatefulWidget {
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
  State<IncidentCommentsSection> createState() => _IncidentCommentsSectionState();
}

class _IncidentCommentsSectionState extends State<IncidentCommentsSection> {
  final _scrollController = ScrollController();

  List<EmergencyMessageDto> get _visible =>
      widget.messages.where((m) => m.message.trim().isNotEmpty).toList();

  @override
  void didUpdateWidget(covariant IncidentCommentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleSend() {
    widget.onSend();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

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
              const SizedBox(width: AppSpacing.xs),
              if (visible.isNotEmpty) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.resolvedGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'en vivo',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.resolvedGreen),
                ),
              ],
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
            Container(
              constraints: const BoxConstraints(maxHeight: 340),
              decoration: BoxDecoration(
                color: AppColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
              ),
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                padding: const EdgeInsets.all(AppSpacing.sm),
                itemCount: visible.length,
                itemBuilder: (context, index) => _buildBubble(visible[index]),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
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
                  onPressed: widget.isSending ? null : _handleSend,
                  icon: widget.isSending
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

  Widget _buildBubble(EmergencyMessageDto message) {
    final isCitizen = message.senderRole == 'CITIZEN';

    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isCitizen ? AppColors.primaryBlue : AppColors.surfacePrimary,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppSpacing.borderRadiusLg),
          topRight: const Radius.circular(AppSpacing.borderRadiusLg),
          bottomLeft: Radius.circular(isCitizen ? AppSpacing.borderRadiusLg : 2),
          bottomRight: Radius.circular(isCitizen ? 2 : AppSpacing.borderRadiusLg),
        ),
        border: isCitizen ? null : Border.all(color: AppColors.borderPrimary, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isCitizen)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                message.senderName,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.secondaryTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Text(
            message.message,
            style: AppTextStyles.bodySmall.copyWith(
              color: isCitizen ? AppColors.textOnPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            Formatters.formatRelativeTime(message.createdAt),
            style: AppTextStyles.bodySmallTertiary.copyWith(
              color: isCitizen ? AppColors.textOnPrimary.withValues(alpha: 0.7) : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isCitizen ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCitizen) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.secondaryTeal.withValues(alpha: 0.15),
              child: const Icon(Icons.local_police_outlined, size: 12, color: AppColors.secondaryTeal),
            ),
            const SizedBox(width: 6),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            child: bubble,
          ),
        ],
      ),
    );
  }
}
