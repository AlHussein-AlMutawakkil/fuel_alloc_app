import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../models/backup_model.dart';
import 'auto_clean_settings_view.dart';
import 'backup_type_settings_view.dart';
import 'backups_list_view.dart';
import 'compression_encryption_settings_view.dart';
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

  void _handleRestoreBackup(BackupController controller) async {
    final localBackups = controller.localBackups;
    if (localBackups.isEmpty) {
      AppSnackBar.showInfo(context, AppStrings.noLocalBackups);
      return;
    }

    final latest = localBackups.first;
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: AppStrings.restoreLocalBackup,
      message: '${AppStrings.restoreLocalBackupDesc}\n(${latest.fileName})',
      confirmText: AppStrings.restore,
      cancelText: AppStrings.cancel,
      isDanger: true,
    );
    if (confirm && mounted) {
      final ok = await controller.restoreLocalBackup(latest.fileName);
      if (mounted) {
        if (ok) {
          AppSnackBar.showSuccess(context, AppStrings.restoreSuccessMsg);
        } else {
          AppSnackBar.showError(context, AppStrings.restoreFailed);
        }
      }
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

  void _handleSelectStorageLocation(BackupController controller) async {
    final currentDir = await controller.getLocalBackupsDirectory();
    BackupStorageLocation tempLocation = controller.storageLocation;

    if (!mounted) return;

    final confirmed = await CustomDialog.showCustomContent(
      context: context,
      title: AppStrings.backupStorageLocationSelectTitle,
      content: StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OneUiSelectionTile(
                title: AppStrings.backupStorageInternalTitle,
                subtitle: AppStrings.backupStorageInternalDesc,
                isSelected: tempLocation == BackupStorageLocation.internal,
                selectionType: SelectionTileType.radio,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceM,
                  vertical: AppDimensions.spaceM,
                ),
                onTap: () {
                  setDialogState(() {
                    tempLocation = BackupStorageLocation.internal;
                  });
                },
              ),
              const OneUiDivider(),
              OneUiSelectionTile(
                title: AppStrings.backupStorageExternalTitle,
                subtitle: AppStrings.backupStorageExternalDesc,
                isSelected: tempLocation == BackupStorageLocation.external,
                selectionType: SelectionTileType.radio,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceM,
                  vertical: AppDimensions.spaceM,
                ),
                onTap: () {
                  setDialogState(() {
                    tempLocation = BackupStorageLocation.external;
                  });
                },
              ),
              const SizedBox(height: AppDimensions.spaceL),
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceM),
                decoration: BoxDecoration(
                  color: AppColors.searchBackground,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(
                    color: AppColors.borderLight,
                    width: AppDimensions.borderWidthThin,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.backupStorageCurrentPath,
                      style: TextStyle(
                        fontSize: AppTypography.sizeCaption,
                        fontWeight: AppTypography.weightSemiBold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceXS),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            currentDir.path,
                            style: const TextStyle(
                              fontSize: AppTypography.sizeCaption - 1,
                              color: AppColors.textPrimary,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            AppIcons.copy,
                            size: AppDimensions.iconSmall + 2,
                            color: AppColors.textPrimary,
                          ),
                          tooltip: AppStrings.copyPath,
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: currentDir.path));
                            AppSnackBar.showSuccess(context, AppStrings.pathCopied);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      confirmText: AppStrings.confirm,
      cancelText: AppStrings.cancel,
    );

    if (confirmed && mounted && tempLocation != controller.storageLocation) {
      controller.setStorageLocation(tempLocation);
      AppSnackBar.showSuccess(
        context,
        tempLocation == BackupStorageLocation.external
            ? AppStrings.backupStorageExternal
            : AppStrings.backupStorageInternal,
      );
    }
  }

  void _handleCleanDuplicates(BackupController controller) async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: AppStrings.cleanDuplicatesConfirmTitle,
      message: AppStrings.cleanDuplicatesConfirmMsg,
      confirmText: AppStrings.confirm,
      cancelText: AppStrings.cancel,
    );
    if (confirm && mounted) {
      AppSnackBar.showInfo(context, AppStrings.cleaningDuplicates);
      final count = await controller.cleanDuplicateCloudBackups();
      if (mounted) {
        if (count > 0) {
          AppSnackBar.showSuccess(
            context,
            '${AppStrings.cleanDuplicatesSuccess} ($count)',
          );
        } else {
          AppSnackBar.showInfo(context, AppStrings.noDuplicatesFound);
        }
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
                    onTap: () => _handleRestoreBackup(controller),
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
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.autoClean,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.autoCleanTitle,
                    subtitle: AppStrings.autoCleanSubtitle,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: controller,
                            child: const AutoCleanSettingsView(),
                          ),
                        ),
                      );
                    },
                  ),
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.security,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.compressionEncryptionTitle,
                    subtitle: controller.isEncryptionEnabled
                        ? AppStrings.encryptBackups
                        : (controller.isCompressionEnabled
                            ? AppStrings.compressBackups
                            : AppStrings.noSyncYet),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: controller,
                            child: const CompressionEncryptionSettingsView(),
                          ),
                        ),
                      );
                    },
                  ),
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.folderOpen,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.backupStorageLocation,
                    subtitle: AppStrings.backupStorageLocationDesc,
                    valueText: controller.storageLocation == BackupStorageLocation.internal
                        ? AppStrings.backupStorageInternalTitle
                        : AppStrings.backupStorageExternalTitle,
                    onTap: () => _handleSelectStorageLocation(controller),
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

                  // خيار تنظيف النسخ السحابية المكررة إذا كان Google Drive متصلاً
                  if (controller.isGoogleDriveConnected)
                    OneUiTile(
                      leading: const Icon(
                        AppIcons.cleanSweep,
                        color: AppColors.textPrimary,
                        size: AppDimensions.iconMedium + 2,
                      ),
                      title: AppStrings.cleanDuplicateCloudBackups,
                      subtitle: AppStrings.cleanDuplicatesDesc,
                      onTap: () => _handleCleanDuplicates(controller),
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

                  // صف الرفع عبر الواي فاي فقط
                  Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: AppDimensions.paddingTile,
                      child: Row(
                        children: [
                          const Icon(
                            AppIcons.wifi,
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
                                  AppStrings.wifiOnlyTitle,
                                  style: TextStyle(
                                    fontSize: AppTypography.sizeBody + 1,
                                    fontWeight: AppTypography.weightSemiBold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: AppDimensions.spaceXXS + 1),
                                Text(
                                  AppStrings.wifiOnlyDesc,
                                  style: TextStyle(
                                    fontSize: AppTypography.sizeCaption,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSwitch(
                            value: controller.wifiOnlySync,
                            onChanged: (val) {
                              controller.toggleWifiOnlySync(val);
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
