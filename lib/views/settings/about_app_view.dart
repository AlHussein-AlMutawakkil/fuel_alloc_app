import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/custom_modal_sheet.dart';
import '../../core/widgets/one_ui_card.dart';

/// واجهة حول التطبيق بتصميم One UI مطابق تماماً للقطة الشاشة المرفقة
class AboutAppView extends StatelessWidget {
  const AboutAppView({super.key});

  void _showInfoSheet(BuildContext context, String title, String content) {
    CustomModalSheet.show(
      context: context,
      title: title,
      saveText: AppStrings.ok,
      onSave: (ctx) async => Navigator.pop(ctx),
      contentBuilder: (ctx, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceM),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: AppTypography.sizeBody,
              height: 1.6,
              color: AppColors.textPrimary,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const OneUiAppBar(
        title: AppStrings.aboutAppHeader,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceL,
          vertical: AppDimensions.spaceL,
        ),
        children: [
          // 1. الكرت العلوي: الشعار، اسم التطبيق، الوصف، وإصدار التطبيق
          Card(
            color: AppColors.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
              side: const BorderSide(color: AppColors.borderLight),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.space2XL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الشعار واسم التطبيق
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        AppStrings.appNameEn,
                        style: TextStyle(
                          fontSize: AppTypography.sizeDisplay,
                          fontWeight: AppTypography.weightBold,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceM),
                      Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(AppDimensions.spaceXS),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusL),
                          border: Border.all(color: AppColors.borderLight),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.charcoal.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusM),
                          child: Image.asset(
                            AppAssets.appIconTransparent,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceL + 2),

                  // نص الوصف التعريفي
                  const Text(
                    AppStrings.aboutAppDescription,
                    style: TextStyle(
                      fontSize: AppTypography.sizeBodySecondary,
                      height: 1.65,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space2XL),

                  // إصدار التطبيق
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppStrings.appVersionLabel,
                          style: TextStyle(
                            fontSize: AppTypography.sizeBody,
                            fontWeight: AppTypography.weightMedium,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          AppStrings.appVersionNumber,
                          style: TextStyle(
                            fontSize: AppTypography.sizeBodySecondary,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),

          // 2. الكرت السفلي: شروط الاستخدام، سياسة الاستخدام، اتفاقية الخصوصية
          OneUiCard(
            margin: EdgeInsets.zero,
            children: [
              OneUiTile(
                title: AppStrings.termsOfUse,
                showChevron: true,
                onTap: () {
                  _showInfoSheet(
                    context,
                    AppStrings.termsOfUse,
                    'شروط وأحكام استخدام نظام مخصصات واعتمادات الوقود. يلتزم المستخدم بالمحافظة على سرية حسابه وبيانات عملياته المدخلة.',
                  );
                },
              ),
              OneUiTile(
                title: AppStrings.usagePolicy,
                showChevron: true,
                onTap: () {
                  _showInfoSheet(
                    context,
                    AppStrings.usagePolicy,
                    'سياسة الاستخدام العادل لنظام إدارة المشتقات النفطية وتوثيق القيود والكشوفات المحاسبية بدقة.',
                  );
                },
              ),
              OneUiTile(
                title: AppStrings.privacyPolicy,
                showChevron: true,
                onTap: () {
                  _showInfoSheet(
                    context,
                    AppStrings.privacyPolicy,
                    'اتفاقية الخصوصية وحماية البيانات. كافة السجلات والبيانات يتم تخزينها محلياً وبشكل آمن ومحمي.',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
