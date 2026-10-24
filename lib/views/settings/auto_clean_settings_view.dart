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
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/one_ui_card.dart';
import '../../models/backup_model.dart';

/// شاشة إعدادات التنظيف التلقائي بنمط One UI مطابقة للمواصفات القياسية
class AutoCleanSettingsView extends StatefulWidget {
  const AutoCleanSettingsView({super.key});

  @override
  State<AutoCleanSettingsView> createState() => _AutoCleanSettingsViewState();
}

class _AutoCleanSettingsViewState extends State<AutoCleanSettingsView> {
  late bool _deleteBeforeLastFull;
  late RetentionPolicy _localPolicy;
  late int _localDays;
  late int _localCount;
  late bool _keepLatestLocalCopy;
  late bool _deleteUnuploadedBackups;

  late RetentionPolicy _cloudPolicy;
  late int _cloudDays;
  late int _cloudCount;
  late bool _cloudPermanentDelete;

  bool _isLocalExpanded = true;
  bool _isDriveExpanded = true;

  @override
  void initState() {
    super.initState();
    final controller = context.read<BackupController>();
    _deleteBeforeLastFull = controller.deleteBeforeLastFull;
    _localPolicy = controller.localRetentionPolicy;
    _localDays = controller.localRetentionDays;
    _localCount = controller.localRetentionCount;
    _keepLatestLocalCopy = controller.keepLatestLocalCopy;
    _deleteUnuploadedBackups = controller.deleteUnuploadedBackups;

    _cloudPolicy = controller.cloudRetentionPolicy;
    _cloudDays = controller.cloudRetentionDays;
    _cloudCount = controller.cloudRetentionCount;
    _cloudPermanentDelete = controller.cloudPermanentDelete;
  }

  void _onSave() {
    final controller = context.read<BackupController>();
    controller.setAutoCleanSettings(
      deleteBeforeLastFull: _deleteBeforeLastFull,
      localPolicy: _localPolicy,
      localDays: _localDays,
      localCount: _localCount,
      keepLatestLocalCopy: _keepLatestLocalCopy,
      deleteUnuploadedBackups: _deleteUnuploadedBackups,
      cloudPolicy: _cloudPolicy,
      cloudDays: _cloudDays,
      cloudCount: _cloudCount,
      cloudPermanentDelete: _cloudPermanentDelete,
    );

    AppSnackBar.showSuccess(context, AppStrings.settingsSavedSuccess);
    Navigator.of(context).pop();
  }

