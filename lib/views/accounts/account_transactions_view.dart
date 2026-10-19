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
      _loadTransactions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions({int? fuelId}) async {
    if (widget.account.id == null) return;
    final ctrl = context.read<TransactionsController>();
    if (widget.account.accountType == AccountType.station) {
      await ctrl.fetchStationTransactions(widget.account.id!,
          defaultFuelTypeId: fuelId);
    } else {
      await ctrl.fetchAccountTransactions(widget.account.id!,
          defaultFuelTypeId: fuelId);
    }
  }

  void _openAddTransactionDialog() async {
    final controller = context.read<TransactionsController>();
    final currentFuelId = controller.selectedFuelTypeId;
    final isStation = widget.account.accountType == AccountType.station;
    final isSupplier = widget.account.accountType == AccountType.supplier;

    if (isStation) {
      await OperationEntrySheet.show(
        context: context,
        initialTabIndex: 1,
        initialDirection: 0,
        initialStationId: widget.account.id,
        initialFuelTypeId: currentFuelId,
      );
    } else {
      await OperationEntrySheet.show(
        context: context,
        account: widget.account,
        initialTabIndex: 0,
        initialDirection: isSupplier ? 0 : 1,
        initialFuelTypeId: currentFuelId,
      );
    }

    if (mounted) {
      await _loadTransactions(fuelId: currentFuelId);
    }
  }

  void _deleteTransaction(TransactionModel tx) async {
    final isStation = widget.account.accountType == AccountType.station;
    final txCtrl = context.read<TransactionsController>();
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: AppStrings.confirmExclamation,
      message: isStation
          ? AppStrings.confirmDeleteStationTransactionMsg
          : AppStrings.confirmDeleteTransactionShortMsg,
      confirmText: AppStrings.ok,
      cancelText: AppStrings.cancel,
      isDanger: true,
    );

    if (confirm && tx.id != null && widget.account.id != null && mounted) {
      final success = isStation
          ? await txCtrl.deleteStationTransaction(
                tx.id!,
                widget.account.id!,
              )
          : await txCtrl.deleteTransaction(
                tx.id!,
                widget.account.id!,
              );
      if (success && mounted) {
        AppSnackBar.showSuccess(context, AppStrings.transactionDeletedSuccess);
      }
    }
  }

  void _showTransactionDetails(TransactionModel tx) {
    final txCtrl = context.read<TransactionsController>();
    CustomDialog.showTransactionDetails(
      context: context,
      transaction: tx,
      accountPhone: widget.account.phoneNumber,
      onEdit: () {
        OperationEntrySheet.show(
          context: context,
          account: widget.account.accountType != AccountType.station
              ? widget.account
              : null,
          initialStationId: widget.account.accountType == AccountType.station
              ? widget.account.id
              : null,
          editTransaction: tx,
        ).then((_) {
          if (mounted) {
            _loadTransactions(
              fuelId: txCtrl.selectedFuelTypeId,
            );
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
                    await _loadTransactions(
                        fuelId: controller.selectedFuelTypeId);
                  },
                  child: ListView(
                    padding: AppDimensions.paddingScreen,
                    children: [
                      if (controller.activeFuelTypes.isNotEmpty) ...[
                        _buildSummaryCard(controller),
                        const SizedBox(height: AppDimensions.spaceL),
                      ],
                      _buildSectionHeader(controller),
                      const SizedBox(height: AppDimensions.spaceS),
                      if (controller.transactions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppDimensions.space3XL,
                          ),
                          child: EmptyStateWidget(
                            icon: widget.account.accountType == AccountType.station
                                ? AppIcons.gasStationOutlined
                                : AppIcons.tabQuota,
                            title: widget.account.accountType == AccountType.station
                                ? AppStrings.noStationTransactionsFound
                                : AppStrings.noTransactionsFound,
                            actionText: widget.account.accountType == AccountType.station
                                ? AppStrings.recordFirstStationOperation
                                : AppStrings.recordFirstOperation,
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

  Widget _buildSummaryCard(TransactionsController controller) {
    final isStation = widget.account.accountType == AccountType.station;
    final isSupplier = widget.account.accountType == AccountType.supplier;

    return FuelSummarySlider(
      fuelTypes: controller.activeFuelTypes,
      selectedFuelId: controller.selectedFuelTypeId,
      onFuelChanged: (fuelId) => controller.setSelectedFuelTypeId(fuelId),
      cardBuilder: (fuelId, fuelName) {
        if (isStation) {
          final supply = controller.getStationSupplyForFuel(fuelId);
          final dispense = controller.getStationDispenseForFuel(fuelId);
          final aeration = controller.getStationAerationForFuel(fuelId);
          final balance = controller.getStationBalanceForFuel(fuelId);

          return FuelCardData(
            title: widget.account.name,
            fuelName: fuelName,
            balance: balance,
            metrics: [
              FuelCardMetric(
                value: supply,
                label: AppStrings.actualSupply,
              ),
              FuelCardMetric(
                value: dispense,
                label: AppStrings.actualDispense,
              ),
              if (aeration > 0)
                FuelCardMetric(
                  value: aeration,
                  label: AppStrings.aerationCommission,
                ),
            ],
          );
        } else {
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
        }
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
    final bool isPositive =
        tx.typeId == 1 || tx.typeId == 2 || tx.typeId == 4 || tx.typeId == 7;
    final bool isAeration = tx.typeId == 3;
    final bool isTransfer = tx.typeId == 6 || tx.typeId == 7;

    final Color badgeColor = isPositive
        ? AppColors.supplyGreen
        : (isAeration ? AppColors.warning : AppColors.dispenseRed);

    final IconData opIcon = isTransfer
        ? AppIcons.transfer
        : (isPositive
            ? AppIcons.supply
            : (isAeration ? AppIcons.tabAeration : AppIcons.dispense));

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
                            if (isTransfer &&
                                tx.recipientName != null &&
                                tx.recipientName!.trim().isNotEmpty) ...[
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
                                  '${tx.isTransferOut ? AppStrings.toAccount : AppStrings.fromAccount}: ${tx.recipientName!.trim()}',
                                  style: const TextStyle(
                                    fontSize: AppTypography.sizeCaption,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ] else if (tx.stationName != null &&
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

              // 2. سطر اسم المستلم والمرجع (أيقونات فقط وبجانب بعضهما)
              if ((!isTransfer &&
                      tx.recipientName != null &&
                      tx.recipientName!.trim().isNotEmpty) ||
                  (tx.referenceNumber != null &&
                      tx.referenceNumber!.trim().isNotEmpty)) ...[
                const SizedBox(height: AppDimensions.spaceXS),
                Row(
                  children: [
                    if (!isTransfer &&
                        tx.recipientName != null &&
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
                      if (!isTransfer &&
                          tx.recipientName != null &&
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

              // 3. نص البيان / الملاحظة (ممتد على طول البطاقة بدون أيقونة وبدون خلفيات إضافية)
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
