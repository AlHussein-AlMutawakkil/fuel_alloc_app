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
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/filter_chip_widget.dart';
import '../../core/widgets/one_ui_card.dart';
import '../../models/account_model.dart';
import '../../models/reconciliation_item_model.dart';
import 'account_statement_report_view.dart';

enum ReconciliationMode {
  supplier,
  station,
  beneficiary,
}

/// واجهة تقرير المطابقة والمراقبة (موردين، محطات، مستفيدين)
class ReconciliationReportView extends StatefulWidget {
  final ReconciliationMode mode;

  const ReconciliationReportView({
    super.key,
    required this.mode,
  });

  @override
  State<ReconciliationReportView> createState() =>
      _ReconciliationReportViewState();
}

class _ReconciliationReportViewState extends State<ReconciliationReportView> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final ctrl = context.read<ReportsController>();
    await ctrl.initializeData();
    _fetchModeData();
  }

  void _fetchModeData() {
    final ctrl = context.read<ReportsController>();
    switch (widget.mode) {
      case ReconciliationMode.supplier:
        ctrl.fetchSupplierReconciliation();
        break;
      case ReconciliationMode.station:
        ctrl.fetchStationReconciliation();
        break;
      case ReconciliationMode.beneficiary:
        ctrl.fetchBeneficiaryReconciliation();
        break;
    }
  }

  String get _title {
    switch (widget.mode) {
      case ReconciliationMode.supplier:
        return AppStrings.reportSupplierReconciliationTitle;
      case ReconciliationMode.station:
        return AppStrings.reportStationReconciliationTitle;
      case ReconciliationMode.beneficiary:
        return AppStrings.reportBeneficiaryReconciliationTitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsController>(
      builder: (context, reportsCtrl, _) {
        final items = reportsCtrl.reconciliationItems;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: OneUiAppBar(
            title: _title,
            showBackButton: true,
            actions: [
              IconButton(
                tooltip: AppStrings.printReport,
                icon: const Icon(AppIcons.print, size: AppDimensions.iconLarge),
                color: AppColors.primary,
                onPressed: () {
                  final pInfo = context.read<PersonalInfoController>().info;
                  reportsCtrl.printReconciliation(
                    personalInfo: pInfo,
                    title: _title,
                  );
                },
              ),
              const SizedBox(width: AppDimensions.spaceXS),
            ],
          ),
          body: Column(
            children: [
              // 1. شريط البحث السريع
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceXL,
                  vertical: AppDimensions.spaceS,
                ),
                child: CustomTextField(
                  controller: _searchCtrl,
                  hint: AppStrings.searchHere,
                  prefixIcon: const Icon(AppIcons.search, size: AppDimensions.iconMedium, color: AppColors.textTertiary),
                  onChanged: (val) {
                    reportsCtrl.setReconciliationSearch(val);
                    _fetchModeData();
                  },
                ),
              ),

              // 2. شريط اختيار صنف الوقود
              _buildFuelTypeSegment(reportsCtrl),

              // 3. شريط فلترة الحالة (الكل، متوفر، وشيك، منتهي)
              _buildStatusFilterRow(reportsCtrl),

              // 4. بطاقة الإجماليات
              _buildTotalSummaryCard(items),

              // 5. محتوى القائمة
              Expanded(
                child: reportsCtrl.isReconciliationLoading
                    ? const Center(child: AppLoadingIndicator())
                    : _buildReconciliationList(items),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFuelTypeSegment(ReportsController reportsCtrl) {
    final fuelTypes = reportsCtrl.fuelTypes;
    if (fuelTypes.isEmpty) return const SizedBox.shrink();

    final currentId = reportsCtrl.reconciliationFuelTypeId;

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
            Expanded(
              child: _buildFuelSegmentItem(
                title: AppStrings.allAccounts,
                isSelected: currentId == null,
                onTap: () {
                  reportsCtrl.setReconciliationFuelTypeId(null);
                  _fetchModeData();
                },
              ),
            ),
            ...fuelTypes.map((ft) {
              final id = ft['id'] as int;
              final name = ft['name'] as String;
              return Expanded(
                child: _buildFuelSegmentItem(
                  title: name,
                  isSelected: currentId == id,
                  onTap: () {
                    reportsCtrl.setReconciliationFuelTypeId(id);
                    _fetchModeData();
                  },
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

  Widget _buildStatusFilterRow(ReportsController reportsCtrl) {
    final current = reportsCtrl.reconciliationStatusFilter;

    final chips = <MapEntry<ReconciliationStatus?, String>>[
      const MapEntry(null, AppStrings.filterAllStatuses),
      const MapEntry(ReconciliationStatus.available, AppStrings.statusAvailable),
      const MapEntry(ReconciliationStatus.warning, AppStrings.statusWarning),
      const MapEntry(ReconciliationStatus.depleted, AppStrings.statusDepleted),
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
                onTap: () {
                  reportsCtrl.setReconciliationStatusFilter(e.key);
                  _fetchModeData();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTotalSummaryCard(List<ReconciliationItemModel> items) {
    double totalQuota = 0.0;
    double totalActual = 0.0;
    double totalBalance = 0.0;

    for (final it in items) {
      totalQuota += it.quota;
      totalActual += it.actual;
      totalBalance += it.balance;
    }

    String label1;
    String label2;
    String label3;

    if (widget.mode == ReconciliationMode.station) {
      label1 = AppStrings.supplyActual;
      label2 = AppStrings.dispenseActual;
      label3 = AppStrings.totalAvailableStock;
    } else {
      label1 = AppStrings.quotaCol;
      label2 = AppStrings.actualCol;
      label3 = AppStrings.totalRemainingQuota;
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
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryMetric(
              title: label1,
              value: totalQuota,
              color: AppColors.textPrimary,
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
            child: _buildSummaryMetric(
              title: label2,
              value: totalActual,
              color: AppColors.supplyGreen,
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
            child: _buildSummaryMetric(
              title: label3,
              value: totalBalance,
              color: AppColors.primary,
              isBold: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric({
    required String title,
    required double value,
    required Color color,
    bool isBold = false,
  }) {
    return Column(
      children: [
        Text(
          AppFormatters.formatQuantity(value),
          style: TextStyle(
            fontSize: AppTypography.sizeBodySecondary,
            fontWeight: isBold ? AppTypography.weightBold : AppTypography.weightSemiBold,
            color: color,
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

  Widget _buildReconciliationList(List<ReconciliationItemModel> items) {
    if (items.isEmpty) {
      return const Center(
        child: EmptyStateWidget(
          icon: AppIcons.tableChart,
          title: AppStrings.noReconciliationData,
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
        return _buildReconciliationCard(item);
      },
    );
  }

  Widget _buildReconciliationCard(ReconciliationItemModel item) {
    Color statusBg;
    Color statusText;
    String statusLabel;

    switch (item.status) {
      case ReconciliationStatus.available:
        statusBg = AppColors.supplyLight;
        statusText = AppColors.supplyGreen;
        statusLabel = AppStrings.statusAvailable;
        break;
      case ReconciliationStatus.warning:
        statusBg = AppColors.warningLight;
        statusText = AppColors.warning;
        statusLabel = AppStrings.statusWarning;
        break;
      case ReconciliationStatus.depleted:
        statusBg = AppColors.dispenseLight;
        statusText = AppColors.dispenseRed;
        statusLabel = AppStrings.statusDepleted;
        break;
    }

    return InkWell(
      onTap: () {
        // الانتقال المباشر لكشف حساب هذا الكيان
        AccountType targetType;
        if (item.accountType == 'STATION') {
          targetType = AccountType.station;
        } else if (item.accountType == 'SUPPLIER') {
          targetType = AccountType.supplier;
        } else {
          targetType = AccountType.beneficiary;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AccountStatementReportView(
              accountType: targetType,
              initialAccountId: item.accountId,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ترويسة الكرت: الاسم، الصنف، وشارة الحالة
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.accountName,
                        style: const TextStyle(
                          fontSize: AppTypography.sizeBody,
                          fontWeight: AppTypography.weightBold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.phoneNumber != null || item.location != null)
                        Text(
                          item.location ?? item.phoneNumber ?? '',
                          style: const TextStyle(
                            fontSize: AppTypography.sizeMicro,
                            color: AppColors.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.chipBackground,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                  ),
                  child: Text(
                    item.fuelTypeName,
                    style: const TextStyle(
                      fontSize: AppTypography.sizeMicro,
                      fontWeight: AppTypography.weightBold,
                      color: AppColors.textDarkSlate,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceS),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: AppTypography.sizeMicro,
                      fontWeight: AppTypography.weightBold,
                      color: statusText,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.spaceS),

            // صندوق الأرقام المقتضبة
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceM,
                vertical: AppDimensions.spaceS,
              ),
              decoration: BoxDecoration(
                color: AppColors.highlightBackground,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildColumnMetric(
                      title: widget.mode == ReconciliationMode.station
                          ? AppStrings.supplyActual
                          : AppStrings.quotaCol,
                      value: widget.mode == ReconciliationMode.station ? item.actual : item.quota,
                    ),
                  ),
                  Expanded(
                    child: _buildColumnMetric(
                      title: widget.mode == ReconciliationMode.station
                          ? AppStrings.dispenseActual
                          : AppStrings.actualCol,
                      value: widget.mode == ReconciliationMode.station ? item.quota : item.actual,
                      valueColor: AppColors.supplyGreen,
                    ),
                  ),
                  Expanded(
                    child: _buildColumnMetric(
                      title: widget.mode == ReconciliationMode.station
                          ? AppStrings.totalAvailableStock
                          : AppStrings.remainingCol,
                      value: item.balance,
                      valueColor: AppColors.primary,
                      isBold: true,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.spaceS),

            // شريط نسبة الإنجاز والتنفيذ
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    child: LinearProgressIndicator(
                      value: item.ratio,
                      backgroundColor: AppColors.borderSubtle,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        item.status == ReconciliationStatus.depleted
                            ? AppColors.dispenseRed
                            : (item.status == ReconciliationStatus.warning
                                ? AppColors.warning
                                : AppColors.supplyGreen),
                      ),
                      minHeight: 5,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceS),
                Text(
                  '${item.percent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: AppTypography.sizeMicro,
                    fontWeight: AppTypography.weightBold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceXS),
                const Icon(
                  AppIcons.chevronRight,
                  size: AppDimensions.iconSmall - 2,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnMetric({
    required String title,
    required double value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Column(
      children: [
        Text(
          AppFormatters.formatQuantity(value),
          style: TextStyle(
            fontSize: AppTypography.sizeBodySecondary,
            fontWeight: isBold ? AppTypography.weightBold : AppTypography.weightMedium,
            color: valueColor ?? AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: AppTypography.sizeMicro,
            color: AppColors.textMuted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
