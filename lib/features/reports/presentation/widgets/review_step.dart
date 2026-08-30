import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../app/theme/index.dart';
import '../../../../../core/animations/motion.dart';
import '../../../../../mock/models.dart';
import '../../../../../shared/widgets/basic_widgets.dart';

class ReviewStep extends StatefulWidget {
  final IncidentCategory? category;
  final Location? location;
  final List<String> evidenceUrls;
  final String description;
  final Function(String) onDescriptionChanged;
  final VoidCallback onSubmit;

  const ReviewStep({
    super.key,
    this.category,
    this.location,
    required this.evidenceUrls,
    required this.description,
    required this.onDescriptionChanged,
    required this.onSubmit,
  });

  @override
  State<ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends State<ReviewStep> {
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _descriptionController.text = widget.description;
    _descriptionController.addListener(() {
      widget.onDescriptionChanged(_descriptionController.text);
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revisar reporte', style: AppTextStyles.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Verifica la información antes de enviar',
            style: AppTextStyles.bodyMediumSecondary,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildReviewCard(
            title: 'Categoría',
            icon: widget.category?.icon ?? Icons.help_outline,
            iconColor: widget.category?.color ?? AppColors.textTertiary,
            child: Text(
              widget.category?.title ?? 'No seleccionado',
              style: AppTextStyles.bodyMedium,
            ),
          ).staggerChild(0),
          const SizedBox(height: AppSpacing.md),
          _buildReviewCard(
            title: 'Ubicación',
            icon: Icons.location_on_outlined,
            iconColor: AppColors.primaryBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.location?.address ?? 'No seleccionada', style: AppTextStyles.bodyMedium),
                if (widget.location != null)
                  Text(widget.location!.zone, style: AppTextStyles.bodySmallSecondary),
              ],
            ),
          ).staggerChild(1),
          const SizedBox(height: AppSpacing.md),
          _buildReviewCard(
            title: 'Descripción',
            icon: Icons.description_outlined,
            iconColor: AppColors.primaryBlue,
            child: TextField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 500,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Agrega detalles adicionales...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabled),
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ).staggerChild(2),
          const SizedBox(height: AppSpacing.md),
          if (widget.evidenceUrls.isNotEmpty) ...[
            _buildReviewCard(
              title: 'Evidencia (${widget.evidenceUrls.length})',
              icon: Icons.photo_library_outlined,
              iconColor: AppColors.primaryBlue,
              child: SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.evidenceUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final url = widget.evidenceUrls[index];
                    final isLocal = !url.startsWith('http');

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderPrimary, width: 0.5),
                        ),
                        child: isLocal
                            ? Image.asset(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.surfaceSecondary,
                                  child: Icon(Icons.broken_image_outlined, size: AppSpacing.iconLg, color: AppColors.textTertiary),
                                ),
                              )
                            : CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppColors.surfaceSecondary,
                                  child: Center(child: AppLoadingIndicator(color: AppColors.primaryBlue)),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.surfaceSecondary,
                                  child: Icon(Icons.broken_image_outlined, size: AppSpacing.iconLg, color: AppColors.textTertiary),
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ).staggerChild(3),
            const SizedBox(height: AppSpacing.md),
          ],
          _buildImportantNotice().staggerChild(4),
        ],
      ),
    );
  }

  Gradient _iconGradient(Color color) {
    return LinearGradient(colors: [color, Color.lerp(color, Colors.white, 0.35) ?? color]);
  }

  Widget _buildReviewCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.borderPrimary, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconBadge(
                icon: icon,
                gradient: _iconGradient(iconColor),
                size: 36,
                iconSize: 18,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(title, style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _buildImportantNotice() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.moderateOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.moderateOrange.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_outlined, color: AppColors.moderateOrange, size: AppSpacing.iconMd),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Antes de enviar', style: AppTextStyles.labelLarge.copyWith(color: AppColors.moderateOrange)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'La información que proporcionas será compartida con tu comunidad y las autoridades locales. '
                  'Asegúrate de que sea veraz y precisa. Los reportes falsos pueden tener consecuencias legales.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}