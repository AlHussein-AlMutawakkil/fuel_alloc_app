import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/messaging_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_switch.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/one_ui_card.dart';
import '../../models/message_template_model.dart';

/// شاشة إعدادات الرسائل النصية والقوالب بنمط Samsung One UI
class MessageSettingsView extends StatelessWidget {
  const MessageSettingsView({super.key});

  void _openTemplateEditor(
      BuildContext context, MessageTemplateModel template) {
    final textController = TextEditingController(text: template.content);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: AppDimensions.spaceXL,
                right: AppDimensions.spaceXL,
                top: AppDimensions.spaceXL,
                bottom: MediaQuery.of(ctx).viewInsets.bottom +
                    AppDimensions.spaceXL,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusCard),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // مقبض السحب العلوي
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

                    // عنوان النافذة
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppDimensions.spaceS),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: AppDimensions.borderRadiusM,
                          ),
                          child: const Icon(
                            AppIcons.template,
                            color: AppColors.primary,
                            size: AppDimensions.iconMedium,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                template.title,
                                style: const TextStyle(
                                  fontSize: AppTypography.sizeH2,
                                  fontWeight: AppTypography.weightBold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                AppStrings.editTemplateTitle,
                                style: TextStyle(
                                  fontSize: AppTypography.sizeCaption,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(AppIcons.closeRounded),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceL),

                    // حقل نص القالب
                    CustomTextField(
                      label: AppStrings.templateContentLabel,
                      controller: textController,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      onChanged: (_) => setSheetState(() {}),
                    ),
                    const SizedBox(height: AppDimensions.spaceL),

                    // عنوان المتغيرات
                    const Text(
                      AppStrings.availableVariables,
                      style: TextStyle(
                        fontSize: AppTypography.sizeBody,
                        fontWeight: AppTypography.weightBold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceS),

                    // رقائق المتغيرات التفاعلية
                    Wrap(
                      spacing: AppDimensions.spaceS,
                      runSpacing: AppDimensions.spaceS,
                      children: MessageTemplateModel.supportedPlaceholders
                          .map((placeholder) {
                        return ActionChip(
                          backgroundColor:
                              AppColors.primary.withOpacity(0.08),
                          label: Text(
                            '+ ${placeholder.arabicTag}',
                            style: const TextStyle(
                              fontSize: AppTypography.sizeCaption,
                              color: AppColors.primary,
                              fontWeight: AppTypography.weightMedium,
                            ),
                          ),
                          side: BorderSide(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppDimensions.borderRadiusFull,
                          ),
                          onPressed: () {
                            final currentText = textController.text;
                            final selection = textController.selection;
                            final tagToInsert = placeholder.arabicTag;

                            if (selection.isValid && selection.start >= 0) {
                              final newText = currentText.replaceRange(
                                selection.start,
                                selection.end,
                                tagToInsert,
                              );
                              textController.value = TextEditingValue(
                                text: newText,
                                selection: TextSelection.collapsed(
                                  offset: selection.start + tagToInsert.length,
                                ),
                              );
                            } else {
                              textController.text =
                                  '$currentText $tagToInsert';
                              textController.selection =
                                  TextSelection.collapsed(
                                offset: textController.text.length,
                              );
                            }
                            setSheetState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppDimensions.space2XL),

                    // أزرار الحفظ والإلغاء
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: AppStrings.save,
                            variant: ButtonVariant.primary,
                            onPressed: () async {
                              final controller =
                                  context.read<MessagingController>();
                              final ok = await controller.updateTemplate(
                                template.key,
                                textController.text.trim(),
                              );
                              if (ok && context.mounted) {
                                Navigator.pop(sheetContext);
                                AppSnackBar.showSuccess(
                                  context,
                                  AppStrings.templateUpdatedSuccess,
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceM),
                        Expanded(
                          child: CustomButton(
                            text: AppStrings.cancel,
                            variant: ButtonVariant.secondary,
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showResetConfirmDialog(BuildContext context) async {
    final confirmed = await CustomDialog.showConfirmation(
      context: context,
      title: AppStrings.resetTemplates,
      message: AppStrings.resetTemplatesConfirm,
      confirmText: AppStrings.restore,
      cancelText: AppStrings.cancel,
      isDanger: true,
    );

    if (confirmed && context.mounted) {
      final controller = context.read<MessagingController>();
      final ok = await controller.resetTemplatesToDefault();
      if (ok && context.mounted) {
        AppSnackBar.showSuccess(
          context,
          AppStrings.templatesResetSuccess,
        );
      }
    }
  }

  void _showChannelSelector(
      BuildContext context, MessagingController controller) {
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
              AppStrings.preferredChannelTitle,
              style: TextStyle(
                fontSize: AppTypography.sizeH2,
                fontWeight: AppTypography.weightBold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceXL),
            OneUiCard(
              children: [
                OneUiTile(
                  leading: const Icon(
                    AppIcons.sms,
                    color: AppColors.textPrimary,
                    size: AppDimensions.iconMedium,
                  ),
                  title: AppStrings.channelSms,
                  trailing: controller.defaultChannel == 'sms'
                      ? const Icon(
                          AppIcons.check,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () {
                    controller.setDefaultChannel('sms');
                    Navigator.pop(ctx);
                  },
                ),
                OneUiTile(
                  leading: const Icon(
                    AppIcons.whatsapp,
                    color: AppColors.supplyGreen,
                    size: AppDimensions.iconMedium,
                  ),
                  title: AppStrings.channelWhatsApp,
                  trailing: controller.defaultChannel == 'whatsapp'
                      ? const Icon(
                          AppIcons.check,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () {
                    controller.setDefaultChannel('whatsapp');
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MessagingController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                AppIcons.back,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              AppStrings.messageSettingsTitle,
              style: TextStyle(
                fontSize: AppTypography.sizeH2,
                fontWeight: AppTypography.weightBold,
                color: AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceL,
              vertical: AppDimensions.spaceL,
            ),
            children: [
              // كرت إعدادات الإرسال العامة
              OneUiCard(
                children: [
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.message,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.enableMessagingTitle,
                    subtitle: AppStrings.enableMessagingDesc,
                    trailing: AppSwitch(
                      value: controller.isMessagingEnabled,
                      onChanged: (val) =>
                          controller.setMessagingEnabled(val),
                    ),
                  ),
                  OneUiTile(
                    leading: Icon(
                      controller.defaultChannel == 'whatsapp'
                          ? AppIcons.whatsapp
                          : AppIcons.sms,
                      color: controller.defaultChannel == 'whatsapp'
                          ? AppColors.supplyGreen
                          : AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.preferredChannelTitle,
                    valueText: controller.defaultChannel == 'whatsapp'
                        ? AppStrings.channelWhatsApp
                        : AppStrings.channelSms,
                    onTap: () => _showChannelSelector(context, controller),
                  ),
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.preview,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.autoPreviewTitle,
                    subtitle: AppStrings.autoPreviewDesc,
                    trailing: AppSwitch(
                      value: controller.autoPreviewEnabled,
                      onChanged: (val) =>
                          controller.setAutoPreviewEnabled(val),
                    ),
                  ),
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.gasStation,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.defaultNotifyStationTitle,
                    subtitle: AppStrings.defaultNotifyStationDesc,
                    trailing: AppSwitch(
                      value: controller.notifyStationDefault,
                      onChanged: (val) =>
                          controller.setNotifyStationDefault(val),
                    ),
                  ),
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.account,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.defaultNotifyAccountTitle,
                    subtitle: AppStrings.defaultNotifyAccountDesc,
                    trailing: AppSwitch(
                      value: controller.notifyAccountDefault,
                      onChanged: (val) =>
                          controller.setNotifyAccountDefault(val),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.spaceL),

              // عنوان قسم القوالب
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceM,
                  vertical: AppDimensions.spaceS,
                ),
                child: Text(
                  AppStrings.messageTemplatesSection,
                  style: TextStyle(
                    fontSize: AppTypography.sizeH2,
                    fontWeight: AppTypography.weightBold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              // كرت القوالب الديناميكية
              OneUiCard(
                children: controller.templates.map((tpl) {
                  return OneUiTile(
                    leading: const Icon(
                      AppIcons.template,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: tpl.title,
                    subtitle: tpl.content.replaceAll('\n', ' '),
                    onTap: () => _openTemplateEditor(context, tpl),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppDimensions.spaceL),

              // كرت إجراءات الاستعادة
              OneUiCard(
                children: [
                  OneUiTile(
                    leading: const Icon(
                      AppIcons.restore,
                      color: AppColors.dispenseRed,
                      size: AppDimensions.iconMedium + 2,
                    ),
                    title: AppStrings.resetTemplates,
                    onTap: () => _showResetConfirmDialog(context),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.space3XL),
            ],
          ),
        );
      },
    );
  }
}
