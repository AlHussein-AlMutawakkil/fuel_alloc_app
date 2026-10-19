import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_icons.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../utils/formatters.dart';
import '../../models/transaction_model.dart';

/// نافذة منبثقة موحدة لعرض بيانات العملية بتصميم مطابق للنموذج المعتمد
class TransactionDetailsDialog extends StatelessWidget {
  final TransactionModel transaction;
  final String? accountPhone;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onPermanentDelete;
  final bool isRecycleBin;

  const TransactionDetailsDialog({
    super.key,
    required this.transaction,
    this.accountPhone,
    this.onEdit,
    this.onDelete,
    this.onRestore,
    this.onPermanentDelete,
    this.isRecycleBin = false,
  });

  /// إظهار نافذة بيانات العملية
  static Future<void> show({
    required BuildContext context,
    required TransactionModel transaction,
    String? accountPhone,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onRestore,
    VoidCallback? onPermanentDelete,
    bool isRecycleBin = false,
  }) async {
    await showDialog(
      context: context,
      barrierColor: AppColors.overlay,
      builder: (ctx) => TransactionDetailsDialog(
        transaction: transaction,
        accountPhone: accountPhone,
        onEdit: onEdit,
        onDelete: onDelete,
        onRestore: onRestore,
        onPermanentDelete: onPermanentDelete,
        isRecycleBin: isRecycleBin,
      ),
    );
  }

