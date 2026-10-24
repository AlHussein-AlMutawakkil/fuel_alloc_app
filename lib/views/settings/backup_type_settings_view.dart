import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/backup_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/one_ui_card.dart';
import '../../models/backup_model.dart';

/// شاشة تحديد نوع النسخة الاحتياطية بنمط One UI
class BackupTypeSettingsView extends StatefulWidget {
  const BackupTypeSettingsView({super.key});

  @override
  State<BackupTypeSettingsView> createState() => _BackupTypeSettingsViewState();
}

class _BackupTypeSettingsViewState extends State<BackupTypeSettingsView> {
  late BackupType _selectedType;
  late IncrementalFrequency _incrementalFreq;
  late int _customDays;
  late bool _forceNext;

  @override
  void initState() {
    super.initState();
    final controller = context.read<BackupController>();
    _selectedType = controller.backupType;
    _incrementalFreq = controller.incrementalFrequency;
    _customDays = controller.incrementalCustomDays;
    _forceNext = controller.forceFullBackupNextRun;
  }

  void _onSave() {
    final controller = context.read<BackupController>();
    controller.setBackupType(_selectedType);
    if (_selectedType == BackupType.incremental) {
      controller.setIncrementalOptions(
        frequency: _incrementalFreq,
        customDays: _customDays,
        forceNext: _forceNext,
      );
    }
    AppSnackBar.showSuccess(context, AppStrings.settingsSavedSuccess);
    Navigator.of(context).pop();
  }

  void _showCustomDaysDialog() async {
    int tempDays = _customDays;
    final confirmed = await CustomDialog.showCustomContent(
      context: context,
      title: AppStrings.customDaysDialogTitle,
      content: StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                AppStrings.customDaysTitle,
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
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    child: Text(
                      '$tempDays ${AppStrings.customDaysSuffix}',
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
                    onPressed: tempDays < 90
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
      setState(() => _customDays = tempDays);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const OneUiAppBar(
        title: AppStrings.backupType,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(
                top: AppDimensions.spaceS,
                bottom: AppDimensions.spaceXL,
              ),
              children: [
                // نص توجيهي رمادي خفيف في الأعلى
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.space2XL,
                    vertical: AppDimensions.spaceM,
                  ),
                  child: Text(
                    AppStrings.backupTypeSubtitle,
                    style: TextStyle(
                      fontSize: AppTypography.sizeBodySecondary,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),

                // بطاقة الخيارات الرئيسية بنمط One UI
                OneUiCard(
                  children: [
                    // 1. النسخ الاحتياطية الكاملة
                    OneUiSelectionTile(
                      title: AppStrings.backupFullTitle,
                      subtitle: AppStrings.backupFullDesc,
                      isSelected: _selectedType == BackupType.full,
                      selectionType: SelectionTileType.checkmark,
                      onTap: () {
                        setState(() => _selectedType = BackupType.full);
                      },
                    ),

                    // 2. وضع الأرشيف
                    OneUiSelectionTile(
                      title: AppStrings.backupArchiveTitle,
                      subtitle: AppStrings.backupArchiveDesc,
                      isSelected: _selectedType == BackupType.archive,
                      selectionType: SelectionTileType.checkmark,
                      onTap: () {
                        setState(() => _selectedType = BackupType.archive);
                      },
                    ),

                    // 3. النسخ الاحتياطية التزايدية
                    OneUiSelectionTile(
                      title: AppStrings.backupIncrementalTitle,
                      subtitle: AppStrings.backupIncrementalDesc,
                      isSelected: _selectedType == BackupType.incremental,
                      selectionType: SelectionTileType.checkmark,
                      onTap: () {
                        setState(() => _selectedType = BackupType.incremental);
                      },
                    ),
                  ],
                ),

                // الخيارات التابعة للنسخ التزايدي (تظهر عند اختياره)
                if (_selectedType == BackupType.incremental) ...[
                  const SizedBox(height: AppDimensions.spaceM),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.space2XL,
                      vertical: AppDimensions.spaceXS,
                    ),
                    child: Text(
                      AppStrings.createFullBackupNew,
                      style: TextStyle(
                        fontSize: AppTypography.sizeBody,
                        fontWeight: AppTypography.weightSemiBold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  OneUiCard(
                    children: [
                      // خيار بعد كل 7 أيام مع رابط التخصيص
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(
                              () => _incrementalFreq = IncrementalFrequency.days7,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.space2XL,
                              vertical: AppDimensions.spaceL,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        _customDays == 7
                                            ? AppStrings.every7Days
                                            : '${AppStrings.repeatDaysPrefix}$_customDays ${AppStrings.days}',
                                        style: const TextStyle(
                                          fontSize: AppTypography.sizeBody,
                                          fontWeight: AppTypography.weightMedium,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: AppDimensions.spaceM),
                                      GestureDetector(
                                        onTap: _showCustomDaysDialog,
                                        child: const Text(
                                          AppStrings.chooseDays,
                                          style: TextStyle(
                                            fontSize: AppTypography.sizeCaption,
                                            fontWeight: AppTypography.weightSemiBold,
                                            color: AppColors.infoText,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  _incrementalFreq == IncrementalFrequency.days7
                                      ? AppIcons.radioChecked
                                      : AppIcons.radioUnchecked,
                                  color: _incrementalFreq ==
                                          IncrementalFrequency.days7
                                      ? AppColors.charcoal
                                      : AppColors.border,
                                  size: AppDimensions.iconMedium + 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // خيار كل شهر
                      OneUiSelectionTile(
                        title: AppStrings.everyMonth,
                        isSelected:
                            _incrementalFreq == IncrementalFrequency.monthly,
                        selectionType: SelectionTileType.radio,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space2XL,
                          vertical: AppDimensions.spaceL,
                        ),
                        onTap: () {
                          setState(
                            () => _incrementalFreq = IncrementalFrequency.monthly,
                          );
                        },
                      ),

                      // خيار Checkbox: فرض نسخة احتياطية كاملة في تشغيل النسخ التالي
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => _forceNext = !_forceNext),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.space2XL,
                              vertical: AppDimensions.spaceL,
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    AppStrings.forceFullBackupNextRun,
                                    style: TextStyle(
                                      fontSize: AppTypography.sizeBodySecondary,
                                      fontWeight: AppTypography.weightRegular,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Icon(
                                  _forceNext
                                      ? AppIcons.checkboxChecked
                                      : AppIcons.checkboxUnchecked,
                                  color: _forceNext
                                      ? AppColors.charcoal
                                      : AppColors.border,
                                  size: AppDimensions.iconLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // الأزرار السفلية (حفظ بالداكن + إلغاء بالرمادي الفاتح)
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
