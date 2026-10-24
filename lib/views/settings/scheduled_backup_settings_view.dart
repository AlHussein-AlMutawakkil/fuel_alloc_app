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

/// شاشة إعدادات النسخ الاحتياطي المجدول بنمط One UI
class ScheduledBackupSettingsView extends StatefulWidget {
  const ScheduledBackupSettingsView({super.key});

  @override
  State<ScheduledBackupSettingsView> createState() =>
      _ScheduledBackupSettingsViewState();
}

class _ScheduledBackupSettingsViewState
    extends State<ScheduledBackupSettingsView> {
  late bool _isScheduleEnabled;
  late ScheduleFrequency _frequency;
  late TimeOfDay _dailyTime;
  late int _repeatDays;
  late bool _disableNotifications;
  bool _showAdvanced = true;

  @override
  void initState() {
    super.initState();
    final controller = context.read<BackupController>();
    _isScheduleEnabled = controller.isScheduleEnabled;
    _frequency = controller.scheduleFrequency;
    _dailyTime = controller.dailyTime;
    _repeatDays = controller.dailyRepeatDays;
    _disableNotifications = controller.disableNotifications;
  }

  void _onSave() {
    final controller = context.read<BackupController>();
    controller.toggleSchedule(_isScheduleEnabled);
    controller.setScheduleFrequency(_frequency);
    controller.setDailyTime(_dailyTime);
    controller.setDailyRepeatDays(_repeatDays);
    controller.toggleNotifications(_disableNotifications);

    AppSnackBar.showSuccess(context, AppStrings.settingsSavedSuccess);
    Navigator.of(context).pop();
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dailyTime,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.charcoal,
              onPrimary: AppColors.textWhite,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox(),
          ),
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _dailyTime = picked);
    }
  }

  void _pickRepeatDays() async {
    int tempDays = _repeatDays;
    final confirmed = await CustomDialog.showCustomContent(
      context: context,
      title: AppStrings.customDaysDialogTitle,
      content: StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                AppStrings.repeatDaily,
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
                      tempDays == 1
                          ? AppStrings.repeatDaily
                          : '${AppStrings.repeatDaysPrefix}$tempDays ${AppStrings.days}',
                      style: const TextStyle(
                        fontSize: AppTypography.sizeBody,
                        fontWeight: AppTypography.weightBold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.addCircleOutline),
                    color: AppColors.charcoal,
                    onPressed: tempDays < 30
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

    if (confirmed == true && mounted) {
      setState(() => _repeatDays = tempDays);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? AppStrings.pmSuffix : AppStrings.amSuffix;
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const OneUiAppBar(
        title: AppStrings.scheduledBackupTitle,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spaceL,
              ),
              children: [
                // البطاقة الأولى: مفتاح التفعيل الرئيسي
                OneUiCard(
                  children: [
                    Padding(
                      padding: AppDimensions.paddingTile,
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppStrings.scheduleRecurringBackups,
                                  style: TextStyle(
                                    fontSize: AppTypography.sizeH2,
                                    fontWeight: AppTypography.weightSemiBold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: AppDimensions.spaceXXS + 1),
                                Text(
                                  AppStrings.keepDataProtectedDesc,
                                  style: TextStyle(
                                    fontSize: AppTypography.sizeCaption,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSwitch(
                            value: _isScheduleEnabled,
                            onChanged: (val) {
                              setState(() => _isScheduleEnabled = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // البطاقة الثانية: خيارات التكرار والوقت
                if (_isScheduleEnabled) ...[
                  OneUiCard(
                    children: [
                      // 1. خيار يوميًا
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() => _frequency = ScheduleFrequency.daily);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.space2XL,
                              vertical: AppDimensions.spaceL,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        AppStrings.daily,
                                        style: TextStyle(
                                          fontSize: AppTypography.sizeH2,
                                          fontWeight:
                                              AppTypography.weightMedium,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      _frequency == ScheduleFrequency.daily
                                          ? AppIcons.radioChecked
                                          : AppIcons.radioUnchecked,
                                      color:
                                          _frequency == ScheduleFrequency.daily
                                              ? AppColors.charcoal
                                              : AppColors.border,
                                      size: AppDimensions.iconMedium + 2,
                                    ),
                                  ],
                                ),

                                // تفاصيل الخيار اليومي (وقت التنفيذ والتكرار)
                                if (_frequency == ScheduleFrequency.daily) ...[
                                  const SizedBox(height: AppDimensions.spaceL),
                                  // سطر الوقت
                                  Row(
                                    children: [
                                      Text(
                                        '${AppStrings.atTimePrefix}${_formatTime(_dailyTime)}',
                                        style: const TextStyle(
                                          fontSize: AppTypography.sizeBodySecondary,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: AppDimensions.spaceL),
                                      GestureDetector(
                                        onTap: _pickTime,
                                        child: const Text(
                                          AppStrings.change,
                                          style: TextStyle(
                                            fontSize: AppTypography.sizeCaption,
                                            fontWeight:
                                                AppTypography.weightSemiBold,
                                            color: AppColors.infoText,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppDimensions.spaceM),
                                  // سطر تكرار الأيام
                                  Row(
                                    children: [
                                      Text(
                                        _repeatDays == 1
                                            ? AppStrings.repeatDaily
                                            : '${AppStrings.repeatDaysPrefix}$_repeatDays ${AppStrings.days}',
                                        style: const TextStyle(
                                          fontSize: AppTypography.sizeBodySecondary,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: AppDimensions.spaceL),
                                      GestureDetector(
                                        onTap: _pickRepeatDays,
                                        child: const Text(
                                          AppStrings.change,
                                          style: TextStyle(
                                            fontSize: AppTypography.sizeCaption,
                                            fontWeight:
                                                AppTypography.weightSemiBold,
                                            color: AppColors.infoText,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 2. خيار أسبوعيًا
                      OneUiSelectionTile(
                        title: AppStrings.weekly,
                        isSelected: _frequency == ScheduleFrequency.weekly,
                        selectionType: SelectionTileType.radio,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space2XL,
                          vertical: AppDimensions.spaceL,
                        ),
                        onTap: () {
                          setState(() => _frequency = ScheduleFrequency.weekly);
                        },
                      ),

                      // 3. خيار كل ساعة
                      OneUiSelectionTile(
                        title: AppStrings.hourly,
                        isSelected: _frequency == ScheduleFrequency.hourly,
                        selectionType: SelectionTileType.radio,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space2XL,
                          vertical: AppDimensions.spaceL,
                        ),
                        onTap: () {
                          setState(() => _frequency = ScheduleFrequency.hourly);
                        },
                      ),
                    ],
                  ),

                  // رابط إظهار / إخفاء الخيارات المتقدمة
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space2XL,
                      vertical: AppDimensions.spaceS,
                    ),
                    child: InkWell(
                      onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.spaceS,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _showAdvanced
                                  ? AppStrings.hideAdvancedOptions
                                  : AppStrings.showAdvancedOptions,
                              style: const TextStyle(
                                fontSize: AppTypography.sizeBodySecondary,
                                fontWeight: AppTypography.weightSemiBold,
                                color: AppColors.infoText,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spaceXS),
                            Icon(
                              _showAdvanced
                                  ? AppIcons.expandLess
                                  : AppIcons.expandMore,
                              color: AppColors.infoText,
                              size: AppDimensions.iconRegular,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // البطاقة الثالثة: الخيارات المتقدمة
                  if (_showAdvanced)
                    OneUiCard(
                      children: [
                        Padding(
                          padding: AppDimensions.paddingTile,
                          child: Row(
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      AppStrings.disableNotifications,
                                      style: TextStyle(
                                        fontSize: AppTypography.sizeBody + 1,
                                        fontWeight:
                                            AppTypography.weightSemiBold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: AppDimensions.spaceXXS + 1),
                                    Text(
                                      AppStrings.disableNotificationsDesc,
                                      style: TextStyle(
                                        fontSize: AppTypography.sizeCaption,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AppSwitch(
                                value: _disableNotifications,
                                onChanged: (val) {
                                  setState(() => _disableNotifications = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),

          // الأزرار السفلية
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
