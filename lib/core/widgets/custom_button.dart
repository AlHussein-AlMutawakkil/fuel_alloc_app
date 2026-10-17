import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';

enum ButtonVariant { primary, secondary, danger, success, dark }

/// الزر الموحد لجميع شاشات التطبيق
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = AppDimensions.buttonHeight,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case ButtonVariant.primary:
        bgColor = AppColors.primary;
        fgColor = AppColors.textWhite;
        break;
      case ButtonVariant.secondary:
        bgColor = AppColors.surface;
        fgColor = AppColors.primary;
        borderSide = const BorderSide(
          color: AppColors.border,
          width: AppDimensions.borderWidthRegular,
        );
        break;
      case ButtonVariant.danger:
        bgColor = AppColors.dispenseRed;
        fgColor = AppColors.textWhite;
        break;
      case ButtonVariant.success:
        bgColor = AppColors.supplyGreen;
        fgColor = AppColors.textWhite;
        break;
      case ButtonVariant.dark:
        bgColor = AppColors.charcoal;
        fgColor = AppColors.textWhite;
        break;
    }

    final effectiveRadius = borderRadius ?? AppDimensions.borderRadiusM;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: effectiveRadius,
            side: borderSide,
          ),
          padding: padding ?? AppDimensions.paddingButton,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: AppDimensions.iconMedium,
                height: AppDimensions.iconMedium,
                child: CircularProgressIndicator(
                  strokeWidth: AppDimensions.borderWidthThick,
                  valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: AppDimensions.iconRegular, color: fgColor),
                    const SizedBox(width: AppDimensions.spaceM),
                  ],
                  Text(
                    text,
                    style: AppTypography.button.copyWith(color: fgColor),
                  ),
                ],
              ),
      ),
    );
  }
}
