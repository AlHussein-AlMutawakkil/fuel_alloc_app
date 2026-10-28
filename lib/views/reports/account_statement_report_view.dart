import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/personal_info_controller.dart';
import '../../controllers/reports_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/custom_modal_sheet.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/filter_chip_widget.dart';
import '../../core/widgets/one_ui_card.dart';
import '../../models/account_model.dart';
import '../../models/statement_item_model.dart';
import '../../models/station_model.dart';

/// واجهة كشف الحساب التفصيلي الموحد (للموردين، المحطات، والمستفيدين)
class AccountStatementReportView extends StatefulWidget {
  final AccountType accountType;
  final int? initialAccountId;

  const AccountStatementReportView({
    super.key,
    required this.accountType,
    this.initialAccountId,
  });

  @override
  State<AccountStatementReportView> createState() =>
      _AccountStatementReportViewState();
}

class _AccountStatementReportViewState
    extends State<AccountStatementReportView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initReport();
    });
  }

  Future<void> _initReport() async {
    final reportsCtrl = context.read<ReportsController>();
    await reportsCtrl.initializeData();

    if (widget.initialAccountId != null) {
      if (widget.accountType == AccountType.station) {
        final match = reportsCtrl.allStations.firstWhere(
          (s) => s.id == widget.initialAccountId,
          orElse: () => reportsCtrl.allStations.isNotEmpty
              ? reportsCtrl.allStations.first
              : StationModel(name: ''),
        );
        if (match.id != null) {
          reportsCtrl.setSelectedStation(match);
        }
      } else {
        final list = widget.accountType == AccountType.supplier
            ? reportsCtrl.suppliers
            : reportsCtrl.beneficiaries;
        final match = list.firstWhere(
          (a) => a.id == widget.initialAccountId,
          orElse: () => list.isNotEmpty
              ? list.first
              : AccountModel(name: '', accountType: widget.accountType),
        );
        if (match.id != null) {
          reportsCtrl.setSelectedAccount(match);
        }
      }
    } else {
      // اختيار أول حساب افتراضياً إن وجد
      if (widget.accountType == AccountType.station &&
          reportsCtrl.allStations.isNotEmpty) {
        reportsCtrl.setSelectedStation(reportsCtrl.allStations.first);
      } else if (widget.accountType == AccountType.supplier &&
          reportsCtrl.suppliers.isNotEmpty) {
        reportsCtrl.setSelectedAccount(reportsCtrl.suppliers.first);
      } else if (widget.accountType == AccountType.beneficiary &&
          reportsCtrl.beneficiaries.isNotEmpty) {
        reportsCtrl.setSelectedAccount(reportsCtrl.beneficiaries.first);
      }
    }
  }

  String get _reportTitle {
    switch (widget.accountType) {
      case AccountType.supplier:
        return AppStrings.reportSupplierStatementTitle;
      case AccountType.station:
        return AppStrings.reportStationStatementTitle;
      case AccountType.beneficiary:
        return AppStrings.reportBeneficiaryStatementTitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsController>(
      builder: (context, reportsCtrl, _) {
        final accountName = reportsCtrl.selectedStation?.name ??
            reportsCtrl.selectedAccount?.name ??
            '';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: OneUiAppBar(
            title: _reportTitle,
            showBackButton: true,
            actions: [
              if (accountName.isNotEmpty) ...[
                IconButton(
                  tooltip: AppStrings.printReport,
                  icon: const Icon(AppIcons.print, size: AppDimensions.iconLarge),
                  color: AppColors.primary,
                  onPressed: () {
                    final pInfo = context.read<PersonalInfoController>().info;
                    reportsCtrl.printStatement(
                      personalInfo: pInfo,
                      title: _reportTitle,
                    );
                  },
                ),
                IconButton(
                  tooltip: AppStrings.shareReport,
                  icon: const Icon(AppIcons.share, size: AppDimensions.iconLarge),
                  color: AppColors.primary,
                  onPressed: () {
                    final pInfo = context.read<PersonalInfoController>().info;
                    reportsCtrl.shareStatement(
                      personalInfo: pInfo,
                      title: _reportTitle,
                    );
                  },
                ),
                const SizedBox(width: AppDimensions.spaceXS),
              ],
            ],
          ),
          body: Column(
            children: [
              // 1. شريط اختيار الحساب والفترة
              _buildAccountAndDateFilterRow(reportsCtrl),

              // 2. شريط اختيار صنف الوقود
              _buildFuelTypeSegment(reportsCtrl),

              // 3. شريط نوع العملية (فلتر chips)
              _buildOperationFilterChips(reportsCtrl),

              // 4. بطاقة ملخص الأرصدة
              _buildSummaryHeader(reportsCtrl),

              // 5. جدول أو قائمة كشف الحساب
              Expanded(
                child: reportsCtrl.isStatementLoading
                    ? const Center(child: AppLoadingIndicator())
                    : _buildStatementContent(reportsCtrl),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 1. شريط اختيار الحساب وتحديد الفترة
  Widget _buildAccountAndDateFilterRow(ReportsController reportsCtrl) {
    final accountName = reportsCtrl.selectedStation?.name ??
        reportsCtrl.selectedAccount?.name ??
        AppStrings.selectAccountPrompt;

    final hasDateFilter = reportsCtrl.statementFromDate != null ||
        reportsCtrl.statementToDate != null;

    String dateLabel = AppStrings.allDates;
    if (reportsCtrl.statementFromDate != null &&
        reportsCtrl.statementToDate != null) {
      dateLabel =
          '${reportsCtrl.statementFromDate!.year}/${reportsCtrl.statementFromDate!.month} - ${reportsCtrl.statementToDate!.year}/${reportsCtrl.statementToDate!.month}';
    } else if (reportsCtrl.statementFromDate != null) {
      dateLabel = 'من ${reportsCtrl.statementFromDate!.year}/${reportsCtrl.statementFromDate!.month}';
    }

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceXL,
        vertical: AppDimensions.spaceS,
      ),
      child: Row(
        children: [
          // زر اختيار الحساب
          Expanded(
            flex: 6,
            child: InkWell(
              onTap: () => _showAccountPicker(reportsCtrl),
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceM,
                  vertical: AppDimensions.spaceS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.chipBackground,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.accountType == AccountType.station
                          ? AppIcons.gasStation
                          : AppIcons.account,
                      size: AppDimensions.iconMedium,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppDimensions.spaceS),
                    Expanded(
                      child: Text(
                        accountName,
                        style: const TextStyle(
                          fontSize: AppTypography.sizeBodySecondary,
                          fontWeight: AppTypography.weightBold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      AppIcons.dropdownArrow,
                      size: AppDimensions.iconSmall,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceS),

          // زر تحديد الفترة
          Expanded(
            flex: 4,
            child: InkWell(
              onTap: () => _pickDateRange(reportsCtrl),
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceM,
                  vertical: AppDimensions.spaceS,
                ),
                decoration: BoxDecoration(
                  color: hasDateFilter ? AppColors.infoLight : AppColors.chipBackground,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  border: Border.all(
                    color: hasDateFilter ? AppColors.info : AppColors.borderSubtle,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      AppIcons.calendar,
                      size: AppDimensions.iconSmall + 2,
                      color: hasDateFilter ? AppColors.infoText : AppColors.textTertiary,
                    ),
                    const SizedBox(width: AppDimensions.spaceXS),
                    Expanded(
                      child: Text(
                        dateLabel,
                        style: TextStyle(
                          fontSize: AppTypography.sizeMicro + 0.5,
                          fontWeight: hasDateFilter
                              ? AppTypography.weightBold
                              : AppTypography.weightMedium,
                          color: hasDateFilter ? AppColors.infoText : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // زر مسح الفلترة الزمنية
          if (hasDateFilter) ...[
            const SizedBox(width: AppDimensions.spaceXS),
            InkWell(
              onTap: () {
                reportsCtrl.setStatementDateRange(null, null);
              },
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.spaceS),
                decoration: BoxDecoration(
                  color: AppColors.dispenseLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                ),
                child: const Icon(
                  AppIcons.close,
                  size: AppDimensions.iconSmall,
                  color: AppColors.dispenseRed,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showAccountPicker(ReportsController reportsCtrl) async {
    if (widget.accountType == AccountType.station) {
      final selected = await CustomModalSheet.showItemPicker<StationModel>(
        context: context,
        title: AppStrings.selectStationPrompt,
        items: reportsCtrl.allStations,
        selectedItem: reportsCtrl.selectedStation,
        itemLabel: (s) => s.name,
        searchHint: AppStrings.searchStationsHint,
      );
      if (selected != null) {
        reportsCtrl.setSelectedStation(selected);
      }
    } else {
      final list = widget.accountType == AccountType.supplier
          ? reportsCtrl.suppliers
          : reportsCtrl.beneficiaries;
      final selected = await CustomModalSheet.showItemPicker<AccountModel>(
        context: context,
        title: widget.accountType == AccountType.supplier
            ? AppStrings.selectSupplierPrompt
            : AppStrings.selectBeneficiaryPrompt,
        items: list,
        selectedItem: reportsCtrl.selectedAccount,
        itemLabel: (a) => a.name,
        searchHint: AppStrings.searchAccountHint,
      );
      if (selected != null) {
        reportsCtrl.setSelectedAccount(selected);
      }
    }
  }

  Future<void> _pickDateRange(ReportsController reportsCtrl) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: reportsCtrl.statementFromDate != null &&
              reportsCtrl.statementToDate != null
          ? DateTimeRange(
              start: reportsCtrl.statementFromDate!,
              end: reportsCtrl.statementToDate!,
            )
          : DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: now,
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textWhite,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      reportsCtrl.setStatementDateRange(picked.start, picked.end);
    }
  }

  /// 2. تبويب صنف الوقود
  Widget _buildFuelTypeSegment(ReportsController reportsCtrl) {
    final fuelTypes = reportsCtrl.fuelTypes;
    if (fuelTypes.isEmpty) return const SizedBox.shrink();

    final currentId = reportsCtrl.statementFuelTypeId;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceXL,
        vertical: AppDimensions.spaceXS,
      ),
      child: Container(
        padding: AppDimensions.paddingAllXS,
        decoration: const BoxDecoration(
          color: AppColors.segmentBackground,
          borderRadius: AppDimensions.borderRadiusXL,
        ),
        child: Row(
          children: [
            // خيار "الكل"
            Expanded(
              child: _buildFuelSegmentItem(
                title: AppStrings.allAccounts,
                isSelected: currentId == null,
                onTap: () => reportsCtrl.setStatementFuelTypeId(null),
              ),
            ),
            ...fuelTypes.map((ft) {
              final id = ft['id'] as int;
              final name = ft['name'] as String;
              return Expanded(
                child: _buildFuelSegmentItem(
                  title: name,
                  isSelected: currentId == id,
                  onTap: () => reportsCtrl.setStatementFuelTypeId(id),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFuelSegmentItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: AppColors.shadowSubtle,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: AppTypography.sizeBodySecondary,
            fontWeight: isSelected
                ? AppTypography.weightBold
                : AppTypography.weightMedium,
            color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }

  /// 3. شريط أنواع العمليات (All, Quota, Actual, etc.)
  Widget _buildOperationFilterChips(ReportsController reportsCtrl) {
    final current = reportsCtrl.statementFilter;

    final chips = <MapEntry<String, String>>[
      const MapEntry('ALL', AppStrings.allOperations),
      if (widget.accountType == AccountType.station) ...[
        const MapEntry('SUPPLY', AppStrings.supplyTransactionsTitle),
        const MapEntry('DISPENSE', AppStrings.dispenseTransactionsTitle),
        const MapEntry('AERATION', AppStrings.aerationTransactionsTitle),
        const MapEntry('TRANSFER', AppStrings.transferTransactionsTitle),
      ] else ...[
        const MapEntry('QUOTA', AppStrings.tabQuota),
        const MapEntry('ACTUAL', AppStrings.tabActual),
        const MapEntry('TRANSFER', AppStrings.tabTransfer),
      ],
    ];

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceXL,
        vertical: AppDimensions.spaceXS,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips.map((e) {
            return Padding(
              padding: const EdgeInsets.only(left: AppDimensions.spaceXS),
              child: AppFilterChip(
                label: e.value,
                isSelected: current == e.key,
                onTap: () => reportsCtrl.setStatementFilter(e.key),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 4. بطاقة ملخص الأرصدة
  Widget _buildSummaryHeader(ReportsController reportsCtrl) {
    final items = reportsCtrl.statementItems;
    double totalIn = 0.0;
    double totalOut = 0.0;

    for (final it in items) {
      totalIn += it.inflow;
      totalOut += it.outflow;
    }

    final latestBalance =
        items.isNotEmpty ? items.first.runningBalance : 0.0;

    String inflowTitle;
    String outflowTitle;
    String balanceTitle;

    if (widget.accountType == AccountType.station) {
      inflowTitle = AppStrings.supplyActual;
      outflowTitle = AppStrings.dispenseActual;
      balanceTitle = AppStrings.totalAvailableStock;
    } else if (widget.accountType == AccountType.supplier) {
      inflowTitle = AppStrings.supplyQuota;
      outflowTitle = AppStrings.supplyActual;
      balanceTitle = AppStrings.balanceQuota;
    } else {
      inflowTitle = AppStrings.dispenseQuota;
      outflowTitle = AppStrings.dispenseActual;
      balanceTitle = AppStrings.balanceQuota;
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceXL,
        vertical: AppDimensions.spaceS,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceL,
        vertical: AppDimensions.spaceM,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSubtle,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricItem(
              title: inflowTitle,
              value: totalIn,
              valueColor: AppColors.supplyGreen,
            ),
          ),
          const SizedBox(
            height: 35,
            child: VerticalDivider(
              color: AppColors.divider,
              thickness: AppDimensions.borderWidthThin,
            ),
          ),
          Expanded(
            child: _buildMetricItem(
              title: outflowTitle,
              value: totalOut,
              valueColor: AppColors.dispenseRed,
            ),
          ),
          const SizedBox(
            height: 35,
            child: VerticalDivider(
              color: AppColors.divider,
              thickness: AppDimensions.borderWidthThin,
            ),
          ),
          Expanded(
            child: _buildMetricItem(
              title: balanceTitle,
              value: latestBalance,
              valueColor: AppColors.primary,
              isBold: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String title,
    required double value,
    required Color valueColor,
    bool isBold = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          AppFormatters.formatQuantity(value),
          style: TextStyle(
            fontSize: AppTypography.sizeBodySecondary,
            fontWeight: isBold
                ? AppTypography.weightBold
                : AppTypography.weightSemiBold,
            color: valueColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        Text(
          title,
          style: const TextStyle(
            fontSize: AppTypography.sizeMicro,
            color: AppColors.textMuted,
            fontWeight: AppTypography.weightMedium,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// 5. محتوى الجدول وقائمة العمليات
  Widget _buildStatementContent(ReportsController reportsCtrl) {
    final items = reportsCtrl.statementItems;

    if (items.isEmpty) {
      return const Center(
        child: EmptyStateWidget(
          icon: AppIcons.statement,
          title: AppStrings.noStatementTransactions,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceXL,
        vertical: AppDimensions.spaceXS,
      ),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.spaceS),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildStatementItemCard(item, index + 1);
      },
    );
  }

  Widget _buildStatementItemCard(StatementItemModel item, int serial) {
    Color badgeBg;
    Color badgeText;
    IconData typeIcon;

    if (item.transaction.isSupply) {
      badgeBg = AppColors.supplyLight;
      badgeText = AppColors.supplyGreen;
      typeIcon = AppIcons.supply;
    } else if (item.transaction.isDispense) {
      badgeBg = AppColors.dispenseLight;
      badgeText = AppColors.dispenseRed;
      typeIcon = AppIcons.dispense;
    } else if (item.transaction.isAeration) {
      badgeBg = AppColors.warningLight;
      badgeText = AppColors.warning;
      typeIcon = AppIcons.tabAeration;
    } else {
      badgeBg = AppColors.infoLight;
      badgeText = AppColors.infoText;
      typeIcon = AppIcons.transfer;
    }

    final String qtyUnit =
        '${AppFormatters.formatQuantity(item.enteredQuantity)} ${item.unitName ?? ''}';

    final String refOrRecipient = item.recipientName?.isNotEmpty == true
        ? item.recipientName!
        : (item.referenceNumber ?? '');

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // الصف العلوي: الرقم التسلسلي، التاريخ، نوع العملية
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.chipBackground,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$serial',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeMicro,
                    color: AppColors.textTertiary,
                    fontWeight: AppTypography.weightBold,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceS),
              Text(
                item.transactionDate,
                style: const TextStyle(
                  fontSize: AppTypography.sizeBodySecondary,
                  fontWeight: AppTypography.weightMedium,
                  color: AppColors.textSecondary,
                ),
              ),
              if (item.transactionNumber != null) ...[
                const SizedBox(width: AppDimensions.spaceS),
                Text(
                  '• ${item.transactionNumber}',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeMicro,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(typeIcon, size: AppDimensions.iconSmall - 2, color: badgeText),
                    const SizedBox(width: AppDimensions.spaceXXS),
                    Text(
                      item.typeName ?? '',
                      style: TextStyle(
                        fontSize: AppTypography.sizeMicro,
                        fontWeight: AppTypography.weightBold,
                        color: badgeText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spaceS),
          const Divider(height: 1, thickness: AppDimensions.borderWidthHairline, color: AppColors.borderSubtle),
          const SizedBox(height: AppDimensions.spaceS),

          // الصف الأوسط: الكمية، الصنف، والمستلم أو المرجع
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        qtyUnit,
                        style: const TextStyle(
                          fontSize: AppTypography.sizeBody,
                          fontWeight: AppTypography.weightBold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceXS),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.chipBackground,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                        ),
                        child: Text(
                          item.fuelTypeName ?? '',
                          style: const TextStyle(
                            fontSize: AppTypography.sizeMicro,
                            color: AppColors.textDarkSlate,
                            fontWeight: AppTypography.weightMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (refOrRecipient.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        refOrRecipient,
                        style: const TextStyle(
                          fontSize: AppTypography.sizeSmall,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                ],
              ),

              // الرصيد الجاري في نهاية الصف
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    AppStrings.statementRunningBalance,
                    style: TextStyle(
                      fontSize: AppTypography.sizeMicro,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    '${AppFormatters.formatQuantity(item.runningBalance)} ${AppStrings.unitLiter}',
                    style: const TextStyle(
                      fontSize: AppTypography.sizeBody,
                      fontWeight: AppTypography.weightBold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spaceXS),
            Text(
              item.notes!,
              style: const TextStyle(
                fontSize: AppTypography.sizeMicro,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

