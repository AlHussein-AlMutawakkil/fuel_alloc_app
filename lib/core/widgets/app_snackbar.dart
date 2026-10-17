import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';

/// مساعد عرض الإشعارات والرسائل التنبيهية الموحد
class AppSnackBar {
  AppSnackBar._();

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, AppColors.supplyGreen);
  }

  static void showWarning(BuildContext context, String message) {
    _show(context, message, AppColors.warning);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, AppColors.dispenseRed);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, AppColors.info);
  }

  static void _show(
      BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: AppTypography.sizeBody,
            fontWeight: AppTypography.weightMedium,
            color: AppColors.textWhite,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusM,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
