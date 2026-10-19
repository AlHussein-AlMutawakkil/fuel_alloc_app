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
import '../../core/widgets/one_ui_card.dart';
import '../../core/widgets/operation_entry_sheet.dart';
import '../../models/station_model.dart';
import '../../models/transaction_model.dart';
import 'widgets/fuel_summary_card.dart';

/// واجهة كشف حساب وعمليات المحطة بتصميم One UI الموحد
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
    CustomDialog.showTransactionDetails(
      context: context,
      transaction: tx,
      onEdit: () {
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
      },
      onDelete: () => _deleteTransaction(tx),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionsController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: OneUiAppBar(
            title: widget.station.name,
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
                    if (widget.station.id != null) {
                      await controller
                          .fetchStationTransactions(widget.station.id!);
                    }
                  },
                  child: ListView(
                    padding: AppDimensions.paddingScreen,
                    children: [
                      if (controller.activeFuelTypes.isNotEmpty) ...[
                        _buildStationSummaryCard(controller),
                        const SizedBox(height: AppDimensions.spaceL),
                      ],
                      _buildFilterChips(controller),
                      const SizedBox(height: AppDimensions.spaceL),
                      _buildSectionHeader(controller),
                      const SizedBox(height: AppDimensions.spaceS),
                      if (controller.transactions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppDimensions.space3XL,
                          ),
                          child: EmptyStateWidget(
                            icon: AppIcons.gasStationOutlined,
                            title: AppStrings.noStationTransactionsFound,
                            actionText:
                                AppStrings.recordFirstStationOperation,
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

  Widget _buildFilterChips(TransactionsController controller) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
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
        ],
      ),
    );
  }

  Widget _buildStationSummaryCard(TransactionsController controller) {
    return FuelSummarySlider(
      fuelTypes: controller.activeFuelTypes,
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
    final bool isSupply = tx.typeId == 2;
    final bool isAeration = tx.typeId == 3;
    final bool isPositive = isSupply || isAeration;

    final Color badgeColor = isSupply
        ? AppColors.supplyGreen
        : (isAeration ? AppColors.warning : AppColors.dispenseRed);

    final IconData opIcon = isSupply
        ? AppIcons.supply
        : (isAeration ? AppIcons.tabAeration : AppIcons.dispense);

    final String sign = isPositive ? '+' : '-';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showTransactionDetails(tx),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceL,
            vertical: AppDimensions.spaceM + 2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. الصف الرئيسي: الأيقونة + البيانات + الكمية
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    opIcon,
                    size: AppDimensions.iconLarge,
                    color: badgeColor,
                  ),
                  const SizedBox(width: AppDimensions.spaceM),

                  // اسم العملية والحساب والتاريخ
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
                            if (tx.accountName != null &&
                                tx.accountName!.trim().isNotEmpty) ...[
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
                                  '${isSupply ? AppStrings.supplierPrefix : AppStrings.beneficiaryPrefix}${tx.accountName!}',
                                  style: const TextStyle(
                                    fontSize: AppTypography.sizeCaption,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            if (tx.referenceStationName != null &&
                                tx.referenceStationName != tx.stationName) ...[
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
                                  '${AppStrings.offsetDiscountFromPrefix}${tx.referenceStationName!}',
                                  style: const TextStyle(
                                    fontSize: AppTypography.sizeCaption,
                                    color: AppColors.infoText,
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

              // 2. سطر اسم المستلم والمرجع (أيقونات فقط وبجانب بعضهما)
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
                        size: AppDimensions.iconMicro,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: AppDimensions.spaceXS),
                      Text(
                        tx.recipientName!.trim(),
                        style: const TextStyle(
                          fontSize: AppTypography.sizeCaption,
                          fontWeight: AppTypography.weightMedium,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (tx.referenceNumber != null &&
                        tx.referenceNumber!.trim().isNotEmpty) ...[
                      if (tx.recipientName != null &&
                          tx.recipientName!.trim().isNotEmpty)
                        const SizedBox(width: AppDimensions.spaceM),
                      const Icon(
                        AppIcons.reference,
                        size: AppDimensions.iconMicro,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: AppDimensions.spaceXS),
                      Text(
                        tx.referenceNumber!.trim(),
                        style: const TextStyle(
                          fontSize: AppTypography.sizeCaption,
                          fontWeight: AppTypography.weightMedium,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              // 3. نص البيان / الملاحظة (إن وجد)
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
}