  Color _getBadgeColor() {
    if (transaction.isSupply ||
        transaction.typeId == 1 ||
        transaction.typeId == 2) {
      return AppColors.supplyGreen;
    } else if (transaction.isDispense ||
        transaction.typeId == 4 ||
        transaction.typeId == 5) {
      return AppColors.dispenseRed;
    } else if (transaction.isAeration || transaction.typeId == 3) {
      return AppColors.warning;
    }
    return AppColors.supplyGreen;
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getBadgeColor();
    final effectivePhone = accountPhone ?? transaction.accountPhone;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: AppColors.background,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusDialog,
        ),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceXL,
          vertical: AppDimensions.space2XL,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 380,
          ),
          child: ClipRRect(
            borderRadius: AppDimensions.borderRadiusDialog,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. شريط العنوان: زر الخيارات (يمين) + العنوان (وسط) + زر الإغلاق (يسار)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.spaceM,
                    AppDimensions.spaceL,
                    AppDimensions.spaceM,
                    AppDimensions.spaceS,
                  ),
                  child: Row(
                    children: [
                      // زر القائمة المنسدلة الثلاث نقاط (يظهر على اليمين في RTL)
                      _buildPopupMenu(context),

                      // العنوان في المنتصف
                      const Expanded(
                        child: Center(
                          child: Text(
                            AppStrings.operationData,
                            style: TextStyle(
                              fontSize: AppTypography.sizeH2,
                              fontWeight: AppTypography.weightBold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),

                      // زر الإغلاق (يظهر على اليسار في RTL)
                      IconButton(
                        icon: const Icon(
                          AppIcons.close,
                          color: AppColors.textSecondary,
                          size: AppDimensions.iconLarge - 2,
                        ),
                        tooltip: AppStrings.close,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // 2. الحاوية البارزة للكمية والصنف (تلوين رقم الكمية فقط)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space2XL,
                    vertical: AppDimensions.spaceS,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.spaceM,
                      horizontal: AppDimensions.spaceXL,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.searchBackground,
                      borderRadius: AppDimensions.borderRadiusXL,
                    ),
                    alignment: Alignment.center,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontWeight: AppTypography.weightBold,
                          fontSize: AppTypography.sizeH1,
                        ),
                        children: [
                          // تلوين رقم الكمية فقط بالأخضر أو الأحمر
                          TextSpan(
                            text: AppFormatters.formatQuantity(
                              transaction.enteredQuantity,
                            ),
                            style: TextStyle(
                              color: badgeColor,
                            ),
                          ),
                          // الوحدة والصنف بالنص الداكن العادي
                          TextSpan(
                            text:
                                ' ${transaction.unitName ?? AppStrings.unitLiter} ${transaction.fuelTypeName ?? ''}'
                                    .trimRight(),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. قائمة الحقول والتفاصيل
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space2XL,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppDimensions.spaceS),

                        // نوع العملية
                        _buildDetailRow(
                          label: AppStrings.operationLabel,
                          valueWidget: Text(
                            transaction.typeName ?? AppStrings.operationLabel,
                            style: const TextStyle(
                              fontSize: AppTypography.sizeBody,
                              fontWeight: AppTypography.weightBold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        const Divider(
                          height: AppDimensions.dividerHeight,
                          thickness: AppDimensions.borderWidthHairline,
                          color: AppColors.borderLight,
                        ),

                        // تاريخ العملية ووقتها
                        _buildDetailRow(
                          label: AppStrings.transactionDate,
                          valueWidget: Text(
                            AppFormatters.formatTransactionDateTime(
                              transaction.transactionDate,
                              transaction.createdAt,
                            ),
                            style: const TextStyle(
                              fontSize: AppTypography.sizeBody,
                              fontWeight: AppTypography.weightBold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        const Divider(
                          height: AppDimensions.dividerHeight,
                          thickness: AppDimensions.borderWidthHairline,
                          color: AppColors.borderLight,
                        ),

                        // الحساب (الاسم ورقم الهاتف إن وجد)
                        if (transaction.accountName != null &&
                            transaction.accountName!.trim().isNotEmpty) ...[
                          _buildDetailRow(
                            label: AppStrings.account,
                            valueWidget: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  transaction.accountName!.trim(),
                                  style: const TextStyle(
                                    fontSize: AppTypography.sizeBody,
                                    fontWeight: AppTypography.weightBold,
                                    color: AppColors.textPrimary,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                                if (effectivePhone != null &&
                                    effectivePhone.trim().isNotEmpty) ...[
                                  const SizedBox(
                                      height: AppDimensions.spaceXXS),
                                  Text(
                                    effectivePhone.trim(),
                                    style: const TextStyle(
                                      fontSize: AppTypography.sizeCaption,
                                      color: AppColors.textSecondary,
                                      fontWeight: AppTypography.weightRegular,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Divider(
                            height: AppDimensions.dividerHeight,
                            thickness: AppDimensions.borderWidthHairline,
                            color: AppColors.borderSubtle,
                          ),
                        ],

                        // المحطة (إن وجدت)
                        if (transaction.stationName != null &&
                            transaction.stationName!.trim().isNotEmpty) ...[
                          _buildDetailRow(
                            label: AppStrings.station,
                            valueWidget: Text(
                              transaction.stationName!.trim(),
                              style: const TextStyle(
                                fontSize: AppTypography.sizeBody,
                                fontWeight: AppTypography.weightBold,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          const Divider(
                            height: AppDimensions.dividerHeight,
                            thickness: AppDimensions.borderWidthHairline,
                            color: AppColors.borderSubtle,
                          ),
                        ],

                        // محطة المقاصة / المحطة المرجعية (إن وجدت وكانت مختلفة)
                        if (transaction.referenceStationName != null &&
                            transaction.referenceStationName!
                                .trim()
                                .isNotEmpty &&
                            transaction.referenceStationName !=
                                transaction.stationName) ...[
                          _buildDetailRow(
                            label: AppStrings.referenceStationShort,
                            valueWidget: Text(
                              transaction.referenceStationName!.trim(),
                              style: const TextStyle(
                                fontSize: AppTypography.sizeBody,
                                fontWeight: AppTypography.weightBold,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          const Divider(
                            height: AppDimensions.dividerHeight,
                            thickness: AppDimensions.borderWidthHairline,
                            color: AppColors.borderSubtle,
                          ),
                        ],

                        // المستلم (إن وجد)
                        if (transaction.recipientName != null &&
                            transaction.recipientName!.trim().isNotEmpty) ...[
                          _buildDetailRow(
                            label: AppStrings.recipientLabel,
                            valueWidget: Text(
                              transaction.recipientName!.trim(),
                              style: const TextStyle(
                                fontSize: AppTypography.sizeBody,
                                fontWeight: AppTypography.weightBold,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          const Divider(
                            height: AppDimensions.dividerHeight,
                            thickness: AppDimensions.borderWidthHairline,
                            color: AppColors.borderSubtle,
                          ),
                        ],

                        // رقم السند / رقم المرجع (إن وجد)
                        if (transaction.referenceNumber != null &&
                            transaction.referenceNumber!.trim().isNotEmpty) ...[
                          _buildDetailRow(
                            label: AppStrings.referenceNumberLabel,
                            valueWidget: Text(
                              transaction.referenceNumber!.trim(),
                              style: const TextStyle(
                                fontSize: AppTypography.sizeBody,
                                fontWeight: AppTypography.weightBold,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          const Divider(
                            height: AppDimensions.dividerHeight,
                            thickness: AppDimensions.borderWidthHairline,
                            color: AppColors.borderSubtle,
                          ),
                        ],

                        // رقم العملية (إن وجد)
                        if (transaction.transactionNumber != null &&
                            transaction.transactionNumber!
                                .trim()
                                .isNotEmpty) ...[
                          _buildDetailRow(
                            label: AppStrings.transactionNumberLabel,
                            valueWidget: Text(
                              transaction.transactionNumber!.trim(),
                              style: const TextStyle(
                                fontSize: AppTypography.sizeBody,
                                fontWeight: AppTypography.weightBold,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          const Divider(
                            height: AppDimensions.dividerHeight,
                            thickness: AppDimensions.borderWidthHairline,
                            color: AppColors.borderSubtle,
                          ),
                        ],

                        // المعادل باللتر (إذا كانت الوحدة ليست لتر)
                        if (transaction.unitName != null &&
                            transaction.unitName != AppStrings.unitLiter &&
                            transaction.baseQuantityLiters !=
                                transaction.enteredQuantity) ...[
                          _buildDetailRow(
                            label: AppStrings.equivalentInLiters,
                            valueWidget: Text(
                              '${AppFormatters.formatQuantity(transaction.baseQuantityLiters)} ${AppStrings.unitLiter}',
                              style: const TextStyle(
                                fontSize: AppTypography.sizeBody,
                                fontWeight: AppTypography.weightBold,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          const Divider(
                            height: AppDimensions.dividerHeight,
                            thickness: AppDimensions.borderWidthHairline,
                            color: AppColors.borderSubtle,
                          ),
                        ],

                        // البيان / الملاحظات (إن وجد)
                        if (transaction.notes != null &&
                            transaction.notes!.trim().isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppDimensions.spaceL,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  AppStrings.statement,
                                  style: TextStyle(
                                    fontSize: AppTypography.sizeBodySecondary,
                                    color: AppColors.textTertiary,
                                    fontWeight: AppTypography.weightRegular,
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.spaceS),
                                Text(
                                  transaction.notes!.trim(),
                                  style: const TextStyle(
                                    fontSize: AppTypography.sizeBody,
                                    fontWeight: AppTypography.weightMedium,
                                    color: AppColors.textPrimary,
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                              ],
                            ),
                          ),
                          const Divider(
                            height: AppDimensions.dividerHeight,
                            thickness: AppDimensions.borderWidthHairline,
                            color: AppColors.borderSubtle,
                          ),
                        ],

                        const SizedBox(height: AppDimensions.spaceXL),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required Widget valueWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.spaceL + 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // نص التصنيف (على اليمين في RTL)
          Text(
            label,
            style: const TextStyle(
              fontSize: AppTypography.sizeBodySecondary,
              color: AppColors.textTertiary,
              fontWeight: AppTypography.weightRegular,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceL),
          // القيمة (على اليسار في RTL)
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: valueWidget,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        AppIcons.moreVert,
        color: AppColors.textPrimary,
        size: AppDimensions.iconLarge - 2,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: AppDimensions.borderRadiusXL,
      ),
      elevation: 6,
      color: AppColors.surface,
      onSelected: (value) {
        Navigator.of(context).pop();
        if (value == 'edit' && onEdit != null) {
          onEdit!();
        } else if (value == 'delete' && onDelete != null) {
          onDelete!();
        } else if (value == 'restore' && onRestore != null) {
          onRestore!();
        } else if (value == 'permanent_delete' && onPermanentDelete != null) {
          onPermanentDelete!();
        }
      },
      itemBuilder: (ctx) {
        if (isRecycleBin) {
          return [
            const PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  Icon(
                    AppIcons.restore,
                    size: AppDimensions.iconRegular,
                    color: AppColors.supplyGreen,
                  ),
                  SizedBox(width: AppDimensions.spaceM),
                  Text(
                    AppStrings.restore,
                    style: TextStyle(
                      fontSize: AppTypography.sizeBody,
                      fontWeight: AppTypography.weightMedium,
                      color: AppColors.supplyGreen,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'permanent_delete',
              child: Row(
                children: [
                  Icon(
                    AppIcons.delete,
                    size: AppDimensions.iconRegular,
                    color: AppColors.dispenseRed,
                  ),
                  SizedBox(width: AppDimensions.spaceM),
                  Text(
                    AppStrings.permanentDelete,
                    style: TextStyle(
                      fontSize: AppTypography.sizeBody,
                      fontWeight: AppTypography.weightMedium,
                      color: AppColors.dispenseRed,
                    ),
                  ),
                ],
              ),
            ),
          ];
        }

        return [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(
                  AppIcons.edit,
                  size: AppDimensions.iconRegular,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: AppDimensions.spaceM),
                Text(
                  AppStrings.edit,
                  style: TextStyle(
                    fontSize: AppTypography.sizeBody,
                    fontWeight: AppTypography.weightMedium,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  AppIcons.delete,
                  size: AppDimensions.iconRegular,
                  color: AppColors.dispenseRed,
                ),
                SizedBox(width: AppDimensions.spaceM),
                Text(
                  AppStrings.delete,
                  style: TextStyle(
                    fontSize: AppTypography.sizeBody,
                    fontWeight: AppTypography.weightMedium,
                    color: AppColors.dispenseRed,
                  ),
                ),
              ],
            ),
          ),
        ];
      },
    );
  }
}
