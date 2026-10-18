import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import '../../core/widgets/operation_entry_sheet.dart';
import '../../models/account_model.dart';
import '../../models/transaction_model.dart';
import 'widgets/fuel_summary_card.dart';

/// واجهة كشف حساب وعمليات الحساب (توريد / صرف)
class AccountTransactionsView extends StatefulWidget {
  final AccountModel account;

  const AccountTransactionsView({
    super.key,
    required this.account,
  });

  @override
  State<AccountTransactionsView> createState() =>
      _AccountTransactionsViewState();
}

class _AccountTransactionsViewState extends State<AccountTransactionsView> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.account.id != null) {
        context
            .read<TransactionsController>()
            .fetchAccountTransactions(widget.account.id!);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddTransactionDialog() async {
    final isSupplier = widget.account.accountType == AccountType.supplier;
    final controller = context.read<TransactionsController>();
    final currentFuelId = controller.selectedFuelTypeId;

    await OperationEntrySheet.show(
      context: context,
      account: widget.account,
      initialTabIndex: 0,
      initialDirection: isSupplier ? 0 : 1,
      initialFuelTypeId: currentFuelId,
    );
    if (widget.account.id != null && mounted) {
      context.read<TransactionsController>().fetchAccountTransactions(
            widget.account.id!,
            defaultFuelTypeId: currentFuelId,
          );
    }
  }

