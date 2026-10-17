import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';

/// رقاقة الفلترة الموحدة في التطبيق
class AppFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppDimensions.borderRadiusS,
      child: Container(
        padding: AppDimensions.paddingChip,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: AppDimensions.borderRadiusS,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: AppDimensions.borderWidthThin,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: isSelected
                    ? AppTypography.weightBold
                    : AppTypography.weightRegular,
                color:
                    isSelected ? AppColors.textWhite : AppColors.textSecondary,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: AppDimensions.spaceXS),
              Text(
                '($count)',
                style: AppTypography.caption.copyWith(
                  fontWeight: AppTypography.weightBold,
                  color: isSelected ? AppColors.textWhite : AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
