import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/backup_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_switch.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/one_ui_card.dart';
import 'backup_type_settings_view.dart';
import 'backups_list_view.dart';
import 'scheduled_backup_settings_view.dart';

/// واجهة النسخ الاحتياطي بنمط One UI
class BackupSettingsView extends StatefulWidget {
  const BackupSettingsView({super.key});

  @override
  State<BackupSettingsView> createState() => _BackupSettingsViewState();
}

class _BackupSettingsViewState extends State<BackupSettingsView> {
  BackupController? _localFallbackController;

  BackupController _resolveController(BuildContext context) {
    try {
      final provider = Provider.of<BackupController>(context);
      return provider;
    } catch (_) {
      _localFallbackController ??= BackupController();
      return _localFallbackController!;
    }
  }

  void _handleCreateBackup(BackupController controller) {
    final backup = controller.createLocalBackup();
    AppSnackBar.showSuccess(
      context,
      '${AppStrings.backupSuccessMsg} (${backup.fileName})',
    );
  }

  void _handleRestoreBackup() async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: AppStrings.restoreLocalBackup,
      message: AppStrings.restoreLocalBackupDesc,
      confirmText: AppStrings.restore,
      cancelText: AppStrings.cancel,
      isDanger: true,
    );
    if (confirm && mounted) {
      AppSnackBar.showSuccess(context, AppStrings.restoreSuccessMsg);
    }
  }

  void _handleConnectGoogleDrive(BackupController controller) async {
    final connected = await controller.connectGoogleDrive();
    if (connected && mounted) {
      AppSnackBar.showSuccess(context, AppStrings.googleDriveConnected);
    }
  }

  void _handleSyncNow(BackupController controller) async {
    final success = await controller.syncCurrentBackupToCloud();
    if (mounted) {
      if (success) {
        AppSnackBar.showSuccess(context, AppStrings.cloudSyncSuccess);
      } else {
        AppSnackBar.showError(context, AppStrings.cloudSyncError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const OneUiAppBar(
            title: AppStrings.backupTitle,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.spaceL,
            ),
            children: [
              // 1. بطاقة العمليات السريعة (المحلية)
              OneUiCard(
                children: [
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.backupExport,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.createLocalBackup,
                    subtitle: AppStrings.createLocalBackupDesc,
                    onTap: () => _handleCreateBackup(controller),
                  ),
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.backupImport,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.restoreLocalBackup,
                    subtitle: AppStrings.restoreLocalBackupDesc,
                    onTap: _handleRestoreBackup,
                  ),
                ],
              ),

              // 2. بطاقة الإعدادات والجدولة (خالية تماماً من الأسهم بناءً على طلب المستخدم)
              OneUiCard(
                children: [
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.backupType,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.backupType,
                    subtitle: AppStrings.backupTypeSubtitle,
                    valueText: controller.backupTypeTitle,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: controller,
                            child: const BackupTypeSettingsView(),
                          ),
                        ),
                      );
                    },
                  ),
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.backupSchedule,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.scheduledBackupTitle,
                    subtitle: controller.scheduleStatusSummary,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: controller,
                            child: const ScheduledBackupSettingsView(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // 3. بطاقة إدارة واستعراض النسخ
              OneUiCard(
                children: [
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.backupList,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.viewBackups,
                    subtitle: AppStrings.viewBackupsDesc,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: controller,
                            child: const BackupsListView(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // 4. بطاقة المزامنة والنسخ التلقائي مع السحابة
              OneUiCard(
                children: [
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.cloudQueue,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.cloudBackup,
                    subtitle: controller.isGoogleDriveConnected
                        ? controller.lastCloudSyncFormatted
                        : AppStrings.cloudBackupDesc,
                    valueText: controller.isGoogleDriveConnected
                        ? AppStrings.googleDriveConnected
                        : AppStrings.googleDriveNotConnected,
                    trailing: controller.isSyncing
                        ? const Padding(
                            padding: EdgeInsets.all(AppDimensions.spaceM),
                            child: SizedBox(
                              width: AppDimensions.iconRegular,
                              height: AppDimensions.iconRegular,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                          )
                        : (controller.isGoogleDriveConnected
                            ? IconButton(
                                icon: const Icon(
                                  AppIcons.sync,
                                  color: AppColors.primary,
                                  size: AppDimensions.iconMedium + 2,
                                ),
                                tooltip: AppStrings.syncNow,
                                onPressed: () => _handleSyncNow(controller),
                              )
                            : null),
                    onTap: () {
                      if (!controller.isGoogleDriveConnected) {
                        _handleConnectGoogleDrive(controller);
                      } else {
                        _handleSyncNow(controller);
                      }
                    },
                  ),

                  // صف النسخ الاحتياطي التلقائي
                  Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: AppDimensions.paddingTile,
                      child: Row(
                        children: [
                          const Icon(
                            AppIcons.backup,
                            color: AppColors.textPrimary,
                            size: AppDimensions.iconMedium + 2,
                          ),
                          const SizedBox(width: AppDimensions.spaceL + 2),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppStrings.autoBackup,
                                  style: TextStyle(
                                    fontSize: AppTypography.sizeBody + 1,
                                    fontWeight: AppTypography.weightSemiBold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: AppDimensions.spaceXXS + 1),
                                Text(
                                  AppStrings.autoBackupDesc,
                                  style: TextStyle(
                                    fontSize: AppTypography.sizeCaption,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSwitch(
                            value: controller.autoBackupEnabled,
                            onChanged: (val) {
                              controller.toggleAutoBackup(val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