  void _deleteTransaction(TransactionModel tx) async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: AppStrings.confirmExclamation,
      message: AppStrings.confirmDeleteTransactionShortMsg,
      confirmText: AppStrings.ok,
      cancelText: AppStrings.cancel,
      isDanger: true,
    );

    if (confirm && tx.id != null && widget.account.id != null && mounted) {
      final success =
          await context.read<TransactionsController>().deleteTransaction(
                tx.id!,
                widget.account.id!,
              );
      if (success && mounted) {
        AppSnackBar.showSuccess(context, AppStrings.transactionDeletedSuccess);
      }
    }
  }

  void _showTransactionDetails(TransactionModel tx) {
    CustomDialog.showDetails(
      context: context,
      title: AppStrings.operationDetails,
      rows: [
        DialogDetailRow(
          label: AppStrings.labelOperationType,
          value: tx.typeName ?? AppStrings.operation,
        ),
        DialogDetailRow(
          label: AppStrings.labelDate,
          value: AppFormatters.formatDate(tx.transactionDate),
        ),
        if (tx.stationName != null)
          DialogDetailRow(
            label: AppStrings.labelStation,
            value: tx.stationName!,
          ),
        if (tx.referenceStationName != null &&
            tx.referenceStationName != tx.stationName)
          DialogDetailRow(
            label: AppStrings.labelReferenceStation,
            value: tx.referenceStationName!,
          ),
        DialogDetailRow(
          label: AppStrings.labelFuelType,
          value: tx.fuelTypeName ?? '-',
        ),
        DialogDetailRow(
          label: AppStrings.labelEnteredQuantity,
          value:
              '${AppFormatters.formatQuantity(tx.enteredQuantity)} ${tx.unitName ?? ''}',
        ),
        DialogDetailRow(
          label: AppStrings.labelEquivalentLiters,
          value:
              '${AppFormatters.formatQuantity(tx.baseQuantityLiters)} ${AppStrings.unitLiter}',
        ),
        if (tx.referenceNumber != null && tx.referenceNumber!.isNotEmpty)
          DialogDetailRow(
            label: AppStrings.referenceNumberLabel,
            value: tx.referenceNumber!,
          ),
        if (tx.notes != null && tx.notes!.isNotEmpty)
          DialogDetailRow(
            label: AppStrings.labelStatement,
            value: tx.notes!,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSupplier = widget.account.accountType == AccountType.supplier;

    return Consumer<TransactionsController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: OneUiAppBar(
            title: widget.account.name,
            titleWidget: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppTypography.sizeBody + 1,
                    ),
                    cursorColor: AppColors.primary,
                    decoration: const InputDecoration(
                      hintText: AppStrings.searchTransactionHint,
                      hintStyle: TextStyle(
                        color: AppColors.textMuted,
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => controller.setSearchQuery(val),
                  )
                : null,
            actions: [
              IconButton(
                icon: Icon(
                  _isSearching ? AppIcons.close : AppIcons.search,
                  color: AppColors.textPrimary,
                ),
                tooltip:
                    _isSearching ? AppStrings.closeSearch : AppStrings.search,
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      controller.setSearchQuery('');
                    }
                  });
                },
              ),
              if (!_isSearching)
                IconButton(
                  icon: const Icon(
                    AppIcons.add,
                    color: AppColors.textPrimary,
                  ),
                  tooltip: AppStrings.addOperation,
                  onPressed: () => _openAddTransactionDialog(),
                ),
            ],
          ),
          body: controller.isLoading
              ? const Center(child: AppLoadingIndicator())
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    if (widget.account.id != null) {
                      await controller
                          .fetchAccountTransactions(widget.account.id!);
                    }
                  },
                  child: ListView(
                    padding: AppDimensions.paddingScreen,
                    children: [
                      _buildSummaryCard(controller, isSupplier),
                      const SizedBox(height: AppDimensions.spaceL),
                      _buildSectionHeader(controller),
                      const SizedBox(height: AppDimensions.spaceS),
                      if (controller.transactions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppDimensions.space3XL,
                          ),
                          child: EmptyStateWidget(
                            icon: AppIcons.tabQuota,
                            title: AppStrings.noTransactionsFound,
                            actionText: AppStrings.recordFirstOperation,
                            actionIcon: AppIcons.add,
                            onAction: () => _openAddTransactionDialog(),
                          ),
                        )
                      else
                        _buildTransactionsContainer(controller.transactions),
                      const SizedBox(height: AppDimensions.space3XL),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSummaryCard(TransactionsController controller, bool isSupplier) {
    return FuelSummarySlider(
      fuelTypes: controller.fuelTypes,
      selectedFuelId: controller.selectedFuelTypeId,
      onFuelChanged: (fuelId) => controller.setSelectedFuelTypeId(fuelId),
      cardBuilder: (fuelId, fuelName) {
        final quota = controller.getQuotaLitersForFuel(fuelId);
        final actual = controller.getActualLitersForFuel(fuelId);
        final balance = controller.getBalanceLitersForFuel(fuelId);

        return FuelCardData(
          title: widget.account.name,
          fuelName: fuelName,
          balance: balance,
          metrics: [
            FuelCardMetric(
              value: quota,
              label: isSupplier
                  ? AppStrings.supplyQuota
                  : AppStrings.dispenseQuota,
            ),
            FuelCardMetric(
              value: actual,
              label: isSupplier
                  ? AppStrings.supplyActual
                  : AppStrings.dispenseActual,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(TransactionsController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceXS,
        vertical: AppDimensions.spaceXS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            AppStrings.operationsHistory,
            style: TextStyle(
              fontSize: AppTypography.sizeBody,
              fontWeight: AppTypography.weightSemiBold,
              color: AppColors.textSecondary,
            ),
          ),
          if (controller.transactions.isNotEmpty)
            Text(
              '${controller.transactions.length} ${AppStrings.operation}',
              style: const TextStyle(
                fontSize: AppTypography.sizeCaption,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionsContainer(List<TransactionModel> transactions) {
    return OneUiCard(
      margin: EdgeInsets.zero,
      children: transactions.map(_buildTransactionItem).toList(),
    );
  }

  Widget _buildTransactionItem(TransactionModel tx) {
    final bool isPositive = tx.typeId == 1 || tx.typeId == 2 || tx.typeId == 4;
    final bool isAeration = tx.typeId == 3;

    final Color badgeColor = isPositive
        ? AppColors.supplyGreen
        : (isAeration ? AppColors.warning : AppColors.dispenseRed);

    final IconData opIcon = isPositive
        ? AppIcons.supply
        : (isAeration ? AppIcons.tabAeration : AppIcons.dispense);

    final String sign = isPositive ? '+' : (isAeration ? '+' : '-');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showTransactionOptions(tx),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceL,
            vertical: AppDimensions.spaceM + 2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. الصف الرئيسي: الأيقونة (سهم فقط بدون دائرة) + البيانات + الكمية
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // الأيقونة (سهم فقط بدون دائرة خلفية)
                  Icon(
                    opIcon,
                    size: AppDimensions.iconLarge,
                    color: badgeColor,
                  ),
                  const SizedBox(width: AppDimensions.spaceM),

                  // اسم العملية والمحطة والتاريخ الرقمي
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tx.typeName ?? AppStrings.operation,
                          style: const TextStyle(
                            fontSize: AppTypography.sizeBody,
                            fontWeight: AppTypography.weightSemiBold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppDimensions.spaceXXS),
                        Row(
                          children: [
                            Text(
                              AppFormatters.formatDate(tx.transactionDate),
                              style: const TextStyle(
                                fontSize: AppTypography.sizeCaption,
                                color: AppColors.textMuted,
                              ),
                            ),
                            if (tx.stationName != null &&
                                tx.stationName!.trim().isNotEmpty) ...[
                              const SizedBox(width: AppDimensions.spaceXS),
                              const Text(
                                '•',
                                style: TextStyle(
                                  fontSize: AppTypography.sizeCaption,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.spaceXS),
                              Flexible(
                                child: Text(
                                  tx.referenceStationName != null &&
                                          tx.referenceStationName !=
                                              tx.stationName
                                      ? '${tx.stationName!} (${AppStrings.referenceStationShort}: ${tx.referenceStationName!})'
                                      : tx.stationName!,
                                  style: const TextStyle(
                                    fontSize: AppTypography.sizeCaption,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceM),

                  // الكمية والصنف والوحدة
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$sign ${AppFormatters.formatQuantity(tx.enteredQuantity)}',
                        style: TextStyle(
                          fontSize: AppTypography.sizeBody + 1,
                          fontWeight: AppTypography.weightBold,
                          color: badgeColor,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceXXS - 1),
                      Text(
                        '${tx.unitName ?? AppStrings.unitLiter} ${tx.fuelTypeName ?? ''}'
                            .trim(),
                        style: const TextStyle(
                          fontSize: AppTypography.sizeCaption - 0.5,
                          fontWeight: AppTypography.weightMedium,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // 2. نص البيان / الملاحظة (ممتد على طول البطاقة بدون أيقونة وبدون خلفيات إضافية)
              if (tx.notes != null && tx.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spaceXS + 1),
                Text(
                  tx.notes!.trim(),
                  style: const TextStyle(
                    fontSize: AppTypography.sizeCaption,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionOptions(TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.overlay,
      builder: (ctx) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceXL,
            vertical: AppDimensions.space2XL,
          ),
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.modalMaxWidth,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppDimensions.borderRadius3XL,
            boxShadow: [
              BoxShadow(
                color: AppColors.overlayLight,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppDimensions.borderRadius3XL,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.spaceL),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.typeName ?? AppStrings.operation,
                              style: const TextStyle(
                                fontSize: AppTypography.sizeH2,
                                fontWeight: AppTypography.weightBold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spaceXXS),
                            Text(
                              '${AppFormatters.formatDate(tx.transactionDate)} • ${AppFormatters.formatQuantity(tx.enteredQuantity)} ${tx.unitName ?? AppStrings.unitLiter} ${tx.fuelTypeName ?? ''}'
                                  .trim(),
                              style: const TextStyle(
                                fontSize: AppTypography.sizeCaption,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          AppIcons.closeRounded,
                          color: AppColors.textTertiary,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: AppDimensions.dividerHeight,
                  thickness: AppDimensions.borderWidthHairline,
                  color: AppColors.borderSubtle,
                ),
                ListTile(
                  leading: const Icon(
                    AppIcons.info,
                    color: AppColors.textSecondary,
                  ),
                  title: const Text(
                    AppStrings.details,
                    style: TextStyle(
                      fontSize: AppTypography.sizeBody,
                      fontWeight: AppTypography.weightMedium,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showTransactionDetails(tx);
                  },
                ),
                const Divider(
                  height: AppDimensions.dividerHeight,
                  thickness: AppDimensions.borderWidthHairline,
                  color: AppColors.borderSubtle,
                ),
                ListTile(
                  leading: const Icon(
                    AppIcons.edit,
                    color: AppColors.textSecondary,
                  ),
                  title: const Text(
                    AppStrings.edit,
                    style: TextStyle(
                      fontSize: AppTypography.sizeBody,
                      fontWeight: AppTypography.weightMedium,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    OperationEntrySheet.show(
                      context: context,
                      account: widget.account,
                      editTransaction: tx,
                    );
                  },
                ),
                const Divider(
                  height: AppDimensions.dividerHeight,
                  thickness: AppDimensions.borderWidthHairline,
                  color: AppColors.borderSubtle,
                ),
                ListTile(
                  leading: const Icon(
                    AppIcons.delete,
                    color: AppColors.dispenseRed,
                  ),
                  title: const Text(
                    AppStrings.delete,
                    style: TextStyle(
                      fontSize: AppTypography.sizeBody,
                      fontWeight: AppTypography.weightMedium,
                      color: AppColors.dispenseRed,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _deleteTransaction(tx);
                  },
                ),
                const SizedBox(height: AppDimensions.spaceS),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
