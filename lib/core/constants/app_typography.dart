import 'package:flutter/material.dart';
import 'app_colors.dart';

/// نظام الخطوط والطباعة الموحد للتطبيق
class AppTypography {
  AppTypography._();

  // عائلة الخط الأساسية
  static const String fontFamily = 'Cairo';

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
    fontFamily: fontFamily,
    fontSize: sizeDisplay,
    fontWeight: weightBold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: sizeH1,
    fontWeight: weightBold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: sizeH2,
    fontWeight: weightBold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: sizeH3,
    fontWeight: weightSemiBold,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: sizeBody,
    fontWeight: weightRegular,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: sizeBody,
    fontWeight: weightMedium,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: sizeBody,
    fontWeight: weightBold,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: sizeBodySecondary,
    fontWeight: weightRegular,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: sizeCaption,
    fontWeight: weightRegular,
    color: AppColors.textMuted,
  );

  static const TextStyle captionBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: sizeCaption,
    fontWeight: weightBold,
    color: AppColors.textMuted,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: sizeBody,
    fontWeight: weightBold,
    color: AppColors.textWhite,
  );

  static const TextStyle appBarTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18.0,
    fontWeight: weightBold,
    color: AppColors.textWhite,
  );

  static const TextStyle oneUiAppBarTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: sizeH1,
    fontWeight: weightBold,
    color: AppColors.textPrimary,
  );

  static const TextStyle badge = TextStyle(
    fontFamily: fontFamily,
    fontSize: sizeCaption,
    fontWeight: weightBold,
    color: AppColors.textPrimary,
  );
}

/// الاسم الرديف المتوافق مع الكود القائم
typedef AppTextStyles = AppTypography;