  void _showDaysDialog({required bool isCloud}) async {
    int tempDays = isCloud ? _cloudDays : _localDays;
    final confirmed = await CustomDialog.showCustomContent(
      context: context,
      title: AppStrings.customDaysDialogTitle,
      content: StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                AppStrings.keepForDays,
                style: TextStyle(
                  fontSize: AppTypography.sizeBodySecondary,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceL),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(AppIcons.removeCircleOutline),
                    color: AppColors.charcoal,
                    onPressed: tempDays > 1
                        ? () => setDialogState(() => tempDays--)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceXL,
                      vertical: AppDimensions.spaceS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.searchBackground,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    child: Text(
                      '$tempDays ${AppStrings.keepForDaysCountUnit}',
                      style: const TextStyle(
                        fontSize: AppTypography.sizeH2,
                        fontWeight: AppTypography.weightBold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.addCircleOutline),
                    color: AppColors.charcoal,
                    onPressed: tempDays < 365
                        ? () => setDialogState(() => tempDays++)
                        : null,
                  ),
                ],
              ),
            ],
          );
        },
      ),
      confirmText: AppStrings.confirm,
      cancelText: AppStrings.cancel,
    );

    if (confirmed && mounted) {
      setState(() {
        if (isCloud) {
          _cloudDays = tempDays;
        } else {
          _localDays = tempDays;
        }
      });
    }
  }

  void _showCountDialog({required bool isCloud}) async {
    int tempCount = isCloud ? _cloudCount : _localCount;
    final confirmed = await CustomDialog.showCustomContent(
      context: context,
      title: AppStrings.keepLastCount,
      content: StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                AppStrings.keepLastCount,
                style: TextStyle(
                  fontSize: AppTypography.sizeBodySecondary,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceL),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(AppIcons.removeCircleOutline),
                    color: AppColors.charcoal,
                    onPressed: tempCount > 1
                        ? () => setDialogState(() => tempCount--)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceXL,
                      vertical: AppDimensions.spaceS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.searchBackground,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    child: Text(
                      '$tempCount ${AppStrings.keepLastCountUnit}',
                      style: const TextStyle(
                        fontSize: AppTypography.sizeH2,
                        fontWeight: AppTypography.weightBold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.addCircleOutline),
                    color: AppColors.charcoal,
                    onPressed: tempCount < 100
                        ? () => setDialogState(() => tempCount++)
                        : null,
                  ),
                ],
              ),
            ],
          );
        },
      ),
      confirmText: AppStrings.confirm,
      cancelText: AppStrings.cancel,
    );

    if (confirmed && mounted) {
      setState(() {
        if (isCloud) {
          _cloudCount = tempCount;
        } else {
          _localCount = tempCount;
        }
      });
    }
  }

  Widget _buildRetentionTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onSelect,
    VoidCallback? onEdit,
    String? editBadge,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onSelect();
          if (onEdit != null && isSelected) {
            onEdit();
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space2XL,
            vertical: AppDimensions.spaceL,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: AppTypography.sizeBody + 1,
                        fontWeight: isSelected
                            ? AppTypography.weightSemiBold
                            : AppTypography.weightMedium,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: AppDimensions.spaceXXS),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: AppTypography.sizeCaption,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (editBadge != null) ...[
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceM,
                      vertical: AppDimensions.spaceXXS + 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.searchBackground,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                      border: Border.all(
                        color: isSelected ? AppColors.charcoal : AppColors.borderLight,
                        width: AppDimensions.borderWidthThin,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          editBadge,
                          style: TextStyle(
                            fontSize: AppTypography.sizeCaption,
                            fontWeight: AppTypography.weightSemiBold,
                            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceXS),
                        Icon(
                          AppIcons.edit,
                          size: AppDimensions.iconSmall,
                          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceM),
              ],
              Icon(
                isSelected ? AppIcons.radioChecked : AppIcons.radioUnchecked,
                color: isSelected ? AppColors.charcoal : AppColors.border,
                size: AppDimensions.iconMedium + 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const OneUiAppBar(
        title: AppStrings.autoCleanTitle,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spaceL,
              ),
              children: [
                // النص التوجيهي العلوي
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.space2XL,
                    vertical: AppDimensions.spaceS,
                  ),
                  child: Text(
                    AppStrings.autoCleanSubtitle,
                    style: TextStyle(
                      fontSize: AppTypography.sizeBodySecondary,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),

                // 1. قسم النسخ الاحتياطية التزايدية
                OneUiCard(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppDimensions.space2XL,
                        AppDimensions.spaceL,
                        AppDimensions.space2XL,
                        AppDimensions.spaceXS,
                      ),
                      child: Text(
                        AppStrings.incrementalBackupsHeader,
                        style: TextStyle(
                          fontSize: AppTypography.sizeBodySecondary,
                          fontWeight: AppTypography.weightSemiBold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    OneUiTile(
                      title: AppStrings.deleteBeforeLastFull,
                      subtitle: AppStrings.deleteBeforeLastFullDesc,
                      trailing: AppSwitch(
                        value: _deleteBeforeLastFull,
                        onChanged: (val) {
                          setState(() => _deleteBeforeLastFull = val);
                        },
                      ),
                    ),
                  ],
                ),

                // 2. قسم نسخة احتياطية محلية
                OneUiCard(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _isLocalExpanded = !_isLocalExpanded),
                      child: Padding(
                        padding: AppDimensions.paddingTile,
                        child: Row(
                          children: [
                            Icon(
                              _isLocalExpanded
                                  ? AppIcons.expandLess
                                  : AppIcons.expandMore,
                              color: AppColors.textPrimary,
                              size: AppDimensions.iconRegular,
                            ),
                            const SizedBox(width: AppDimensions.spaceM),
                            const Expanded(
                              child: Text(
                                AppStrings.localBackupSection,
                                style: TextStyle(
                                  fontSize: AppTypography.sizeBody + 1,
                                  fontWeight: AppTypography.weightBold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isLocalExpanded) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.space2XL,
                        ),
                        child: Text(
                          AppStrings.localBackupCleanDesc,
                          style: TextStyle(
                            fontSize: AppTypography.sizeCaption,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceS),

                      // خيار عدم الحذف
                      _buildRetentionTile(
                        title: AppStrings.noDeletion,
                        subtitle: '',
                        isSelected: _localPolicy == RetentionPolicy.none,
                        onSelect: () => setState(() => _localPolicy = RetentionPolicy.none),
                      ),

                      // خيار الاحتفاظ بعدد من الأيام
                      _buildRetentionTile(
                        title: AppStrings.keepForDays,
                        subtitle: '$_localDays ${AppStrings.keepForDaysCountUnit}',
                        isSelected: _localPolicy == RetentionPolicy.days,
                        editBadge: '$_localDays ${AppStrings.keepForDaysCountUnit}',
                        onSelect: () => setState(() => _localPolicy = RetentionPolicy.days),
                        onEdit: () => _showDaysDialog(isCloud: false),
                      ),

                      // خيار الاحتفاظ بعدد من النسخ الأخيرة
                      _buildRetentionTile(
                        title: AppStrings.keepLastCount,
                        subtitle: '$_localCount ${AppStrings.keepLastCountUnit}',
                        isSelected: _localPolicy == RetentionPolicy.count,
                        editBadge: '$_localCount ${AppStrings.keepLastCountUnit}',
                        onSelect: () => setState(() => _localPolicy = RetentionPolicy.count),
                        onEdit: () => _showCountDialog(isCloud: false),
                      ),

                      const OneUiDivider(),

                      // مفتاح الاحتفاظ بنسخة من أحدث نسخة احتياطية
                      OneUiTile(
                        title: AppStrings.keepLatestLocalCopy,
                        subtitle: AppStrings.keepLatestLocalCopyDesc,
                        trailing: AppSwitch(
                          value: _keepLatestLocalCopy,
                          onChanged: (val) {
                            setState(() => _keepLatestLocalCopy = val);
                          },
                        ),
                      ),

                      // مفتاح حذف النسخ الاحتياطية التي لم ترفع بعد
                      OneUiTile(
                        title: AppStrings.deleteUnuploadedBackups,
                        subtitle: AppStrings.deleteUnuploadedBackupsDesc,
                        trailing: AppSwitch(
                          value: _deleteUnuploadedBackups,
                          onChanged: (val) {
                            setState(() => _deleteUnuploadedBackups = val);
                          },
                        ),
                      ),
                    ],
                  ],
                ),

                // 3. قسم GOOGLE DRIVE
                OneUiCard(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _isDriveExpanded = !_isDriveExpanded),
                      child: Padding(
                        padding: AppDimensions.paddingTile,
                        child: Row(
                          children: [
                            Icon(
                              _isDriveExpanded
                                  ? AppIcons.expandLess
                                  : AppIcons.expandMore,
                              color: AppColors.textPrimary,
                              size: AppDimensions.iconRegular,
                            ),
                            const SizedBox(width: AppDimensions.spaceM),
                            const Expanded(
                              child: Text(
                                AppStrings.googleDriveSection,
                                style: TextStyle(
                                  fontSize: AppTypography.sizeBody + 1,
                                  fontWeight: AppTypography.weightBold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isDriveExpanded) ...[
                      // خيار عدم الحذف
                      _buildRetentionTile(
                        title: AppStrings.noDeletion,
                        subtitle: '',
                        isSelected: _cloudPolicy == RetentionPolicy.none,
                        onSelect: () => setState(() => _cloudPolicy = RetentionPolicy.none),
                      ),

                      // خيار الاحتفاظ بعدد من الأيام
                      _buildRetentionTile(
                        title: AppStrings.keepForDays,
                        subtitle: '$_cloudDays ${AppStrings.keepForDaysCountUnit}',
                        isSelected: _cloudPolicy == RetentionPolicy.days,
                        editBadge: '$_cloudDays ${AppStrings.keepForDaysCountUnit}',
                        onSelect: () => setState(() => _cloudPolicy = RetentionPolicy.days),
                        onEdit: () => _showDaysDialog(isCloud: true),
                      ),

                      // خيار الاحتفاظ بعدد من النسخ الأخيرة
                      _buildRetentionTile(
                        title: AppStrings.keepLastCount,
                        subtitle: '$_cloudCount ${AppStrings.keepLastCountUnit}',
                        isSelected: _cloudPolicy == RetentionPolicy.count,
                        editBadge: '$_cloudCount ${AppStrings.keepLastCountUnit}',
                        onSelect: () => setState(() => _cloudPolicy = RetentionPolicy.count),
                        onEdit: () => _showCountDialog(isCloud: true),
                      ),

                      const OneUiDivider(),

                      // مفتاح حذف نهائي
                      OneUiTile(
                        title: AppStrings.permanentDelete,
                        trailing: AppSwitch(
                          value: _cloudPermanentDelete,
                          onChanged: (val) {
                            setState(() => _cloudPermanentDelete = val);
                          },
                        ),
                      ),
                    ],
                  ],
                ),

                // 4. قسم DROPBOX
                const OneUiCard(
                  children: [
                    OneUiTile(
                      leading: Icon(
                        AppIcons.cloudQueue,
                        color: AppColors.textSecondary,
                        size: AppDimensions.iconMedium + 2,
                      ),
                      title: AppStrings.dropboxSection,
                      subtitle: AppStrings.dropboxComingSoon,
                      valueText: AppStrings.underDevelopment,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // الأزرار السفلية (حفظ + إلغاء)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceXL,
              vertical: AppDimensions.spaceL,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(
                  color: AppColors.borderLight,
                  width: AppDimensions.borderWidthThin,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: AppStrings.save,
                      variant: ButtonVariant.dark,
                      onPressed: _onSave,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceL),
                  Expanded(
                    child: CustomButton(
                      text: AppStrings.cancel,
                      variant: ButtonVariant.neutral,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
