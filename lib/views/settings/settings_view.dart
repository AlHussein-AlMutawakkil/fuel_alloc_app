import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/one_ui_card.dart';
import '../data/fuel_types_view.dart';
import '../data/units_view.dart';
import 'archived_accounts_view.dart';
import 'language_settings_view.dart';
import 'permissions_settings_view.dart';
import 'recycle_bin_view.dart';
import 'theme_settings_view.dart';

/// واجهة الإعدادات بنمط One UI مطابقة للقطات الشاشة
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  void _showUnderDevelopmentSnackBar(String title) {
    AppSnackBar.showInfo(context, '$title (${AppStrings.underDevelopment})');
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusCard,
        ),
        title: const Row(
          children: [
            Icon(
              AppIcons.gasStation,
              color: AppColors.primary,
              size: AppDimensions.iconExtraLarge,
            ),
            SizedBox(width: AppDimensions.spaceM + 2),
            Text(
              AppStrings.appTitle,
              style: TextStyle(
                fontSize: AppTypography.sizeH1 - 2,
                fontWeight: AppTypography.weightBold,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.appVersionOfficial,
              style: TextStyle(
                fontSize: AppTypography.sizeBody,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppDimensions.spaceM),
            Text(
              AppStrings.aboutAppDescription,
              style: TextStyle(
                fontSize: AppTypography.sizeBodySecondary,
                height: 1.5,
                color: AppColors.textDarkSlate,
              ),
            ),
          ],
        ),
        actions: [
          CustomButton(
            text: AppStrings.close,
            variant: ButtonVariant.secondary,
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: AppStrings.confirmLogoutTitle,
      message: AppStrings.confirmLogoutMsg,
      confirmText: AppStrings.logout,
      cancelText: AppStrings.cancel,
      isDanger: true,
    );
    if (confirm && mounted) {
      AppSnackBar.showSuccess(context, AppStrings.logoutSuccessMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const OneUiAppBar(
        title: AppStrings.settingsTitle,
        showBackButton: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.spaceL,
        ),
        children: [
          // 1. كرت الملف الشخصي للمستخدم
          OneUiCard(
            children: [
              OneUiTile(
                leading: Container(
                  width: AppDimensions.avatarSize,
                  height: AppDimensions.avatarSize,
                  decoration: const BoxDecoration(
                    color: AppColors.textDarkSlate,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    AppIcons.profile,
                    color: AppColors.textWhite,
                    size: AppDimensions.iconExtraLarge - 2,
                  ),
                ),
                title: AppStrings.profileTitle,
                subtitle: AppStrings.editProfile,
                onTap: () =>
                    _showUnderDevelopmentSnackBar(AppStrings.editProfile),
              ),
            ],
          ),

          // 2. كرت الحساب
          OneUiCard(
            children: [
              OneUiTile(
                leading: const Icon(
                  AppIcons.accountOutline,
                  color: AppColors.textPrimary,
                  size: AppDimensions.iconMedium + 2,
                ),
                title: AppStrings.account,
                valueText: 'alhossenail776472265...',
                onTap: () => _showUnderDevelopmentSnackBar(AppStrings.account),
              ),
            ],
          ),

          // 3. كرت البيانات (الأصناف والوحدات)
          OneUiCard(
            children: [
              OneUiTile(
                leading: const Icon(
                  AppIcons.category,
                  color: AppColors.textPrimary,
                  size: AppDimensions.iconMedium + 2,
                ),
                title: AppStrings.dataFuelTypes,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FuelTypesView()),
                  );
                },
              ),
              OneUiTile(
                leading: const Icon(
                  AppIcons.unit,
                  color: AppColors.textPrimary,
                  size: AppDimensions.iconMedium + 2,
                ),
                title: AppStrings.dataUnits,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UnitsView()),
                  );
                },
              ),
            ],
          ),

          // 4. كرت سلة المحذوفات والأرشيف (منفصل لحاله)
          OneUiCard(
            children: [
              OneUiTile(
                leading: const Icon(
                  AppIcons.recycleBin,
                  color: AppColors.textPrimary,
                  size: AppDimensions.iconMedium + 2,
                ),
                title: AppStrings.recycleBinTitle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecycleBinView()),
                  );
                },
              ),
              OneUiTile(
                leading: const Icon(
                  AppIcons.archive,
                  color: AppColors.textPrimary,
                  size: AppDimensions.iconMedium + 2,
                ),
                title: AppStrings.archiveTitle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ArchivedAccountsView()),
                  );
                },
              ),
            ],
          ),

          // 5. كرت المظهر واللغة
          OneUiCard(
            children: [
              OneUiTile(
                leading: const Icon(
                  AppIcons.theme,
                  color: AppColors.textPrimary,
                  size: AppDimensions.iconMedium + 2,
                ),
                title: AppStrings.theme,
                valueText: AppStrings.themeLight,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ThemeSettingsView()),
                  );
                },
              ),
              OneUiTile(
                leading: const Icon(
                  AppIcons.language,
                  color: AppColors.textPrimary,
                  size: AppDimensions.iconMedium + 2,
                ),
                title: AppStrings.appLanguage,
                valueText: AppStrings.languageArabic,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LanguageSettingsView()),
                  );
                },
              ),
            ],
          ),

          // 5. كرت الأذونات وحول التطبيق
          OneUiCard(
            children: [
              OneUiTile(
                leading: const Icon(
                  AppIcons.permissions,
                  color: AppColors.textPrimary,
                  size: AppDimensions.iconMedium + 2,
                ),
                title: AppStrings.permissionsManagement,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PermissionsSettingsView()),
                  );
                },
              ),
              OneUiTile(
                leading: const Icon(
                  AppIcons.info,
                  color: AppColors.textPrimary,
                  size: AppDimensions.iconMedium + 2,
                ),
                title: AppStrings.aboutApp,
                onTap: _showAboutDialog,
              ),
            ],
          ),

          // 6. كرت تسجيل الخروج
          OneUiCard(
            children: [
              OneUiTile(
                leading: const Icon(
                  AppIcons.logout,
                  color: AppColors.dispenseRed,
                  size: AppDimensions.iconMedium + 2,
                ),
                title: AppStrings.logout,
                titleColor: AppColors.dispenseRed,
                onTap: _confirmLogout,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceXL),
        ],
      ),
    );
  }
}
