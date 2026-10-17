import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_icons.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import 'custom_button.dart';

/// عنصر صف في نافذة التفاصيل
class DialogDetailRow {
  final String label;
  final String value;

  const DialogDetailRow({
    required this.label,
    required this.value,
  });
}

/// نظام النوافذ المنبثقة الموحد المطابق للتصميم المعتمد
class CustomDialog {
  CustomDialog._();

  /// نافذة تأكيد عملية موحدة
  static Future<bool> showConfirmation({
    required BuildContext context,
    String title = AppStrings.confirmExclamation,
    required String message,
    String confirmText = AppStrings.ok,
    String cancelText = AppStrings.cancel,
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadius3XL,
        ),
        child: SizedBox(
          width: AppDimensions.dialogMaxWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppDimensions.space3XL),
              // العنوان في المنتصف
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppTypography.sizeH1,
                  fontWeight: AppTypography.weightBold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spaceL),
              // نص الرسالة في المنتصف
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space2XL,
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: AppTypography.sizeBody,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppDimensions.space3XL),
              // الفاصل الأفقي السفلي
              const Divider(
                height: AppDimensions.dividerHeight,
                color: AppColors.borderSubtle,
                thickness: AppDimensions.dividerThickness,
              ),
              // أزرار التأكيد والإلغاء مقسومة بخط رأسي (في RTL الأول يظهر يميناً والثاني يساراً)
              IntrinsicHeight(
                child: Row(
                  children: [
                    // زر التأكيد على اليمين (حسناً)
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.of(ctx).pop(true),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(AppDimensions.radius3XL),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppDimensions.spaceL + 2,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            confirmText,
                            style: TextStyle(
                              fontSize: AppTypography.sizeBody + 1,
                              fontWeight: AppTypography.weightBold,
                              color: isDanger
                                  ? AppColors.dispenseRed
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const VerticalDivider(
                      width: AppDimensions.dividerHeight,
                      color: AppColors.borderSubtle,
                      thickness: AppDimensions.dividerThickness,
                    ),
                    // زر الإلغاء على اليسار (إلغاء)
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.of(ctx).pop(false),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(AppDimensions.radius3XL),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppDimensions.spaceL + 2,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            cancelText,
                            style: const TextStyle(
                              fontSize: AppTypography.sizeBody + 1,
                              color: AppColors.textTertiary,
                              fontWeight: AppTypography.weightMedium,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  /// نافذة عرض التفاصيل الموحدة (تفاصيل القيد، العمليات، الحسابات)
  static Future<void> showDetails({
    required BuildContext context,
    String title = AppStrings.operationDetails,
    required List<DialogDetailRow> rows,
    String closeText = AppStrings.close,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusXL,
          side: BorderSide(
            color: AppColors.border,
            width: AppDimensions.borderWidthThin,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTypography.heading2),
            IconButton(
              icon: const Icon(
                AppIcons.close,
                size: AppDimensions.iconMedium,
                color: AppColors.textTertiary,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: rows.map((row) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spaceS,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      row.label,
                      style: AppTypography.captionBold,
                    ),
                  ),
                  Expanded(
                    child: Text(row.value, style: AppTypography.body),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          CustomButton(
            text: closeText,
            variant: ButtonVariant.secondary,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
}
