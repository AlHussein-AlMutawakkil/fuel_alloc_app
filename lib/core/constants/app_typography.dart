import 'package:flutter/material.dart';
import 'app_colors.dart';

/// نظام الخطوط والطباعة الموحد للتطبيق
class AppTypography {
  AppTypography._();

  // أحجام الخطوط
  static const double sizeDisplay = 24.0;
  static const double sizeH1 = 20.0;
  static const double sizeH2 = 16.0;
  static const double sizeH3 = 14.0;
  static const double sizeBody = 14.0;
  static const double sizeBodySecondary = 13.0;
  static const double sizeCaption = 12.0;
  static const double sizeSmall = 11.0;
  static const double sizeMicro = 10.0;

  // أوزان الخطوط
  static const FontWeight weightBold = FontWeight.bold;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightRegular = FontWeight.normal;

  // أنماط النصوص الموحدة
  static const TextStyle display = TextStyle(
    fontSize: sizeDisplay,
    fontWeight: weightBold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading1 = TextStyle(
    fontSize: sizeH1,
    fontWeight: weightBold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: sizeH2,
    fontWeight: weightBold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: sizeH3,
    fontWeight: weightSemiBold,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: sizeBody,
    fontWeight: weightRegular,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: sizeBody,
    fontWeight: weightMedium,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: sizeBody,
    fontWeight: weightBold,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: sizeBodySecondary,
    fontWeight: weightRegular,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: sizeCaption,
    fontWeight: weightRegular,
    color: AppColors.textMuted,
  );

  static const TextStyle captionBold = TextStyle(
    fontSize: sizeCaption,
    fontWeight: weightBold,
    color: AppColors.textMuted,
  );

  static const TextStyle button = TextStyle(
    fontSize: sizeBody,
    fontWeight: weightBold,
    color: AppColors.textWhite,
  );

  static const TextStyle appBarTitle = TextStyle(
    fontSize: 18.0,
    fontWeight: weightBold,
    color: AppColors.textWhite,
  );

  static const TextStyle oneUiAppBarTitle = TextStyle(
    fontSize: sizeH1,
    fontWeight: weightBold,
    color: AppColors.textPrimary,
  );

  static const TextStyle badge = TextStyle(
    fontSize: sizeCaption,
    fontWeight: weightBold,
    color: AppColors.textPrimary,
  );
}

/// الاسم الرديف المتوافق مع الكود القائم
typedef AppTextStyles = AppTypography;
