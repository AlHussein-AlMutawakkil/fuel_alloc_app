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
import '../../data/local/database_helper.dart';
import '../../models/account_model.dart';
import '../../models/transaction_model.dart';
import '../accounts/account_transactions_view.dart';

enum RecycleBinTab { operations, accounts }

/// واجهة سلة المحذوفات بنمط One UI (العمليات والحسابات المحذوفة مع إمكانية التعطيل والحذف النهائي)
class RecycleBinView extends StatefulWidget {
  const RecycleBinView({super.key});

  @override
  State<RecycleBinView> createState() => _RecycleBinViewState();
}

class _RecycleBinViewState extends State<RecycleBinView> {
  RecycleBinTab _activeTab = RecycleBinTab.operations;
  bool _isRecycleBinEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadRecycleSetting();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionsController>().fetchDeletedTransactions();
      context.read<AccountsController>().fetchDeletedAccounts();
    });
  }

  Future<void> _loadRecycleSetting() async {
    final enabled = await DatabaseHelper.instance.isRecycleBinEnabled();
    if (mounted) {
      setState(() => _isRecycleBinEnabled = enabled);
    }
  }

  Future<void> _toggleRecycleBinSetting(bool val) async {
    await DatabaseHelper.instance.setRecycleBinEnabled(val);
    if (mounted) {
      setState(() => _isRecycleBinEnabled = val);
      AppSnackBar.showSuccess(
        context,
        val
            ? 'تم تفعيل سلة المحذوفات'
            : 'تم إيقاف سلة المحذوفات (الحذف سيكون نهائياً)',
      );
    }
  }

  Widget _buildSettingTile() {
    return OneUiCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceL,
        vertical: AppDimensions.spaceS,
      ),
      children: [
        OneUiTile(
          leading: const Icon(
            AppIcons.recycleBin,
            color: AppColors.primary,
            size: AppDimensions.iconMedium + 2,
          ),
          title: AppStrings.enableRecycleBin,
          subtitle: AppStrings.recycleBinSettingDesc,
          trailing: Switch.adaptive(
            value: _isRecycleBinEnabled,
            activeColor: AppColors.primary,
            onChanged: _toggleRecycleBinSetting,
          ),
        ),
      ],
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

  void _showTransactionDetails(TransactionModel tx) {
    CustomDialog.showTransactionDetails(
      context: context,
      transaction: tx,
      isRecycleBin: true,
      onRestore: () => _restoreTransaction(tx),
      onPermanentDelete: () => _permanentlyDeleteTransaction(tx),
    );
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

  void _openAccountStatement(AccountModel account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountTransactionsView(account: account),
      ),
    );
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
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            onTap: () => _showTransactionDetails(tx),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // رأس البطاقة: التاريخ والنوع وزر الثلاث نقاط
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
                      PopupMenuButton<String>(
                        icon: const Icon(
                          AppIcons.moreVert,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusM),
                        ),
                        onSelected: (val) {
                          if (val == 'details') {
                            _showTransactionDetails(tx);
                          } else if (val == 'restore') {
                            _restoreTransaction(tx);
                          } else if (val == 'delete') {
                            _permanentlyDeleteTransaction(tx);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'details',
                            child: Row(
                              children: [
                                Icon(AppIcons.info,
                                    size: 18, color: AppColors.textPrimary),
                                SizedBox(width: AppDimensions.spaceM),
                                Text(AppStrings.viewDetails),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'restore',
                            child: Row(
                              children: [
                                Icon(AppIcons.restore,
                                    size: 18, color: AppColors.supplyGreen),
                                SizedBox(width: AppDimensions.spaceM),
                                Text(AppStrings.restore),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(AppIcons.delete,
                                    size: 18, color: AppColors.dispenseRed),
                                SizedBox(width: AppDimensions.spaceM),
                                Text(AppStrings.permanentDelete),
                              ],
                            ),
                          ),
                        ],
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
                            // المستلم مع الأيقونة فقط وإضافة المرجع بجانبه
                            if ((tx.recipientName != null &&
                                    tx.recipientName!.trim().isNotEmpty) ||
                                (tx.referenceNumber != null &&
                                    tx.referenceNumber!.trim().isNotEmpty)) ...[
                              const SizedBox(height: AppDimensions.spaceXS),
                              Row(
                                children: [
                                  if (tx.recipientName != null &&
                                      tx.recipientName!.trim().isNotEmpty) ...[
                                    const Icon(
                                      AppIcons.accountOutline,
                                      size: 14,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      tx.recipientName!.trim(),
                                      style: const TextStyle(
                                        fontSize: AppTypography.sizeCaption,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (tx.referenceNumber != null &&
                                      tx.referenceNumber!
                                          .trim()
                                          .isNotEmpty) ...[
                                    const SizedBox(width: AppDimensions.spaceM),
                                    const Icon(
                                      AppIcons.reference,
                                      size: 14,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      tx.referenceNumber!.trim(),
                                      style: const TextStyle(
                                        fontSize: AppTypography.sizeCaption,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
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

                  // تاريخ الحذف في الأسفل
                  Row(
                    children: [
                      const Icon(
                        AppIcons.calendar,
                        size: 13,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${AppStrings.deletedAtPrefix}${AppFormatters.formatDate(tx.deletedAt ?? tx.transactionDate)}',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeCaption - 1,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
        final isStation = account.accountType == AccountType.station;
        final isSupplier = account.accountType == AccountType.supplier;

        final badgeText = isStation
            ? AppStrings.typeStation
            : (isSupplier ? AppStrings.typeSupplier : AppStrings.typeBeneficiary);

        final badgeColor = isStation
            ? AppColors.warning
            : (isSupplier ? AppColors.primary : AppColors.supplyGreen);

        final iconData = isStation ? AppIcons.gasStation : AppIcons.account;

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
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Icon(
                    iconData,
                    color: badgeColor,
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
                          Flexible(
                            child: Text(
                              account.name,
                              style: const TextStyle(
                                fontSize: AppTypography.sizeH2,
                                fontWeight: AppTypography.weightBold,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spaceS),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.spaceS + 2,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusS),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: AppTypography.sizeCaption - 1,
                                fontWeight: AppTypography.weightBold,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (isStation &&
                              account.location != null &&
                              account.location!.isNotEmpty) ...[
                            Text(
                              account.location!,
                              style: const TextStyle(
                                fontSize: AppTypography.sizeBodySecondary,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spaceM),
                          ] else if (account.phoneNumber != null &&
                              account.phoneNumber!.isNotEmpty) ...[
                            Text(
                              account.phoneNumber!,
                              style: const TextStyle(
                                fontSize: AppTypography.sizeBodySecondary,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spaceM),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.borderLight.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${AppStrings.operationsCountPrefix}${account.operationsCount}',
                              style: const TextStyle(
                                fontSize: AppTypography.sizeCaption - 1,
                                fontWeight: AppTypography.weightSemiBold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppStrings.deletedAtPrefix}${AppFormatters.formatDate(account.deletedAt ?? account.createdAt ?? '')}',
                        style: const TextStyle(
                          fontSize: AppTypography.sizeCaption - 1,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    AppIcons.moreVert,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  onSelected: (val) {
                    if (val == 'statement') {
                      _openAccountStatement(account);
                    } else if (val == 'restore') {
                      _restoreAccount(account);
                    } else if (val == 'delete') {
                      _permanentlyDeleteAccount(account);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'statement',
                      child: Row(
                        children: [
                          Icon(AppIcons.statement,
                              size: 18, color: AppColors.textPrimary),
                          SizedBox(width: AppDimensions.spaceM),
                          Text(AppStrings.viewAccountStatement),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'restore',
                      child: Row(
                        children: [
                          Icon(AppIcons.restore,
                              size: 18, color: AppColors.supplyGreen),
                          SizedBox(width: AppDimensions.spaceM),
                          Text(AppStrings.restore),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(AppIcons.delete,
                              size: 18, color: AppColors.dispenseRed),
                          SizedBox(width: AppDimensions.spaceM),
                          Text(AppStrings.permanentDelete),
                        ],
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
          _buildSettingTile(),
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
