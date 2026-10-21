import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/backup_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/one_ui_card.dart';
import '../../models/backup_model.dart';

enum BackupsTab { local, cloud }

/// شاشة عرض واستعراض ملفات النسخ الاحتياطية بنمط One UI
class BackupsListView extends StatefulWidget {
  const BackupsListView({super.key});

  @override
  State<BackupsListView> createState() => _BackupsListViewState();
}

class _BackupsListViewState extends State<BackupsListView> {
  BackupsTab _activeTab = BackupsTab.local;

  void _createBackup() {
    final controller = context.read<BackupController>();
    final newBackup = controller.createLocalBackup();
    AppSnackBar.showSuccess(
      context,
      '${AppStrings.backupSuccessMsg} (${newBackup.fileName})',
    );
  }

  void _restoreBackup(BackupModel backup) async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: AppStrings.confirmRestoreTitle,
      message:
          '${AppStrings.restoreLocalBackupDesc}\n(${backup.fileName})',
      confirmText: AppStrings.restore,
      cancelText: AppStrings.cancel,
      isDanger: true,
    );
    if (confirm && mounted) {
      AppSnackBar.showSuccess(context, AppStrings.restoreSuccessMsg);
    }
  }

  void _shareBackup(BackupModel backup) {
    AppSnackBar.showInfo(
      context,
      '${AppStrings.backupShareSuccess} (${backup.fileName})',
    );
  }

  void _deleteBackup(BackupModel backup) async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: AppStrings.confirmDeleteBackupTitle,
      message:
          '${AppStrings.confirmDeleteBackupMsg}\n(${backup.fileName})',
      confirmText: AppStrings.delete,
      cancelText: AppStrings.cancel,
      isDanger: true,
    );
    if (confirm && mounted) {
      context.read<BackupController>().deleteBackup(backup.id);
      AppSnackBar.showSuccess(context, AppStrings.backupDeleteSuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BackupController>();
    final localBackups = controller.localBackups;
    final cloudBackups = controller.cloudBackups;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: OneUiAppBar(
        title: AppStrings.backupsListTitle,
        actions: [
          IconButton(
            icon: const Icon(
              AppIcons.addRounded,
              color: AppColors.textPrimary,
              size: AppDimensions.iconExtraLarge,
            ),
            tooltip: AppStrings.createLocalBackup,
            onPressed: _createBackup,
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط التبويب المعتمد (Segment Control)
          _buildSegmentControl(),

          // قائمة النسخ أو الحالة الفارغة
          Expanded(
            child: _activeTab == BackupsTab.local
                ? _buildLocalBackupsList(localBackups)
                : _buildCloudBackupsList(cloudBackups),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentControl() {
    return Container(
      margin: AppDimensions.paddingSegment,
      padding: AppDimensions.paddingAllXS,
      decoration: const BoxDecoration(
        color: AppColors.segmentBackground,
        borderRadius: AppDimensions.borderRadiusXL,
      ),
      child: Row(
        children: [
          _buildSegmentItem(
            label: AppStrings.tabLocal,
            isSelected: _activeTab == BackupsTab.local,
            onTap: () => setState(() => _activeTab = BackupsTab.local),
          ),
          _buildSegmentItem(
            label: AppStrings.tabCloud,
            isSelected: _activeTab == BackupsTab.cloud,
            onTap: () => setState(() => _activeTab = BackupsTab.cloud),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: AppColors.shadowSubtle,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.sizeBodySecondary,
              fontWeight: isSelected
                  ? AppTypography.weightBold
                  : AppTypography.weightMedium,
              color:
                  isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocalBackupsList(List<BackupModel> backups) {
    if (backups.isEmpty) {
      return EmptyStateWidget(
        icon: AppIcons.backupExport,
        title: AppStrings.noLocalBackups,
        subtitle: AppStrings.localBackupEmptyDesc,
        actionText: AppStrings.createLocalBackup,
        onAction: _createBackup,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        bottom: AppDimensions.spaceXL,
      ),
      itemCount: backups.length,
      itemBuilder: (context, index) {
        final backup = backups[index];
        return _buildBackupCard(backup);
      },
    );
  }

  Widget _buildCloudBackupsList(List<BackupModel> backups) {
    if (backups.isEmpty) {
      return const EmptyStateWidget(
        icon: AppIcons.cloudQueue,
        title: AppStrings.noCloudBackups,
        subtitle: AppStrings.cloudBackupEmptyDesc,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        bottom: AppDimensions.spaceXL,
      ),
      itemCount: backups.length,
      itemBuilder: (context, index) {
        final backup = backups[index];
        return _buildBackupCard(backup, isCloud: true);
      },
    );
  }

  Widget _buildBackupCard(BackupModel backup, {bool isCloud = false}) {
    return OneUiCard(
      showDividers: false,
      padding: AppDimensions.paddingTile,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceM),
              decoration: BoxDecoration(
                color: AppColors.searchBackground,
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              child: Icon(
                isCloud ? AppIcons.cloudQueue : AppIcons.backupDatabase,
                color: AppColors.textPrimary,
                size: AppDimensions.iconLarge,
              ),
            ),
            const SizedBox(width: AppDimensions.spaceL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اسم الملف وشارة النوع
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          backup.fileName,
                          style: const TextStyle(
                            fontSize: AppTypography.sizeBody,
                            fontWeight: AppTypography.weightSemiBold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: AppDimensions.paddingMiniTag,
                        decoration: BoxDecoration(
                          color: AppColors.chipBackground,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusXS),
                          border: Border.all(
                            color: AppColors.borderLight,
                            width: AppDimensions.borderWidthThin,
                          ),
                        ),
                        child: Text(
                          backup.typeBadge,
                          style: const TextStyle(
                            fontSize: AppTypography.sizeMicro,
                            fontWeight: AppTypography.weightSemiBold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceXS),

                  // التاريخ والحجم
                  Row(
                    children: [
                      Text(
                        backup.formattedDate,
                        style: const TextStyle(
                          fontSize: AppTypography.sizeCaption,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceL),
                      Text(
                        backup.formattedSize,
                        style: const TextStyle(
                          fontSize: AppTypography.sizeCaption,
                          fontWeight: AppTypography.weightMedium,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceL),

                  // أزرار الإجراءات السريعة (استعادة، مشاركة، حذف)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // زر استعادة
                      _buildActionButton(
                        icon: AppIcons.restore,
                        label: AppStrings.restore,
                        color: AppColors.primary,
                        onTap: () => _restoreBackup(backup),
                      ),
                      const SizedBox(width: AppDimensions.spaceM),
                      // زر مشاركة
                      _buildActionButton(
                        icon: AppIcons.share,
                        label: AppStrings.share,
                        color: AppColors.textSecondary,
                        onTap: () => _shareBackup(backup),
                      ),
                      const SizedBox(width: AppDimensions.spaceM),
                      // زر حذف
                      _buildActionButton(
                        icon: AppIcons.delete,
                        label: AppStrings.delete,
                        color: AppColors.dispenseRed,
                        onTap: () => _deleteBackup(backup),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceM,
          vertical: AppDimensions.spaceXS,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppDimensions.iconSmall, color: color),
            const SizedBox(width: AppDimensions.spaceXS),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.sizeCaption,
                fontWeight: AppTypography.weightSemiBold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
