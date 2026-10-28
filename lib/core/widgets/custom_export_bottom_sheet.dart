import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';

/// تنسيقات التصدير المتاحة
enum ExportFormat { pdf, excel }

/// نافذة التصدير السفلية الموحدة لجميع شاشات التطبيق (مطابقة للصورة 3 بنسبة 100%)
class CustomExportBottomSheet extends StatelessWidget {
  final String title;

  const CustomExportBottomSheet({
    super.key,
    this.title = AppStrings.exportAs,
  });

  /// عرض شيت التصدير من أي مكان في التطبيق
  static Future<ExportFormat?> show({
    required BuildContext context,
    String? title,
  }) {
    return showModalBottomSheet<ExportFormat>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CustomExportBottomSheet(
        title: title ?? AppStrings.exportAs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusCard + 4),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.space2XL,
        AppDimensions.spaceXL,
        AppDimensions.space2XL,
        AppDimensions.space3XL,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // شريط الرأس: زر الإغلاق X على اليسار، والعنوان في المنتصف تماماً كما في الصورة 3
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft, // زر الإغلاق X في أقصى اليسار
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 4,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTypography.sizeH2,
                    fontWeight: AppTypography.weightSemiBold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.space2XL),

            // الخيار 1: تصدير الى ملف Pdf (الأيقونة في اليسار والنص في المنتصف مطابق للصورة 3)
            _buildExportOption(
              context: context,
              title: AppStrings.exportToPdf,
              badge: _buildPdfBadge(),
              onTap: () => Navigator.of(context).pop(ExportFormat.pdf),
            ),

            const SizedBox(height: AppDimensions.spaceL),

            // الخيار 2: تصدير الى ملف Excel (الأيقونة في اليسار والنص في المنتصف مطابق للصورة 3)
            _buildExportOption(
              context: context,
              title: AppStrings.exportToExcel,
              badge: _buildExcelBadge(),
              onTap: () => Navigator.of(context).pop(ExportFormat.excel),
            ),

            const SizedBox(height: AppDimensions.spaceM),
          ],
        ),
      ),
    );
  }

  /// زر خيار التصدير محدد بإطار أسود دائري والأيقونة في اليسار مطابق للصورة 3
  Widget _buildExportOption({
    required BuildContext context,
    required String title,
    required Widget badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radius2XL),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceXL),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radius2XL),
            border: Border.all(
              color: AppColors.textPrimary,
              width: AppDimensions.borderWidthThin + 0.3,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // الأيقونة في جهة اليسار دائماً كما في الصورة 3
              Align(
                alignment: Alignment.centerLeft,
                child: badge,
              ),
              // نص الخيار في المنتصف
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppTypography.sizeBody + 1,
                  fontWeight: AppTypography.weightBold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// شارة PDF السوداء المدمجة (كما في لقطة الشاشة 3)
  Widget _buildPdfBadge() {
    return Container(
      width: 28,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
      ),
      alignment: Alignment.center,
      child: const Text(
        'PDF',
        style: TextStyle(
          color: AppColors.textWhite,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// شارة Excel السوداء المدمجة (كما في لقطة الشاشة 3)
  Widget _buildExcelBadge() {
    return Container(
      width: 28,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
      ),
      alignment: Alignment.center,
      child: const Text(
        'X',
        style: TextStyle(
          color: AppColors.textWhite,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
