import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/messaging_controller.dart';
import '../../models/transaction_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_icons.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import 'app_snackbar.dart';

/// نافذة سفلية منبثقة (Modal Bottom Sheet) لمعاينة وإرسال إشعار العملية بنمط خفيف ومطابق للمرجع
class OperationMessagePreviewDialog extends StatefulWidget {
  final TransactionPreparedMessages preparedMessages;
  final TransactionModel transaction;

  const OperationMessagePreviewDialog({
    super.key,
    required this.preparedMessages,
    required this.transaction,
  });

  /// فتح النافذة المنبثقة السفلية
  static Future<void> show({
    required BuildContext context,
    required TransactionPreparedMessages preparedMessages,
    required TransactionModel transaction,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.overlay,
      builder: (ctx) => OperationMessagePreviewDialog(
        preparedMessages: preparedMessages,
        transaction: transaction,
      ),
    );
  }

  @override
  State<OperationMessagePreviewDialog> createState() =>
      _OperationMessagePreviewDialogState();
}

class _OperationMessagePreviewDialogState
    extends State<OperationMessagePreviewDialog> {
  late TextEditingController _beneficiaryMsgController;
  late TextEditingController _stationMsgController;

  bool _sendToBeneficiary = true;
  bool _sendToStation = true;

  @override
  void initState() {
    super.initState();
    _beneficiaryMsgController = TextEditingController(
      text: widget.preparedMessages.beneficiaryMessage ?? '',
    );
    _stationMsgController = TextEditingController(
      text: widget.preparedMessages.stationMessage ?? '',
    );
  }

  @override
  void dispose() {
    _beneficiaryMsgController.dispose();
    _stationMsgController.dispose();
    super.dispose();
  }

  Future<void> _handleExecute() async {
    final controller = context.read<MessagingController>();
    final hasBeneficiary = widget.preparedMessages.beneficiaryMessage != null &&
        widget.preparedMessages.beneficiaryMessage!.isNotEmpty;
    final hasStation = widget.preparedMessages.stationMessage != null &&
        widget.preparedMessages.stationMessage!.isNotEmpty;

    final sendBeneficiary = _sendToBeneficiary && hasBeneficiary;
    final sendStation = _sendToStation && hasStation;

    if (!sendBeneficiary && !sendStation) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pop();

    if (sendBeneficiary) {
      final phone = widget.preparedMessages.beneficiaryPhone;
      final message = _beneficiaryMsgController.text.trim();
      if (phone != null && phone.trim().isNotEmpty && message.isNotEmpty) {
        final success = await controller.sendSms(phone: phone, message: message);
        if (!success && mounted) {
          AppSnackBar.showError(context, AppStrings.sendFailed);
        }
      }
    }

    if (sendStation) {
      final phone = widget.preparedMessages.stationPhone;
      final message = _stationMsgController.text.trim();
      if (phone != null && phone.trim().isNotEmpty && message.isNotEmpty) {
        final success = await controller.sendSms(phone: phone, message: message);
        if (!success && mounted) {
          AppSnackBar.showError(context, AppStrings.sendFailed);
        }
      }
    }
  }

  Widget _buildCard({
    required String sectionLabel,
    required String partyName,
    required IconData partyIcon,
    required String? phone,
    required TextEditingController controller,
    required bool isChecked,
    required ValueChanged<bool?> onCheckChanged,
  }) {
    final hasPhone = phone != null && phone.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // السطر التعريفي فوق البطاقة (الطرف + رقم الهاتف + نوع الإشعار)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // الطرف (الأيقونة + الاسم + رقم الهاتف بخط أصغر ولون ثانوي + زر التحديد)
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: isChecked,
                    activeColor: AppColors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: onCheckChanged,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    partyIcon,
                    size: 17,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      partyName,
                      style: const TextStyle(
                        fontSize: AppTypography.sizeBody,
                        fontWeight: AppTypography.weightBold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasPhone) ...[
                    const SizedBox(width: 6),
                    Text(
                      phone,
                      style: const TextStyle(
                        fontSize: AppTypography.sizeCaption,
                        fontWeight: AppTypography.weightMedium,
                        color: AppColors.textSecondary,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spaceS),
            // عنوان العملية / الإشعار
            Text(
              sectionLabel,
              style: const TextStyle(
                fontSize: AppTypography.sizeCaption,
                color: AppColors.textTertiary,
                fontWeight: AppTypography.weightMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // الصندوق الأبيض ذو الإطار الدائري الخفيف (بدون رقم الهاتف بداخله)
        Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.spaceM),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceL,
            vertical: AppDimensions.spaceM,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isChecked ? AppColors.textPrimary : AppColors.borderLight,
              width: 1.2,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: null,
            style: const TextStyle(
              fontSize: AppTypography.sizeBodySecondary,
              color: AppColors.textPrimary,
              height: 1.45,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasBeneficiary = widget.preparedMessages.beneficiaryMessage != null &&
        widget.preparedMessages.beneficiaryMessage!.isNotEmpty;
    final hasStation = widget.preparedMessages.stationMessage != null &&
        widget.preparedMessages.stationMessage!.isNotEmpty;

    final operationTitle =
        widget.transaction.typeName ?? AppStrings.operation;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top: AppDimensions.spaceM,
        bottom: AppDimensions.spaceXL + MediaQuery.of(context).viewInsets.bottom,
        left: AppDimensions.spaceXL,
        right: AppDimensions.spaceXL,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // الرأس العلوي مع عنوان العملية في البداية وزر الإغلاق X في اليسار
          Row(
            children: [
              Expanded(
                child: Text(
                  operationTitle,
                  style: const TextStyle(
                    fontSize: AppTypography.sizeH2,
                    fontWeight: AppTypography.weightBold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  AppIcons.closeRounded,
                  color: AppColors.textTertiary,
                  size: AppDimensions.iconMedium,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: AppDimensions.space4XL,
                  minHeight: AppDimensions.space4XL,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),

          // المحتوى القابل للتمرير
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (hasBeneficiary)
                    _buildCard(
                      sectionLabel: AppStrings.beneficiaryNotice,
                      partyName: widget.transaction.accountName ?? '',
                      partyIcon: AppIcons.account,
                      phone: widget.preparedMessages.beneficiaryPhone,
                      controller: _beneficiaryMsgController,
                      isChecked: _sendToBeneficiary,
                      onCheckChanged: (val) {
                        setState(() => _sendToBeneficiary = val ?? false);
                      },
                    ),
                  if (hasStation)
                    _buildCard(
                      sectionLabel: AppStrings.stationOrder,
                      partyName: widget.transaction.stationName ?? '',
                      partyIcon: AppIcons.gasStation,
                      phone: widget.preparedMessages.stationPhone,
                      controller: _stationMsgController,
                      isChecked: _sendToStation,
                      onCheckChanged: (val) {
                        setState(() => _sendToStation = val ?? false);
                      },
                    ),
                ],
              ),
            ),
          ),

          // السطر التنبيهي النصي بلون البرنامج الأساسي
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              AppStrings.verifyMessageNotice,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTypography.sizeCaption,
                fontWeight: AppTypography.weightBold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),

          // زرا الإجراءات السفلية: تنفيذ في اليمين، وإلغاء في اليسار
          Row(
            children: [
              // زر تنفيذ (في اليمين بلون البرنامج الأساسي)
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _handleExecute,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      AppStrings.execute,
                      style: TextStyle(
                        fontSize: AppTypography.sizeBody,
                        fontWeight: AppTypography.weightBold,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),

              // زر إلغاء (في اليسار بإطار خفيف)
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.textPrimary.withOpacity(0.6),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: AppColors.surface,
                    ),
                    child: const Text(
                      AppStrings.cancel,
                      style: TextStyle(
                        fontSize: AppTypography.sizeBody,
                        fontWeight: AppTypography.weightBold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
