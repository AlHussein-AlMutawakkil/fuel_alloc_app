import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import 'custom_button.dart';

/// مكون الحالة الفارغة الموحد في التطبيق
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionText;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final double iconSize;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionText,
    this.actionIcon,
    this.onAction,
    this.iconSize = AppDimensions.iconEmptyState,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space3XL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: AppDimensions.spaceL),
            Text(
              title,
              style: AppTypography.heading2,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.spaceM),
              Text(
                subtitle!,
                style: AppTypography.bodySecondary,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppDimensions.spaceXL),
              CustomButton(
                text: actionText!,
                icon: actionIcon,
                variant: ButtonVariant.secondary,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
