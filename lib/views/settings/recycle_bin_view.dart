import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/accounts_controller.dart';
import '../../controllers/transactions_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/one_ui_card.dart';
import '../../models/account_model.dart';
import '../../models/transaction_model.dart';

enum RecycleBinTab { operations, accounts }

/// واجهة سلة المحذوفات بنمط One UI (تبويبان: العمليات المحذوفة / الحسابات المحذوفة)
class RecycleBinView extends StatefulWidget {
  const RecycleBinView({super.key});

  @override
  State<RecycleBinView> createState() => _RecycleBinViewState();
}

class _RecycleBinViewState extends State<RecycleBinView> {
  RecycleBinTab _activeTab = RecycleBinTab.operations;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionsController>().fetchDeletedTransactions();
      context.read<AccountsController>().fetchDeletedAccounts();
    });
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
            label: AppStrings.tabOperations,
            isSelected: _activeTab == RecycleBinTab.operations,
            onTap: () {
              setState(() => _activeTab = RecycleBinTab.operations);
              context.read<TransactionsController>().fetchDeletedTransactions();
            },
          ),
          _buildSegmentItem(
            label: AppStrings.tabAccounts,
            isSelected: _activeTab == RecycleBinTab.accounts,
            onTap: () {
              setState(() => _activeTab = RecycleBinTab.accounts);
              context.read<AccountsController>().fetchDeletedAccounts();
            },
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
              fontSize: AppTypography.sizeBody,
              fontWeight: isSelected
                  ? AppTypography.weightBold
                  : AppTypography.weightMedium,
              color:
                  isSelected ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }

  // --- عمليات الاستعادة والحذف للعمليات ---

  Future<void> _restoreTransaction(TransactionModel tx) async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: AppStrings.confirmRestoreTitle,
      message: AppStrings.confirmRestoreMsg,
      confirmText: AppStrings.restore,
      cancelText: AppStrings.cancel,
      isDanger: false,
    );
    if (!confirm || !mounted) return;

    final success = await context
        .read<TransactionsController>()
        .restoreTransaction(tx.id!);
    if (success && mounted) {
      AppSnackBar.showSuccess(context, AppStrings.itemRestoredSuccess);
    }
  }

  Future<void> _permanentlyDeleteTransaction(TransactionModel tx) async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: AppStrings.confirmPermanentDeleteTitle,
      message: AppStrings.confirmPermanentDeleteMsg,
      confirmText: AppStrings.permanentDelete,
      cancelText: AppStrings.cancel,
      isDanger: true,
    );
    if (!confirm || !mounted) return;

    final success = await context
        .read<TransactionsController>()
        .permanentlyDeleteTransaction(tx.id!);
    if (success && mounted) {
      AppSnackBar.showSuccess(context, AppStrings.itemDeletedPermanentSuccess);
    }
  }

  // --- عمليات الاستعادة والحذف للحسابات ---

  Future<void> _restoreAccount(AccountModel account) async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: AppStrings.confirmRestoreTitle,
      message: AppStrings.confirmRestoreMsg,
      confirmText: AppStrings.restore,
      cancelText: AppStrings.cancel,
      isDanger: false,
    );
    if (!confirm || !mounted) return;

    final success =
        await context.read<AccountsController>().restoreAccount(account.id!);
    if (success && mounted) {
      AppSnackBar.showSuccess(context, AppStrings.itemRestoredSuccess);
    }
  }

  Future<void> _permanentlyDeleteAccount(AccountModel account) async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: AppStrings.confirmPermanentDeleteTitle,
      message: AppStrings.confirmPermanentDeleteMsg,
      confirmText: AppStrings.permanentDelete,
      cancelText: AppStrings.cancel,
      isDanger: true,
    );
    if (!confirm || !mounted) return;

    final success = await context
        .read<AccountsController>()
        .permanentlyDeleteAccount(account.id!);
    if (success && mounted) {
      AppSnackBar.showSuccess(context, AppStrings.itemDeletedPermanentSuccess);
    }
  }

  Widget _buildOperationsList(TransactionsController txCtrl) {
    if (txCtrl.isLoading) {
      return const Center(child: AppLoadingIndicator());
    }

    final deleted = txCtrl.deletedTransactions;
    if (deleted.isEmpty) {
      return const EmptyStateWidget(
        icon: AppIcons.recycleBin,
        title: AppStrings.noDeletedOperations,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceL,
        vertical: AppDimensions.spaceS,
      ),
      itemCount: deleted.length,
      itemBuilder: (ctx, index) {
        final tx = deleted[index];
        final isSupply = tx.typeId == 1 || tx.typeId == 2;

        return Card(
          margin: const EdgeInsets.only(bottom: AppDimensions.spaceM),
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // رأس البطاقة: التاريخ والنوع
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spaceM,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isSupply
                            ? AppColors.supplyGreen.withOpacity(0.12)
                            : AppColors.dispenseRed.withOpacity(0.12),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusS),
                      ),
                      child: Text(
                        tx.typeName ?? AppStrings.operation,
                        style: TextStyle(
                          fontSize: AppTypography.sizeCaption,
                          fontWeight: AppTypography.weightBold,
                          color: isSupply
                              ? AppColors.supplyGreen
                              : AppColors.dispenseRed,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceS),
                    if (tx.fuelTypeName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spaceM,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusS),
                        ),
                        child: Text(
                          tx.fuelTypeName!,
                          style: const TextStyle(
                            fontSize: AppTypography.sizeCaption,
                            fontWeight: AppTypography.weightMedium,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      AppFormatters.formatDate(tx.transactionDate),
                      style: const TextStyle(
                        fontSize: AppTypography.sizeCaption,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceM),

                // تفاصيل العملية: الكمية والحساب والمحطة
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (tx.accountName != null)
                            Text(
                              '${AppStrings.account}: ${tx.accountName}',
                              style: const TextStyle(
                                fontSize: AppTypography.sizeBodySecondary,
                                fontWeight: AppTypography.weightSemiBold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          if (tx.stationName != null)
                            Text(
                              '${AppStrings.station}: ${tx.stationName}',
                              style: const TextStyle(
                                fontSize: AppTypography.sizeCaption,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          if (tx.recipientName != null &&
                              tx.recipientName!.isNotEmpty)
                            Text(
                              '${AppStrings.recipientPrefix}${tx.recipientName}',
                              style: const TextStyle(
                                fontSize: AppTypography.sizeCaption,
                                color: AppColors.textTertiary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${AppFormatters.formatQuantity(tx.enteredQuantity)} ${tx.unitName ?? AppStrings.unitLiter}',
                          style: TextStyle(
                            fontSize: AppTypography.sizeH2,
                            fontWeight: AppTypography.weightBold,
                            color: isSupply
                                ? AppColors.supplyGreen
                                : AppColors.dispenseRed,
                          ),
                        ),
                        if (tx.baseQuantityLiters != tx.enteredQuantity)
                          Text(
                            '${AppFormatters.formatQuantity(tx.baseQuantityLiters)} ${AppStrings.unitLiter}',
                            style: const TextStyle(
                              fontSize: AppTypography.sizeCaption,
                              color: AppColors.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.spaceS),
                  Text(
                    tx.notes!,
                    style: const TextStyle(
                      fontSize: AppTypography.sizeCaption,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],

                const SizedBox(height: AppDimensions.spaceM),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: AppDimensions.spaceS),

                // أزرار الإجراءات: استعادة وحذف نهائي
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(
                        AppIcons.delete,
                        size: 16,
                        color: AppColors.dispenseRed,
                      ),
                      label: const Text(
                        AppStrings.permanentDelete,
                        style: TextStyle(
                          color: AppColors.dispenseRed,
                          fontSize: AppTypography.sizeCaption,
                          fontWeight: AppTypography.weightSemiBold,
                        ),
                      ),
                      onPressed: () => _permanentlyDeleteTransaction(tx),
                    ),
                    const SizedBox(width: AppDimensions.spaceM),
                    ElevatedButton.icon(
                      icon: const Icon(
                        AppIcons.restore,
                        size: 16,
                        color: AppColors.textWhite,
                      ),
                      label: const Text(
                        AppStrings.restore,
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: AppTypography.sizeCaption,
                          fontWeight: AppTypography.weightBold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.supplyGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusM),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spaceL,
                          vertical: 6,
                        ),
                      ),
                      onPressed: () => _restoreTransaction(tx),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountsList(AccountsController accCtrl) {
    if (accCtrl.isLoading) {
      return const Center(child: AppLoadingIndicator());
    }

    final deleted = accCtrl.deletedAccounts;
    if (deleted.isEmpty) {
      return const EmptyStateWidget(
        icon: AppIcons.recycleBin,
        title: AppStrings.noDeletedAccounts,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceL,
        vertical: AppDimensions.spaceS,
      ),
      itemCount: deleted.length,
      itemBuilder: (ctx, index) {
        final account = deleted[index];
        final isSupplier = account.accountType == AccountType.supplier;

        return Card(
          margin: const EdgeInsets.only(bottom: AppDimensions.spaceM),
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSupplier
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.supplyGreen.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusM),
                      ),
                      child: Icon(
                        AppIcons.account,
                        color: isSupplier
                            ? AppColors.primary
                            : AppColors.supplyGreen,
                        size: AppDimensions.iconMedium,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceL),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                account.name,
                                style: const TextStyle(
                                  fontSize: AppTypography.sizeH2,
                                  fontWeight: AppTypography.weightBold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.spaceS),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.spaceS + 2,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isSupplier
                                      ? AppColors.primary.withOpacity(0.1)
                                      : AppColors.supplyGreen
                                          .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusS),
                                ),
                                child: Text(
                                  isSupplier
                                      ? AppStrings.typeSupplier
                                      : AppStrings.typeBeneficiary,
                                  style: TextStyle(
                                    fontSize: AppTypography.sizeCaption - 1,
                                    fontWeight: AppTypography.weightBold,
                                    color: isSupplier
                                        ? AppColors.primary
                                        : AppColors.supplyGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (account.phoneNumber != null &&
                              account.phoneNumber!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              account.phoneNumber!,
                              style: const TextStyle(
                                fontSize: AppTypography.sizeBodySecondary,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceM),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: AppDimensions.spaceS),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(
                        AppIcons.delete,
                        size: 16,
                        color: AppColors.dispenseRed,
                      ),
                      label: const Text(
                        AppStrings.permanentDelete,
                        style: TextStyle(
                          color: AppColors.dispenseRed,
                          fontSize: AppTypography.sizeCaption,
                          fontWeight: AppTypography.weightSemiBold,
                        ),
                      ),
                      onPressed: () => _permanentlyDeleteAccount(account),
                    ),
                    const SizedBox(width: AppDimensions.spaceM),
                    ElevatedButton.icon(
                      icon: const Icon(
                        AppIcons.restore,
                        size: 16,
                        color: AppColors.textWhite,
                      ),
                      label: const Text(
                        AppStrings.restore,
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: AppTypography.sizeCaption,
                          fontWeight: AppTypography.weightBold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.supplyGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusM),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spaceL,
                          vertical: 6,
                        ),
                      ),
                      onPressed: () => _restoreAccount(account),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final txCtrl = context.watch<TransactionsController>();
    final accCtrl = context.watch<AccountsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const OneUiAppBar(
        title: AppStrings.recycleBinTitle,
      ),
      body: Column(
        children: [
          _buildSegmentControl(),
          Expanded(
            child: _activeTab == RecycleBinTab.operations
                ? _buildOperationsList(txCtrl)
                : _buildAccountsList(accCtrl),
          ),
        ],
      ),
    );
  }
}
