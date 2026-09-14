import 'package:flutter/material.dart';
import '../../../../../app/theme/index.dart';
import '../../../../../core/animations/motion.dart';
import '../../../../../mock/models.dart';

class CategorySelectionStep extends StatelessWidget {
  final List<IncidentCategory> categories;
  final IncidentCategory? selectedCategory;
  final Function(IncidentCategory) onCategorySelected;

  const CategorySelectionStep({
    super.key,
    required this.categories,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Qué está pasando?', style: AppTextStyles.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Selecciona el tipo de incidente que quieres reportar',
            style: AppTextStyles.bodyMediumSecondary,
          ),
          const SizedBox(height: AppSpacing.lg),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.88,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = selectedCategory?.type == category.type;

              return CategoryCard(
                category: category,
                isSelected: isSelected,
                onTap: () => onCategorySelected(category),
              ).staggerChild(index);
            },
          ),
        ],
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final IncidentCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: isSelected ? category.gradient : null,
          color: isSelected ? null : AppColors.surfacePrimary,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
          border: Border.all(
            color: isSelected ? category.color : AppColors.borderPrimary,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: category.color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: AppSpacing.elevationSm,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.textOnPrimary.withValues(alpha: 0.2)
                    : category.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                category.icon,
                size: AppSpacing.iconLg,
                color: isSelected ? AppColors.textOnPrimary : category.color,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: Text(
                category.title,
                style: AppTextStyles.titleMedium.copyWith(
                  color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Flexible(
              child: Text(
                category.description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? AppColors.textOnPrimary.withValues(alpha: 0.8) : AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}