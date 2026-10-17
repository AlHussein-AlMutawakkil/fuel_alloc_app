import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_icons.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import 'custom_text_field.dart';

/// المكون المشترك الموحد لكافة النوافذ المنبثقة في التطبيق
/// (إضافة حساب، إضافة محطة، إضافة صنف)
/// بتصميم One UI العصري الموحد
class CustomModalSheet {
  CustomModalSheet._();

  // لون حدود الحقول الموحد الناعم
  static const Color fieldBorderColor = AppColors.borderLight;

  /// فتح نافذة منبثقة موحدة في كافة شاشات التطبيق
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget Function(BuildContext ctx, StateSetter setState)
        contentBuilder,
    required Future<void> Function(BuildContext ctx) onSave,
    String saveText = AppStrings.confirm,
    String cancelText = AppStrings.cancel,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.overlay,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return Center(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceXL,
                  vertical: AppDimensions.space2XL,
                ),
                constraints: const BoxConstraints(
                  maxWidth: AppDimensions.modalMaxWidth,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppDimensions.borderRadius3XL,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.overlayLight,
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: AppDimensions.borderRadius3XL,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(dialogCtx).viewInsets.bottom,
                    ),
                    child: SingleChildScrollView(
                      padding: AppDimensions.paddingModal,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. الشريط العلوي: العنوان وزر الإغلاق
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: AppTypography.sizeH2,
                                    fontWeight: AppTypography.weightBold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  AppIcons.closeRounded,
                                  color: AppColors.textTertiary,
                                  size: AppDimensions.iconMedium,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: AppDimensions.space4XL,
                                  minHeight: AppDimensions.space4XL,
                                ),
                                onPressed: () => Navigator.of(dialogCtx).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spaceL + 6),

                          // 2. محتوى الحقول
                          contentBuilder(dialogCtx, setModalState),
                          const SizedBox(height: AppDimensions.space3XL),

                          // 3. شريط الأزرار السفلي (إلغاء رمادي يميناً، وتأكيد أسود يساراً في RTL)
                          Row(
                            children: [
                              // زر الإلغاء على اليمين
                              Expanded(
                                child: InkWell(
                                  onTap: () => Navigator.of(dialogCtx).pop(),
                                  borderRadius: AppDimensions.borderRadius2XL,
                                  child: Container(
                                    height: AppDimensions.inputHeight,
                                    decoration: const BoxDecoration(
                                      color: AppColors.scaffoldBackground,
                                      borderRadius:
                                          AppDimensions.borderRadius2XL,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      cancelText,
                                      style: const TextStyle(
                                        fontSize: AppTypography.sizeBody + 1,
                                        fontWeight:
                                            AppTypography.weightSemiBold,
                                        color: AppColors.textSlate,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.spaceL),

                              // زر التأكيد الأسود على اليسار
                              Expanded(
                                child: InkWell(
                                  onTap: () => onSave(dialogCtx),
                                  borderRadius: AppDimensions.borderRadius2XL,
                                  child: Container(
                                    height: AppDimensions.inputHeight,
                                    decoration: const BoxDecoration(
                                      color: AppColors.charcoal,
                                      borderRadius:
                                          AppDimensions.borderRadius2XL,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      saveText,
                                      style: const TextStyle(
                                        fontSize: AppTypography.sizeBody + 1,
                                        fontWeight:
                                            AppTypography.weightSemiBold,
                                        color: AppColors.textWhite,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// بناء عنوان الحقل الموحد
  static Widget buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: AppTypography.sizeCaption,
          fontWeight: AppTypography.weightMedium,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  /// بناء حقل إدخال نصي موحد بنسبة 100%
  static Widget buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
  }) {
    return CustomTextField(
      label: label,
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      variant: TextFieldVariant.oneUi,
    );
  }
}
