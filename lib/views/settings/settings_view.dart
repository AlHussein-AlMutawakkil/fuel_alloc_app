import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
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
import 'about_app_view.dart';
import 'archived_accounts_view.dart';
import 'backup_settings_view.dart';
import 'language_settings_view.dart';
import 'message_settings_view.dart';
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
  void _showAccountDialog(AuthController auth) {
    if (!auth.isLoggedIn) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusCard),
            ),
          ),
          padding: const EdgeInsets.all(AppDimensions.spaceXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: AppDimensions.handleWidth,
                  height: AppDimensions.handleHeight,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceL),
              const Text(
                AppStrings.accountLinkDialogTitle,
                style: TextStyle(
                  fontSize: AppTypography.sizeH2,
                  fontWeight: AppTypography.weightBold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spaceS),
              const Text(
                AppStrings.accountLinkDialogMsg,
                style: TextStyle(
                  fontSize: AppTypography.sizeBody,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spaceXL),
              CustomButton(
                text: AppStrings.connectGoogleDrive,
                icon: AppIcons.profile,
                onPressed: () async {
                  Navigator.pop(ctx);
                  final ok = await auth.signInWithGoogle();
                  if (ok && mounted) {
                    AppSnackBar.showSuccess(
                        context, AppStrings.googleDriveConnected);
                  }
                },
              ),
              const SizedBox(height: AppDimensions.spaceS),
              CustomButton(
                text: AppStrings.cancel,
                variant: ButtonVariant.secondary,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusCard),
            ),
          ),
          padding: const EdgeInsets.all(AppDimensions.spaceXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: AppDimensions.handleWidth,
                  height: AppDimensions.handleHeight,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceL),
              Row(
                children: [
                  Container(
                    width: AppDimensions.avatarSize,
                    height: AppDimensions.avatarSize,
                    decoration: const BoxDecoration(
                      color: AppColors.textDarkSlate,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: auth.photoUrl != null
                        ? Image.network(
                            auth.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              AppIcons.profile,
                              color: AppColors.textWhite,
                              size: AppDimensions.iconExtraLarge - 2,
                            ),
                          )
                        : const Icon(
                            AppIcons.profile,
                            color: AppColors.textWhite,
                            size: AppDimensions.iconExtraLarge - 2,
                          ),
                  ),
                  const SizedBox(width: AppDimensions.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.displayName,
                          style: const TextStyle(
                            fontSize: AppTypography.sizeH2,
                            fontWeight: AppTypography.weightBold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (auth.email != null)
                          Text(
                            auth.email!,
                            style: const TextStyle(
                              fontSize: AppTypography.sizeBodySecondary,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceXL),
              CustomButton(
                text: AppStrings.switchGoogleAccount,
                icon: AppIcons.switchAccount,
                variant: ButtonVariant.secondary,
                onPressed: () async {
                  Navigator.pop(ctx);
                  final ok = await auth.switchAccount();
                  if (ok && mounted) {
                    AppSnackBar.showSuccess(
                        context, AppStrings.googleDriveConnected);
                  }
                },
              ),
              const SizedBox(height: AppDimensions.spaceS),
              CustomButton(
                text: AppStrings.logout,
                icon: AppIcons.delete,
                variant: ButtonVariant.danger,
                onPressed: () {
                  Navigator.pop(ctx);
                  _confirmLogout();
                },
              ),
              const SizedBox(height: AppDimensions.spaceS),
              CustomButton(
                text: AppStrings.close,
                variant: ButtonVariant.secondary,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _confirmLogout() async {
    final auth = context.read<AuthController>();
    if (!auth.isLoggedIn) {
      AppSnackBar.showInfo(context, AppStrings.alreadyLoggedOutMsg);
      return;
    }
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: AppStrings.confirmLogoutTitle,
      message: AppStrings.confirmLogoutMsg,
      confirmText: AppStrings.logout,
      cancelText: AppStrings.cancel,
      isDanger: true,
    );
    if (confirm && mounted) {
      await auth.logout();
      if (mounted) {
        AppSnackBar.showSuccess(context, AppStrings.logoutSuccessMsg);
      }
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
          Consumer<AuthController>(
            builder: (context, auth, _) {
              return OneUiCard(
                children: [
                  OneUiTile(
                    leading: Container(
                      width: AppDimensions.avatarSize,
                      height: AppDimensions.avatarSize,
                      decoration: const BoxDecoration(
                        color: AppColors.textDarkSlate,
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: auth.isLoggedIn && auth.photoUrl != null
                          ? Image.network(
                              auth.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                AppIcons.profile,
                                color: AppColors.textWhite,
                                size: AppDimensions.iconExtraLarge - 2,
                              ),
                            )
                          : const Icon(
                              AppIcons.profile,
                              color: AppColors.textWhite,
                              size: AppDimensions.iconExtraLarge - 2,
                            ),
                    ),
                    title: auth.displayName,
                    subtitle: auth.displaySubtitle,
                    onTap: () => _showAccountDialog(auth),
                  ),
                ],
              );
            },
          ),

          // 2. كرت الحساب
          Consumer<AuthController>(
            builder: (context, auth, _) {
              return OneUiCard(
                children: [
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.accountOutline,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.account,
                    valueText: auth.accountStatusText,
                    onTap: () => _showAccountDialog(auth),
                  ),
                ],
              );
            },
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

          // 4. كرت النسخ الاحتياطي وسلة المحذوفات والأرشيف
          OneUiCard(
            children: [
              OneUiTile(
                leading: const Icon(
                  AppIcons.backup,
                  color: AppColors.textPrimary,
                  size: AppDimensions.iconMedium + 2,
                ),
                title: AppStrings.backup,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BackupSettingsView()),
                  );
                },
              ),
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
              OneUiTile(
                leading: const Icon(
                  AppIcons.message,
                  color: AppColors.textPrimary,
                  size: AppDimensions.iconMedium + 2,
                ),
                title: AppStrings.messageSettingsTitle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MessageSettingsView()),
                  );
                },
              ),
            ],
          ),

          // كرت الرسائل النصية والقوالب

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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AboutAppView(),
                    ),
                  );
                },
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
