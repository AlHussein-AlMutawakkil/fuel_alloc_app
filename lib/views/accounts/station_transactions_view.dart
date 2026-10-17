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
import '../../models/station_model.dart';
import '../../models/transaction_model.dart';
import 'widgets/fuel_summary_card.dart';

/// واجهة كشف حساب وعمليات المحطة (وارد فعلي، منصرف فعلي، عمولة تهوية، ومقاصات)
class StationTransactionsView extends StatefulWidget {
  final StationModel station;

  const StationTransactionsView({
    super.key,
    required this.station,
  });

  @override
  State<StationTransactionsView> createState() =>
      _StationTransactionsViewState();
}

class _StationTransactionsViewState extends State<StationTransactionsView> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.station.id != null) {
        context
            .read<TransactionsController>()
            .fetchStationTransactions(widget.station.id!);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddTransactionDialog() async {
    final controller = context.read<TransactionsController>();
    final currentFuelId = controller.selectedFuelTypeId;

    await OperationEntrySheet.show(
      context: context,
      initialTabIndex: 1,
      initialDirection: 0,
      initialStationId: widget.station.id,
      initialFuelTypeId: currentFuelId,
    );
    if (widget.station.id != null && mounted) {
      context.read<TransactionsController>().fetchStationTransactions(
            widget.station.id!,
            defaultFuelTypeId: currentFuelId,
          );
    }
  }

  void _deleteTransaction(TransactionModel tx) async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: AppStrings.confirmExclamation,
      message: AppStrings.confirmDeleteStationTransactionMsg,
      confirmText: AppStrings.ok,
      cancelText: AppStrings.cancel,
      isDanger: true,
    );

    if (confirm && tx.id != null && widget.station.id != null && mounted) {
      final success =
          await context.read<TransactionsController>().deleteStationTransaction(
                tx.id!,
                widget.station.id!,
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
        if (tx.accountName != null)
          DialogDetailRow(
            label: AppStrings.linkedAccountLabel,
            value: tx.accountName!,
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
                      hintText: AppStrings.searchStationTransactionsHint,
                      hintStyle: TextStyle(
                        color: AppColors.textWhite.withOpacity(0.7),
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => controller.setSearchQuery(val),
                  )
                : Text(
                    '${AppStrings.stationStatementPrefix}${widget.station.name}',
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
                  if (widget.station.id != null) {
                    controller.fetchStationTransactions(widget.station.id!);
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
                _buildStationSummaryCard(controller),
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
                      label: AppStrings.filterSupplyActual,
                      isSelected: controller.selectedFilter == 'SUPPLY',
                      onTap: () => controller.setFilter('SUPPLY'),
                    ),
                    const SizedBox(width: AppDimensions.spaceM),
                    AppFilterChip(
                      label: AppStrings.filterDispenseActual,
                      isSelected: controller.selectedFilter == 'DISPENSE',
                      onTap: () => controller.setFilter('DISPENSE'),
                    ),
                    const SizedBox(width: AppDimensions.spaceM),
                    AppFilterChip(
                      label: AppStrings.filterAeration,
                      isSelected: controller.selectedFilter == 'AERATION',
                      onTap: () => controller.setFilter('AERATION'),
                    ),
                    const Spacer(),
                    Text(
                      '${AppStrings.totalOperations}: ${_getFilteredTransactions(controller).length}',
                      style: AppTypography.captionBold,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceL + 2),
                Expanded(
                  child: controller.isLoading
                      ? const AppLoadingIndicator()
                      : _getFilteredTransactions(controller).isEmpty
                          ? EmptyStateWidget(
                              icon: AppIcons.gasStationOutlined,
                              title: AppStrings.noStationTransactionsFound,
                              actionText:
                                  AppStrings.recordFirstStationOperation,
                              actionIcon: AppIcons.add,
                              onAction: () => _openAddTransactionDialog(),
                            )
                          : ListView.separated(
                              itemCount:
                                  _getFilteredTransactions(controller).length,
                              separatorBuilder: (_, __) => const SizedBox(
                                height: AppDimensions.spaceM + 2,
                              ),
                              itemBuilder: (context, index) {
                                final tx =
                                    _getFilteredTransactions(controller)[index];
                                return _buildStationTransactionCard(tx);
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

  List<TransactionModel> _getFilteredTransactions(
      TransactionsController controller) {
    return controller.transactions;
  }

  Widget _buildStationSummaryCard(TransactionsController controller) {
    return FuelSummarySlider(
      fuelTypes: controller.fuelTypes,
      selectedFuelId: controller.selectedFuelTypeId,
      onFuelChanged: (fuelId) => controller.setSelectedFuelTypeId(fuelId),
      cardBuilder: (fuelId, fuelName) {
        final supply = controller.getStationSupplyForFuel(fuelId);
        final aeration = controller.getStationAerationForFuel(fuelId);
        final dispense = controller.getStationDispenseForFuel(fuelId);
        final balance = controller.getStationBalanceForFuel(fuelId);

        return FuelCardData(
          title: widget.station.name,
          fuelName: fuelName,
          balance: balance,
          secondaryTag:
              '${AppStrings.commissionRatePrefix}${widget.station.defaultCommissionRate}%',
          metrics: [
            FuelCardMetric(
              value: supply,
              label: AppStrings.actualSupply,
            ),
            FuelCardMetric(
              value: aeration,
              label: AppStrings.aerationCommissionTitle,
              valueColor: AppColors.warning,
            ),
            FuelCardMetric(
              value: dispense,
              label: AppStrings.actualDispense,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStationTransactionCard(TransactionModel tx) {
    final bool isSupply = tx.typeId == 2;
    final bool isDispense = tx.typeId == 5;
    final bool isAeration = tx.typeId == 3;

    final Color badgeColor = isDispense
        ? AppColors.dispenseRed
        : (isAeration ? AppColors.warning : AppColors.supplyGreen);

    final Color badgeBg = isDispense
        ? AppColors.dispenseLight
        : (isAeration ? AppColors.warningLight : AppColors.supplyLight);

    final String sign = isSupply ? '+' : '-';

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
                              style: TextStyle(
                                fontSize: AppTypography.sizeCaption,
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
                                if (tx.accountName != null)
                                  Flexible(
                                    child: Text(
                                      '${isSupply ? AppStrings.supplierPrefix : AppStrings.beneficiaryPrefix} ${tx.accountName!}',
                                      style:
                                          AppTypography.bodySecondary.copyWith(
                                        fontWeight:
                                            AppTypography.weightSemiBold,
                                      ),
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
                      if (tx.referenceStationName != null &&
                          tx.referenceStationName != tx.stationName) ...[
                        const SizedBox(height: AppDimensions.spaceXS),
                        Container(
                          padding: AppDimensions.paddingMiniTag,
                          decoration: const BoxDecoration(
                            color: AppColors.infoLight,
                            borderRadius: AppDimensions.borderRadiusXS,
                          ),
                          child: Text(
                            '${AppStrings.offsetDiscountFromPrefix}${tx.referenceStationName!}',
                            style: const TextStyle(
                              fontSize: AppTypography.sizeSmall,
                              color: AppColors.infoText,
                            ),
                          ),
                        ),
                      ],
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
                      editTransaction: tx,
                    ).then((_) {
                      if (widget.station.id != null && mounted) {
                        context
                            .read<TransactionsController>()
                            .fetchStationTransactions(widget.station.id!);
                      }
                    });
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
