import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';

enum TextFieldVariant { outlined, oneUi }

/// حقل الإدخال الموحد لجميع شاشات التطبيق
class CustomTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final TextFieldVariant variant;
  final Color? fillColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final double? height;
  final TextAlign textAlign;

  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.maxLines = 1,
    this.variant = TextFieldVariant.outlined,
    this.fillColor,
    this.borderColor,
    this.borderRadius,
    this.height,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == TextFieldVariant.oneUi) {
      return _buildOneUiVariant();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.bodySecondary.copyWith(
              fontWeight: AppTypography.weightSemiBold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          maxLines: maxLines,
          textAlign: textAlign,
          style: AppTypography.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.caption.copyWith(
              fontSize: AppTypography.sizeBodySecondary,
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: fillColor ?? AppColors.surface,
            contentPadding: AppDimensions.paddingInput,
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? AppDimensions.borderRadiusM,
              borderSide: BorderSide(
                color: borderColor ?? AppColors.border,
                width: AppDimensions.borderWidthRegular,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? AppDimensions.borderRadiusM,
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: AppDimensions.borderWidthThick,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? AppDimensions.borderRadiusM,
              borderSide: const BorderSide(
                color: AppColors.dispenseRed,
                width: AppDimensions.borderWidthRegular,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? AppDimensions.borderRadiusM,
              borderSide: const BorderSide(
                color: AppColors.dispenseRed,
                width: AppDimensions.borderWidthThick,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOneUiVariant() {
    final effectiveBorderRadius = borderRadius ?? AppDimensions.borderRadius2XL;
    final effectiveBorderColor = borderColor ?? AppColors.borderLight;
    final effectiveFillColor = fillColor ?? AppColors.background;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
            child: Text(
              label!,
              style: const TextStyle(
                fontSize: AppTypography.sizeCaption,
                fontWeight: AppTypography.weightMedium,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
        Container(
          height: maxLines == 1 ? (height ?? AppDimensions.inputHeight) : null,
          decoration: BoxDecoration(
            color: effectiveFillColor,
            borderRadius: effectiveBorderRadius,
            border: Border.all(
              color: effectiveBorderColor,
              width: AppDimensions.borderWidthThin,
            ),
          ),
          alignment: maxLines == 1 ? Alignment.center : Alignment.topLeft,
          padding: AppDimensions.paddingInputDense,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            readOnly: readOnly,
            onTap: onTap,
            onChanged: onChanged,
            maxLines: maxLines,
            textAlign: textAlign,
            style: const TextStyle(
              fontSize: AppTypography.sizeBody,
              fontWeight: AppTypography.weightMedium,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: maxLines == 1
                  ? AppDimensions.paddingNone
                  : const EdgeInsets.symmetric(vertical: AppDimensions.spaceM),
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: AppTypography.sizeBodySecondary,
                fontWeight: AppTypography.weightRegular,
                color: AppColors.textMuted,
              ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}
