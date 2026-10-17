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
import '../../core/widgets/filter_chip_widget.dart';
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
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: AppTypography.sizeBody + 1,
                    ),
                    cursorColor: AppColors.textWhite,
                    decoration: InputDecoration(
                      hintText: AppStrings.searchTransactionHint,
                      hintStyle: TextStyle(
                        color: AppColors.textWhite.withOpacity(0.7),
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => controller.setSearchQuery(val),
                  )
                : Text(
                    '${AppStrings.accountOperations}: ${widget.account.name}',
                    style: AppTypography.appBarTitle,
                  ),
            actions: [
              IconButton(
                icon: Icon(_isSearching ? AppIcons.close : AppIcons.search),
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
              IconButton(
                icon: const Icon(AppIcons.add),
                tooltip: AppStrings.addOperation,
                onPressed: () => _openAddTransactionDialog(),
              ),
              IconButton(
                icon: const Icon(AppIcons.refresh),
                tooltip: AppStrings.refresh,
                onPressed: () {
                  if (widget.account.id != null) {
                    controller.fetchAccountTransactions(widget.account.id!);
                  }
                },
              ),
            ],
          ),
          body: Padding(
            padding: AppDimensions.paddingScreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(controller, isSupplier),
                const SizedBox(height: AppDimensions.spaceL),
                Row(
                  children: [
                    AppFilterChip(
                      label: AppStrings.allFilter,
                      isSelected: controller.selectedFilter == 'ALL',
                      onTap: () => controller.setFilter('ALL'),
                    ),
                    const SizedBox(width: AppDimensions.spaceM),
                    AppFilterChip(
                      label: AppStrings.quotaFilter,
                      isSelected: controller.selectedFilter == 'QUOTA',
                      onTap: () => controller.setFilter('QUOTA'),
                    ),
                    const SizedBox(width: AppDimensions.spaceM),
                    AppFilterChip(
                      label: AppStrings.actualFilter,
                      isSelected: controller.selectedFilter == 'ACTUAL',
                      onTap: () => controller.setFilter('ACTUAL'),
                    ),
                    const Spacer(),
                    Text(
                      '${AppStrings.totalOperations}: ${controller.transactions.length}',
                      style: AppTypography.captionBold,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceL + 2),
                Expanded(
                  child: controller.isLoading
                      ? const AppLoadingIndicator()
                      : controller.transactions.isEmpty
                          ? EmptyStateWidget(
                              icon: AppIcons.tabQuota,
                              title: AppStrings.noTransactionsFound,
                              actionText: AppStrings.recordFirstOperation,
                              actionIcon: AppIcons.add,
                              onAction: () => _openAddTransactionDialog(),
                            )
                          : ListView.separated(
                              itemCount: controller.transactions.length,
                              separatorBuilder: (_, __) => const SizedBox(
                                height: AppDimensions.spaceM + 2,
                              ),
                              itemBuilder: (context, index) {
                                final tx = controller.transactions[index];
                                return _buildTransactionCard(tx);
                              },
                            ),
                ),
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

  Widget _buildTransactionCard(TransactionModel tx) {
    final bool isPositive = tx.typeId == 1 || tx.typeId == 2 || tx.typeId == 4;
    final bool isActualDispense = tx.typeId == 5;
    final bool isAeration = tx.typeId == 3;

    final Color badgeColor = isActualDispense
        ? AppColors.dispenseRed
        : (isAeration ? AppColors.warning : AppColors.supplyGreen);

    final Color badgeBg = isActualDispense
        ? AppColors.dispenseLight
        : (isAeration ? AppColors.warningLight : AppColors.supplyLight);

    final String sign = isPositive ? '+' : '-';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.borderRadiusM,
        border: Border.all(
          color: AppColors.border,
          width: AppDimensions.borderWidthThin,
        ),
      ),
      child: ClipRRect(
        borderRadius: AppDimensions.borderRadiusM,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: badgeColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceL,
                    vertical: AppDimensions.spaceM + 2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: AppDimensions.paddingTag,
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: AppDimensions.borderRadiusXS,
                            ),
                            child: Text(
                              tx.typeName ?? AppStrings.operation,
                              style: AppTypography.caption.copyWith(
                                color: badgeColor,
                                fontWeight: AppTypography.weightBold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                AppIcons.calendar,
                                size: AppDimensions.iconMicro,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: AppDimensions.spaceXS),
                              Text(
                                AppFormatters.formatDate(tx.transactionDate),
                                style: AppTypography.caption,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceM),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (tx.fuelTypeName != null) ...[
                                  Container(
                                    padding: AppDimensions.paddingMiniTag,
                                    decoration: const BoxDecoration(
                                      color: AppColors.chipBackground,
                                      borderRadius:
                                          AppDimensions.borderRadiusXS,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          AppIcons.gasStation,
                                          size: AppDimensions.iconMicro,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(
                                          width: AppDimensions.spaceXXS + 1,
                                        ),
                                        Text(
                                          tx.fuelTypeName!,
                                          style: AppTypography.caption.copyWith(
                                            fontWeight:
                                                AppTypography.weightSemiBold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppDimensions.spaceM),
                                ],
                                if (tx.stationName != null)
                                  Flexible(
                                    child: Text(
                                      tx.referenceStationName != null &&
                                              tx.referenceStationName !=
                                                  tx.stationName
                                          ? '${tx.stationName!} (${AppStrings.referenceStationShort}: ${tx.referenceStationName!})'
                                          : tx.stationName!,
                                      style: AppTypography.bodySecondary,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$sign ${AppFormatters.formatQuantity(tx.enteredQuantity)} ${tx.unitName ?? ''}',
                                style: TextStyle(
                                  fontSize: AppTypography.sizeBody + 1,
                                  fontWeight: AppTypography.weightBold,
                                  color: badgeColor,
                                ),
                              ),
                              Text(
                                '(${AppFormatters.formatQuantity(tx.baseQuantityLiters)} ${AppStrings.unitLiter})',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.spaceS),
                        Row(
                          children: [
                            const Icon(
                              AppIcons.statement,
                              size: AppDimensions.iconMini,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: AppDimensions.spaceXS),
                            Expanded(
                              child: Text(
                                tx.notes!,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  AppIcons.moreVert,
                  color: AppColors.textSecondary,
                  size: AppDimensions.iconRegular,
                ),
                color: AppColors.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppDimensions.borderRadiusM,
                  side: BorderSide(
                    color: AppColors.border,
                    width: AppDimensions.borderWidthThin,
                  ),
                ),
                onSelected: (action) {
                  if (action == 'details') {
                    _showTransactionDetails(tx);
                  } else if (action == 'edit') {
                    OperationEntrySheet.show(
                      context: context,
                      account: widget.account,
                      editTransaction: tx,
                    );
                  } else if (action == 'delete') {
                    _deleteTransaction(tx);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(
                          AppIcons.info,
                          size: AppDimensions.iconRegular,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: AppDimensions.spaceM),
                        Text(AppStrings.details, style: AppTypography.body),
                      ],
                    ),
                  ),
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
                        Text(AppStrings.edit, style: AppTypography.body),
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
                            color: AppColors.dispenseRed,
                            fontSize: AppTypography.sizeBody,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
